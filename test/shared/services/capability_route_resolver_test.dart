import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/capability_route_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CapabilityRouteResolver', () {
    test('legacy custom providers keep model-list fallback to Gemini models',
        () {
      final provider = ProviderConfig(
        id: 'proxy',
        name: 'Proxy',
        isCustom: true,
        baseUrl: 'http://127.0.0.1:8080',
      );

      final route = const CapabilityRouteResolver().resolve(
        provider: provider,
        capability: ProviderCapability.models,
      );

      expect(route.preset, ProtocolPreset.openaiModels);
      expect(route.fallbackPreset, ProtocolPreset.geminiModels);
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
  });
}
