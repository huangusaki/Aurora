import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/capability_route_resolver.dart';
import 'package:aurora/shared/services/gemini_native_endpoint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CapabilityRouteResolver', () {
    test('openai protocol resolves model lists without hidden fallback', () {
      final provider = ProviderConfig(
        id: 'proxy',
        name: 'Proxy',
        isCustom: true,
        baseUrl: 'http://127.0.0.1:8080',
        providerProtocol: ProviderProtocol.openaiCompatible,
      );

      final route = const CapabilityRouteResolver().resolve(
        provider: provider,
        capability: ProviderCapability.models,
      );

      expect(route.preset, ProtocolPreset.openaiModels);
      expect(route.fallbackPreset, isNull);
    });

    test('model capability overrides win over provider routes', () {
      final provider = ProviderConfig(
        id: 'mixed',
        name: 'Mixed',
        baseUrl: 'https://api.openai.com/v1',
        capabilityConfig: ProviderCapabilityConfig(
          routes: {
            ProviderCapability.chat: const CapabilityRouteConfig(
              preset: ProtocolPreset.openaiChatCompletions,
            ),
          },
        ),
        modelCapabilityOverrides: const {
          'claude-sonnet': ModelCapabilityOverride(
            routes: {
              ProviderCapability.chat: CapabilityRouteConfig(
                preset: ProtocolPreset.anthropicMessages,
                baseUrlOverride: 'https://api.anthropic.com/v1',
              ),
            },
          ),
        },
      );

      final route = const CapabilityRouteResolver().resolve(
        provider: provider,
        capability: ProviderCapability.chat,
        modelName: 'claude-sonnet',
      );

      expect(route.preset, ProtocolPreset.anthropicMessages);
      expect(route.baseUrl, 'https://api.anthropic.com/v1');
    });

    test('anthropic protocol disables unsupported non-chat routes', () {
      final provider = ProviderConfig(
        id: 'anthropic',
        name: 'Anthropic',
        baseUrl: 'https://api.anthropic.com/v1',
        providerProtocol: ProviderProtocol.anthropic,
      );

      expect(
        provider.capabilityConfig.routeFor(ProviderCapability.chat)?.enabled,
        true,
      );
      expect(
        provider.capabilityConfig.routeFor(ProviderCapability.models)?.enabled,
        true,
      );
      expect(
        provider.capabilityConfig
            .routeFor(ProviderCapability.transcriptions)
            ?.enabled,
        false,
      );
      expect(
        provider.capabilityConfig
            .routeFor(ProviderCapability.embeddings)
            ?.enabled,
        false,
      );
    });

    test('gemini protocol keeps native v1beta urls on native routes', () {
      final provider = ProviderConfig(
        id: 'gemini',
        name: 'Gemini',
        baseUrl: officialGeminiNativeBaseUrl,
        providerProtocol: ProviderProtocol.gemini,
      );

      final route = const CapabilityRouteResolver().resolve(
        provider: provider,
        capability: ProviderCapability.transcriptions,
        modelName: 'gemini-2.5-flash',
      );

      expect(route.baseUrl, officialGeminiNativeBaseUrl);
      expect(route.preset, ProtocolPreset.geminiNativeGenerateContent);
    });

    test('gemini protocol keeps /openai urls on openai-compatible routes', () {
      final provider = ProviderConfig(
        id: 'gemini-openai',
        name: 'Gemini OpenAI',
        baseUrl: officialGeminiOpenAIBaseUrl,
        providerProtocol: ProviderProtocol.gemini,
      );

      final route = const CapabilityRouteResolver().resolve(
        provider: provider,
        capability: ProviderCapability.transcriptions,
        modelName: 'gemini-2.5-flash',
      );

      expect(route.baseUrl, officialGeminiOpenAIBaseUrl);
      expect(route.preset, ProtocolPreset.geminiOpenaiChatCompletions);
    });
  });
}
