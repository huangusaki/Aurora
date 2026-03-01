import 'package:aurora/features/studio/application/agent_workflow/agent_workflow_runner.dart';
import 'package:aurora/features/studio/application/agent_workflow/agent_workflow_value.dart';
import 'package:aurora/features/studio/domain/agent_workflow/agent_workflow_models.dart';
import 'package:aurora/features/studio/domain/agent_workflow/agent_workflow_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

AgentWorkflowPort _out(AgentWorkflowNode node, String name) =>
    node.outputs.firstWhere((p) => p.name.trim() == name);

AgentWorkflowPort _in(AgentWorkflowNode node, String name) =>
    node.inputs.firstWhere((p) => p.name.trim() == name);

void main() {
  group('AgentWorkflowRunner', () {
    test('runs nodes serially and returns End output', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();

      final llm = AgentWorkflowNode.createLlm().copyWith(
        title: 'LLM1',
        bodyTemplate: 'Echo: {{input}}',
      );

      final skill = AgentWorkflowNode.createSkill().copyWith(
        title: 'SK1',
        bodyTemplate: '{{input}} + skill',
        skillId: 'demo',
      );

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, llm, skill, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: llm.id,
            toPortId: _in(llm, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: llm.id,
            fromPortId: _out(llm, 'result').id,
            toNodeId: skill.id,
            toPortId: _in(skill, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: skill.id,
            fromPortId: _out(skill, 'result').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      final executed = <String>[];
      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async {
          executed.add(node.title);
          if (node.type == AgentWorkflowNodeType.llm) {
            return AgentWorkflowValue.fromText('LLM(${req.renderedBody})');
          }
          if (node.type == AgentWorkflowNodeType.skill) {
            return AgentWorkflowValue.fromText('SKILL(${req.renderedBody})');
          }
          throw StateError('unexpected');
        },
      );

      final updates = <AgentWorkflowNodeRunUpdate>[];
      final result = await runner.run(
        template: t,
        startInput: 'hi',
        onUpdate: updates.add,
        shouldStop: () => false,
        onRequestUserInput: (_, __) async => null,
      );

      expect(result.success, isTrue);
      expect(result.finalOutput, equals('SKILL(LLM(Echo: hi) + skill)'));
      expect(executed, equals(['LLM1', 'SK1']));
      expect(
        updates.any((u) => u.status == AgentWorkflowNodeRunStatus.running),
        isTrue,
      );
    });

    test('broadcasts the same output across multiple output ports', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();

      final multiOut = AgentWorkflowNode.createLlm().copyWith(
        title: 'Multi',
        outputs: [
          AgentWorkflowPort(id: const Uuid().v4(), name: 'a'),
          AgentWorkflowPort(id: const Uuid().v4(), name: 'b'),
          AgentWorkflowPort(id: const Uuid().v4(), name: 'error'),
        ],
        bodyTemplate: '{{input}}',
      );

      final next = AgentWorkflowNode.createLlm().copyWith(
        title: 'Next',
        inputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'x')],
        bodyTemplate: '->{{x}}',
      );

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, multiOut, next, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: multiOut.id,
            toPortId: _in(multiOut, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: multiOut.id,
            fromPortId: _out(multiOut, 'b').id,
            toNodeId: next.id,
            toPortId: _in(next, 'x').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: next.id,
            fromPortId: _out(next, 'result').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async =>
            AgentWorkflowValue.fromText('[${node.title}]${req.renderedBody}'),
      );

      final result = await runner.run(
        template: t,
        startInput: 'S',
        onUpdate: (_) {},
        shouldStop: () => false,
        onRequestUserInput: (_, __) async => null,
      );

      expect(result.success, isTrue);
      expect(result.finalOutput, equals('[Next]->[Multi]S'));
    });

    test('unhandled executor error stops the run', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final a = AgentWorkflowNode.createLlm().copyWith(title: 'A');
      final b = AgentWorkflowNode.createLlm().copyWith(title: 'B');

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, a, b, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: a.id,
            toPortId: _in(a, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: a.id,
            fromPortId: _out(a, 'result').id,
            toNodeId: b.id,
            toPortId: _in(b, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: b.id,
            fromPortId: _out(b, 'result').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      final executed = <String>[];
      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async {
          executed.add(node.title);
          if (node.title == 'B') {
            throw StateError('boom');
          }
          return AgentWorkflowValue.fromText(node.title);
        },
      );

      final result = await runner.run(
        template: t,
        startInput: 'x',
        onUpdate: (_) {},
        shouldStop: () => false,
        onRequestUserInput: (_, __) async => null,
      );

      expect(result.success, isFalse);
      expect(executed, equals(['A', 'B']));
      expect(result.error, contains('boom'));
    });

    test('stop flag halts further execution', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final a = AgentWorkflowNode.createLlm().copyWith(title: 'A');
      final b = AgentWorkflowNode.createLlm().copyWith(title: 'B');

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, a, b, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: a.id,
            toPortId: _in(a, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: a.id,
            fromPortId: _out(a, 'result').id,
            toNodeId: b.id,
            toPortId: _in(b, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: b.id,
            fromPortId: _out(b, 'result').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      var stop = false;
      final executed = <String>[];
      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async {
          executed.add(node.title);
          return AgentWorkflowValue.fromText(node.title);
        },
      );

      final result = await runner.run(
        template: t,
        startInput: 'x',
        onUpdate: (u) {
          if (u.nodeId == a.id && u.status == AgentWorkflowNodeRunStatus.running) {
            stop = true;
          }
        },
        shouldStop: () => stop,
        onRequestUserInput: (_, __) async => null,
      );

      expect(result.stopped, isTrue);
      expect(executed, equals(['A']));
    });

    test('strict input validation failure routes to error branch and skips executor',
        () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();

      final llm1 = AgentWorkflowNode.createLlm().copyWith(title: 'LLM1');
      final llm2Base = AgentWorkflowNode.createLlm().copyWith(title: 'LLM2');
      final llm2 = llm2Base.copyWith(
        inputs: [
          llm2Base.inputs.first.copyWith(
            valueType: AgentWorkflowPortValueType.json,
            schema: {
              'type': 'object',
              'properties': {
                'x': {'type': 'string'},
              },
              'required': ['x'],
            },
          )
        ],
      );

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, llm1, llm2, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: llm1.id,
            toPortId: _in(llm1, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: llm1.id,
            fromPortId: _out(llm1, 'result').id,
            toNodeId: llm2.id,
            toPortId: _in(llm2, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: llm2.id,
            fromPortId: _out(llm2, 'error').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      final executed = <String>[];
      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async {
          executed.add(node.title);
          if (node.title == 'LLM1') {
            return AgentWorkflowValue.fromText('not-json');
          }
          return AgentWorkflowValue.fromText('should-not-run');
        },
      );

      final result = await runner.run(
        template: t,
        startInput: 'x',
        onUpdate: (_) {},
        shouldStop: () => false,
        onRequestUserInput: (_, __) async => null,
      );

      expect(result.success, isTrue);
      expect(executed, equals(['LLM1']));
      expect(result.finalOutput, contains('Input validation failed on node "LLM2"'));
    });

    test('executor exception routes to error branch', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final a = AgentWorkflowNode.createLlm().copyWith(title: 'A');

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, a, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: a.id,
            toPortId: _in(a, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: a.id,
            fromPortId: _out(a, 'error').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async {
          throw StateError('boom');
        },
      );

      final result = await runner.run(
        template: t,
        startInput: 'x',
        onUpdate: (_) {},
        shouldStop: () => false,
        onRequestUserInput: (_, __) async => null,
      );

      expect(result.success, isTrue);
      expect(result.finalOutput, contains('boom'));
    });

    test('user input pauses and continues', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final ui = AgentWorkflowNode.createUserInput().copyWith(
        title: 'Ask',
        bodyTemplate: 'Prompt: {{input}}',
      );

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, ui, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: ui.id,
            toPortId: _in(ui, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: ui.id,
            fromPortId: _out(ui, 'result').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      final updates = <AgentWorkflowNodeRunUpdate>[];
      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (_, __) async => AgentWorkflowValue.fromText('unexpected'),
      );

      final result = await runner.run(
        template: t,
        startInput: 'hi',
        onUpdate: updates.add,
        shouldStop: () => false,
        onRequestUserInput: (node, prompt) async {
          expect(node.id, ui.id);
          expect(prompt, 'Prompt: hi');
          return 'answer';
        },
      );

      expect(result.success, isTrue);
      expect(result.finalOutput, 'answer');
      expect(
        updates.any((u) => u.nodeId == ui.id && u.status == AgentWorkflowNodeRunStatus.waiting),
        isTrue,
      );
      expect(
        updates.any((u) => u.nodeId == ui.id && u.status == AgentWorkflowNodeRunStatus.success),
        isTrue,
      );
    });

    test('user input cancel routes to error branch when connected', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final ui = AgentWorkflowNode.createUserInput().copyWith(title: 'Ask');

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, ui, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: ui.id,
            toPortId: _in(ui, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: ui.id,
            fromPortId: _out(ui, 'error').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (_, __) async => AgentWorkflowValue.fromText('unexpected'),
      );

      final result = await runner.run(
        template: t,
        startInput: 'hi',
        onUpdate: (_) {},
        shouldStop: () => false,
        onRequestUserInput: (_, __) async => null,
      );

      expect(result.success, isTrue);
      expect(result.finalOutput, contains('User input cancelled'));
    });

    test('user input cancel stops the run when error is not connected', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final ui = AgentWorkflowNode.createUserInput().copyWith(title: 'Ask');

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, ui, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: ui.id,
            toPortId: _in(ui, 'input').id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: ui.id,
            fromPortId: _out(ui, 'result').id,
            toNodeId: end.id,
            toPortId: _in(end, 'result').id,
          ),
        ],
      );

      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (_, __) async => AgentWorkflowValue.fromText('unexpected'),
      );

      final result = await runner.run(
        template: t,
        startInput: 'hi',
        onUpdate: (_) {},
        shouldStop: () => false,
        onRequestUserInput: (_, __) async => null,
      );

      expect(result.stopped, isTrue);
      expect(result.success, isFalse);
    });
  });
}

