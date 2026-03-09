enum ProviderCapability {
  chat('chat'),
  models('models'),
  embeddings('embeddings'),
  images('images'),
  speech('speech'),
  transcriptions('transcriptions'),
  translations('translations');

  final String wireName;
  const ProviderCapability(this.wireName);

  static ProviderCapability? fromRaw(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    for (final value in values) {
      if (value.wireName == normalized) {
        return value;
      }
    }
    return null;
  }
}

enum ProtocolPreset {
  openaiResponses('openai_responses'),
  openaiChatCompletions('openai_chat_completions'),
  anthropicMessages('anthropic_messages'),
  geminiNativeGenerateContent('gemini_native_generate_content'),
  geminiOpenaiChatCompletions('gemini_openai_chat_completions'),
  openaiModels('openai_models'),
  anthropicModels('anthropic_models'),
  geminiModels('gemini_models'),
  openaiEmbeddings('openai_embeddings'),
  geminiEmbedContent('gemini_embed_content'),
  openaiImages('openai_images'),
  openaiAudioSpeech('openai_audio_speech'),
  openaiAudioTranscriptions('openai_audio_transcriptions'),
  openaiAudioTranslations('openai_audio_translations'),
  customJson('custom_json'),
  customMultipart('custom_multipart');

  final String wireName;
  const ProtocolPreset(this.wireName);

  static ProtocolPreset? fromRaw(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    for (final value in values) {
      if (value.wireName == normalized) {
        return value;
      }
    }
    return null;
  }
}

enum RouteAuthMode {
  bearerHeader('bearer_header'),
  xApiKeyHeader('x_api_key_header'),
  customHeader('custom_header'),
  query('query'),
  none('none');

  final String wireName;
  const RouteAuthMode(this.wireName);

  static RouteAuthMode fromRaw(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    for (final value in values) {
      if (value.wireName == normalized) {
        return value;
      }
    }
    return RouteAuthMode.bearerHeader;
  }
}

enum RouteStreamMode {
  auto('auto'),
  sse('sse'),
  none('none');

  final String wireName;
  const RouteStreamMode(this.wireName);

  static RouteStreamMode fromRaw(Object? raw) {
    final normalized = raw?.toString().trim().toLowerCase();
    for (final value in values) {
      if (value.wireName == normalized) {
        return value;
      }
    }
    return RouteStreamMode.auto;
  }
}

class CapabilityRouteConfig {
  final ProtocolPreset? preset;
  final bool? enabled;
  final String? baseUrlOverride;
  final String? pathOverride;
  final String? methodOverride;
  final RouteAuthMode? authMode;
  final String? authHeaderName;
  final String? authQueryKey;
  final String? apiKeyOverride;
  final Map<String, String> staticHeaders;
  final Map<String, String> staticQuery;
  final RouteStreamMode? streamMode;
  final int? timeoutOverrideMs;
  final ProtocolPreset? fallbackPreset;

  const CapabilityRouteConfig({
    this.preset,
    this.enabled,
    this.baseUrlOverride,
    this.pathOverride,
    this.methodOverride,
    this.authMode,
    this.authHeaderName,
    this.authQueryKey,
    this.apiKeyOverride,
    this.staticHeaders = const {},
    this.staticQuery = const {},
    this.streamMode,
    this.timeoutOverrideMs,
    this.fallbackPreset,
  });

  bool get isEmpty =>
      preset == null &&
      enabled == null &&
      _isBlank(baseUrlOverride) &&
      _isBlank(pathOverride) &&
      _isBlank(methodOverride) &&
      authMode == null &&
      _isBlank(authHeaderName) &&
      _isBlank(authQueryKey) &&
      _isBlank(apiKeyOverride) &&
      staticHeaders.isEmpty &&
      staticQuery.isEmpty &&
      streamMode == null &&
      timeoutOverrideMs == null &&
      fallbackPreset == null;

