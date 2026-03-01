import 'package:flutter_test/flutter_test.dart';

import 'package:aurora/features/studio/application/agent_workflow/agent_workflow_runner.dart';
import 'package:aurora/features/studio/application/agent_workflow/agent_workflow_value.dart';

void main() {
  group('AgentWorkflowTemplateEngine', () {
    test('replaces known placeholders', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        'Hello {{name}}!',
        {'name': AgentWorkflowValue.fromText('Aurora')},
      );
      expect(out, equals('Hello Aurora!'));
    });

    test('supports Chinese placeholder keys', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        '总结：{{输入}}',
        {'输入': AgentWorkflowValue.fromText('你好')},
      );
      expect(out, equals('总结：你好'));
    });

    test('keeps unknown placeholders unchanged', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        'Hi {{missing}}',
        {'name': AgentWorkflowValue.fromText('x')},
      );
      expect(out, equals('Hi {{missing}}'));
    });

    test('supports JSON path access', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        'Hello {{input.user.name}}!',
        {
          'input': AgentWorkflowValue.fromJson({
            'user': {'name': 'Ada'}
          }),
        },
      );
      expect(out, equals('Hello Ada!'));
    });

    test('supports list indexing in JSON path access', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        'ID={{input.items.0.id}}',
        {
          'input': AgentWorkflowValue.fromJson({
            'items': [
              {'id': 7},
            ],
          }),
        },
      );
      expect(out, equals('ID=7'));
    });

    test('keeps placeholder when JSON path access fails', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        'Hello {{input.user.age}}!',
        {
          'input': AgentWorkflowValue.fromJson({
            'user': {'name': 'Ada'}
          }),
        },
      );
      expect(out, equals('Hello {{input.user.age}}!'));
    });

    test('supports \$json and \$raw accessors', () {
      final out = AgentWorkflowTemplateEngine.applyTemplate(
        'json={{input.\$json}} raw={{input.\$raw}}',
        {
          'input': AgentWorkflowValue.fromJson(
            {'a': 1},
            raw: 'raw-text',
          ),
        },
      );
      expect(out, equals('json={"a":1} raw=raw-text'));
    });
  });
}
