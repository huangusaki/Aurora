import '../../features/settings/domain/provider_route_config.dart';
import 'gemini_native_endpoint.dart';

enum ProviderModelFamily {
  openai('openai'),
  geminiOpenAi('gemini_openai'),
  geminiNative('gemini_native'),
  anthropic('anthropic'),
  unknown('unknown');

  final String wireName;
  const ProviderModelFamily(this.wireName);
}

enum CapabilitySupportStatus {
  supported,
  unsupported,
  unknown,
}

enum ModelCapabilityConfidence {
  documented,
  unknown,
}

enum AudioInputMode {
  chatOnly('chat_only'),
  unsupported('unsupported'),
  unknown('unknown');

  final String wireName;
  const AudioInputMode(this.wireName);
}

class ModelCapabilityAssessment {
  final ProviderModelFamily family;
  final ProviderCapability capability;
  final String model;
  final CapabilitySupportStatus status;
  final ModelCapabilityConfidence confidence;
  final AudioInputMode audioInputMode;
  final bool routeEnabled;

  const ModelCapabilityAssessment({
    required this.family,
    required this.capability,
    required this.model,
    required this.status,
    required this.confidence,
    required this.audioInputMode,
    required this.routeEnabled,
  });

  bool get isKnownSupported =>
      routeEnabled &&
      status == CapabilitySupportStatus.supported &&
      confidence == ModelCapabilityConfidence.documented;

  bool get isKnownUnsupported =>
      !routeEnabled || status == CapabilitySupportStatus.unsupported;

  bool get isUnknown => !isKnownSupported && !isKnownUnsupported;
}

class _CapabilityRule {
  final ProviderModelFamily? family;
  final RegExp pattern;
  final Set<ProviderCapability> supported;
  final Set<ProviderCapability> unsupported;
  final AudioInputMode audioInputMode;
  final ModelCapabilityConfidence confidence;

  _CapabilityRule({
    this.family,
    required this.pattern,
    this.supported = const {},
    this.unsupported = const {},
    this.audioInputMode = AudioInputMode.unknown,
    this.confidence = ModelCapabilityConfidence.documented,
  });
}

