import 'package:flutter_test/flutter_test.dart';

import 'package:aurora/features/studio/domain/agent_workflow/agent_workflow_models.dart';
import 'package:aurora/features/studio/domain/agent_workflow/agent_workflow_validator.dart';
import 'package:uuid/uuid.dart';

AgentWorkflowPort _out(AgentWorkflowNode node, String name) =>
    node.outputs.firstWhere((p) => p.name.trim() == name);

void main() {
  group('AgentWorkflowValidator', () {
    const validator = AgentWorkflowValidator();

    test('requires exactly one Start and End', () {
      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 'bad',
        nodes: [AgentWorkflowNode.createLlm()],
        edges: const [],
      );
      final result = validator.validate(t);
      expect(result.isValid, isFalse);
      expect(result.toMultilineString(), contains('Start'));
      expect(result.toMultilineString(), contains('End'));
    });

    test('fails when End is not reachable from Start', () {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final mid = AgentWorkflowNode.createLlm();

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 'bad',
        nodes: [start, mid, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: mid.id,
            toPortId: mid.inputs.single.id,
          ),
        ],
      );
      final result = validator.validate(t);
      expect(result.isValid, isFalse);
      expect(result.toMultilineString(), contains('reachable'));
    });

    test('requires End.result to have exactly one incoming edge', () {
      final t = AgentWorkflowTemplate.create(name: 'bad');
      final result = validator.validate(t);
      expect(result.isValid, isFalse);
      expect(result.toMultilineString(), contains('End.result'));
    });

    test('rejects edges that reference missing ports', () {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 'bad',
        nodes: [start, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: 'missing',
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
          ),
        ],
      );
      final result = validator.validate(t);
      expect(result.isValid, isFalse);
      expect(result.toMultilineString(), contains('fromPortId'));
    });

    test('rejects multiple incoming edges to the same input port', () {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final a = AgentWorkflowNode.createLlm();
      final b = AgentWorkflowNode.createLlm().copyWith(title: 'B');

      final targetInputPortId = a.inputs.single.id;
      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 'bad',
        nodes: [start, a, b, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: a.id,
            toPortId: targetInputPortId,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: b.id,
            fromPortId: _out(b, 'result').id,
            toNodeId: a.id,
            toPortId: targetInputPortId,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: a.id,
            fromPortId: _out(a, 'result').id,
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
          ),
        ],
      );

      final result = validator.validate(t);
      expect(result.isValid, isFalse);
      expect(result.toMultilineString(), contains('incoming edges'));
    });

    test('detects cycles on Start→End path', () {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final aBase = AgentWorkflowNode.createLlm().copyWith(title: 'A');
      final loopPort =
          AgentWorkflowPort(id: const Uuid().v4(), name: 'loop');
      final a = aBase.copyWith(inputs: [...aBase.inputs, loopPort]);
      final b = AgentWorkflowNode.createLlm().copyWith(title: 'B');

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 'cycle',
        nodes: [start, a, b, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: a.id,
            toPortId: a.inputs.first.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: a.id,
            fromPortId: _out(a, 'result').id,
            toNodeId: b.id,
            toPortId: b.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: b.id,
            fromPortId: _out(b, 'result').id,
            toNodeId: a.id,
            toPortId: loopPort.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: b.id,
            fromPortId: _out(b, 'result').id,
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
          ),
        ],
      );

      final result = validator.validate(t);
      expect(result.isValid, isFalse);
      expect(result.toMultilineString(), contains('cycle'));
    });

    test('rejects invalid JSON Schema on a port', () {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final llmBase = AgentWorkflowNode.createLlm().copyWith(title: 'LLM');
      final llm = llmBase.copyWith(
        inputs: [
          llmBase.inputs.single.copyWith(
            schema: {
              'type': 123,
            },
          ),
        ],
      );

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 'bad-schema',
        nodes: [start, llm, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: llm.id,
            toPortId: llm.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: llm.id,
            fromPortId: _out(llm, 'result').id,
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
          ),
        ],
      );

      final result = validator.validate(t);
      expect(result.isValid, isFalse);
      expect(result.toMultilineString(), contains('invalid JSON Schema'));
    });

    test('structured output requires json primary output with object schema', () {
      final start = AgentWorkflowNode.createStart();
      final end = AgentWorkflowNode.createEnd();
      final llm = AgentWorkflowNode.createLlm().copyWith(
        title: 'LLM',
        structuredOutput: true,
      );

      final t = AgentWorkflowTemplate(
        id: const Uuid().v4(),
        name: 'bad-structured',
        nodes: [start, llm, end],
        edges: [
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: start.id,
            fromPortId: _out(start, 'start').id,
            toNodeId: llm.id,
            toPortId: llm.inputs.single.id,
          ),
          AgentWorkflowEdge(
            id: const Uuid().v4(),
            fromNodeId: llm.id,
            fromPortId: _out(llm, 'result').id,
            toNodeId: end.id,
            toPortId: end.inputs.single.id,
          ),
        ],
      );

      final result = validator.validate(t);
      expect(result.isValid, isFalse);
      expect(result.toMultilineString(), contains('structured output'));
    });
  });
}