  CapabilityRouteConfig copyWith({
    ProtocolPreset? preset,
    Object? enabled = _unset,
    Object? baseUrlOverride = _unset,
    Object? pathOverride = _unset,
    Object? methodOverride = _unset,
    Object? authMode = _unset,
    Object? authHeaderName = _unset,
    Object? authQueryKey = _unset,
    Object? apiKeyOverride = _unset,
    Map<String, String>? staticHeaders,
    Map<String, String>? staticQuery,
    Object? streamMode = _unset,
    Object? timeoutOverrideMs = _unset,
    Object? fallbackPreset = _unset,
  }) {
    return CapabilityRouteConfig(
      preset: preset ?? this.preset,
      enabled: enabled == _unset ? this.enabled : enabled as bool?,
      baseUrlOverride: baseUrlOverride == _unset
          ? this.baseUrlOverride
          : baseUrlOverride as String?,
      pathOverride:
          pathOverride == _unset ? this.pathOverride : pathOverride as String?,
      methodOverride: methodOverride == _unset
          ? this.methodOverride
          : methodOverride as String?,
      authMode: authMode == _unset ? this.authMode : authMode as RouteAuthMode?,
      authHeaderName: authHeaderName == _unset
          ? this.authHeaderName
          : authHeaderName as String?,
      authQueryKey:
          authQueryKey == _unset ? this.authQueryKey : authQueryKey as String?,
      apiKeyOverride: apiKeyOverride == _unset
          ? this.apiKeyOverride
          : apiKeyOverride as String?,
      staticHeaders: staticHeaders ?? this.staticHeaders,
      staticQuery: staticQuery ?? this.staticQuery,
      streamMode: streamMode == _unset
          ? this.streamMode
          : streamMode as RouteStreamMode?,
      timeoutOverrideMs: timeoutOverrideMs == _unset
          ? this.timeoutOverrideMs
          : timeoutOverrideMs as int?,
      fallbackPreset: fallbackPreset == _unset
          ? this.fallbackPreset
          : fallbackPreset as ProtocolPreset?,
    );
  }

  CapabilityRouteConfig merge(CapabilityRouteConfig override) {
    return CapabilityRouteConfig(
      preset: override.preset ?? preset,
      enabled: override.enabled ?? enabled,
      baseUrlOverride: _preferNonBlank(
        override.baseUrlOverride,
        baseUrlOverride,
      ),
      pathOverride: _preferNonBlank(override.pathOverride, pathOverride),
      methodOverride: _preferNonBlank(override.methodOverride, methodOverride),
      authMode: override.authMode ?? authMode,
      authHeaderName: _preferNonBlank(
        override.authHeaderName,
        authHeaderName,
      ),
      authQueryKey: _preferNonBlank(override.authQueryKey, authQueryKey),
      apiKeyOverride: _preferNonBlank(override.apiKeyOverride, apiKeyOverride),
      staticHeaders: {...staticHeaders, ...override.staticHeaders},
      staticQuery: {...staticQuery, ...override.staticQuery},
      streamMode: override.streamMode ?? streamMode,
      timeoutOverrideMs: override.timeoutOverrideMs ?? timeoutOverrideMs,
      fallbackPreset: override.fallbackPreset ?? fallbackPreset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (preset != null) 'preset': preset!.wireName,
      if (enabled != null) 'enabled': enabled,
      if (!_isBlank(baseUrlOverride)) 'baseUrlOverride': baseUrlOverride,
      if (!_isBlank(pathOverride)) 'pathOverride': pathOverride,
      if (!_isBlank(methodOverride)) 'methodOverride': methodOverride,
      if (authMode != null) 'authMode': authMode!.wireName,
      if (!_isBlank(authHeaderName)) 'authHeaderName': authHeaderName,
      if (!_isBlank(authQueryKey)) 'authQueryKey': authQueryKey,
      if (!_isBlank(apiKeyOverride)) 'apiKeyOverride': apiKeyOverride,
      if (staticHeaders.isNotEmpty) 'staticHeaders': staticHeaders,
      if (staticQuery.isNotEmpty) 'staticQuery': staticQuery,
      if (streamMode != null) 'streamMode': streamMode!.wireName,
      if (timeoutOverrideMs != null) 'timeoutOverrideMs': timeoutOverrideMs,
      if (fallbackPreset != null) 'fallbackPreset': fallbackPreset!.wireName,
    };
  }