final List<_CapabilityRule> _rules = [
  _CapabilityRule(
    pattern: RegExp(
      r'(?:^|[-_])(?:gemini|learnlm)(?:[-_]|$)',
      caseSensitive: false,
    ),
    supported: {
      ProviderCapability.chat,
      ProviderCapability.models,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.chatOnly,
  ),
  _CapabilityRule(
    pattern: RegExp(r'(?:image|imagen)', caseSensitive: false),
    supported: {
      ProviderCapability.images,
    },
  ),
  _CapabilityRule(
    pattern: RegExp(r'(?:^|[-_])claude(?:[-_]|$)', caseSensitive: false),
    supported: {
      ProviderCapability.chat,
      ProviderCapability.models,
    },
    unsupported: {
      ProviderCapability.embeddings,
      ProviderCapability.images,
      ProviderCapability.speech,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.unsupported,
  ),
  _CapabilityRule(
    pattern: RegExp(
      r'(?:^|[-_])(?:gpt-audio(?:-mini|-1\.5)?|gpt-4o(?:-mini)?-audio-preview(?:-\d{4}-\d{2}-\d{2})?)(?:[-_]|$)',
      caseSensitive: false,
    ),
    supported: {
      ProviderCapability.chat,
      ProviderCapability.models,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.chatOnly,
  ),
  _CapabilityRule(
    pattern: RegExp(
      r'(?:^|[-_])(?:gpt-4o-transcribe|gpt-4o-transcribe-diarize)(?:[-_]|$)',
      caseSensitive: false,
    ),
    supported: {
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.chatOnly,
  ),
  _CapabilityRule(
    pattern: RegExp(
      r'(?:^|[-_])gpt-4o-mini-transcribe(?:[-_]|$)',
      caseSensitive: false,
    ),
    supported: {
      ProviderCapability.transcriptions,
    },
    audioInputMode: AudioInputMode.chatOnly,
  ),
  _CapabilityRule(
    pattern: RegExp(
      r'(?:^|[-_])(?:gpt-4o-mini-tts|tts-1(?:-hd)?)(?:[-_]|$)',
      caseSensitive: false,
    ),
    supported: {
      ProviderCapability.speech,
    },
    audioInputMode: AudioInputMode.unsupported,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.anthropic,
    pattern: RegExp(r'^claude-', caseSensitive: false),
    supported: {
      ProviderCapability.chat,
      ProviderCapability.models,
    },
    unsupported: {
      ProviderCapability.embeddings,
      ProviderCapability.images,
      ProviderCapability.speech,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.unsupported,
    confidence: ModelCapabilityConfidence.documented,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.geminiNative,
    pattern: RegExp(r'^(?:gemini-|learnlm-)', caseSensitive: false),
    supported: {
      ProviderCapability.chat,
      ProviderCapability.models,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.chatOnly,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.geminiOpenAi,
    pattern: RegExp(r'^(?:gemini-|learnlm-)', caseSensitive: false),
    supported: {
      ProviderCapability.chat,
      ProviderCapability.models,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.chatOnly,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.geminiNative,
    pattern: RegExp(r'^(?:gemini-embedding-|text-embedding-004$)',
        caseSensitive: false),
    supported: {
      ProviderCapability.embeddings,
    },
  ),
  _CapabilityRule(
    family: ProviderModelFamily.geminiNative,
    pattern: RegExp(r'(?:image|imagen)', caseSensitive: false),
    supported: {
      ProviderCapability.images,
    },
  ),
  _CapabilityRule(
    family: ProviderModelFamily.geminiOpenAi,
    pattern: RegExp(r'(?:image|imagen)', caseSensitive: false),
    supported: {
      ProviderCapability.images,
    },
  ),
  _CapabilityRule(
    family: ProviderModelFamily.openai,
    pattern: RegExp(
        r'^(?:text-embedding-3-(?:small|large)|text-embedding-ada-002)$',
        caseSensitive: false),
    supported: {
      ProviderCapability.embeddings,
    },
  ),
  _CapabilityRule(
    family: ProviderModelFamily.openai,
    pattern: RegExp(r'^(?:gpt-image-1|dall-e-[23])$', caseSensitive: false),
    supported: {
      ProviderCapability.images,
    },
    unsupported: {
      ProviderCapability.speech,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.unsupported,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.openai,
    pattern:
        RegExp(r'^(?:gpt-4o-mini-tts|tts-1(?:-hd)?)$', caseSensitive: false),
    supported: {
      ProviderCapability.speech,
    },
    unsupported: {
      ProviderCapability.images,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.unsupported,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.openai,
    pattern: RegExp(
      r'^(?:gpt-audio(?:-mini)?|gpt-4o(?:-mini)?-audio-preview(?:-\d{4}-\d{2}-\d{2})?)$',
      caseSensitive: false,
    ),
    supported: {
      ProviderCapability.chat,
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.chatOnly,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.openai,
    pattern: RegExp(r'^gpt-4o(?:-mini)?-transcribe$', caseSensitive: false),
    supported: {
      ProviderCapability.transcriptions,
    },
    audioInputMode: AudioInputMode.chatOnly,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.openai,
    pattern: RegExp(r'^whisper-1$', caseSensitive: false),
    unsupported: {
      ProviderCapability.transcriptions,
      ProviderCapability.translations,
    },
    audioInputMode: AudioInputMode.unsupported,
  ),
  _CapabilityRule(
    family: ProviderModelFamily.openai,
    pattern:
        RegExp(r'^(?:gpt-|o[13]|computer-use-preview)', caseSensitive: false),
    supported: {
      ProviderCapability.chat,
    },
  ),
];

ProviderModelFamily detectProviderFamily({
  String? baseUrl,
  ProtocolPreset? preset,
}) {
  final normalizedBase = (baseUrl ?? '').trim();
  final effectivePreset = preset;
  if (effectivePreset == ProtocolPreset.anthropicMessages ||
      effectivePreset == ProtocolPreset.anthropicModels ||
      normalizedBase.toLowerCase().contains('anthropic.com')) {
    return ProviderModelFamily.anthropic;
  }
  if (effectivePreset == ProtocolPreset.geminiNativeGenerateContent ||
      effectivePreset == ProtocolPreset.geminiModels ||
      effectivePreset == ProtocolPreset.geminiEmbedContent) {
    return ProviderModelFamily.geminiNative;
  }
  if (effectivePreset == ProtocolPreset.geminiOpenaiChatCompletions) {
    return ProviderModelFamily.geminiOpenAi;
  }
  if (isOfficialGeminiNativeBaseUrl(normalizedBase)) {
    if (looksLikeGeminiNativeBaseUrl(normalizedBase) &&
        !_isOpenAiCompatiblePreset(effectivePreset)) {
      return ProviderModelFamily.geminiNative;
    }
    return ProviderModelFamily.geminiOpenAi;
  }
  if (_isOpenAiCompatiblePreset(effectivePreset)) {
    return ProviderModelFamily.openai;
  }
  return ProviderModelFamily.unknown;
}

ProviderModelFamily detectProviderFamilyFromBaseUrl(
  String baseUrl, {
  bool forceGeminiNative = false,
}) {
  if (forceGeminiNative) {
    return ProviderModelFamily.geminiNative;
  }
  final lowerBaseUrl = baseUrl.trim().toLowerCase();
  if (lowerBaseUrl.contains('anthropic.com')) {
    return ProviderModelFamily.anthropic;
  }
  if (looksLikeGeminiNativeBaseUrl(baseUrl)) {
    return ProviderModelFamily.geminiNative;
  }
  if (isOfficialGeminiNativeBaseUrl(baseUrl)) {
    return ProviderModelFamily.geminiOpenAi;
  }
  if (lowerBaseUrl.contains('openai.com') || lowerBaseUrl.contains('/v1')) {
    return ProviderModelFamily.openai;
  }
  return ProviderModelFamily.unknown;
}

ModelCapabilityAssessment matchModelCapability({
  required ProviderCapability capability,
  required String model,
  required String baseUrl,
  required ProtocolPreset preset,
  required bool routeEnabled,
}) {
  final normalizedModel = model.trim();
  final family = detectProviderFamily(baseUrl: baseUrl, preset: preset);
  if (!routeEnabled) {
    return ModelCapabilityAssessment(
      family: family,
      capability: capability,
      model: normalizedModel,
      status: CapabilitySupportStatus.unsupported,
      confidence: ModelCapabilityConfidence.documented,
      audioInputMode: AudioInputMode.unsupported,
      routeEnabled: false,
    );
  }
  if (normalizedModel.isEmpty) {
    return ModelCapabilityAssessment(
      family: family,
      capability: capability,
      model: normalizedModel,
      status: CapabilitySupportStatus.unknown,
      confidence: ModelCapabilityConfidence.unknown,
      audioInputMode: AudioInputMode.unknown,
      routeEnabled: true,
    );
  }
  for (final rule in _rules) {
    if (rule.family != null && rule.family != family) {
      continue;
    }
    if (!rule.pattern.hasMatch(normalizedModel)) {
      continue;
    }
    if (rule.supported.contains(capability)) {
      return ModelCapabilityAssessment(
        family: family,
        capability: capability,
        model: normalizedModel,
        status: CapabilitySupportStatus.supported,
        confidence: rule.confidence,
        audioInputMode: rule.audioInputMode,
        routeEnabled: true,
      );
    }
    if (rule.unsupported.contains(capability)) {
      return ModelCapabilityAssessment(
        family: family,
        capability: capability,
        model: normalizedModel,
        status: CapabilitySupportStatus.unsupported,
        confidence: rule.confidence,
        audioInputMode: AudioInputMode.unsupported,
        routeEnabled: true,
      );
    }
  }
  return ModelCapabilityAssessment(
    family: family,
    capability: capability,
    model: normalizedModel,
    status: CapabilitySupportStatus.unknown,
    confidence: ModelCapabilityConfidence.unknown,
    audioInputMode: AudioInputMode.unknown,
    routeEnabled: true,
  );
}

String displayCapabilityMarker(ModelCapabilityAssessment assessment) {
  return assessment.isKnownSupported ? '✅' : '❓';
}

bool _isOpenAiCompatiblePreset(ProtocolPreset? preset) {
  return switch (preset) {
    ProtocolPreset.openaiResponses ||
    ProtocolPreset.openaiChatCompletions ||
    ProtocolPreset.openaiModels ||
    ProtocolPreset.openaiEmbeddings ||
    ProtocolPreset.openaiImages ||
    ProtocolPreset.openaiAudioSpeech ||
    ProtocolPreset.openaiAudioTranscriptions ||
    ProtocolPreset.openaiAudioTranslations =>
      true,
    _ => false,
  };
}
