import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/services/model_capability_registry.dart';
import 'package:aurora/shared/services/capability_route_resolver.dart';
import 'package:aurora/shared/services/provider_capability_gateway.dart';
import 'package:aurora/shared/utils/app_logger.dart';
import '../data/settings_storage.dart';
import '../data/provider_config_entity.dart';
import '../domain/chat_preset.dart';
import '../domain/provider_route_config.dart';
import '../data/chat_preset_entity.dart';

const List<String> _legacyTransportRoutingKeys = <String>[
  '_aurora_transport_mode',
  '_aurora_transport',
  '_aurora_transport_base_url',
  '_aurora_transport_api_key',
];
const int minLlmRequestTimeoutSeconds = 30;
const int maxLlmRequestTimeoutSeconds = 1800;
const int defaultLlmRequestTimeoutSeconds = 300;

class _ProviderEntityLoadResult {
  final ProviderConfig config;
  final bool needsWriteBack;

  const _ProviderEntityLoadResult({
    required this.config,
    required this.needsWriteBack,
  });
}

class ProviderConfig {
  final String id;
  final String name;
  final String? color;
  final List<String> apiKeys;
  final int currentKeyIndex;
  final bool autoRotateKeys;
  final String baseUrl;
  final ProviderProtocol providerProtocol;
  final bool isCustom;
  final Map<String, dynamic> customParameters;
  final Map<String, Map<String, dynamic>> modelSettings;
  final Map<String, dynamic> globalSettings;
  final ProviderCapabilityConfig capabilityConfig;
  final Map<String, ModelCapabilityOverride> modelCapabilityOverrides;
  final List<String> globalExcludeModels;
  final List<String> models;
  final String? selectedChatModel;
  final bool isEnabled;

  String? get selectedModel => selectedChatModel;
  ProviderModelFamily get providerFamily => _resolveProviderModelFamily(
        providerProtocol: providerProtocol,
        baseUrl: baseUrl,
      );

  String get apiKey {
    if (apiKeys.isEmpty) return '';
    final safeIndex = currentKeyIndex.clamp(0, apiKeys.length - 1);
    return apiKeys[safeIndex];
  }

  int get safeCurrentKeyIndex {
    if (apiKeys.isEmpty) return 0;
    return currentKeyIndex.clamp(0, apiKeys.length - 1);
  }

  factory ProviderConfig({
    required String id,
    required String name,
    String? color,
    List<String> apiKeys = const [],
    int currentKeyIndex = 0,
    bool autoRotateKeys = false,
    String baseUrl = 'https://api.openai.com/v1',
    ProviderProtocol? providerProtocol,
    bool isCustom = false,
    Map<String, dynamic> customParameters = const {},
    Map<String, Map<String, dynamic>> modelSettings = const {},
    Map<String, dynamic> globalSettings = const {},
    ProviderCapabilityConfig capabilityConfig =
        const ProviderCapabilityConfig(),
    Map<String, ModelCapabilityOverride> modelCapabilityOverrides = const {},
    List<String> globalExcludeModels = const [],
    List<String> models = const [],
    String? selectedChatModel,
    bool isEnabled = true,
  }) {
    final normalizedModelSettings = _sanitizeModelSettings(modelSettings);
    final effectiveProtocol = providerProtocol ??
        _inferProviderProtocol(
          baseUrl: baseUrl,
          modelSettings: modelSettings,
        );
    final effectiveCapabilityConfig = capabilityConfig.routes.isNotEmpty
        ? capabilityConfig
        : _buildCapabilityConfig(
            providerProtocol: effectiveProtocol,
            baseUrl: baseUrl,
          );

    return ProviderConfig._(
      id: id,
      name: name,
      color: color,
      apiKeys: apiKeys,
      currentKeyIndex: currentKeyIndex,
      autoRotateKeys: autoRotateKeys,
      baseUrl: baseUrl,
      providerProtocol: effectiveProtocol,
      isCustom: isCustom,
      customParameters: customParameters,
      modelSettings: normalizedModelSettings,
      globalSettings: globalSettings,
      capabilityConfig: effectiveCapabilityConfig,
      modelCapabilityOverrides: modelCapabilityOverrides,
      globalExcludeModels: globalExcludeModels,
      models: models,
      selectedChatModel: selectedChatModel,
      isEnabled: isEnabled,
    );
  }

  const ProviderConfig._({
    required this.id,
    required this.name,
    required this.color,
    required this.apiKeys,
    required this.currentKeyIndex,
    required this.autoRotateKeys,
    required this.baseUrl,
    required this.providerProtocol,
    required this.isCustom,
    required this.customParameters,
    required this.modelSettings,
    required this.globalSettings,
    required this.capabilityConfig,
    required this.modelCapabilityOverrides,
    required this.globalExcludeModels,
    required this.models,
    required this.selectedChatModel,
    required this.isEnabled,
  });

