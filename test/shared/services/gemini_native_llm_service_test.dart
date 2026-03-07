import 'dart:convert';
import 'dart:io';

import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/gemini_native_llm_service.dart';
import 'package:aurora/shared/services/llm_transport_mode.dart';
import 'package:aurora/shared/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiNativeLlmService', () {
    setUp(() {
      AppLogger.resetForTest();
    });

    test('emits one stream summary log for streaming responses', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = server.listen((request) async {
        request.response.statusCode = 200;
        request.response.headers.contentType =
            ContentType('text', 'event-stream', charset: 'utf-8');
        request.response.add(utf8.encode(
          'data: ${jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {'text': '你'},
                      ],
                    },
                  },
                ],
                'usageMetadata': {
                  'promptTokenCount': 3,
                  'candidatesTokenCount': 1,
                  'thoughtsTokenCount': 2,
                  'totalTokenCount': 6,
                },
              })}\n\n',
        ));
        request.response.add(utf8.encode(
          'data: ${jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {'text': '你好'},
                        {'text': '思', 'thought': true},
                      ],
                    },
                    'finishReason': 'STOP',
                  },
                ],
                'usageMetadata': {
                  'promptTokenCount': 3,
                  'candidatesTokenCount': 2,
                  'thoughtsTokenCount': 5,
                  'totalTokenCount': 10,
                },
              })}\n\n',
        ));
        request.response.add(utf8.encode('data: [DONE]\n\n'));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final received = <AppLogEntry>[];
      final removeListener = AppLogger.addListener(received.add);
      addTearDown(removeListener);

      final settings = SettingsState(
        providers: [
          ProviderConfig(
            id: 'gemini',
            name: 'Gemini',
            apiKeys: const ['test-key'],
            selectedModel: 'gemini-2.0-flash',
            globalSettings: {
              auroraTransportBaseUrlKey:
                  'http://${server.address.host}:${server.port}/v1beta/',
            },
          ),
        ],
        activeProviderId: 'gemini',
        viewingProviderId: 'gemini',
        language: 'zh',
      );
      final service = GeminiNativeLlmService(settings);

      final chunks =
          await service.streamResponse([Message.user('你好')]).toList();
      final content = chunks.map((chunk) => chunk.content ?? '').join();
      final reasoning = chunks.map((chunk) => chunk.reasoning ?? '').join();

      expect(content, '你好');
      expect(reasoning, '思');
      expect(
        received.any((entry) =>
            entry.channel == 'LLM' &&
            entry.category == 'REQUEST' &&
            entry.message.contains('streamGenerateContent')),
        isTrue,
      );
      expect(
        received.where(
            (entry) => entry.channel == 'LLM' && entry.category == 'RESPONSE'),
        isEmpty,
      );

      final streamEntries = received
          .where(
              (entry) => entry.channel == 'LLM' && entry.category == 'STREAM')
          .toList();
      expect(streamEntries, hasLength(1));
      expect(streamEntries.single.message, 'stream completed');

      final summary = _decodeLogDetails(streamEntries.single);
      expect(summary['outcome'], 'completed');
      expect(summary['provider_id'], 'gemini');
      expect(summary['model'], 'gemini-2.0-flash');
      expect(summary['duration_ms'], greaterThanOrEqualTo(0));
      expect(summary['sse_events'], 2);
      expect(summary['emitted_chunks'], 4);
      expect(summary['done_marker_seen'], isTrue);
      expect(summary['finish_reason'], 'stop');
      expect(summary['content_chars'], 2);
      expect(summary['reasoning_chars'], 1);
      expect(summary['image_count'], 0);
      expect(summary['parse_error_count'], 0);
      expect(summary['prompt_tokens'], 3);
      expect(summary['completion_tokens'], 2);
      expect(summary['reasoning_tokens'], 5);
      expect(summary['usage'], 10);
    });
  });
}

Map<String, dynamic> _decodeLogDetails(AppLogEntry entry) {
  final details = entry.details;
  if (details == null || details.isEmpty) {
    fail('Expected JSON details for log entry "${entry.message}".');
  }

  final decoded = jsonDecode(details);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  fail('Expected log details to decode into a JSON object.');
}
