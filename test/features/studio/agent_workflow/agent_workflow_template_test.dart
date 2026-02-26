import 'package:flutter_test/flutter_test.dart';

import 'package:aurora/features/studio/application/agent_workflow/agent_workflow_runner.dart';

void main() {
  group('AgentWorkflowTemplateEngine', () {
    test('replaces known placeholders', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        'Hello {{name}}!',
        {'name': 'Aurora'},
      );
      expect(out, equals('Hello Aurora!'));
    });

    test('supports Chinese placeholder keys', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        '总结：{{输入}}',
        {'输入': '你好'},
      );
      expect(out, equals('总结：你好'));
    });

    test('keeps unknown placeholders unchanged', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        'Hi {{missing}}',
        {'name': 'x'},
      );
      expect(out, equals('Hi {{missing}}'));
    });
  });
}