  factory CapabilityRouteConfig.fromJson(Map<String, dynamic> json) {
    return CapabilityRouteConfig(
      preset: ProtocolPreset.fromRaw(json['preset']),
      enabled: json['enabled'] is bool ? json['enabled'] as bool : null,
      baseUrlOverride: _normalizeString(json['baseUrlOverride']),
      pathOverride: _normalizeString(json['pathOverride']),
      methodOverride: _normalizeString(json['methodOverride']),
      authMode: json.containsKey('authMode')
          ? RouteAuthMode.fromRaw(json['authMode'])
          : null,
      authHeaderName: _normalizeString(json['authHeaderName']),
      authQueryKey: _normalizeString(json['authQueryKey']),
      apiKeyOverride: _normalizeString(json['apiKeyOverride']),
      staticHeaders: _decodeStringMap(json['staticHeaders']),
      staticQuery: _decodeStringMap(json['staticQuery']),
      streamMode: json.containsKey('streamMode')
          ? RouteStreamMode.fromRaw(json['streamMode'])
          : null,
      timeoutOverrideMs: _asInt(json['timeoutOverrideMs']),
      fallbackPreset: ProtocolPreset.fromRaw(json['fallbackPreset']),
    );
  }
}

class ProviderCapabilityConfig {
  final Map<ProviderCapability, CapabilityRouteConfig> routes;

  const ProviderCapabilityConfig({
    this.routes = const {},
  });

  CapabilityRouteConfig? routeFor(ProviderCapability capability) {
    return routes[capability];
  }

  ProviderCapabilityConfig copyWith({
    Map<ProviderCapability, CapabilityRouteConfig>? routes,
  }) {
    return ProviderCapabilityConfig(routes: routes ?? this.routes);
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    for (final entry in routes.entries) {
      if (!entry.value.isEmpty) {
        result[entry.key.wireName] = entry.value.toJson();
      }
    }
    return result;
  }

  factory ProviderCapabilityConfig.fromJson(Map<String, dynamic> json) {
    final routes = <ProviderCapability, CapabilityRouteConfig>{};
    json.forEach((key, value) {
      final capability = ProviderCapability.fromRaw(key);
      if (capability == null || value is! Map) return;
      routes[capability] = CapabilityRouteConfig.fromJson(
        value.map((mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue)),
      );
    });
    return ProviderCapabilityConfig(routes: routes);
  }
}

class ModelCapabilityOverride {
  final Map<ProviderCapability, CapabilityRouteConfig> routes;

  const ModelCapabilityOverride({
    this.routes = const {},
  });

  CapabilityRouteConfig? routeFor(ProviderCapability capability) {
    return routes[capability];
  }

  bool get isEmpty => routes.isEmpty;

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    for (final entry in routes.entries) {
      if (!entry.value.isEmpty) {
        result[entry.key.wireName] = entry.value.toJson();
      }
    }
    return result;
  }

  factory ModelCapabilityOverride.fromJson(Map<String, dynamic> json) {
    final routes = <ProviderCapability, CapabilityRouteConfig>{};
    json.forEach((key, value) {
      final capability = ProviderCapability.fromRaw(key);
      if (capability == null || value is! Map) return;
      routes[capability] = CapabilityRouteConfig.fromJson(
        value.map((mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue)),
      );
    });
    return ModelCapabilityOverride(routes: routes);
  }
}

Map<String, ModelCapabilityOverride> decodeModelCapabilityOverrides(
  Object? raw,
) {
  if (raw is! Map) return const {};
  final result = <String, ModelCapabilityOverride>{};
  raw.forEach((key, value) {
    if (value is! Map) return;
    result[key.toString()] = ModelCapabilityOverride.fromJson(
      value.map((mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue)),
    );
  });
  return result;
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

String? _preferNonBlank(String? primary, String? fallback) {
  return _isBlank(primary) ? fallback : primary?.trim();
}

String? _normalizeString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

Map<String, String> _decodeStringMap(Object? raw) {
  if (raw is! Map) return const {};
  final result = <String, String>{};
  raw.forEach((key, value) {
    final normalizedKey = key.toString().trim();
    final normalizedValue = value?.toString().trim() ?? '';
    if (normalizedKey.isEmpty || normalizedValue.isEmpty) return;
    result[normalizedKey] = normalizedValue;
  });
  return result;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '');
}

const Object _unset = Object();
