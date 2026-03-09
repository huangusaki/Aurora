import 'dart:convert';
import 'dart:io';

import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/model_routed_llm_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModelRoutedLlmService protocol handlers', () {
    test('routes OpenAI Responses preset to responses handler', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'content': [
                {'type': 'output_text', 'text': 'responses ok'}
              ],
            }
          ],
          'usage': {
            'input_tokens': 2,
            'output_tokens': 3,
            'total_tokens': 5,
          }
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final provider = ProviderConfig(
        id: 'responses',
        name: 'Responses',
        apiKeys: const ['key'],
        selectedModel: 'gpt-5.1',
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.chat: CapabilityRouteConfig(
              preset: ProtocolPreset.openaiResponses,
              baseUrlOverride:
                  'http://${server.address.host}:${server.port}/v1',
            ),
          },
        ),
      );
      final settings = SettingsState(
        providers: [provider],
        activeProviderId: provider.id,
        viewingProviderId: provider.id,
        language: 'en',
      );

      final response = await ModelRoutedLlmService(settings).getResponse(
        [Message.user('hello')],
        providerId: provider.id,
      );

      expect(requestedPath, '/v1/responses');
      expect(response.content, 'responses ok');
      expect(response.usage, 5);
    });

    test('routes Anthropic Messages preset to anthropic handler', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      String? apiKeyHeader;
      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        apiKeyHeader = request.headers.value('x-api-key');
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'content': [
            {'type': 'text', 'text': 'anthropic ok'}
          ],
          'usage': {
            'input_tokens': 4,
            'output_tokens': 6,
          },
          'stop_reason': 'end_turn',
        }));
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final provider = ProviderConfig(
        id: 'anthropic',
        name: 'Anthropic',
        apiKeys: const ['anthropic-key'],
        selectedModel: 'claude-sonnet-4-5',
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.chat: CapabilityRouteConfig(
              preset: ProtocolPreset.anthropicMessages,
              baseUrlOverride:
                  'http://${server.address.host}:${server.port}/v1',
            ),
          },
        ),
      );
      final settings = SettingsState(
        providers: [provider],
        activeProviderId: provider.id,
        viewingProviderId: provider.id,
        language: 'en',
      );

      final response = await ModelRoutedLlmService(settings).getResponse(
        [Message.user('hello')],
        providerId: provider.id,
      );

      expect(requestedPath, '/v1/messages');
      expect(apiKeyHeader, 'anthropic-key');
      expect(response.content, 'anthropic ok');
      expect(response.usage, 10);
      expect(response.finishReason, 'end_turn');
    });
  });
}
