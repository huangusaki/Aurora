import '../../features/settings/domain/provider_route_config.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'gemini_native_endpoint.dart';

class ResolvedCapabilityRoute {
  final ProviderCapability capability;
  final ProtocolPreset preset;
  final bool enabled;
  final String baseUrl;
  final String? path;
  final String method;
  final RouteAuthMode authMode;
  final String? authHeaderName;
  final String? authQueryKey;
  final String? apiKeyOverride;
  final Map<String, String> staticHeaders;
  final Map<String, String> staticQuery;
  final RouteStreamMode streamMode;
  final int? timeoutOverrideMs;
  final ProtocolPreset? fallbackPreset;

  const ResolvedCapabilityRoute({
    required this.capability,
    required this.preset,
    required this.enabled,
    required this.baseUrl,
    required this.path,
    required this.method,
    required this.authMode,
    required this.authHeaderName,
    required this.authQueryKey,
    required this.apiKeyOverride,
    required this.staticHeaders,
    required this.staticQuery,
    required this.streamMode,
    required this.timeoutOverrideMs,
    required this.fallbackPreset,
  });

  String effectiveApiKey(ProviderConfig provider) {
    final override = apiKeyOverride?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return provider.apiKey;
  }

  Uri buildUri({
    String? model,
    bool stream = false,
    String? apiKey,
  }) {
    final resolvedPath = _resolvePath(
      preset: preset,
      baseUrl: baseUrl,
      path: path,
      model: model,
      stream: stream,
    );
    final query = <String, String>{...staticQuery};
    final effectiveKey = apiKey?.trim();
    if (authMode == RouteAuthMode.query &&
        effectiveKey != null &&
        effectiveKey.isNotEmpty) {
      query[authQueryKey?.trim().isNotEmpty == true
          ? authQueryKey!.trim()
          : 'api_key'] = effectiveKey;
    }
    return _joinUri(baseUrl: baseUrl, path: resolvedPath, query: query);
  }

  Map<String, String> buildHeaders({
    required String apiKey,
    Map<String, String> extra = const {},
  }) {
    final headers = <String, String>{...staticHeaders};
    final normalizedKey = apiKey.trim();
    switch (authMode) {
      case RouteAuthMode.bearerHeader:
        if (normalizedKey.isNotEmpty) {
          headers[authHeaderName?.trim().isNotEmpty == true
              ? authHeaderName!.trim()
              : 'Authorization'] = 'Bearer $normalizedKey';
        }
        break;
      case RouteAuthMode.xApiKeyHeader:
        if (normalizedKey.isNotEmpty) {
          headers[authHeaderName?.trim().isNotEmpty == true
              ? authHeaderName!.trim()
              : 'x-api-key'] = normalizedKey;
        }
        break;
      case RouteAuthMode.customHeader:
        if (normalizedKey.isNotEmpty) {
          headers[authHeaderName?.trim().isNotEmpty == true
              ? authHeaderName!.trim()
              : 'Authorization'] = normalizedKey;
        }
        break;
      case RouteAuthMode.query:
      case RouteAuthMode.none:
        break;
    }
    headers.addAll(extra);
    return headers;
  }

  ResolvedCapabilityRoute copyWith({
    ProtocolPreset? preset,
    String? baseUrl,
    String? path,
    ProtocolPreset? fallbackPreset,
  }) {
    return ResolvedCapabilityRoute(
      capability: capability,
      preset: preset ?? this.preset,
      enabled: enabled,
      baseUrl: baseUrl ?? this.baseUrl,
      path: path ?? this.path,
      method: method,
      authMode: authMode,
      authHeaderName: authHeaderName,
      authQueryKey: authQueryKey,
      apiKeyOverride: apiKeyOverride,
      staticHeaders: staticHeaders,
      staticQuery: staticQuery,
      streamMode: streamMode,
      timeoutOverrideMs: timeoutOverrideMs,
      fallbackPreset: fallbackPreset ?? this.fallbackPreset,
    );
  }
}

class CapabilityRouteResolver {
  const CapabilityRouteResolver();

