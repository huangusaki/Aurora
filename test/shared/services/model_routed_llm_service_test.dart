import 'dart:convert';
import 'dart:io';

import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/model_routed_llm_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModelRoutedLlmService', () {
    test('auto mode routes third-party v1beta providers to Gemini native',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      String? requestedPath;
      String? requestedApiKey;

      final sub = server.listen((request) async {
        requestedPath = request.uri.path;
        requestedApiKey = request.headers.value('x-goog-api-key');

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'auto native'},
                ],
              },
            },
          ],
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
            id: 'gemini-proxy',
            name: 'Gemini Proxy',
            apiKeys: const ['proxy-key'],
            baseUrl: 'http://${server.address.host}:${server.port}/v1beta/',
            selectedModel: 'gemini-2.0-flash',
          ),
        ],
        activeProviderId: 'gemini-proxy',
        viewingProviderId: 'gemini-proxy',
        language: 'zh',
      );
      final service = ModelRoutedLlmService(settings);

      final response = await service.getResponse([Message.user('你好')]);

      expect(response.content, 'auto native');
      expect(
        requestedPath,
        '/v1beta/models/gemini-2.0-flash:generateContent',
      );
      expect(requestedApiKey, 'proxy-key');
    });
  });
}
