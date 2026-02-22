import '../../features/settings/presentation/settings_provider.dart';

const String auroraTransportModeKey = '_aurora_transport_mode';
const String auroraLegacyTransportModeKey = '_aurora_transport';
const String auroraTransportBaseUrlKey = '_aurora_transport_base_url';
const String auroraTransportApiKeyKey = '_aurora_transport_api_key';
const String auroraGeminiNativeToolsKey = '_aurora_gemini_native_tools';
const String auroraGeminiNativeGoogleSearchKey = 'google_search';
const String auroraGeminiNativeUrlContextKey = 'url_context';
const String auroraGeminiNativeCodeExecutionKey = 'code_execution';

enum LlmTransportMode {
  auto('auto'),
  openaiCompat('openai_compat'),
  geminiNative('gemini_native');

  final String wireName;
  const LlmTransportMode(this.wireName);

  static LlmTransportMode fromRaw(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    switch (value) {
      case 'openai_compat':
        return LlmTransportMode.openaiCompat;
      case 'gemini_native':
        return LlmTransportMode.geminiNative;
      case 'auto':
      default:
        return LlmTransportMode.auto;
    }
  }
}

LlmTransportMode resolveTransportModeFromSettings(
    Map<String, dynamic>? modelSettings) {
  if (modelSettings == null || modelSettings.isEmpty) {
    return LlmTransportMode.auto;
  }
  final raw = modelSettings[auroraTransportModeKey] ??
      modelSettings[auroraLegacyTransportModeKey];
  return LlmTransportMode.fromRaw(raw);
}

LlmTransportMode resolveModelTransportMode({
  required ProviderConfig provider,
  required String modelName,
}) {
  return resolveTransportModeFromSettings(provider.modelSettings[modelName]);
}

Map<String, dynamic> withTransportMode(
  Map<String, dynamic> source,
  LlmTransportMode mode,
) {
  final next = Map<String, dynamic>.from(source);
  next.remove(auroraLegacyTransportModeKey);
  if (mode == LlmTransportMode.auto) {
    next.remove(auroraTransportModeKey);
  } else {
    next[auroraTransportModeKey] = mode.wireName;
  }
  return next;
}

class GeminiNativeToolsConfig {
  final bool googleSearch;
  final bool urlContext;
  final bool codeExecution;

  const GeminiNativeToolsConfig({
    this.googleSearch = false,
    this.urlContext = false,
    this.codeExecution = false,
  });

  bool get hasAnyEnabled => googleSearch || urlContext || codeExecution;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value == null) return false;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'on';
}

GeminiNativeToolsConfig resolveGeminiNativeToolsFromSettings(
  Map<String, dynamic>? modelSettings,
) {
  if (modelSettings == null || modelSettings.isEmpty) {
    return const GeminiNativeToolsConfig();
  }
  final raw = modelSettings[auroraGeminiNativeToolsKey];
  if (raw is! Map) {
    return const GeminiNativeToolsConfig();
  }
  return GeminiNativeToolsConfig(
    googleSearch: _asBool(raw[auroraGeminiNativeGoogleSearchKey]),
    urlContext: _asBool(raw[auroraGeminiNativeUrlContextKey]),
    codeExecution: _asBool(raw[auroraGeminiNativeCodeExecutionKey]),
  );
}

Map<String, dynamic> withGeminiNativeTools(
  Map<String, dynamic> source,
  GeminiNativeToolsConfig config,
) {
  final next = Map<String, dynamic>.from(source);
  if (!config.hasAnyEnabled) {
    next.remove(auroraGeminiNativeToolsKey);
    return next;
  }
  next[auroraGeminiNativeToolsKey] = {
    auroraGeminiNativeGoogleSearchKey: config.googleSearch,
    auroraGeminiNativeUrlContextKey: config.urlContext,
    auroraGeminiNativeCodeExecutionKey: config.codeExecution,
  };
  return next;
}