  ResolvedCapabilityRoute resolve({
    required ProviderConfig provider,
    required ProviderCapability capability,
    String? modelName,
    ProtocolPreset? forcePreset,
  }) {
    final providerRoute = provider.capabilityConfig.routeFor(capability) ??
        const CapabilityRouteConfig();
    final modelRoute = modelName == null
        ? null
        : provider.modelCapabilityOverrides[modelName]?.routeFor(capability);
    final merged =
        providerRoute.merge(modelRoute ?? const CapabilityRouteConfig());
    final preset = forcePreset ?? merged.preset ?? _fallbackPreset(capability);
    final defaults = _defaultsForPreset(preset);
    final baseUrl = _normalizeBaseUrlForPreset(
      preset: preset,
      rawBaseUrl: _firstNonBlank(
            merged.baseUrlOverride,
            provider.baseUrl,
          ) ??
          defaults.baseUrl,
    );
    return ResolvedCapabilityRoute(
      capability: capability,
      preset: preset,
      enabled: merged.enabled ?? defaults.enabled,
      baseUrl: baseUrl,
      path: _firstNonBlank(merged.pathOverride, defaults.path),
      method: (_firstNonBlank(merged.methodOverride, defaults.method) ?? 'POST')
          .toUpperCase(),
      authMode: merged.authMode ?? defaults.authMode,
      authHeaderName:
          _firstNonBlank(merged.authHeaderName, defaults.authHeaderName),
      authQueryKey: _firstNonBlank(merged.authQueryKey, defaults.authQueryKey),
      apiKeyOverride: merged.apiKeyOverride,
      staticHeaders: {...defaults.staticHeaders, ...merged.staticHeaders},
      staticQuery: merged.staticQuery,
      streamMode: merged.streamMode ?? defaults.streamMode,
      timeoutOverrideMs: merged.timeoutOverrideMs,
      fallbackPreset: merged.fallbackPreset,
    );
  }

  ResolvedCapabilityRoute? resolveFallback({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute current,
    String? modelName,
  }) {
    final fallbackPreset = current.fallbackPreset;
    if (fallbackPreset == null || fallbackPreset == current.preset) {
      return null;
    }
    return resolve(
      provider: provider,
      capability: capability,
      modelName: modelName,
      forcePreset: fallbackPreset,
    );
  }

  ProtocolPreset _fallbackPreset(ProviderCapability capability) {
    return switch (capability) {
      ProviderCapability.chat => ProtocolPreset.openaiChatCompletions,
      ProviderCapability.models => ProtocolPreset.openaiModels,
      ProviderCapability.embeddings => ProtocolPreset.openaiEmbeddings,
      ProviderCapability.images => ProtocolPreset.openaiImages,
      ProviderCapability.speech => ProtocolPreset.openaiAudioSpeech,
      ProviderCapability.transcriptions =>
        ProtocolPreset.openaiAudioTranscriptions,
      ProviderCapability.translations => ProtocolPreset.openaiAudioTranslations,
    };
  }
}

class _RoutePresetDefaults {
  final String baseUrl;
  final String? path;
  final String method;
  final bool enabled;
  final RouteAuthMode authMode;
  final String? authHeaderName;
  final String? authQueryKey;
  final Map<String, String> staticHeaders;
  final RouteStreamMode streamMode;

  const _RoutePresetDefaults({
    required this.baseUrl,
    required this.path,
    required this.method,
    required this.enabled,
    required this.authMode,
    required this.authHeaderName,
    required this.authQueryKey,
    this.staticHeaders = const {},
    this.streamMode = RouteStreamMode.auto,
  });
}

