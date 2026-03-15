import 'dart:convert';
import 'dart:io';

import 'package:aurora/features/settings/data/provider_config_entity.dart';
import 'package:aurora/features/settings/data/settings_storage.dart';
import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySettingsStorage extends SettingsStorage {
  ProviderConfigEntity? savedProvider;
  final List<ProviderConfigEntity> providerEntities;

  _MemorySettingsStorage({this.providerEntities = const []});

  @override
  Future<List<ProviderConfigEntity>> loadProviders() async => providerEntities;

  @override
  Future<AppSettingsEntity?> loadAppSettings() async => null;

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
    test('uses configured Gemini protocol for model lists', () async {
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
            providerProtocol: ProviderProtocol.gemini,
            isCustom: true,
          ),
        ],
        initialActiveId: 'other',
      );

      notifier.viewProvider('proxy');
      final success = await notifier.fetchModels();

      expect(success, isTrue);
      expect(openAiAuthHeader, isNull);
      expect(geminiApiKeyHeader, 'proxy-key');
      expect(requestedPaths, ['/v1beta/models']);
      expect(
        notifier.state.viewingProvider.models,
        ['gemini-1.5-pro', 'gemini-2.0-flash'],
      );
      expect(notifier.state.viewingProvider.selectedModel, 'gemini-1.5-pro');
      expect(storage.savedProvider?.providerId, 'proxy');
      expect(storage.savedProvider?.providerProtocol, 'gemini');
    });

    test('refreshSettings migrates legacy routing state to provider protocol',
        () async {
      final entity = ProviderConfigEntity()
        ..providerId = 'legacy'
        ..name = 'Legacy Gemini'
        ..apiKeys = ['legacy-key']
        ..baseUrl = 'https://generativelanguage.googleapis.com/v1beta'
        ..modelSettingsJson = jsonEncode({
          'gemini-2.5-flash': {
            '_aurora_transport_mode': 'gemini_native',
            '_aurora_transport_base_url': 'https://old.example/v1beta',
            '_aurora_gemini_native_tools': {
              'google_search': true,
            },
          },
        })
        ..capabilityRoutesJson = jsonEncode({
          'chat': {
            'preset': 'gemini_native_generate_content',
          },
        })
        ..modelCapabilityOverridesJson = jsonEncode({
          'gemini-2.5-flash': {
            'chat': {
              'preset': 'openai_chat_completions',
            },
          },
        })
        ..savedModels = ['gemini-2.5-flash'];

      final storage = _MemorySettingsStorage(providerEntities: [entity]);
      final notifier = _TestSettingsNotifier(
        storage: storage,
        initialProviders: const [],
        initialActiveId: '',
      );

      await notifier.refreshSettings();

      final provider = notifier.state.activeProvider;
      expect(provider.id, 'legacy');
      expect(provider.providerProtocol, ProviderProtocol.gemini);
      expect(
        provider.modelSettings['gemini-2.5-flash'],
        {
          '_aurora_gemini_native_tools': {
            'google_search': true,
          },
        },
      );
      expect(storage.savedProvider?.providerProtocol, 'gemini');
      expect(storage.savedProvider?.capabilityRoutesJson, isNull);
      expect(storage.savedProvider?.modelCapabilityOverridesJson, isNull);
      final savedModelSettings =
          jsonDecode(storage.savedProvider?.modelSettingsJson ?? '{}')
              as Map<String, dynamic>;
      final savedGeminiSettings =
          savedModelSettings['gemini-2.5-flash'] as Map<String, dynamic>;
      expect(
        savedGeminiSettings.containsKey('_aurora_transport_mode'),
        isFalse,
      );
      expect(
        savedGeminiSettings.containsKey('_aurora_transport_base_url'),
        isFalse,
      );
    });

    test('commitProviderBaseUrl auto-syncs protocol from submitted url',
        () async {
      final storage = _MemorySettingsStorage();
      final notifier = _TestSettingsNotifier(
        storage: storage,
        initialProviders: [
          ProviderConfig(
            id: 'provider',
            name: 'Provider',
            baseUrl: 'https://api.openai.com/v1',
            providerProtocol: ProviderProtocol.anthropic,
            isCustom: true,
          ),
        ],
        initialActiveId: 'provider',
      );

      await notifier.commitProviderBaseUrl(
        id: 'provider',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      );
      expect(notifier.state.activeProvider.providerProtocol,
          ProviderProtocol.gemini);

      await notifier.commitProviderBaseUrl(
        id: 'provider',
        baseUrl: 'https://api.example.com/v1/messages',
      );
      expect(
        notifier.state.activeProvider.providerProtocol,
        ProviderProtocol.anthropic,
      );

      await notifier.commitProviderBaseUrl(
        id: 'provider',
        baseUrl: 'https://proxy.example.com/custom',
      );
      expect(
        notifier.state.activeProvider.providerProtocol,
        ProviderProtocol.openaiCompatible,
      );
    });
  });
}