  ProviderConfig copyWith({
    String? name,
    String? color,
    List<String>? apiKeys,
    int? currentKeyIndex,
    bool? autoRotateKeys,
    String? baseUrl,
    ProviderProtocol? providerProtocol,
    Map<String, dynamic>? customParameters,
    Map<String, Map<String, dynamic>>? modelSettings,
    Map<String, dynamic>? globalSettings,
    ProviderCapabilityConfig? capabilityConfig,
    Map<String, ModelCapabilityOverride>? modelCapabilityOverrides,
    List<String>? globalExcludeModels,
    List<String>? models,
    Object? selectedChatModel = _settingsSentinel,
    bool? isEnabled,
  }) {
    return ProviderConfig(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      apiKeys: apiKeys ?? this.apiKeys,
      currentKeyIndex: currentKeyIndex ?? this.currentKeyIndex,
      autoRotateKeys: autoRotateKeys ?? this.autoRotateKeys,
      baseUrl: baseUrl ?? this.baseUrl,
      providerProtocol: providerProtocol ?? this.providerProtocol,
      isCustom: isCustom,
      customParameters: customParameters ?? this.customParameters,
      modelSettings: modelSettings ?? this.modelSettings,
      globalSettings: globalSettings ?? this.globalSettings,
      capabilityConfig: capabilityConfig ?? const ProviderCapabilityConfig(),
      modelCapabilityOverrides:
          modelCapabilityOverrides ?? this.modelCapabilityOverrides,
      globalExcludeModels: globalExcludeModels ?? this.globalExcludeModels,
      models: models ?? this.models,
      selectedChatModel: selectedChatModel == _settingsSentinel
          ? this.selectedChatModel
          : selectedChatModel as String?,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  bool isModelEnabled(String modelId) {
    if (modelSettings.containsKey(modelId)) {
      final settings = modelSettings[modelId]!;
      if (settings['_aurora_model_disabled'] == true) {
        return false;
      }
    }
    return true;
  }

  static List<ProviderConfig> fromEntities(
      List<ProviderConfigEntity> entities) {
    if (entities.isEmpty) {
      return defaultProviders();
    }
    final providers =
        entities.map((entity) => _loadFromEntity(entity).config).toList();
    if (!providers.any((provider) => provider.id == 'custom')) {
      providers.add(
        ProviderConfig(
          id: 'custom',
          name: 'Custom',
          isCustom: true,
          providerProtocol: ProviderProtocol.openaiCompatible,
        ),
      );
    }
    return providers;
  }

  static List<ProviderConfig> defaultProviders() {
    return [
      ProviderConfig(
        id: 'openai',
        name: 'OpenAI',
        isCustom: false,
        providerProtocol: ProviderProtocol.openaiCompatible,
      ),
      ProviderConfig(
        id: 'custom',
        name: 'Custom',
        isCustom: true,
        providerProtocol: ProviderProtocol.openaiCompatible,
      ),
    ];
  }

  static ProviderConfig fromEntity(ProviderConfigEntity entity) {
    return _loadFromEntity(entity).config;
  }

  static _ProviderEntityLoadResult _loadFromEntity(
      ProviderConfigEntity entity) {
    final customParams = _decodeJsonMap(entity.customParametersJson);
    final rawModelSettings = _decodeModelSettings(entity.modelSettingsJson);
    final sanitizedModelSettings = _sanitizeModelSettings(rawModelSettings);
    final globalSettings = _decodeJsonMap(entity.globalSettingsJson);

    List<String> apiKeys = List<String>.from(entity.apiKeys);
    // ignore: deprecated_member_use_from_same_package
    if (apiKeys.isEmpty && entity.apiKey.isNotEmpty) {
      // ignore: deprecated_member_use_from_same_package
      apiKeys = [entity.apiKey];
    }

    final selectedChatModel =
        entity.selectedChatModel ?? entity.lastSelectedModel;
    final storedProtocolRaw = entity.providerProtocol?.trim().toLowerCase();
    final storedProtocol = ProviderProtocol.fromRaw(entity.providerProtocol);
    final effectiveProtocol = storedProtocol ??
        _inferProviderProtocol(
          baseUrl: entity.baseUrl,
          modelSettings: rawModelSettings,
        );
    final needsWriteBack = storedProtocolRaw != effectiveProtocol.wireName ||
        (entity.capabilityRoutesJson?.trim().isNotEmpty ?? false) ||
        (entity.modelCapabilityOverridesJson?.trim().isNotEmpty ?? false) ||
        jsonEncode(rawModelSettings) != jsonEncode(sanitizedModelSettings) ||
        // ignore: deprecated_member_use_from_same_package
        (entity.apiKey.isNotEmpty && entity.apiKeys.isEmpty) ||
        entity.selectedChatModel != selectedChatModel;

    return _ProviderEntityLoadResult(
      config: ProviderConfig(
        id: entity.providerId,
        name: entity.name,
        color: entity.color,
        apiKeys: apiKeys,
        currentKeyIndex: entity.currentKeyIndex,
        autoRotateKeys: entity.autoRotateKeys,
        baseUrl: entity.baseUrl,
        providerProtocol: effectiveProtocol,
        isCustom: entity.isCustom,
        customParameters: customParams,
        modelSettings: sanitizedModelSettings,
        globalSettings: globalSettings,
        globalExcludeModels: entity.globalExcludeModels,
        models: entity.savedModels,
        selectedChatModel: selectedChatModel,
        isEnabled: entity.isEnabled,
      ),
      needsWriteBack: needsWriteBack,
    );
  }

  static Map<String, dynamic> _decodeJsonMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {}
    return {};
  }

  static Map<String, Map<String, dynamic>> _decodeModelSettings(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }
      final modelSettings = <String, Map<String, dynamic>>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          modelSettings[key.toString()] = value.map(
            (mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue),
          );
        }
      });
      return modelSettings;
    } catch (_) {}
    return {};
  }

  static Map<String, Map<String, dynamic>> _sanitizeModelSettings(
    Map<String, Map<String, dynamic>> source,
  ) {
    final result = <String, Map<String, dynamic>>{};
    source.forEach((modelName, settings) {
      final sanitized = Map<String, dynamic>.from(settings)
        ..removeWhere(
          (key, _) => _legacyTransportRoutingKeys.contains(key),
        );
      if (sanitized.isNotEmpty) {
        result[modelName] = sanitized;
      }
    });
    return result;
  }

  static ProviderProtocol _inferProviderProtocol({
    required String baseUrl,
    required Map<String, Map<String, dynamic>> modelSettings,
  }) {
    final protocolFromBaseUrl = _inferProviderProtocolFromBaseUrl(baseUrl);
    if (protocolFromBaseUrl != ProviderProtocol.openaiCompatible) {
      return protocolFromBaseUrl;
    }

    final hasLegacyGeminiTransport = modelSettings.values.any((settings) {
      final rawTransport =
          settings['_aurora_transport_mode'] ?? settings['_aurora_transport'];
      return rawTransport?.toString().trim().toLowerCase() == 'gemini_native';
    });
    return hasLegacyGeminiTransport
        ? ProviderProtocol.gemini
        : ProviderProtocol.openaiCompatible;
  }

  static ProviderProtocol _inferProviderProtocolFromBaseUrl(String baseUrl) {
    if (_looksLikeAnthropicMessagesPath(baseUrl)) {
      return ProviderProtocol.anthropic;
    }

    final family = detectProviderFamilyFromBaseUrl(baseUrl);
    return switch (family) {
      ProviderModelFamily.geminiOpenAi ||
      ProviderModelFamily.geminiNative =>
        ProviderProtocol.gemini,
      ProviderModelFamily.anthropic => ProviderProtocol.anthropic,
      _ => ProviderProtocol.openaiCompatible,
    };
  }

  static ProviderModelFamily _resolveProviderModelFamily({
    required ProviderProtocol providerProtocol,
    required String baseUrl,
  }) {
    switch (providerProtocol) {
      case ProviderProtocol.openaiCompatible:
        return ProviderModelFamily.openai;
      case ProviderProtocol.anthropic:
        return ProviderModelFamily.anthropic;
      case ProviderProtocol.gemini:
        final family = detectProviderFamilyFromBaseUrl(baseUrl);
        return family == ProviderModelFamily.geminiNative
            ? ProviderModelFamily.geminiNative
            : ProviderModelFamily.geminiOpenAi;
    }
  }

  static bool _looksLikeAnthropicMessagesPath(String baseUrl) {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null || uri.host.isEmpty) return false;

    final lowerHost = uri.host.toLowerCase();
    if (lowerHost.contains('anthropic.com')) {
      return true;
    }

    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .map((segment) => segment.toLowerCase())
        .toList(growable: false);
    if (segments.isEmpty || segments.last != 'messages') {
      return false;
    }
    if (segments.length == 1) {
      return true;
    }
    return segments.length >= 2 && segments[segments.length - 2] == 'v1';
  }

  static ProviderCapabilityConfig _buildCapabilityConfig({
    required ProviderProtocol providerProtocol,
    required String baseUrl,
  }) {
    final family = _resolveProviderModelFamily(
      providerProtocol: providerProtocol,
      baseUrl: baseUrl,
    );
    final chatPreset = switch (family) {
      ProviderModelFamily.geminiNative =>
        ProtocolPreset.geminiNativeGenerateContent,
      ProviderModelFamily.geminiOpenAi =>
        ProtocolPreset.geminiOpenaiChatCompletions,
      ProviderModelFamily.anthropic => ProtocolPreset.anthropicMessages,
      _ => ProtocolPreset.openaiChatCompletions,
    };
    final modelPreset = switch (family) {
      ProviderModelFamily.geminiNative ||
      ProviderModelFamily.geminiOpenAi =>
        ProtocolPreset.geminiModels,
      ProviderModelFamily.anthropic => ProtocolPreset.anthropicModels,
      _ => ProtocolPreset.openaiModels,
    };
    final embeddingPreset = switch (family) {
      ProviderModelFamily.geminiNative ||
      ProviderModelFamily.geminiOpenAi =>
        ProtocolPreset.geminiEmbedContent,
      ProviderModelFamily.anthropic => ProtocolPreset.customJson,
      _ => ProtocolPreset.openaiEmbeddings,
    };
    final audioChatPreset = switch (family) {
      ProviderModelFamily.geminiNative =>
        ProtocolPreset.geminiNativeGenerateContent,
      ProviderModelFamily.geminiOpenAi =>
        ProtocolPreset.geminiOpenaiChatCompletions,
      ProviderModelFamily.anthropic => ProtocolPreset.customJson,
      _ => ProtocolPreset.openaiChatCompletions,
    };
    final supportsNonChatCapabilities = family != ProviderModelFamily.anthropic;

    return ProviderCapabilityConfig(
      routes: {
        ProviderCapability.chat: CapabilityRouteConfig(
          preset: chatPreset,
          enabled: true,
        ),
        ProviderCapability.models: CapabilityRouteConfig(
          preset: modelPreset,
          enabled: true,
        ),
        ProviderCapability.embeddings: CapabilityRouteConfig(
          preset: embeddingPreset,
          enabled: supportsNonChatCapabilities,
        ),
        ProviderCapability.images: CapabilityRouteConfig(
          preset: ProtocolPreset.openaiImages,
          enabled: supportsNonChatCapabilities,
        ),
        ProviderCapability.speech: CapabilityRouteConfig(
          preset: ProtocolPreset.openaiAudioSpeech,
          enabled: supportsNonChatCapabilities,
        ),
        ProviderCapability.transcriptions: CapabilityRouteConfig(
          preset: audioChatPreset,
          enabled: supportsNonChatCapabilities,
        ),
        ProviderCapability.translations: CapabilityRouteConfig(
          preset: audioChatPreset,
          enabled: supportsNonChatCapabilities,
        ),
      },
    );
  }
}

