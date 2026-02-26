import 'package:flutter_test/flutter_test.dart';

import 'package:aurora/features/studio/domain/agent_workflow/agent_workflow_models.dart';

void main() {
  group('AgentWorkflow models', () {
    test('toJson/fromJson roundtrip', () {
      final t = AgentWorkflowTemplate.create(name: 'Demo').copyWith(
        nodes: [
          AgentWorkflowNode.createStart(),
          AgentWorkflowNode.createLlm()
              .copyWith(title: 'My LLM', bodyTemplate: 'Hello {{input}}'),
          AgentWorkflowNode.createEnd(),
        ],
      );

      final doc = AgentWorkflowDocument(version: 1, templates: [t]);
      final decoded = AgentWorkflowDocument.fromJson(doc.toJson());

      expect(decoded.version, equals(1));
      expect(decoded.templates, hasLength(1));
      expect(decoded.templates.first.name, equals('Demo'));
      expect(decoded.templates.first.nodes.map((n) => n.type).toList(),
          containsAll([AgentWorkflowNodeType.start, AgentWorkflowNodeType.end]));
    });

    test('create() includes fixed Start/End nodes', () {
      final t = AgentWorkflowTemplate.create(name: 'X');
      expect(
        t.nodes.where((n) => n.type == AgentWorkflowNodeType.start).length,
        equals(1),
      );
      expect(
        t.nodes.where((n) => n.type == AgentWorkflowNodeType.end).length,
        equals(1),
      );

      final start = t.startNode!;
      final end = t.endNode!;
      expect(start.inputs, isEmpty);
      expect(start.outputs.single.name, equals('start'));
      expect(end.outputs, isEmpty);
      expect(end.inputs.single.name, equals('result'));
    });
  });
}

