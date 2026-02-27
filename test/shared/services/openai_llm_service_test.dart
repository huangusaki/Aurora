import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aurora/features/chat/domain/ui_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/llm_service.dart';
import 'package:aurora/shared/services/openai_llm_service.dart';

void main() {
  group('OpenAILLMService', () {
    test('returns missing model message when model is not configured',
        () async {
      final settings = SettingsState(
        providers: [
          ProviderConfig(
            id: 'openai',
            name: 'OpenAI',
            apiKeys: const ['test-key'],
            selectedModel: null,
          ),
        ],
        activeProviderId: 'openai',
        viewingProviderId: 'openai',
        language: 'en',
      );
      final service = OpenAILLMService(settings);

      final response = await service.getResponse([Message.user('hello')]);

      expect(response.content, contains('no model selected'));
    });

    test('returns empty API key message before sending request', () async {
      final settings = SettingsState(
        providers: [
          ProviderConfig(
            id: 'openai',
            name: 'OpenAI',
            apiKeys: const [],
            selectedModel: 'gpt-4.1',
          ),
        ],
        activeProviderId: 'openai',
        viewingProviderId: 'openai',
        language: 'en',
      );
      final service = OpenAILLMService(settings);

      final response = await service.getResponse([Message.user('hello')]);

      expect(response.content, contains('API key is empty'));
    });

    test(
        'uses reasoning_effort=auto for gemini 3.0 image models',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final payloadCompleter = Completer<Map<String, dynamic>>();
      final sub = server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        if (!payloadCompleter.isCompleted) {
          payloadCompleter.complete(payload);
        }

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'choices': [
            {
              'message': {'content': 'ok'}
            }
          ]
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final settings = SettingsState(
        providers: [
          ProviderConfig(
            id: 'openai',
            name: 'OpenAI',
            apiKeys: const ['test-key'],
            selectedModel: 'gemini-3-pro-image-preview',
            baseUrl: 'http://${server.address.host}:${server.port}/v1',
            globalSettings: const {
              '_aurora_thinking_config': {
                'enabled': true,
                'budget': 'high',
                'mode': 'reasoning_effort',
              }
            },
          ),
        ],
        activeProviderId: 'openai',
        viewingProviderId: 'openai',
        language: 'en',
      );
      final service = OpenAILLMService(settings);

      final response = await service.getResponse([Message.user('hello')]);
      final payload = await payloadCompleter.future;

      expect(response.content, 'ok');
      expect(payload['model'], 'gemini-3-pro-image-preview');
      // 3.0 image models: forced to auto; CLIProxyAPI handles includeThoughts
      expect(payload['reasoning_effort'], 'auto');
      // No extra_body needed
      expect(payload.containsKey('extra_body'), isFalse);
    });

    test(
        'uses reasoning_effort=high for gemini 3.1+ image models',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final payloadCompleter = Completer<Map<String, dynamic>>();
      final sub = server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        if (!payloadCompleter.isCompleted) {
          payloadCompleter.complete(payload);
        }

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'choices': [
            {
              'message': {'content': 'ok'}
            }
          ]
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final settings = SettingsState(
        providers: [
          ProviderConfig(
            id: 'openai',
            name: 'OpenAI',
            apiKeys: const ['test-key'],
            selectedModel: 'gemini-3.1-flash-image-preview',
            baseUrl: 'http://${server.address.host}:${server.port}/v1',
            globalSettings: const {
              '_aurora_thinking_config': {
                'enabled': true,
                'budget': 'high',
                'mode': 'reasoning_effort',
              }
            },
          ),
        ],
        activeProviderId: 'openai',
        viewingProviderId: 'openai',
        language: 'en',
      );
      final service = OpenAILLMService(settings);

      final response = await service.getResponse([Message.user('hello')]);
      final payload = await payloadCompleter.future;

      expect(response.content, 'ok');
      expect(payload['model'], 'gemini-3.1-flash-image-preview');
      // 3.1+ uses user's thinking level; CLIProxyAPI handles includeThoughts
      expect(payload['reasoning_effort'], 'high');
      // No extra_body needed
      expect(payload.containsKey('extra_body'), isFalse);
    });

    test('collects multiple images from a single streaming delta', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final sub = server.listen((request) async {
        request.response.statusCode = 200;
        request.response.headers
            .set(HttpHeaders.contentTypeHeader, 'text/event-stream');
        request.response.write(
            'data: {"choices":[{"delta":{"images":[{"image_url":{"url":"https://example.com/a.png"}},{"image_url":{"url":"https://example.com/b.png"}}]}}]}\n\n');
        request.response.write('data: [DONE]\n\n');
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final settings = SettingsState(
        providers: [
          ProviderConfig(
            id: 'openai',
            name: 'OpenAI',
            apiKeys: const ['test-key'],
            selectedModel: 'gpt-4.1',
            baseUrl: 'http://${server.address.host}:${server.port}/v1',
          ),
        ],
        activeProviderId: 'openai',
        viewingProviderId: 'openai',
        language: 'en',
      );
      final service = OpenAILLMService(settings);

      final chunks =
          await service.streamResponse([Message.user('hello')]).toList();
      final imageChunks = chunks.where((c) => c.images.isNotEmpty).toList();

      expect(imageChunks, hasLength(1));
      expect(imageChunks.first.images, const [
        'https://example.com/a.png',
        'https://example.com/b.png',
      ]);
    });

    test('decodes JSON toolChoice string into an object payload', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final payloadCompleter = Completer<Map<String, dynamic>>();
      final sub = server.listen((request) async {
        final raw = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(raw) as Map<String, dynamic>;
        if (!payloadCompleter.isCompleted) {
          payloadCompleter.complete(payload);
        }

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'choices': [
            {
              'message': {'content': 'ok'}
            }
          ]
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final settings = SettingsState(
        providers: [
          ProviderConfig(
            id: 'openai',
            name: 'OpenAI',
            apiKeys: const ['test-key'],
            selectedModel: 'gpt-4.1',
            baseUrl: 'http://${server.address.host}:${server.port}/v1',
          ),
        ],
        activeProviderId: 'openai',
        viewingProviderId: 'openai',
        language: 'en',
      );
      final service = OpenAILLMService(settings);

      await service.getResponse(
        [Message.user('hello')],
        tools: const [
          {
            'type': 'function',
            'function': {
              'name': 'workflow_output',
              'parameters': {
                'type': 'object',
                'properties': {},
              },
            },
          },
        ],
        toolChoice: '{"type":"function","function":{"name":"workflow_output"}}',
      );

      final payload = await payloadCompleter.future;
      expect(payload['tool_choice'], isA<Map<String, dynamic>>());
      final toolChoice = payload['tool_choice'] as Map<String, dynamic>;
      expect(toolChoice['type'], 'function');
      expect(
        (toolChoice['function'] as Map)['name'],
        'workflow_output',
      );
    });
  });

  group('UiMessage.appendChunk images', () {
    test('keeps multiple streamed image chunks instead of replacing', () {
      var message = UiMessage(
        id: 'assistant-1',
        role: UiRole.assistant,
        timestamp: DateTime(2026, 2, 25),
      );

      message = message.appendChunk(const LLMResponseChunk(images: ['img-1']));
      message = message.appendChunk(const LLMResponseChunk(images: ['img-2']));

      expect(message.images, const ['img-1', 'img-2']);
    });

    test('deduplicates repeated image urls', () {
      var message = UiMessage(
        id: 'assistant-2',
        role: UiRole.assistant,
        timestamp: DateTime(2026, 2, 25),
      );

      message = message.appendChunk(const LLMResponseChunk(images: ['img-1']));
      message =
          message.appendChunk(const LLMResponseChunk(images: [' img-1 ']));

      expect(message.images, const ['img-1']);
    });
  });
}
