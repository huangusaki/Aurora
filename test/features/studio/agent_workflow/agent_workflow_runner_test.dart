import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:aurora/features/studio/application/agent_workflow/agent_workflow_runner.dart';
import 'package:aurora/features/studio/domain/agent_workflow/agent_workflow_models.dart';
import 'package:aurora/features/studio/domain/agent_workflow/agent_workflow_validator.dart';

void main() {
  group('AgentWorkflowRunner', () {
    test('runs nodes serially and returns End output', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();

      final llmInput =
          AgentWorkflowPort(id: const Uuid().v4(), name: 'start');
      final llm = AgentWorkflowNode.createLlm().copyWith(
        title: 'LLM1',
        inputs: [llmInput],
        outputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'result')],
        bodyTemplate: 'Echo: {{start}}',
      );

      final skillInput =
          AgentWorkflowPort(id: const Uuid().v4(), name: 'text');
      final skill = AgentWorkflowNode.createSkill().copyWith(
        title: 'SK1',
        inputs: [skillInput],
        outputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'result')],
        bodyTemplate: '{{text}} + skill',
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
            fromPortId: start.outputs.single.id,
            toNodeId: llm.id,
            toPortId: llm.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: llm.id,
            fromPortId: llm.outputs.single.id,
            toNodeId: skill.id,
            toPortId: skill.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: skill.id,
            fromPortId: skill.outputs.single.id,
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
          ),
        ],
      );

      final executed = <String>[];
      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async {
          executed.add(node.title);
          if (node.type == AgentWorkflowNodeType.llm) {
            return 'LLM(${req.renderedBody})';
          }
          if (node.type == AgentWorkflowNodeType.skill) {
            return 'SKILL(${req.renderedBody})';
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
      );

      expect(result.success, isTrue);
      expect(result.finalOutput, equals('SKILL(LLM(Echo: hi) + skill)'));
      expect(executed, equals(['LLM1', 'SK1']));
      expect(updates.any((u) => u.status == AgentWorkflowNodeRunStatus.running),
          isTrue);
    });

    test('broadcasts the same output across multiple output ports', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();

      final multiOut = AgentWorkflowNode.createLlm().copyWith(
        title: 'Multi',
        inputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'start')],
        outputs: [
          AgentWorkflowPort(id: const Uuid().v4(), name: 'a'),
          AgentWorkflowPort(id: const Uuid().v4(), name: 'b'),
        ],
        bodyTemplate: '{{start}}',
      );

      final next = AgentWorkflowNode.createLlm().copyWith(
        title: 'Next',
        inputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'x')],
        outputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'result')],
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
            fromPortId: start.outputs.single.id,
            toNodeId: multiOut.id,
            toPortId: multiOut.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: multiOut.id,
            fromPortId: multiOut.outputs[1].id,
            toNodeId: next.id,
            toPortId: next.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: next.id,
            fromPortId: next.outputs.single.id,
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
          ),
        ],
      );

      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async => '[${node.title}]${req.renderedBody}',
      );

      final result = await runner.run(
        template: t,
        startInput: 'S',
        onUpdate: (_) {},
        shouldStop: () => false,
      );

      expect(result.success, isTrue);
      expect(result.finalOutput, equals('[Next]->[Multi]S'));
    });

    test('fail-fast stops execution on node error', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final a = AgentWorkflowNode.createLlm().copyWith(
        title: 'A',
        inputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'start')],
        outputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'result')],
        bodyTemplate: '{{start}}',
      );
      final b = AgentWorkflowNode.createLlm().copyWith(
        title: 'B',
        inputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'x')],
        outputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'result')],
        bodyTemplate: '{{x}}',
      );

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, a, b, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: start.outputs.single.id,
            toNodeId: a.id,
            toPortId: a.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: a.id,
            fromPortId: a.outputs.single.id,
            toNodeId: b.id,
            toPortId: b.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: b.id,
            fromPortId: b.outputs.single.id,
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
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
          return node.title;
        },
      );

      final result = await runner.run(
        template: t,
        startInput: 'x',
        onUpdate: (_) {},
        shouldStop: () => false,
      );

      expect(result.success, isFalse);
      expect(executed, equals(['A', 'B']));
    });

    test('stop flag halts further execution', () async {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final a = AgentWorkflowNode.createLlm().copyWith(
        title: 'A',
        inputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'start')],
        outputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'result')],
        bodyTemplate: '{{start}}',
      );
      final b = AgentWorkflowNode.createLlm().copyWith(
        title: 'B',
        inputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'x')],
        outputs: [AgentWorkflowPort(id: const Uuid().v4(), name: 'result')],
        bodyTemplate: '{{x}}',
      );

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 't',
        nodes: [start, a, b, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: start.outputs.single.id,
            toNodeId: a.id,
            toPortId: a.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: a.id,
            fromPortId: a.outputs.single.id,
            toNodeId: b.id,
            toPortId: b.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: b.id,
            fromPortId: b.outputs.single.id,
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
          ),
        ],
      );

      var stop = false;
      final executed = <String>[];
      final runner = AgentWorkflowRunner(
        validator: const AgentWorkflowValidator(),
        executor: (node, req) async {
          executed.add(node.title);
          return node.title;
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
      );

      expect(result.stopped, isTrue);
      expect(executed, equals(['A']));
    });
  });
}
