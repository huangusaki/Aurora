import 'package:flutter/widgets.dart';
import 'package:aurora/l10n/app_localizations.dart';

import '../domain/provider_route_config.dart';

String capabilityLabel(BuildContext context, ProviderCapability capability) {
  final l10n = AppLocalizations.of(context)!;
  return switch (capability) {
    ProviderCapability.chat => l10n.capabilityChatLabel,
    ProviderCapability.models => l10n.capabilityModelsLabel,
    ProviderCapability.embeddings => l10n.capabilityEmbeddingsLabel,
    ProviderCapability.images => l10n.capabilityImagesLabel,
    ProviderCapability.speech => l10n.capabilitySpeechLabel,
    ProviderCapability.transcriptions => l10n.capabilityTranscriptionsLabel,
    ProviderCapability.translations => l10n.capabilityTranslationsLabel,
  };
}

String capabilityDescription(
  BuildContext context,
  ProviderCapability capability,
) {
  final l10n = AppLocalizations.of(context)!;
  return switch (capability) {
    ProviderCapability.chat => l10n.capabilityChatDescription,
    ProviderCapability.models => l10n.capabilityModelsDescription,
    ProviderCapability.embeddings => l10n.capabilityEmbeddingsDescription,
    ProviderCapability.images => l10n.capabilityImagesDescription,
    ProviderCapability.speech => l10n.capabilitySpeechDescription,
    ProviderCapability.transcriptions =>
      l10n.capabilityTranscriptionsDescription,
    ProviderCapability.translations => l10n.capabilityTranslationsDescription,
  };
}

String protocolPresetLabel(BuildContext context, ProtocolPreset preset) {
  final l10n = AppLocalizations.of(context)!;
  return switch (preset) {
    ProtocolPreset.openaiResponses => l10n.protocolPresetOpenaiResponses,
    ProtocolPreset.openaiChatCompletions =>
      l10n.protocolPresetOpenaiChatCompletions,
    ProtocolPreset.anthropicMessages => l10n.protocolPresetAnthropicMessages,
    ProtocolPreset.geminiNativeGenerateContent =>
      l10n.protocolPresetGeminiNativeGenerateContent,
    ProtocolPreset.geminiOpenaiChatCompletions =>
      l10n.protocolPresetGeminiOpenaiChatCompletions,
    ProtocolPreset.openaiModels => l10n.protocolPresetOpenaiModels,
    ProtocolPreset.anthropicModels => l10n.protocolPresetAnthropicModels,
    ProtocolPreset.geminiModels => l10n.protocolPresetGeminiModels,
    ProtocolPreset.openaiEmbeddings => l10n.protocolPresetOpenaiEmbeddings,
    ProtocolPreset.geminiEmbedContent => l10n.protocolPresetGeminiEmbedContent,
    ProtocolPreset.openaiImages => l10n.protocolPresetOpenaiImages,
    ProtocolPreset.openaiAudioSpeech => l10n.protocolPresetOpenaiAudioSpeech,
    ProtocolPreset.openaiAudioTranscriptions =>
      l10n.protocolPresetOpenaiAudioTranscriptions,
    ProtocolPreset.openaiAudioTranslations =>
      l10n.protocolPresetOpenaiAudioTranslations,
    ProtocolPreset.customJson => l10n.protocolPresetCustomJson,
    ProtocolPreset.customMultipart => l10n.protocolPresetCustomMultipart,
  };
}

String authModeLabel(BuildContext context, RouteAuthMode mode) {
  final l10n = AppLocalizations.of(context)!;
  return switch (mode) {
    RouteAuthMode.bearerHeader => l10n.authModeBearerHeader,
    RouteAuthMode.xApiKeyHeader => l10n.authModeXApiKeyHeader,
    RouteAuthMode.customHeader => l10n.authModeCustomHeader,
    RouteAuthMode.query => l10n.authModeQueryParameter,
    RouteAuthMode.none => l10n.authModeNoAuth,
  };
}

String streamModeLabel(BuildContext context, RouteStreamMode mode) {
  final l10n = AppLocalizations.of(context)!;
  return switch (mode) {
    RouteStreamMode.auto => l10n.streamModeAutoLabel,
    RouteStreamMode.sse => l10n.streamModeSseLabel,
    RouteStreamMode.none => l10n.streamModeNonStreamingLabel,
  };
}
