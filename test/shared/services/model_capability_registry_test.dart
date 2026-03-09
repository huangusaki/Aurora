import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/shared/services/model_capability_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModelCapabilityRegistry', () {
    test('marks Gemini multimodal models as supported for audio text tasks',
        () {
      final assessment = matchModelCapability(
        capability: ProviderCapability.transcriptions,
        model: 'gemini-2.5-flash',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        preset: ProtocolPreset.geminiNativeGenerateContent,
        routeEnabled: true,
      );

      expect(assessment.isKnownSupported, isTrue);
      expect(displayCapabilityMarker(assessment), '✅');
      expect(assessment.audioInputMode, AudioInputMode.chatOnly);
    });

    test('marks Claude models as unsupported for audio text tasks', () {
      final assessment = matchModelCapability(
        capability: ProviderCapability.translations,
        model: 'claude-sonnet-4-5',
        baseUrl: 'https://api.anthropic.com/v1',
        preset: ProtocolPreset.anthropicMessages,
        routeEnabled: true,
      );

      expect(assessment.isKnownUnsupported, isTrue);
      expect(assessment.audioInputMode, AudioInputMode.unsupported);
    });

    test('matches prefixed Gemini model names by regex', () {
      final assessment = matchModelCapability(
        capability: ProviderCapability.translations,
        model: 'CLI-gemini-3-pro-preview',
        baseUrl: 'https://proxy.example.com/v1',
        preset: ProtocolPreset.openaiChatCompletions,
        routeEnabled: true,
      );

      expect(assessment.isKnownSupported, isTrue);
      expect(displayCapabilityMarker(assessment), '✅');
    });

    test('models containing image are treated as image-capable', () {
      final assessment = matchModelCapability(
        capability: ProviderCapability.images,
        model: 'gemini-3.1-flash-image',
        baseUrl: 'https://proxy.example.com/v1',
        preset: ProtocolPreset.openaiImages,
        routeEnabled: true,
      );

      expect(assessment.isKnownSupported, isTrue);
      expect(displayCapabilityMarker(assessment), '✅');
    });

    test('falls back to unknown for uncovered models', () {
      final assessment = matchModelCapability(
        capability: ProviderCapability.images,
        model: 'gpt-4.1',
        baseUrl: 'https://api.openai.com/v1',
        preset: ProtocolPreset.openaiImages,
        routeEnabled: true,
      );

      expect(assessment.isUnknown, isTrue);
      expect(displayCapabilityMarker(assessment), '❓');
    });

    test('marks documented GPT audio models as supported by regex', () {
      final assessment = matchModelCapability(
        capability: ProviderCapability.translations,
        model: 'gpt-audio-mini',
        baseUrl: 'https://proxy.example.com/v1',
        preset: ProtocolPreset.openaiChatCompletions,
        routeEnabled: true,
      );

      expect(assessment.isKnownSupported, isTrue);
      expect(displayCapabilityMarker(assessment), '✅');
    });

    test('keeps generic GPT models unknown for audio translation', () {
      final assessment = matchModelCapability(
        capability: ProviderCapability.translations,
        model: 'gpt-5.2',
        baseUrl: 'https://proxy.example.com/v1',
        preset: ProtocolPreset.openaiChatCompletions,
        routeEnabled: true,
      );

      expect(assessment.isUnknown, isTrue);
      expect(displayCapabilityMarker(assessment), '❓');
    });

    test('prefers documented supported models over unknown and unsupported',
        () {
      final best = pickBestModelForCapability(
        capability: ProviderCapability.transcriptions,
        models: const ['whisper-1', 'gpt-4.1', 'gpt-audio'],
        assessModel: (model) => matchModelCapability(
          capability: ProviderCapability.transcriptions,
          model: model,
          baseUrl: 'https://api.openai.com/v1',
          preset: ProtocolPreset.openaiChatCompletions,
          routeEnabled: true,
        ),
      );

      expect(best, 'gpt-audio');
    });
  });
}