class SettingsState {
  final List<ProviderConfig> providers;
  final String activeProviderId;
  final String viewingProviderId;
  final bool isLoadingModels;
  final String? error;
  final String userName;
  final String? userAvatar;
  final String llmName;
  final String? llmAvatar;
  final String themeMode;
  final bool isStreamEnabled;
  final bool isSearchEnabled;
  final bool isKnowledgeEnabled;
  final String searchEngine;
  final String searchRegion;
  final String searchSafeSearch;
  final int searchMaxResults;
  final int searchTimeoutSeconds;
  final int knowledgeTopK;
  final bool knowledgeUseEmbedding;
  final String knowledgeLlmEnhanceMode;
  final String? knowledgeEmbeddingModel;
  final String? knowledgeEmbeddingProviderId;
  final List<String> activeKnowledgeBaseIds;
  final bool enableSmartTopic;
  final String? topicGenerationModel;
  final bool restoreLastSessionOnLaunch;
  final bool keepChatScrollPositionOnResponse;
  final String language;
  final List<ChatPreset> presets;
  final String? lastPresetId;
  final String themeColor;
  final String backgroundColor;
  final int closeBehavior;
  final String? executionModel;
  final String? executionProviderId;
  final String? imageModel;
  final String? imageProviderId;
  final String? speechModel;
  final String? speechProviderId;
  final String? transcriptionModel;
  final String? transcriptionProviderId;
  final String? translationModel;
  final String? translationProviderId;
  final int llmRequestTimeoutSeconds;
  final int memoryMinNewUserMessages;
  final int memoryIdleSeconds;
  final int memoryMaxBufferedMessages;
  final int memoryMaxRunsPerDay;
  final int memoryContextWindowSize;
  final double fontSize;
  final String? backgroundImagePath;
  final double backgroundBrightness;
  final double backgroundBlur;
  final bool useCustomTheme;
  SettingsState({
    required this.providers,
    required this.activeProviderId,
    required this.viewingProviderId,
    this.isLoadingModels = false,
    this.error,
    this.userName = 'User',
    this.userAvatar,
    this.llmName = 'Assistant',
    this.llmAvatar,
    this.themeMode = 'system',
    this.isStreamEnabled = true,
    this.isSearchEnabled = false,
    this.isKnowledgeEnabled = false,
    this.searchEngine = 'duckduckgo',
    this.searchRegion = 'us-en',
    this.searchSafeSearch = 'moderate',
    this.searchMaxResults = 5,
    this.searchTimeoutSeconds = 15,
    this.knowledgeTopK = 5,
    this.knowledgeUseEmbedding = false,
    this.knowledgeLlmEnhanceMode = 'off',
    this.knowledgeEmbeddingModel,
    this.knowledgeEmbeddingProviderId,
    this.activeKnowledgeBaseIds = const [],
    this.enableSmartTopic = true,
    this.topicGenerationModel,
    this.restoreLastSessionOnLaunch = true,
    this.keepChatScrollPositionOnResponse = true,
    this.language = 'zh',
    this.presets = const [],
    this.lastPresetId,
    this.themeColor = 'teal',
    this.backgroundColor = 'default',
    this.closeBehavior = 0,
    this.executionModel,
    this.executionProviderId,
    this.imageModel,
    this.imageProviderId,
    this.speechModel,
    this.speechProviderId,
    this.transcriptionModel,
    this.transcriptionProviderId,
    this.translationModel,
    this.translationProviderId,
    this.llmRequestTimeoutSeconds = defaultLlmRequestTimeoutSeconds,
    this.memoryMinNewUserMessages = 20,
    this.memoryIdleSeconds = 600,
    this.memoryMaxBufferedMessages = 120,
    this.memoryMaxRunsPerDay = 2,
    this.memoryContextWindowSize = 80,
    this.fontSize = 14.0,
    this.backgroundImagePath,
    this.backgroundBrightness = 0.5,
    this.backgroundBlur = 0.0,
    this.useCustomTheme = false,
  });
  ProviderConfig get activeProvider {
    if (providers.isEmpty) {
      return ProviderConfig(id: 'custom', name: 'Custom', isCustom: true);
    }

    final normalizedId = activeProviderId.trim();
    final index = normalizedId.isEmpty
        ? -1
        : providers.indexWhere((p) => p.id == normalizedId);
    if (index != -1) {
      return providers[index];
    }

    final customIndex = providers.indexWhere((p) => p.id == 'custom');
    if (customIndex != -1) {
      return providers[customIndex];
    }

    return providers.first;
  }

  ProviderConfig get viewingProvider {
    if (providers.isEmpty) {
      return activeProvider;
    }

    final normalizedId = viewingProviderId.trim();
    final index = normalizedId.isEmpty
        ? -1
        : providers.indexWhere((p) => p.id == normalizedId);
    if (index != -1) {
      return providers[index];
    }

    return activeProvider;
  }

  String? get selectedModel => activeProvider.selectedModel;
  List<String> get availableModels => activeProvider.models;
  SettingsState copyWith({
    List<ProviderConfig>? providers,
    String? activeProviderId,
    String? viewingProviderId,
    bool? isLoadingModels,
    String? error,
    String? userName,
    String? userAvatar,
    String? llmName,
    String? llmAvatar,
    String? themeMode,
    bool? isStreamEnabled,
    bool? isSearchEnabled,
    bool? isKnowledgeEnabled,
    String? searchEngine,
    String? searchRegion,
    String? searchSafeSearch,
    int? searchMaxResults,
    int? searchTimeoutSeconds,
    int? knowledgeTopK,
    bool? knowledgeUseEmbedding,
    String? knowledgeLlmEnhanceMode,
    Object? knowledgeEmbeddingModel = _settingsSentinel,
    Object? knowledgeEmbeddingProviderId = _settingsSentinel,
    List<String>? activeKnowledgeBaseIds,
    bool? enableSmartTopic,
    String? topicGenerationModel,
    bool? restoreLastSessionOnLaunch,
    bool? keepChatScrollPositionOnResponse,
    String? language,
    List<ChatPreset>? presets,
    Object? lastPresetId = _settingsSentinel,
    String? themeColor,
    String? backgroundColor,
    int? closeBehavior,
    Object? executionModel = _settingsSentinel,
    Object? executionProviderId = _settingsSentinel,
    Object? imageModel = _settingsSentinel,
    Object? imageProviderId = _settingsSentinel,
    Object? speechModel = _settingsSentinel,
    Object? speechProviderId = _settingsSentinel,
    Object? transcriptionModel = _settingsSentinel,
    Object? transcriptionProviderId = _settingsSentinel,
    Object? translationModel = _settingsSentinel,
    Object? translationProviderId = _settingsSentinel,
    int? llmRequestTimeoutSeconds,
    int? memoryMinNewUserMessages,
    int? memoryIdleSeconds,
    int? memoryMaxBufferedMessages,
    int? memoryMaxRunsPerDay,
    int? memoryContextWindowSize,
    double? fontSize,
    Object? backgroundImagePath = _settingsSentinel,
    double? backgroundBrightness,
    double? backgroundBlur,
    bool? useCustomTheme,
  }) {
    return SettingsState(
      providers: providers ?? this.providers,
      activeProviderId: activeProviderId ?? this.activeProviderId,
      viewingProviderId: viewingProviderId ?? this.viewingProviderId,
      isLoadingModels: isLoadingModels ?? this.isLoadingModels,
      error: error,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      llmName: llmName ?? this.llmName,
      llmAvatar: llmAvatar ?? this.llmAvatar,
      themeMode: themeMode ?? this.themeMode,
      isStreamEnabled: isStreamEnabled ?? this.isStreamEnabled,
      isSearchEnabled: isSearchEnabled ?? this.isSearchEnabled,
      isKnowledgeEnabled: isKnowledgeEnabled ?? this.isKnowledgeEnabled,
      searchEngine: searchEngine ?? this.searchEngine,
      searchRegion: searchRegion ?? this.searchRegion,
      searchSafeSearch: searchSafeSearch ?? this.searchSafeSearch,
      searchMaxResults: searchMaxResults != null
          ? _clampInt(searchMaxResults, 1, 50)
          : this.searchMaxResults,
      searchTimeoutSeconds: searchTimeoutSeconds != null
          ? _clampInt(searchTimeoutSeconds, 5, 60)
          : this.searchTimeoutSeconds,
      knowledgeTopK: knowledgeTopK != null
          ? _clampInt(knowledgeTopK, 1, 12)
          : this.knowledgeTopK,
      knowledgeUseEmbedding:
          knowledgeUseEmbedding ?? this.knowledgeUseEmbedding,
      knowledgeLlmEnhanceMode:
          knowledgeLlmEnhanceMode ?? this.knowledgeLlmEnhanceMode,
      knowledgeEmbeddingModel: knowledgeEmbeddingModel == _settingsSentinel
          ? this.knowledgeEmbeddingModel
          : knowledgeEmbeddingModel as String?,
      knowledgeEmbeddingProviderId:
          knowledgeEmbeddingProviderId == _settingsSentinel
              ? this.knowledgeEmbeddingProviderId
              : knowledgeEmbeddingProviderId as String?,
      activeKnowledgeBaseIds:
          activeKnowledgeBaseIds ?? this.activeKnowledgeBaseIds,
      enableSmartTopic: enableSmartTopic ?? this.enableSmartTopic,
      topicGenerationModel: topicGenerationModel ?? this.topicGenerationModel,
      restoreLastSessionOnLaunch:
          restoreLastSessionOnLaunch ?? this.restoreLastSessionOnLaunch,
      keepChatScrollPositionOnResponse: keepChatScrollPositionOnResponse ??
          this.keepChatScrollPositionOnResponse,
      language: language ?? this.language,
      presets: presets ?? this.presets,
      lastPresetId: lastPresetId == _settingsSentinel
          ? this.lastPresetId
          : lastPresetId as String?,
      themeColor: themeColor ?? this.themeColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      closeBehavior: closeBehavior ?? this.closeBehavior,
      executionModel: executionModel == _settingsSentinel
          ? this.executionModel
          : executionModel as String?,
      executionProviderId: executionProviderId == _settingsSentinel
          ? this.executionProviderId
          : executionProviderId as String?,
      imageModel: imageModel == _settingsSentinel
          ? this.imageModel
          : imageModel as String?,
      imageProviderId: imageProviderId == _settingsSentinel
          ? this.imageProviderId
          : imageProviderId as String?,
      speechModel: speechModel == _settingsSentinel
          ? this.speechModel
          : speechModel as String?,
      speechProviderId: speechProviderId == _settingsSentinel
          ? this.speechProviderId
          : speechProviderId as String?,
      transcriptionModel: transcriptionModel == _settingsSentinel
          ? this.transcriptionModel
          : transcriptionModel as String?,
      transcriptionProviderId: transcriptionProviderId == _settingsSentinel
          ? this.transcriptionProviderId
          : transcriptionProviderId as String?,
      translationModel: translationModel == _settingsSentinel
          ? this.translationModel
          : translationModel as String?,
      translationProviderId: translationProviderId == _settingsSentinel
          ? this.translationProviderId
          : translationProviderId as String?,
      llmRequestTimeoutSeconds: llmRequestTimeoutSeconds != null
          ? _clampInt(
              llmRequestTimeoutSeconds,
              minLlmRequestTimeoutSeconds,
              maxLlmRequestTimeoutSeconds,
            )
          : this.llmRequestTimeoutSeconds,
      memoryMinNewUserMessages: memoryMinNewUserMessages != null
          ? _clampInt(memoryMinNewUserMessages, 1, 200)
          : this.memoryMinNewUserMessages,
      memoryIdleSeconds: memoryIdleSeconds != null
          ? _clampInt(memoryIdleSeconds, 30, 7200)
          : this.memoryIdleSeconds,
      memoryMaxBufferedMessages: memoryMaxBufferedMessages != null
          ? _clampInt(memoryMaxBufferedMessages, 20, 500)
          : this.memoryMaxBufferedMessages,
      memoryMaxRunsPerDay: memoryMaxRunsPerDay != null
          ? _clampInt(memoryMaxRunsPerDay, 1, 30)
          : this.memoryMaxRunsPerDay,
      memoryContextWindowSize: memoryContextWindowSize != null
          ? _clampInt(memoryContextWindowSize, 20, 240)
          : this.memoryContextWindowSize,
      fontSize: fontSize ?? this.fontSize,
      backgroundImagePath: backgroundImagePath == _settingsSentinel
          ? this.backgroundImagePath
          : backgroundImagePath as String?,
      backgroundBrightness: backgroundBrightness ?? this.backgroundBrightness,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      useCustomTheme: useCustomTheme ?? this.useCustomTheme,
    );
  }
}