_RoutePresetDefaults _defaultsForPreset(ProtocolPreset preset) {
  return switch (preset) {
    ProtocolPreset.openaiResponses => const _RoutePresetDefaults(
        baseUrl: 'https://api.openai.com/v1',
        path: 'responses',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
        streamMode: RouteStreamMode.sse,
      ),
    ProtocolPreset.openaiChatCompletions => const _RoutePresetDefaults(
        baseUrl: 'https://api.openai.com/v1',
        path: 'chat/completions',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
        streamMode: RouteStreamMode.sse,
      ),
    ProtocolPreset.anthropicMessages => const _RoutePresetDefaults(
        baseUrl: 'https://api.anthropic.com/v1',
        path: 'messages',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.customHeader,
        authHeaderName: 'x-api-key',
        authQueryKey: null,
        staticHeaders: {'anthropic-version': '2023-06-01'},
        streamMode: RouteStreamMode.sse,
      ),
    ProtocolPreset.geminiNativeGenerateContent => const _RoutePresetDefaults(
        baseUrl: officialGeminiNativeBaseUrl,
        path: '{model}:{action}',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.customHeader,
        authHeaderName: 'x-goog-api-key',
        authQueryKey: null,
        streamMode: RouteStreamMode.sse,
      ),
    ProtocolPreset.geminiOpenaiChatCompletions => const _RoutePresetDefaults(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
        path: 'chat/completions',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
        streamMode: RouteStreamMode.sse,
      ),
    ProtocolPreset.openaiModels => const _RoutePresetDefaults(
        baseUrl: 'https://api.openai.com/v1',
        path: 'models',
        method: 'GET',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
      ),
    ProtocolPreset.anthropicModels => const _RoutePresetDefaults(
        baseUrl: 'https://api.anthropic.com/v1',
        path: 'models',
        method: 'GET',
        enabled: true,
        authMode: RouteAuthMode.customHeader,
        authHeaderName: 'x-api-key',
        authQueryKey: null,
        staticHeaders: {'anthropic-version': '2023-06-01'},
      ),
    ProtocolPreset.geminiModels => const _RoutePresetDefaults(
        baseUrl: officialGeminiNativeBaseUrl,
        path: 'models',
        method: 'GET',
        enabled: true,
        authMode: RouteAuthMode.customHeader,
        authHeaderName: 'x-goog-api-key',
        authQueryKey: null,
      ),
    ProtocolPreset.openaiEmbeddings => const _RoutePresetDefaults(
        baseUrl: 'https://api.openai.com/v1',
        path: 'embeddings',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
      ),
    ProtocolPreset.geminiEmbedContent => const _RoutePresetDefaults(
        baseUrl: officialGeminiNativeBaseUrl,
        path: '{model}:embedContent',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.customHeader,
        authHeaderName: 'x-goog-api-key',
        authQueryKey: null,
      ),
    ProtocolPreset.openaiImages => const _RoutePresetDefaults(
        baseUrl: 'https://api.openai.com/v1',
        path: 'images/generations',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
      ),
    ProtocolPreset.openaiAudioSpeech => const _RoutePresetDefaults(
        baseUrl: 'https://api.openai.com/v1',
        path: 'audio/speech',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
      ),
    ProtocolPreset.openaiAudioTranscriptions => const _RoutePresetDefaults(
        baseUrl: 'https://api.openai.com/v1',
        path: 'audio/transcriptions',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
      ),
    ProtocolPreset.openaiAudioTranslations => const _RoutePresetDefaults(
        baseUrl: 'https://api.openai.com/v1',
        path: 'audio/translations',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
      ),
    ProtocolPreset.customJson => const _RoutePresetDefaults(
        baseUrl: '',
        path: '',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
      ),
    ProtocolPreset.customMultipart => const _RoutePresetDefaults(
        baseUrl: '',
        path: '',
        method: 'POST',
        enabled: true,
        authMode: RouteAuthMode.bearerHeader,
        authHeaderName: 'Authorization',
        authQueryKey: null,
      ),
  };
}

String _normalizeBaseUrlForPreset({
  required ProtocolPreset preset,
  required String rawBaseUrl,
}) {
  final trimmed = rawBaseUrl.trim();
  if (trimmed.isEmpty) {
    return _defaultsForPreset(preset).baseUrl;
  }
  return switch (preset) {
    ProtocolPreset.geminiNativeGenerateContent ||
    ProtocolPreset.geminiModels ||
    ProtocolPreset.geminiEmbedContent =>
      normalizeGeminiNativeBaseUrl(trimmed),
    _ => trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed,
  };
}

String _resolvePath({
  required ProtocolPreset preset,
  required String baseUrl,
  required String? path,
  required String? model,
  required bool stream,
}) {
  if (path == null || path.trim().isEmpty) {
    return '';
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  var resolved = path.trim();
  if (resolved.contains('{model}')) {
    final normalizedModel = model?.trim();
    if (normalizedModel == null || normalizedModel.isEmpty) {
      throw StateError('Model is required for preset ${preset.wireName}.');
    }
    resolved = resolved.replaceAll(
        '{model}', _normalizeGeminiModelPath(normalizedModel));
  }
  if (resolved.contains('{action}')) {
    final action = stream ? 'streamGenerateContent' : 'generateContent';
    resolved = resolved.replaceAll('{action}', action);
  }
  if (preset == ProtocolPreset.geminiNativeGenerateContent && stream) {
    if (!resolved.contains('alt=sse')) {
      if (resolved.contains('?')) {
        resolved = '$resolved&alt=sse';
      } else {
        resolved = '$resolved?alt=sse';
      }
    }
  }
  return resolved;
}

Uri _joinUri({
  required String baseUrl,
  required String path,
  required Map<String, String> query,
}) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    final parsed = Uri.parse(path);
    if (query.isEmpty) return parsed;
    return parsed
        .replace(queryParameters: {...parsed.queryParameters, ...query});
  }
  final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  final uri = Uri.parse('$normalizedBase$normalizedPath');
  if (query.isEmpty) return uri;
  return uri.replace(queryParameters: {...uri.queryParameters, ...query});
}

String? _firstNonBlank(String? primary, String? fallback) {
  final normalizedPrimary = primary?.trim();
  if (normalizedPrimary != null && normalizedPrimary.isNotEmpty) {
    return normalizedPrimary;
  }
  final normalizedFallback = fallback?.trim();
  if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
    return normalizedFallback;
  }
  return null;
}

String _normalizeGeminiModelPath(String model) {
  if (model.startsWith('models/') || model.startsWith('publishers/')) {
    return model;
  }
  return 'models/$model';
}
