import 'dart:convert';
import 'dart:io';

import 'package:aurora/features/settings/data/provider_config_entity.dart';
import 'package:aurora/features/settings/data/settings_storage.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySettingsStorage extends SettingsStorage {
  ProviderConfigEntity? savedProvider;

  @override
  Future<void> saveProvider(ProviderConfigEntity provider) async {
    savedProvider = provider;
  }
}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier({
    required super.storage,
    required super.initialProviders,
    required super.initialActiveId,
  });

  @override
  Future<void> loadPresets() async {}
}

void main() {
  group('SettingsNotifier.fetchModels', () {
    test('falls back to Gemini v1beta list for third-party providers',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requestedPaths = <String>[];
      String? openAiAuthHeader;
      String? geminiApiKeyHeader;

      final sub = server.listen((request) async {
        requestedPaths.add(request.uri.path);

        if (request.uri.path == '/models') {
          openAiAuthHeader = request.headers.value('authorization');
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        if (request.uri.path == '/v1beta/models') {
          geminiApiKeyHeader = request.headers.value('x-goog-api-key');
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'models': [
              {'name': 'models/gemini-2.0-flash'},
              {'name': 'models/gemini-1.5-pro'},
            ],
          }));
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close(force: true);
      });

      final storage = _MemorySettingsStorage();
      final notifier = _TestSettingsNotifier(
        storage: storage,
        initialProviders: [
          ProviderConfig(
            id: 'other',
            name: 'Other',
            isCustom: true,
          ),
          ProviderConfig(
            id: 'proxy',
            name: 'Gemini Proxy',
            apiKeys: const ['proxy-key'],
            baseUrl: 'http://${server.address.host}:${server.port}',
            isCustom: true,
          ),
        ],
        initialActiveId: 'other',
      );

      notifier.viewProvider('proxy');
      final success = await notifier.fetchModels();

      expect(success, isTrue);
      expect(openAiAuthHeader, 'Bearer proxy-key');
      expect(geminiApiKeyHeader, 'proxy-key');
      expect(requestedPaths, ['/models', '/v1beta/models']);
      expect(
        notifier.state.viewingProvider.models,
        ['gemini-1.5-pro', 'gemini-2.0-flash'],
      );
      expect(notifier.state.viewingProvider.selectedModel, 'gemini-1.5-pro');
      expect(storage.savedProvider?.providerId, 'proxy');
    });
  });
}
