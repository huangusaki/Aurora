import '../../features/settings/domain/provider_route_config.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'capability_route_resolver.dart';

const String auroraTransportBaseUrlKey = '_aurora_transport_base_url';
const String auroraTransportApiKeyKey = '_aurora_transport_api_key';
const String auroraImageConfigKey = '_aurora_image_config';
const String auroraImageConfigModeKey = 'mode';
const String auroraImageConfigIncludeThoughtsKey = 'include_thoughts';
const String auroraGeminiProxyAssistantImageRewriteKey =
    '_aurora_gemini_proxy_assistant_image_rewrite';
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
}

enum ImageConfigTransportMode {
  auto('auto'),
  openaiImageConfig('openai_image_config'),
  googleExtraBody('google_extra_body');

  final String wireName;
  const ImageConfigTransportMode(this.wireName);

  static ImageConfigTransportMode fromRaw(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    switch (value) {
      case 'openai_image_config':
        return ImageConfigTransportMode.openaiImageConfig;
      case 'google_extra_body':
        return ImageConfigTransportMode.googleExtraBody;
      case 'auto':
      default:
        return ImageConfigTransportMode.auto;
    }
  }
}

class AuroraImageConfig {
  final ImageConfigTransportMode mode;
  final String? aspectRatio;
  final String? imageSize;
  final bool? includeThoughts;

  const AuroraImageConfig({
    this.mode = ImageConfigTransportMode.auto,
    this.aspectRatio,
    this.imageSize,
    this.includeThoughts,
  });

  bool get hasValues =>
      aspectRatio != null || imageSize != null || includeThoughts != null;

  Map<String, dynamic> toSettingsMap() {
    return {
      if (mode != ImageConfigTransportMode.auto)
        auroraImageConfigModeKey: mode.wireName,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
      if (imageSize != null) 'image_size': imageSize,
      if (includeThoughts != null)
        auroraImageConfigIncludeThoughtsKey: includeThoughts,
    };
  }
}

Map<String, dynamic> _stringKeyedMap(dynamic value) {
  if (value is! Map) return const <String, dynamic>{};
  final result = <String, dynamic>{};
  value.forEach((key, val) {
    if (key is String) {
      result[key] = val;
    }
  });
  return result;
}

String? _normalizeImageAspectRatio(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  final normalized = raw.toLowerCase();
  if (normalized == 'auto' || normalized == '自动') return null;
  return raw;
}

String? _normalizeImageSize(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  return raw;
}

bool? _normalizeOptionalBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'on') {
    return true;
  }
  if (normalized == '0' ||
      normalized == 'false' ||
      normalized == 'no' ||
      normalized == 'off') {
    return false;
  }
  return null;
}

AuroraImageConfig resolveAuroraImageConfig(Map<String, dynamic>? settings) {
  if (settings == null || settings.isEmpty) {
    return const AuroraImageConfig();
  }

  final rawConfig = settings[auroraImageConfigKey] ?? settings['image_config'];
  final imageConfig = _stringKeyedMap(rawConfig);
  if (imageConfig.isEmpty) {
    return const AuroraImageConfig();
  }

  return AuroraImageConfig(
    mode: ImageConfigTransportMode.fromRaw(
      imageConfig[auroraImageConfigModeKey],
    ),
    aspectRatio: _normalizeImageAspectRatio(imageConfig['aspect_ratio']),
    imageSize: _normalizeImageSize(imageConfig['image_size']),
    includeThoughts: _normalizeOptionalBool(
      imageConfig[auroraImageConfigIncludeThoughtsKey],
    ),
  );
}

Map<String, dynamic> withAuroraImageConfig(
  Map<String, dynamic> source,
  AuroraImageConfig config,
) {
  final next = Map<String, dynamic>.from(source);
  next.remove('image_config');

  final configMap = config.toSettingsMap();
  if (configMap.isEmpty) {
    next.remove(auroraImageConfigKey);
  } else {
    next[auroraImageConfigKey] = configMap;
  }
  return next;
}

LlmTransportMode resolveModelTransportMode({
  required ProviderConfig provider,
  required String modelName,
}) {
  final route = const CapabilityRouteResolver().resolve(
    provider: provider,
    capability: ProviderCapability.chat,
    modelName: modelName,
  );
  return route.preset == ProtocolPreset.geminiNativeGenerateContent
      ? LlmTransportMode.geminiNative
      : LlmTransportMode.openaiCompat;
}

bool resolveGeminiProxyAssistantImageRewrite(
  Map<String, dynamic>? modelSettings,
) {
  if (modelSettings == null || modelSettings.isEmpty) return false;
  return _asBool(modelSettings[auroraGeminiProxyAssistantImageRewriteKey]);
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
