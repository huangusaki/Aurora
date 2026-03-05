import 'package:aurora/shared/utils/message_meta_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('message_meta_sanitizer', () {
    test('sanitizeMessageRequestId trims and keeps short values', () {
      expect(sanitizeMessageRequestId('  abc  '), 'abc');
    });

    test('sanitizeMessageRequestId drops empty / multiline / oversized values',
        () {
      expect(sanitizeMessageRequestId(''), isNull);
      expect(sanitizeMessageRequestId('a\nb'), isNull);
      expect(
        sanitizeMessageRequestId('x' * (kMaxMessageRequestIdChars + 1)),
        isNull,
      );
    });

    test('sanitizeMessageModel drops oversized values', () {
      expect(sanitizeMessageModel('x' * (kMaxMessageModelChars + 1)), isNull);
      expect(sanitizeMessageModel('gpt-4o'), 'gpt-4o');
    });

    test('sanitizeMessageProvider drops multiline values', () {
      expect(sanitizeMessageProvider('openai\nazure'), isNull);
    });

    test('sanitizeMessageRole normalizes case and enforces max length', () {
      expect(sanitizeMessageRole('User'), 'user');
      expect(sanitizeMessageRole('assistant'), 'assistant');
      expect(sanitizeMessageRole('x' * (kMaxMessageRoleChars + 1)), isNull);
    });
  });
}