const Object _settingsSentinel = Object();

ProviderConfigEntity _buildProviderEntity(ProviderConfig source) {
  return ProviderConfigEntity()
    ..providerId = source.id
    ..name = source.name
    ..color = source.color
    ..apiKeys = source.apiKeys
    ..currentKeyIndex = source.currentKeyIndex
    ..autoRotateKeys = source.autoRotateKeys
    ..baseUrl = source.baseUrl
    ..providerProtocol = source.providerProtocol.wireName
    ..isCustom = source.isCustom
    ..customParametersJson = jsonEncode(source.customParameters)
    ..modelSettingsJson = jsonEncode(source.modelSettings)
    ..globalSettingsJson = jsonEncode(source.globalSettings)
    ..capabilityRoutesJson = null
    ..modelCapabilityOverridesJson = null
    ..globalExcludeModels = source.globalExcludeModels
    ..savedModels = source.models
    ..lastSelectedModel = null
    ..selectedChatModel = source.selectedChatModel
    ..isEnabled = source.isEnabled;
}

int _clampInt(int value, int min, int max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

String _normalizeProviderId({
  required List<ProviderConfig> providers,
  required String? desiredId,
}) {
  final normalized = desiredId?.trim() ?? '';
  if (normalized.isNotEmpty && providers.any((p) => p.id == normalized)) {
    return normalized;
  }

  if (providers.any((p) => p.id == 'custom')) {
    return 'custom';
  }

  if (providers.isNotEmpty) {
    return providers.first.id;
  }

  return 'custom';
}

String _normalizeSearchEngine(String engine) {
  final normalized = engine.trim().toLowerCase();
  return normalized.isEmpty ? 'duckduckgo' : normalized;
}

String _normalizeSearchRegion(String region) {
  final normalized = region.trim().toLowerCase();
  return normalized.isEmpty ? 'us-en' : normalized;
}

String _normalizeSafeSearch(String safeSearch) {
  final normalized = safeSearch.trim().toLowerCase();
  switch (normalized) {
    case 'off':
    case 'moderate':
    case 'on':
      return normalized;
    default:
      return 'moderate';
  }
}

class ThemeBackgroundStateResolution {
  final String themeMode;
  final bool useCustomTheme;
  final String? backgroundImagePath;

  const ThemeBackgroundStateResolution({
    required this.themeMode,
    required this.useCustomTheme,
    required this.backgroundImagePath,
  });

  bool differsFrom({
    required String themeMode,
    required bool useCustomTheme,
    required String? backgroundImagePath,
  }) {
    return this.themeMode != themeMode ||
        this.useCustomTheme != useCustomTheme ||
        this.backgroundImagePath != backgroundImagePath;
  }
}

ThemeBackgroundStateResolution resolveThemeBackgroundState({
  required String themeMode,
  required bool useCustomTheme,
  required String? backgroundImagePath,
}) {
  final trimmedPath = backgroundImagePath?.trim();
  String? normalizedPath;
  if (trimmedPath != null && trimmedPath.isNotEmpty) {
    try {
      if (File(trimmedPath).existsSync()) {
        normalizedPath = trimmedPath;
      }
    } catch (_) {
      normalizedPath = null;
    }
  }

  var normalizedThemeMode = themeMode;
  var normalizedUseCustomTheme = useCustomTheme;

  if (normalizedPath == null &&
      (normalizedUseCustomTheme || normalizedThemeMode == 'custom')) {
    normalizedUseCustomTheme = false;
    if (normalizedThemeMode == 'custom') {
      normalizedThemeMode = 'system';
    }
  }

  return ThemeBackgroundStateResolution(
    themeMode: normalizedThemeMode,
    useCustomTheme: normalizedUseCustomTheme,
    backgroundImagePath: normalizedPath,
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsStorage _storage;

  void _debugLifecycleLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }

  SettingsStorage get storage => _storage;
  SettingsNotifier({
    required SettingsStorage storage,
    required List<ProviderConfig> initialProviders,
    required String initialActiveId,
    String userName = 'User',
    String? userAvatar,
    String llmName = 'Assistant',
    String? llmAvatar,
    String themeMode = 'system',
    bool isStreamEnabled = true,
    bool isSearchEnabled = false,
    bool isKnowledgeEnabled = false,
    String searchEngine = 'duckduckgo',
    String searchRegion = 'us-en',
    String searchSafeSearch = 'moderate',
    int searchMaxResults = 5,
    int searchTimeoutSeconds = 15,
    int knowledgeTopK = 5,
    bool knowledgeUseEmbedding = false,
    String knowledgeLlmEnhanceMode = 'off',
    String? knowledgeEmbeddingModel,
    String? knowledgeEmbeddingProviderId,
    List<String> activeKnowledgeBaseIds = const [],
    bool enableSmartTopic = true,
    String? topicGenerationModel,
    bool restoreLastSessionOnLaunch = true,
    bool keepChatScrollPositionOnResponse = true,
    String language = 'zh',
    String themeColor = 'teal',
    String backgroundColor = 'default',
    int closeBehavior = 0,
    String? executionModel,
    String? executionProviderId,
    String? imageModel,
    String? imageProviderId,
    String? speechModel,
    String? speechProviderId,
    String? transcriptionModel,
    String? transcriptionProviderId,
    String? translationModel,
    String? translationProviderId,
    int llmRequestTimeoutSeconds = defaultLlmRequestTimeoutSeconds,
    int memoryMinNewUserMessages = 20,
    int memoryIdleSeconds = 600,
    int memoryMaxBufferedMessages = 120,
    int memoryMaxRunsPerDay = 2,
    int memoryContextWindowSize = 80,
    double fontSize = 14.0,
    String? backgroundImagePath,
    double backgroundBrightness = 0.5,
    double backgroundBlur = 0.0,
    bool useCustomTheme = false,
  })  : _storage = storage,
        super(SettingsState(
          providers: initialProviders,
          activeProviderId: _normalizeProviderId(
            providers: initialProviders,
            desiredId: initialActiveId,
          ),
          viewingProviderId: _normalizeProviderId(
            providers: initialProviders,
            desiredId: initialActiveId,
          ),
          userName: userName,
          userAvatar: userAvatar,
          llmName: llmName,
          llmAvatar: llmAvatar,
          themeMode: themeMode,
          isStreamEnabled: isStreamEnabled,
          isSearchEnabled: isSearchEnabled,
          isKnowledgeEnabled: isKnowledgeEnabled,
          searchEngine: _normalizeSearchEngine(searchEngine),
          searchRegion: _normalizeSearchRegion(searchRegion),
          searchSafeSearch: _normalizeSafeSearch(searchSafeSearch),
          searchMaxResults: _clampInt(searchMaxResults, 1, 50),
          searchTimeoutSeconds: _clampInt(searchTimeoutSeconds, 5, 60),
          knowledgeTopK: _clampInt(knowledgeTopK, 1, 12),
          knowledgeUseEmbedding: knowledgeUseEmbedding,
          knowledgeLlmEnhanceMode: knowledgeLlmEnhanceMode,
          knowledgeEmbeddingModel: knowledgeEmbeddingModel,
          knowledgeEmbeddingProviderId: knowledgeEmbeddingProviderId,
          activeKnowledgeBaseIds: activeKnowledgeBaseIds,
          enableSmartTopic: enableSmartTopic,
          topicGenerationModel: topicGenerationModel,
          restoreLastSessionOnLaunch: restoreLastSessionOnLaunch,
          keepChatScrollPositionOnResponse: keepChatScrollPositionOnResponse,
          language: language,
          presets: [],
          themeColor: themeColor,
          backgroundColor: backgroundColor,
          closeBehavior: closeBehavior,
          executionModel: executionModel,
          executionProviderId: executionProviderId,
          imageModel: imageModel,
          imageProviderId: imageProviderId,
          speechModel: speechModel,
          speechProviderId: speechProviderId,
          transcriptionModel: transcriptionModel,
          transcriptionProviderId: transcriptionProviderId,
          translationModel: translationModel,
          translationProviderId: translationProviderId,
          llmRequestTimeoutSeconds: _clampInt(
            llmRequestTimeoutSeconds,
            minLlmRequestTimeoutSeconds,
            maxLlmRequestTimeoutSeconds,
          ),
          memoryMinNewUserMessages: _clampInt(memoryMinNewUserMessages, 1, 200),
          memoryIdleSeconds: _clampInt(memoryIdleSeconds, 30, 7200),
          memoryMaxBufferedMessages:
              _clampInt(memoryMaxBufferedMessages, 20, 500),
          memoryMaxRunsPerDay: _clampInt(memoryMaxRunsPerDay, 1, 30),
          memoryContextWindowSize: _clampInt(memoryContextWindowSize, 20, 240),
          fontSize: fontSize,
          backgroundImagePath: backgroundImagePath,
          backgroundBrightness: backgroundBrightness,
          backgroundBlur: backgroundBlur,
          useCustomTheme: useCustomTheme,
        )) {
    _debugLifecycleLog(
        'SettingsNotifier initialized with backgroundImagePath: $backgroundImagePath');
    loadPresets();
  }

  Future<void> refreshSettings() async {
    final providerEntities = await _storage.loadProviders();
    final appSettings = await _storage.loadAppSettings();

    final loadedProviders = providerEntities.isEmpty
        ? const <_ProviderEntityLoadResult>[]
        : providerEntities.map(ProviderConfig._loadFromEntity).toList();
    final newProviders = loadedProviders.isEmpty
        ? ProviderConfig.defaultProviders()
        : loadedProviders.map((entry) => entry.config).toList();

    final rawActiveProviderId = appSettings?.activeProviderId ?? '';
    final normalizedActiveProviderId = _normalizeProviderId(
      providers: newProviders,
      desiredId: rawActiveProviderId,
    );
    final rawThemeMode = appSettings?.themeMode ?? 'system';
    final rawUseCustomTheme = appSettings?.useCustomTheme ?? false;
    final rawBackgroundImagePath = appSettings?.backgroundImagePath;
    final resolvedThemeState = resolveThemeBackgroundState(
      themeMode: rawThemeMode,
      useCustomTheme: rawUseCustomTheme,
      backgroundImagePath: rawBackgroundImagePath,
    );

    state = state.copyWith(
      providers: newProviders,
      activeProviderId: normalizedActiveProviderId,
      viewingProviderId: normalizedActiveProviderId,
      userName: appSettings?.userName ?? 'User',
      userAvatar: appSettings?.userAvatar,
      llmName: appSettings?.llmName ?? 'Assistant',
      llmAvatar: appSettings?.llmAvatar,
      themeMode: resolvedThemeState.themeMode,
      isStreamEnabled: appSettings?.isStreamEnabled ?? true,
      isSearchEnabled: appSettings?.isSearchEnabled ?? false,
      isKnowledgeEnabled: appSettings?.isKnowledgeEnabled ?? false,
      searchEngine:
          _normalizeSearchEngine(appSettings?.searchEngine ?? 'duckduckgo'),
      searchRegion:
          _normalizeSearchRegion(appSettings?.searchRegion ?? 'us-en'),
      searchSafeSearch:
          _normalizeSafeSearch(appSettings?.searchSafeSearch ?? 'moderate'),
      searchMaxResults: _clampInt(appSettings?.searchMaxResults ?? 5, 1, 50),
      searchTimeoutSeconds:
          _clampInt(appSettings?.searchTimeoutSeconds ?? 15, 5, 60),
      knowledgeTopK: _clampInt(appSettings?.knowledgeTopK ?? 5, 1, 12),
      knowledgeUseEmbedding: appSettings?.knowledgeUseEmbedding ?? false,
      knowledgeLlmEnhanceMode: appSettings?.knowledgeLlmEnhanceMode ?? 'off',
      knowledgeEmbeddingModel: appSettings?.knowledgeEmbeddingModel,
      knowledgeEmbeddingProviderId: appSettings?.knowledgeEmbeddingProviderId,
      activeKnowledgeBaseIds: appSettings?.activeKnowledgeBaseIds ?? const [],
      enableSmartTopic: appSettings?.enableSmartTopic ?? true,
      topicGenerationModel: appSettings?.topicGenerationModel,
      restoreLastSessionOnLaunch:
          appSettings?.restoreLastSessionOnLaunch ?? true,
      keepChatScrollPositionOnResponse:
          appSettings?.keepChatScrollPositionOnResponse ?? true,
      language: appSettings?.language ?? 'zh',
      themeColor: appSettings?.themeColor ?? 'teal',
      backgroundColor: appSettings?.backgroundColor ?? 'default',
      closeBehavior: appSettings?.closeBehavior ?? 0,
      executionModel: appSettings?.executionModel,
      executionProviderId: appSettings?.executionProviderId,
      imageModel: appSettings?.imageModel,
      imageProviderId: appSettings?.imageProviderId,
      speechModel: appSettings?.speechModel,
      speechProviderId: appSettings?.speechProviderId,
      transcriptionModel: appSettings?.transcriptionModel,
      transcriptionProviderId: appSettings?.transcriptionProviderId,
      translationModel: appSettings?.translationModel,
      translationProviderId: appSettings?.translationProviderId,
      llmRequestTimeoutSeconds: _clampInt(
        appSettings?.llmRequestTimeoutSeconds ??
            defaultLlmRequestTimeoutSeconds,
        minLlmRequestTimeoutSeconds,
        maxLlmRequestTimeoutSeconds,
      ),
      memoryMinNewUserMessages:
          _clampInt(appSettings?.memoryMinNewUserMessages ?? 20, 1, 200),
      memoryIdleSeconds:
          _clampInt(appSettings?.memoryIdleSeconds ?? 600, 30, 7200),
      memoryMaxBufferedMessages:
          _clampInt(appSettings?.memoryMaxBufferedMessages ?? 120, 20, 500),
      memoryMaxRunsPerDay:
          _clampInt(appSettings?.memoryMaxRunsPerDay ?? 2, 1, 30),
      memoryContextWindowSize:
          _clampInt(appSettings?.memoryContextWindowSize ?? 80, 20, 240),
      fontSize: appSettings?.fontSize ?? 14.0,
      backgroundImagePath: resolvedThemeState.backgroundImagePath,
      backgroundBrightness: appSettings?.backgroundBrightness ?? 0.5,
      backgroundBlur: appSettings?.backgroundBlur ?? 0.0,
      useCustomTheme: resolvedThemeState.useCustomTheme,
    );

    if (appSettings != null &&
        rawActiveProviderId != normalizedActiveProviderId) {
      final fixedProvider = state.activeProvider;
      await _storage.saveAppSettings(
        activeProviderId: fixedProvider.id,
        availableModels: fixedProvider.models,
      );
      debugPrint(
        'Normalized invalid active provider id from "$rawActiveProviderId" to "${fixedProvider.id}".',
      );
    }

    if (appSettings != null &&
        resolvedThemeState.differsFrom(
          themeMode: rawThemeMode,
          useCustomTheme: rawUseCustomTheme,
          backgroundImagePath: rawBackgroundImagePath,
        )) {
      await _storage.saveAppSettings(
        activeProviderId: state.activeProvider.id,
        themeMode: resolvedThemeState.themeMode,
        useCustomTheme: resolvedThemeState.useCustomTheme,
        backgroundImagePath: resolvedThemeState.backgroundImagePath,
        clearBackgroundImage: resolvedThemeState.backgroundImagePath == null,
      );
      debugPrint(
          'Normalized invalid custom background settings during refresh.');
    }
    debugPrint(
        'Settings reloaded with backgroundImagePath: ${resolvedThemeState.backgroundImagePath}');
    debugPrint(
        'DEBUG: refreshSettings loaded - executionModel: ${appSettings?.executionModel}, executionProviderId: ${appSettings?.executionProviderId}');

    final providersNeedingWriteBack = loadedProviders
        .where((entry) => entry.needsWriteBack)
        .map((entry) => entry.config)
        .toList(growable: false);
    for (final provider in providersNeedingWriteBack) {
      await _storage.saveProvider(_buildProviderEntity(provider));
    }

    await loadPresets();
  }

  void viewProvider(String id) {
    if (state.viewingProviderId != id) {
      state = state.copyWith(viewingProviderId: id, error: null);
    }
  }

  Future<void> selectProvider(String id) async {
    if (state.activeProviderId != id) {
      var provider = state.providers.firstWhere((p) => p.id == id);
      if (provider.selectedModel == null && provider.models.isNotEmpty) {
        final defaultModel = provider.models.first;
        final newProviders = state.providers.map((p) {
          if (p.id == id) {
            return p.copyWith(selectedChatModel: defaultModel);
          }
          return p;
        }).toList();
        state = state.copyWith(providers: newProviders);
        await updateProvider(id: id, selectedChatModel: defaultModel);
        provider = state.providers.firstWhere((p) => p.id == id);
      }
      state = state.copyWith(
        activeProviderId: id,
        error: null,
      );
      await _storage.saveAppSettings(
        activeProviderId: id,
        availableModels: provider.models,
      );
    }
  }

  Future<void> updateProvider({
    required String id,
    String? name,
    String? color,
    List<String>? apiKeys,
    int? currentKeyIndex,
    bool? autoRotateKeys,
    String? baseUrl,
    ProviderProtocol? providerProtocol,
    Map<String, dynamic>? customParameters,
    Map<String, Map<String, dynamic>>? modelSettings,
    Map<String, dynamic>? globalSettings,
    ProviderCapabilityConfig? capabilityConfig,
    Map<String, ModelCapabilityOverride>? modelCapabilityOverrides,
    List<String>? globalExcludeModels,
    List<String>? models,
    Object? selectedChatModel = _settingsSentinel,
    bool? isEnabled,
  }) async {
    final newProviders = state.providers.map((p) {
      if (p.id == id) {
        return p.copyWith(
          name: name,
          color: color,
          apiKeys: apiKeys,
          currentKeyIndex: currentKeyIndex,
          autoRotateKeys: autoRotateKeys,
          baseUrl: baseUrl,
          providerProtocol: providerProtocol,
          customParameters: customParameters,
          modelSettings: modelSettings,
          globalSettings: globalSettings,
          capabilityConfig: capabilityConfig,
          modelCapabilityOverrides: modelCapabilityOverrides,
          globalExcludeModels: globalExcludeModels,
          models: models,
          selectedChatModel: selectedChatModel,
          isEnabled: isEnabled,
        );
      }
      return p;
    }).toList();
    state = state.copyWith(providers: newProviders);
    final updatedProvider = newProviders.firstWhere((p) => p.id == id);
    await _storage.saveProvider(_buildProviderEntity(updatedProvider));
  }

  Future<void> commitProviderBaseUrl({
    required String id,
    required String baseUrl,
  }) async {
    final normalizedBaseUrl = baseUrl.trim();
    final inferredProtocol =
        ProviderConfig._inferProviderProtocolFromBaseUrl(normalizedBaseUrl);
    await updateProvider(
      id: id,
      baseUrl: normalizedBaseUrl,
      providerProtocol: inferredProtocol,
    );
  }

  Future<void> setSelectedModel(String model) async {
    await updateProvider(id: state.activeProvider.id, selectedChatModel: model);
    final provider = state.activeProvider;
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      availableModels: provider.models,
    );
  }

  Future<void> addProvider() async {
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final newProvider = ProviderConfig(
      id: newId,
      name: 'New Provider',
      isCustom: true,
      models: [],
    );
    state = state.copyWith(
      providers: [...state.providers, newProvider],
      viewingProviderId: newId,
    );
    await updateProvider(id: newId, name: 'New Provider');
  }

  Future<void> toggleProviderEnabled(String id) async {
    final provider = state.providers.firstWhere((p) => p.id == id);
    await updateProvider(id: id, isEnabled: !provider.isEnabled);
  }

  Future<void> deleteProvider(String id) async {
    final providerToDelete = state.providers
        .firstWhere((p) => p.id == id, orElse: () => state.providers.first);
    if (!providerToDelete.isCustom && id == 'root_openai_cannot_delete') {
      return;
    }
    final newProviders = state.providers.where((p) => p.id != id).toList();
    if (newProviders.isEmpty) {
      return;
    }
    String newActiveId = state.activeProviderId;
    if (state.activeProviderId == id) {
      newActiveId = newProviders.first.id;
    }
    String newViewingId = state.viewingProviderId;
    if (state.viewingProviderId == id) {
      newViewingId = newActiveId;
    }
    state = state.copyWith(
      providers: newProviders,
      activeProviderId: newActiveId,
      viewingProviderId: newViewingId,
    );
    await _storage.deleteProvider(id);
    if (newActiveId != id) {
      await selectProvider(newActiveId);
    }
  }

  Future<void> reorderProviders(int oldIndex, int newIndex) async {
    if (state.providers.length <= 1) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<ProviderConfig>.from(state.providers);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    state = state.copyWith(providers: items);

    final orderIds = items.map((p) => p.id).toList();
    await _storage.saveProviderOrder(orderIds);
  }

  Future<void> toggleModelDisabled(String providerId, String modelId) async {
    final provider = state.providers.firstWhere((p) => p.id == providerId);
    final currentSettings = provider.modelSettings[modelId] ?? {};
    final isDisabled = currentSettings['_aurora_model_disabled'] == true;

    final newSettings = Map<String, dynamic>.from(currentSettings);
    newSettings['_aurora_model_disabled'] = !isDisabled;

    final newModelSettings =
        Map<String, Map<String, dynamic>>.from(provider.modelSettings);
    newModelSettings[modelId] = newSettings;

    await updateProvider(id: providerId, modelSettings: newModelSettings);
  }

  Future<void> setAllModelsEnabled(String providerId, bool enabled) async {
    final provider = state.providers.firstWhere((p) => p.id == providerId);
    final newModelSettings =
        Map<String, Map<String, dynamic>>.from(provider.modelSettings);

    for (final modelId in provider.models) {
      final currentSettings = newModelSettings[modelId] ?? {};
      final newSettings = Map<String, dynamic>.from(currentSettings);
      newSettings['_aurora_model_disabled'] = !enabled;
      newModelSettings[modelId] = newSettings;
    }

    await updateProvider(id: providerId, modelSettings: newModelSettings);
  }

  // ==================== API Key Management Methods ====================

  /// Add a new API key to a provider
  Future<void> addApiKey(String providerId, String key) async {
    if (key.trim().isEmpty) return;
    final provider = state.providers.firstWhere((p) => p.id == providerId);
    final newKeys = [...provider.apiKeys, key.trim()];
    await updateProvider(id: providerId, apiKeys: newKeys);
  }

  /// Remove an API key at the specified index
  Future<void> removeApiKey(String providerId, int index) async {
    final provider = state.providers.firstWhere((p) => p.id == providerId);
    if (index < 0 || index >= provider.apiKeys.length) return;
    final newKeys = List<String>.from(provider.apiKeys)..removeAt(index);
    int newIndex = provider.currentKeyIndex;
    if (newIndex >= newKeys.length) {
      newIndex = newKeys.isEmpty ? 0 : newKeys.length - 1;
    }
    await updateProvider(
        id: providerId, apiKeys: newKeys, currentKeyIndex: newIndex);
  }

  /// Update an API key at the specified index
  Future<void> updateApiKeyAtIndex(
      String providerId, int index, String key) async {
    final provider = state.providers.firstWhere((p) => p.id == providerId);
    if (index < 0 || index >= provider.apiKeys.length) return;
    final newKeys = List<String>.from(provider.apiKeys);
    newKeys[index] = key;
    await updateProvider(id: providerId, apiKeys: newKeys);
  }

  /// Set the current active key index
  Future<void> setCurrentKeyIndex(String providerId, int index) async {
    final provider = state.providers.firstWhere((p) => p.id == providerId);
    if (index < 0 || index >= provider.apiKeys.length) return;
    await updateProvider(id: providerId, currentKeyIndex: index);
  }

  /// Rotate to the next API key
  Future<void> rotateApiKey(String providerId) async {
    final provider = state.providers.firstWhere((p) => p.id == providerId);
    if (provider.apiKeys.length <= 1) return;
    final nextIndex = (provider.currentKeyIndex + 1) % provider.apiKeys.length;
    await updateProvider(id: providerId, currentKeyIndex: nextIndex);
  }

  /// Set auto-rotate keys option
  Future<void> setAutoRotateKeys(String providerId, bool enabled) async {
    await updateProvider(id: providerId, autoRotateKeys: enabled);
  }

  Map<String, dynamic> getModelSettings(String providerId, String modelName) {
    try {
      final provider = state.providers.firstWhere((p) => p.id == providerId);
      return provider.modelSettings[modelName] ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> updateModelSettings({
    required String providerId,
    required String modelName,
    required Map<String, dynamic> settings,
  }) async {
    final provider = state.providers.firstWhere((p) => p.id == providerId);
    final newModelSettings =
        Map<String, Map<String, dynamic>>.from(provider.modelSettings);
    if (settings.isEmpty) {
      newModelSettings.remove(modelName);
    } else {
      newModelSettings[modelName] = settings;
    }

    await updateProvider(id: providerId, modelSettings: newModelSettings);
  }

  Future<bool> fetchModels() async {
    final provider = state.viewingProvider;
    final isActiveProvider = provider.id == state.activeProviderId;
    final resolver = const CapabilityRouteResolver();
    final gateway = ProviderCapabilityGateway();
    final primaryRoute = resolver.resolve(
      provider: provider,
      capability: ProviderCapability.models,
    );
    AppLogger.info(
      'SETTINGS',
      'Model fetch started',
      category: 'MODEL_FETCH',
      data: {
        'provider_id': provider.id,
        'provider_name': provider.name,
        'base_url': provider.baseUrl,
      },
    );
    if (provider.apiKey.isEmpty) {
      AppLogger.warn(
        'SETTINGS',
        'Model fetch skipped because API key is empty',
        category: 'MODEL_FETCH',
        data: {
          'provider_id': provider.id,
          'provider_name': provider.name,
        },
      );
      state = state.copyWith(error: 'Please enter API Key');
      return false;
    }
    state = state.copyWith(isLoadingModels: true, error: null);
    try {
      List<String> models;
      var fetchMode = primaryRoute.preset.wireName;
      try {
        models = await gateway.fetchModels(
          provider: provider,
          route: primaryRoute,
        );
      } catch (primaryError) {
        final fallbackRoute = resolver.resolveFallback(
          provider: provider,
          capability: ProviderCapability.models,
          current: primaryRoute,
        );
        if (fallbackRoute == null) {
          rethrow;
        }
        AppLogger.warn(
          'SETTINGS',
          'Primary model fetch route failed, retrying configured fallback',
          category: 'MODEL_FETCH',
          data: {
            'provider_id': provider.id,
            'provider_name': provider.name,
            'primary_mode': primaryRoute.preset.wireName,
            'fallback_mode': fallbackRoute.preset.wireName,
            'error': primaryError.toString(),
          },
        );
        fetchMode = fallbackRoute.preset.wireName;
        models = await gateway.fetchModels(
          provider: provider,
          route: fallbackRoute,
        );
      }

      String? newSelectedModel = provider.selectedModel;
      if (newSelectedModel == null || !models.contains(newSelectedModel)) {
        newSelectedModel = models.isNotEmpty ? models.first : null;
      }
      await updateProvider(
        id: provider.id,
        models: models,
        selectedChatModel: newSelectedModel,
      );
      state = state.copyWith(isLoadingModels: false);
      if (isActiveProvider) {
        await _storage.saveAppSettings(
          activeProviderId: provider.id,
          availableModels: models,
        );
      }
      AppLogger.info(
        'SETTINGS',
        'Model fetch completed',
        category: 'MODEL_FETCH',
        data: {
          'provider_id': provider.id,
          'provider_name': provider.name,
          'model_count': models.length,
          'selected_model': newSelectedModel,
          'fetch_mode': fetchMode,
        },
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'SETTINGS',
        'Model fetch failed',
        category: 'MODEL_FETCH',
        data: {
          'provider_id': provider.id,
          'provider_name': provider.name,
          'error': e.toString(),
        },
      );
      state = state.copyWith(isLoadingModels: false, error: 'Error: $e');
      return false;
    }
  }

  Future<void> setChatDisplaySettings({
    String? userName,
    String? userAvatar,
    String? llmName,
    String? llmAvatar,
  }) async {
    state = state.copyWith(
      userName: userName,
      userAvatar: userAvatar,
      llmName: llmName,
      llmAvatar: llmAvatar,
    );
    await _storage.saveChatDisplaySettings(
      userName: userName ?? state.userName,
      userAvatar: userAvatar,
      llmName: llmName ?? state.llmName,
      llmAvatar: llmAvatar,
    );
  }

  Future<void> setThemeMode(String mode) async {
    final resolvedThemeState = resolveThemeBackgroundState(
      themeMode: mode,
      useCustomTheme: mode == 'custom',
      backgroundImagePath: state.backgroundImagePath,
    );
    state = state.copyWith(
      themeMode: resolvedThemeState.themeMode,
      useCustomTheme: resolvedThemeState.useCustomTheme,
      backgroundImagePath: resolvedThemeState.backgroundImagePath,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      themeMode: resolvedThemeState.themeMode,
      useCustomTheme: resolvedThemeState.useCustomTheme,
      backgroundImagePath: resolvedThemeState.backgroundImagePath,
      clearBackgroundImage: resolvedThemeState.backgroundImagePath == null,
    );
  }

  Future<void> toggleThemeMode() async {
    final current = state.useCustomTheme || state.themeMode == 'custom'
        ? 'custom'
        : state.themeMode;
    final next = switch (current) {
      'light' => 'dark',
      'dark' => 'custom',
      'custom' => 'light',
      _ => 'light',
    };
    await setThemeMode(next);
  }

  Future<void> toggleStreamEnabled() async {
    final newValue = !state.isStreamEnabled;
    state = state.copyWith(isStreamEnabled: newValue);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      isStreamEnabled: newValue,
    );
  }

  Future<void> setSearchEnabled(bool enabled) async {
    if (state.isSearchEnabled == enabled) return;
    state = state.copyWith(isSearchEnabled: enabled);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      isSearchEnabled: enabled,
    );
  }

  Future<void> toggleSearchEnabled() async {
    await setSearchEnabled(!state.isSearchEnabled);
  }

  Future<void> setKnowledgeEnabled(bool enabled) async {
    if (state.isKnowledgeEnabled == enabled) return;
    state = state.copyWith(isKnowledgeEnabled: enabled);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      isKnowledgeEnabled: enabled,
    );
  }

  Future<void> setKnowledgeTopK(int topK) async {
    final clamped = topK.clamp(1, 12);
    state = state.copyWith(knowledgeTopK: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      knowledgeTopK: clamped,
    );
  }

  Future<void> setKnowledgeUseEmbedding(bool enabled) async {
    state = state.copyWith(knowledgeUseEmbedding: enabled);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      knowledgeUseEmbedding: enabled,
    );
  }

  Future<void> setKnowledgeLlmEnhanceMode(String mode) async {
    final normalized = mode.trim().toLowerCase();
    final allowed = {'off', 'rewrite'};
    final selected = allowed.contains(normalized) ? normalized : 'off';
    state = state.copyWith(knowledgeLlmEnhanceMode: selected);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      knowledgeLlmEnhanceMode: selected,
    );
  }

  Future<void> setKnowledgeEmbeddingModel(String? model) async {
    final normalized = (model ?? '').trim();
    final next = normalized.isEmpty ? null : normalized;
    state = state.copyWith(knowledgeEmbeddingModel: next);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      knowledgeEmbeddingModel: next,
    );
  }

  Future<void> setKnowledgeEmbeddingProviderId(String? providerId) async {
    final normalized = (providerId ?? '').trim();
    final next = normalized.isEmpty ? null : normalized;
    state = state.copyWith(knowledgeEmbeddingProviderId: next);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      knowledgeEmbeddingProviderId: next,
    );
  }

  Future<void> setActiveKnowledgeBaseIds(List<String> baseIds) async {
    final deduped = baseIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    state = state.copyWith(activeKnowledgeBaseIds: deduped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      activeKnowledgeBaseIds: deduped,
    );
  }

  Future<void> setSearchEngine(String engine) async {
    state = state.copyWith(searchEngine: engine);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      searchEngine: engine,
    );
  }

  Future<void> setSearchRegion(String region) async {
    final normalized = region.trim().toLowerCase();
    if (normalized.isEmpty) return;
    state = state.copyWith(searchRegion: normalized);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      searchRegion: normalized,
    );
  }

  Future<void> setSearchSafeSearch(String safeSearch) async {
    final normalized = safeSearch.trim().toLowerCase();
    if (normalized.isEmpty) return;
    state = state.copyWith(searchSafeSearch: normalized);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      searchSafeSearch: normalized,
    );
  }

  Future<void> setSearchMaxResults(int maxResults) async {
    final clamped = maxResults.clamp(1, 50);
    state = state.copyWith(searchMaxResults: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      searchMaxResults: clamped,
    );
  }

  Future<void> setSearchTimeoutSeconds(int seconds) async {
    final clamped = seconds.clamp(5, 60);
    state = state.copyWith(searchTimeoutSeconds: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      searchTimeoutSeconds: clamped,
    );
  }

  Future<void> toggleSmartTopicEnabled(bool enabled) async {
    state = state.copyWith(enableSmartTopic: enabled);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      enableSmartTopic: enabled,
    );
  }

  Future<void> toggleRestoreLastSessionOnLaunch(bool enabled) async {
    state = state.copyWith(restoreLastSessionOnLaunch: enabled);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      restoreLastSessionOnLaunch: enabled,
    );
  }

  Future<void> toggleKeepChatScrollPositionOnResponse(bool enabled) async {
    state = state.copyWith(keepChatScrollPositionOnResponse: enabled);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      keepChatScrollPositionOnResponse: enabled,
    );
  }

  Future<void> setTopicGenerationModel(String? model) async {
    String? normalized = model;
    if (normalized != null) {
      final parts = normalized.split('@');
      if (parts.length != 2) {
        normalized = null;
      } else {
        final provider = state.providers.where((p) => p.id == parts[0]);
        if (provider.isEmpty ||
            !provider.first.isEnabled ||
            !provider.first.models.contains(parts[1]) ||
            !provider.first.isModelEnabled(parts[1])) {
          normalized = null;
        }
      }
    }

    state = state.copyWith(topicGenerationModel: normalized);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      topicGenerationModel: normalized,
    );
  }

  Future<void> setMemoryMinNewUserMessages(int value) async {
    final clamped = _clampInt(value, 1, 200);
    state = state.copyWith(memoryMinNewUserMessages: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      memoryMinNewUserMessages: clamped,
    );
  }

  Future<void> setMemoryIdleSeconds(int value) async {
    final clamped = _clampInt(value, 30, 7200);
    state = state.copyWith(memoryIdleSeconds: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      memoryIdleSeconds: clamped,
    );
  }

  Future<void> setMemoryMaxBufferedMessages(int value) async {
    final clamped = _clampInt(value, 20, 500);
    state = state.copyWith(memoryMaxBufferedMessages: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      memoryMaxBufferedMessages: clamped,
    );
  }

  Future<void> setMemoryMaxRunsPerDay(int value) async {
    final clamped = _clampInt(value, 1, 30);
    state = state.copyWith(memoryMaxRunsPerDay: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      memoryMaxRunsPerDay: clamped,
    );
  }

  Future<void> setMemoryContextWindowSize(int value) async {
    final clamped = _clampInt(value, 20, 240);
    state = state.copyWith(memoryContextWindowSize: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      memoryContextWindowSize: clamped,
    );
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      language: lang,
    );
  }

  Future<void> loadPresets() async {
    final entities = await _storage.loadChatPresets();
    final presets = entities
        .map((e) => ChatPreset(
              id: e.presetId,
              name: e.name,
              description: e.description ?? '',
              systemPrompt: e.systemPrompt,
            ))
        .toList();
    final appSettings = await _storage.loadAppSettings();
    final lastPresetId = appSettings?.lastPresetId;
    state = state.copyWith(presets: presets, lastPresetId: lastPresetId);
  }

  Future<void> addPreset(ChatPreset preset) async {
    final entity = ChatPresetEntity()
      ..presetId = preset.id
      ..name = preset.name
      ..description = preset.description
      ..systemPrompt = preset.systemPrompt;
    await _storage.saveChatPreset(entity);
    await loadPresets();
  }

  Future<void> setUseCustomTheme(bool value) async {
    final resolvedThemeState = resolveThemeBackgroundState(
      themeMode: value ? 'custom' : 'system',
      useCustomTheme: value,
      backgroundImagePath: state.backgroundImagePath,
    );
    state = state.copyWith(
      useCustomTheme: resolvedThemeState.useCustomTheme,
      themeMode: resolvedThemeState.themeMode,
      backgroundImagePath: resolvedThemeState.backgroundImagePath,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      useCustomTheme: resolvedThemeState.useCustomTheme,
      themeMode: resolvedThemeState.themeMode,
      backgroundImagePath: resolvedThemeState.backgroundImagePath,
      clearBackgroundImage: resolvedThemeState.backgroundImagePath == null,
    );
  }

  Future<void> updatePreset(ChatPreset preset) async {
    final entity = ChatPresetEntity()
      ..presetId = preset.id
      ..name = preset.name
      ..description = preset.description
      ..systemPrompt = preset.systemPrompt;
    await _storage.saveChatPreset(entity);
    await loadPresets();
  }

  Future<void> deletePreset(String id) async {
    await _storage.deleteChatPreset(id);
    await loadPresets();
  }

  Future<void> setLastPresetId(String? id) async {
    state = state.copyWith(lastPresetId: id);
    await _storage.saveLastPresetId(id);
  }

  Future<void> setThemeColor(String color) async {
    state = state.copyWith(themeColor: color);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      themeColor: color,
    );
  }

  Future<void> setBackgroundColor(String color) async {
    state = state.copyWith(backgroundColor: color);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      backgroundColor: color,
    );
  }

  Future<void> setBackgroundImagePath(String? path) async {
    debugPrint('Saving background image path: $path');

    String? finalPath;
    if (path != null && path.isNotEmpty) {
      try {
        final supportDir = await getApplicationSupportDirectory();
        final bgDir = Directory(p.join(supportDir.path, 'backgrounds'));
        if (!await bgDir.exists()) {
          await bgDir.create(recursive: true);
        }

        // Clean up any existing background files before saving the new one
        try {
          final files = bgDir.listSync();
          for (var file in files) {
            if (p.basename(file.path).startsWith('custom_background')) {
              await file.delete();
            }
          }
        } catch (e) {
          debugPrint('Error during background cleanup: $e');
        }

        final fileName =
            'custom_background_${DateTime.now().millisecondsSinceEpoch}${p.extension(path)}';
        final savedFile = File(p.join(bgDir.path, fileName));

        // Copy file to persistent storage
        await File(path).copy(savedFile.path);
        finalPath = savedFile.path;
        debugPrint('Background image persisted to: $finalPath');
      } catch (e) {
        debugPrint('Error persisting background image: $e');
        finalPath = path; // Fallback to original path if copy fails
      }
    } else {
      // If path is null, try to clean up the existing file
      try {
        final supportDir = await getApplicationSupportDirectory();
        final bgDir = Directory(p.join(supportDir.path, 'backgrounds'));
        if (await bgDir.exists()) {
          final files = bgDir.listSync();
          for (var file in files) {
            if (p.basename(file.path).startsWith('custom_background')) {
              await file.delete();
            }
          }
        }
      } catch (_) {}
    }

    final resolvedThemeState = resolveThemeBackgroundState(
      themeMode: finalPath == null ? state.themeMode : 'custom',
      useCustomTheme: finalPath == null ? state.useCustomTheme : true,
      backgroundImagePath: finalPath,
    );

    state = state.copyWith(
      backgroundImagePath: resolvedThemeState.backgroundImagePath,
      themeMode: resolvedThemeState.themeMode,
      useCustomTheme: resolvedThemeState.useCustomTheme,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      backgroundImagePath: resolvedThemeState.backgroundImagePath,
      clearBackgroundImage: resolvedThemeState.backgroundImagePath == null,
      themeMode: resolvedThemeState.themeMode,
      useCustomTheme: resolvedThemeState.useCustomTheme,
    );
  }

  Future<void> setBackgroundBrightness(double brightness) async {
    state = state.copyWith(backgroundBrightness: brightness);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      backgroundBrightness: brightness,
    );
  }

  Future<void> setBackgroundBlur(double blur) async {
    state = state.copyWith(backgroundBlur: blur);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      backgroundBlur: blur,
    );
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      fontSize: size,
    );
  }

  Future<void> setCloseBehavior(int behavior) async {
    state = state.copyWith(closeBehavior: behavior);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      closeBehavior: behavior,
    );
  }

  Future<void> setImageSettings({String? model, String? providerId}) async {
    state = state.copyWith(
      imageModel: model,
      imageProviderId: providerId,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      imageModel: model,
      imageProviderId: providerId,
    );
  }

  Future<void> setSpeechSettings({String? model, String? providerId}) async {
    state = state.copyWith(
      speechModel: model,
      speechProviderId: providerId,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      speechModel: model,
      speechProviderId: providerId,
    );
  }

  Future<void> setTranscriptionSettings({
    String? model,
    String? providerId,
  }) async {
    state = state.copyWith(
      transcriptionModel: model,
      transcriptionProviderId: providerId,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      transcriptionModel: model,
      transcriptionProviderId: providerId,
    );
  }

  Future<void> setTranslationSettings({
    String? model,
    String? providerId,
  }) async {
    state = state.copyWith(
      translationModel: model,
      translationProviderId: providerId,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      translationModel: model,
      translationProviderId: providerId,
    );
  }

  Future<void> setLlmRequestTimeoutSeconds(int seconds) async {
    final clamped = _clampInt(
      seconds,
      minLlmRequestTimeoutSeconds,
      maxLlmRequestTimeoutSeconds,
    );
    state = state.copyWith(llmRequestTimeoutSeconds: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      llmRequestTimeoutSeconds: clamped,
    );
  }

  Future<void> setExecutionSettings({String? model, String? providerId}) async {
    state = state.copyWith(
      executionModel: model,
      executionProviderId: providerId,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProvider.id,
      executionModel: model,
      executionProviderId: providerId,
    );
  }
}

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  throw UnimplementedError('SettingsStorage must be overridden in main.dart');
});
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  throw UnimplementedError(
      'settingsProvider must be overridden or dependencies provided');
});
final settingsPageIndexProvider = StateProvider<int>((ref) => 0);
