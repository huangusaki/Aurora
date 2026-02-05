import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/settings_storage.dart';
import '../data/provider_config_entity.dart';
import '../domain/chat_preset.dart';
import '../data/chat_preset_entity.dart';

class ProviderConfig {
  final String id;
  final String name;
  final String? color;
  final List<String> apiKeys;
  final int currentKeyIndex;
  final bool autoRotateKeys;
  final String baseUrl;
  final bool isCustom;
  final Map<String, dynamic> customParameters;
  final Map<String, Map<String, dynamic>> modelSettings;
  final Map<String, dynamic> globalSettings;
  final List<String> globalExcludeModels;
  final List<String> models;
  final String? selectedModel;
  final bool isEnabled;

  /// Returns the current API key based on currentKeyIndex (with bounds checking)
  String get apiKey {
    if (apiKeys.isEmpty) return '';
    final safeIndex = currentKeyIndex.clamp(0, apiKeys.length - 1);
    return apiKeys[safeIndex];
  }

  /// Returns a safe current key index (clamped to valid range)
  int get safeCurrentKeyIndex {
    if (apiKeys.isEmpty) return 0;
    return currentKeyIndex.clamp(0, apiKeys.length - 1);
  }

  ProviderConfig({
    required this.id,
    required this.name,
    this.color,
    this.apiKeys = const [],
    this.currentKeyIndex = 0,
    this.autoRotateKeys = false,
    this.baseUrl = 'https://api.openai.com/v1',
    this.isCustom = false,
    this.customParameters = const {},
    this.modelSettings = const {},
    this.globalSettings = const {},
    this.globalExcludeModels = const [],
    this.models = const [],
    this.selectedModel,
    this.isEnabled = true,
  });

  ProviderConfig copyWith({
    String? name,
    String? color,
    List<String>? apiKeys,
    int? currentKeyIndex,
    bool? autoRotateKeys,
    String? baseUrl,
    Map<String, dynamic>? customParameters,
    Map<String, Map<String, dynamic>>? modelSettings,
    Map<String, dynamic>? globalSettings,
    List<String>? globalExcludeModels,
    List<String>? models,
    String? selectedModel,
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
      isCustom: isCustom,
      customParameters: customParameters ?? this.customParameters,
      modelSettings: modelSettings ?? this.modelSettings,
      globalSettings: globalSettings ?? this.globalSettings,
      globalExcludeModels: globalExcludeModels ?? this.globalExcludeModels,
      models: models ?? this.models,
      selectedModel: selectedModel ?? this.selectedModel,
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
  final String searchEngine;
  final String searchRegion;
  final String searchSafeSearch;
  final int searchMaxResults;
  final int searchTimeoutSeconds;
  final bool enableSmartTopic;
  final String? topicGenerationModel;
  final String language;
  final List<ChatPreset> presets;
  final String? lastPresetId;
  final String themeColor;
  final String backgroundColor;
  final int closeBehavior;
  final String? executionModel;
  final String? executionProviderId;
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
    this.searchEngine = 'duckduckgo',
    this.searchRegion = 'us-en',
    this.searchSafeSearch = 'moderate',
    this.searchMaxResults = 5,
    this.searchTimeoutSeconds = 15,
    this.enableSmartTopic = true,
    this.topicGenerationModel,
    this.language = 'zh',
    this.presets = const [],
    this.lastPresetId,
    this.themeColor = 'teal',
    this.backgroundColor = 'default',
    this.closeBehavior = 0,
    this.executionModel,
    this.executionProviderId,
    this.fontSize = 14.0,
    this.backgroundImagePath,
    this.backgroundBrightness = 0.5,
    this.backgroundBlur = 0.0,
    this.useCustomTheme = false,
  });
  ProviderConfig get activeProvider =>
      providers.firstWhere((p) => p.id == activeProviderId);
  ProviderConfig get viewingProvider =>
      providers.firstWhere((p) => p.id == viewingProviderId,
          orElse: () => activeProvider);
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
    String? searchEngine,
    String? searchRegion,
    String? searchSafeSearch,
    int? searchMaxResults,
    int? searchTimeoutSeconds,
    bool? enableSmartTopic,
    String? topicGenerationModel,
    String? language,
    List<ChatPreset>? presets,
    Object? lastPresetId = _settingsSentinel,
    String? themeColor,
    String? backgroundColor,
    int? closeBehavior,
    String? executionModel,
    String? executionProviderId,
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
      searchEngine: searchEngine ?? this.searchEngine,
      searchRegion: searchRegion ?? this.searchRegion,
      searchSafeSearch: searchSafeSearch ?? this.searchSafeSearch,
      searchMaxResults: searchMaxResults != null
          ? _clampInt(searchMaxResults, 1, 50)
          : this.searchMaxResults,
      searchTimeoutSeconds: searchTimeoutSeconds != null
          ? _clampInt(searchTimeoutSeconds, 5, 60)
          : this.searchTimeoutSeconds,
      enableSmartTopic: enableSmartTopic ?? this.enableSmartTopic,
      topicGenerationModel: topicGenerationModel ?? this.topicGenerationModel,
      language: language ?? this.language,
      presets: presets ?? this.presets,
      lastPresetId: lastPresetId == _settingsSentinel
          ? this.lastPresetId
          : lastPresetId as String?,
      themeColor: themeColor ?? this.themeColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      closeBehavior: closeBehavior ?? this.closeBehavior,
      executionModel: executionModel ?? this.executionModel,
      executionProviderId: executionProviderId ?? this.executionProviderId,
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

int _clampInt(int value, int min, int max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
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

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsStorage _storage;
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
    String searchEngine = 'duckduckgo',
    String searchRegion = 'us-en',
    String searchSafeSearch = 'moderate',
    int searchMaxResults = 5,
    int searchTimeoutSeconds = 15,
    bool enableSmartTopic = true,
    String? topicGenerationModel,
    String language = 'zh',
    String themeColor = 'teal',
    String backgroundColor = 'default',
    int closeBehavior = 0,
    String? executionModel,
    String? executionProviderId,
    double fontSize = 14.0,
    String? backgroundImagePath,
    double backgroundBrightness = 0.5,
    double backgroundBlur = 0.0,
    bool useCustomTheme = false,
  })  : _storage = storage,
        super(SettingsState(
          providers: initialProviders,
          activeProviderId: initialActiveId,
          viewingProviderId: initialActiveId,
          userName: userName,
          userAvatar: userAvatar,
          llmName: llmName,
          llmAvatar: llmAvatar,
          themeMode: themeMode,
          isStreamEnabled: isStreamEnabled,
          isSearchEnabled: isSearchEnabled,
          searchEngine: _normalizeSearchEngine(searchEngine),
          searchRegion: _normalizeSearchRegion(searchRegion),
          searchSafeSearch: _normalizeSafeSearch(searchSafeSearch),
          searchMaxResults: _clampInt(searchMaxResults, 1, 50),
          searchTimeoutSeconds: _clampInt(searchTimeoutSeconds, 5, 60),
          enableSmartTopic: enableSmartTopic,
          topicGenerationModel: topicGenerationModel,
          language: language,
          presets: [],
          themeColor: themeColor,
          backgroundColor: backgroundColor,
          closeBehavior: closeBehavior,
          executionModel: executionModel,
          executionProviderId: executionProviderId,
          fontSize: fontSize,
          backgroundImagePath: backgroundImagePath,
          backgroundBrightness: backgroundBrightness,
          backgroundBlur: backgroundBlur,
          useCustomTheme: useCustomTheme,
        )) {
    debugPrint(
        'SettingsNotifier initialized with backgroundImagePath: $backgroundImagePath');
    loadPresets();
  }

  Future<void> refreshSettings() async {
    final providerEntities = await _storage.loadProviders();
    final appSettings = await _storage.loadAppSettings();

    final List<ProviderConfig> newProviders;
    if (providerEntities.isEmpty) {
      newProviders = [
        ProviderConfig(id: 'openai', name: 'OpenAI', isCustom: false),
        ProviderConfig(id: 'custom', name: 'Custom', isCustom: true),
      ];
    } else {
      newProviders = providerEntities.map((e) {
        Map<String, dynamic> customParams = {};
        Map<String, Map<String, dynamic>> modelSettings = {};
        Map<String, dynamic> globalSettings = {};

        if (e.customParametersJson != null &&
            e.customParametersJson!.isNotEmpty) {
          try {
            customParams =
                jsonDecode(e.customParametersJson!) as Map<String, dynamic>;
          } catch (_) {}
        }
        if (e.modelSettingsJson != null && e.modelSettingsJson!.isNotEmpty) {
          try {
            final decoded = jsonDecode(e.modelSettingsJson!);
            if (decoded is Map) {
              modelSettings = decoded.map((key, value) =>
                  MapEntry(key.toString(), value as Map<String, dynamic>));
            }
          } catch (_) {}
        }
        if (e.globalSettingsJson != null && e.globalSettingsJson!.isNotEmpty) {
          try {
            globalSettings =
                jsonDecode(e.globalSettingsJson!) as Map<String, dynamic>;
          } catch (_) {}
        }
        List<String> apiKeys = e.apiKeys;
        // ignore: deprecated_member_use_from_same_package
        if (apiKeys.isEmpty && e.apiKey.isNotEmpty) {
          // ignore: deprecated_member_use_from_same_package
          apiKeys = [e.apiKey];
        }
        return ProviderConfig(
          id: e.providerId,
          name: e.name,
          color: e.color,
          apiKeys: apiKeys,
          currentKeyIndex: e.currentKeyIndex,
          autoRotateKeys: e.autoRotateKeys,
          baseUrl: e.baseUrl,
          isCustom: e.isCustom,
          customParameters: customParams,
          modelSettings: modelSettings,
          globalSettings: globalSettings,
          globalExcludeModels: e.globalExcludeModels,
          models: e.savedModels,
          selectedModel: e.lastSelectedModel,
          isEnabled: e.isEnabled,
        );
      }).toList();
      if (!newProviders.any((p) => p.id == 'custom')) {
        newProviders
            .add(ProviderConfig(id: 'custom', name: 'Custom', isCustom: true));
      }
    }

    final activeProviderId = appSettings?.activeProviderId ?? 'custom';

    state = state.copyWith(
      providers: newProviders,
      activeProviderId: activeProviderId,
      viewingProviderId: activeProviderId,
      userName: appSettings?.userName ?? 'User',
      userAvatar: appSettings?.userAvatar,
      llmName: appSettings?.llmName ?? 'Assistant',
      llmAvatar: appSettings?.llmAvatar,
      themeMode: appSettings?.themeMode ?? 'system',
      isStreamEnabled: appSettings?.isStreamEnabled ?? true,
      isSearchEnabled: appSettings?.isSearchEnabled ?? false,
      searchEngine: _normalizeSearchEngine(
          appSettings?.searchEngine ?? 'duckduckgo'),
      searchRegion: _normalizeSearchRegion(appSettings?.searchRegion ?? 'us-en'),
      searchSafeSearch:
          _normalizeSafeSearch(appSettings?.searchSafeSearch ?? 'moderate'),
      searchMaxResults: _clampInt(appSettings?.searchMaxResults ?? 5, 1, 50),
      searchTimeoutSeconds:
          _clampInt(appSettings?.searchTimeoutSeconds ?? 15, 5, 60),
      enableSmartTopic: appSettings?.enableSmartTopic ?? true,
      topicGenerationModel: appSettings?.topicGenerationModel,
      language: appSettings?.language ?? 'zh',
      themeColor: appSettings?.themeColor ?? 'teal',
      backgroundColor: appSettings?.backgroundColor ?? 'default',
      closeBehavior: appSettings?.closeBehavior ?? 0,
      executionModel: appSettings?.executionModel,
      executionProviderId: appSettings?.executionProviderId,
      fontSize: appSettings?.fontSize ?? 14.0,
      backgroundImagePath: appSettings?.backgroundImagePath,
      backgroundBrightness: appSettings?.backgroundBrightness ?? 0.5,
      backgroundBlur: appSettings?.backgroundBlur ?? 0.0,
      useCustomTheme: appSettings?.useCustomTheme ?? false,
    );
    debugPrint(
        'Settings reloaded with backgroundImagePath: ${appSettings?.backgroundImagePath}');
    debugPrint(
        'DEBUG: refreshSettings loaded - executionModel: ${appSettings?.executionModel}, executionProviderId: ${appSettings?.executionProviderId}');

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
            return p.copyWith(selectedModel: defaultModel);
          }
          return p;
        }).toList();
        state = state.copyWith(providers: newProviders);
        await updateProvider(id: id, selectedModel: defaultModel);
        provider = state.providers.firstWhere((p) => p.id == id);
      }
      state = state.copyWith(
        activeProviderId: id,
        error: null,
      );
      await _storage.saveAppSettings(
        activeProviderId: id,
        selectedModel: provider.selectedModel,
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
    Map<String, dynamic>? customParameters,
    Map<String, Map<String, dynamic>>? modelSettings,
    Map<String, dynamic>? globalSettings,
    List<String>? globalExcludeModels,
    List<String>? models,
    String? selectedModel,
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
          customParameters: customParameters,
          modelSettings: modelSettings,
          globalSettings: globalSettings,
          globalExcludeModels: globalExcludeModels,
          models: models,
          selectedModel: selectedModel,
          isEnabled: isEnabled,
        );
      }
      return p;
    }).toList();
    state = state.copyWith(providers: newProviders);
    final updatedProvider = newProviders.firstWhere((p) => p.id == id);
    final entity = ProviderConfigEntity()
      ..providerId = updatedProvider.id
      ..name = updatedProvider.name
      ..color = updatedProvider.color
      ..apiKeys = updatedProvider.apiKeys
      ..currentKeyIndex = updatedProvider.currentKeyIndex
      ..autoRotateKeys = updatedProvider.autoRotateKeys
      ..baseUrl = updatedProvider.baseUrl
      ..isCustom = updatedProvider.isCustom
      ..customParametersJson = jsonEncode(updatedProvider.customParameters)
      ..modelSettingsJson = jsonEncode(updatedProvider.modelSettings)
      ..globalSettingsJson = jsonEncode(updatedProvider.globalSettings)
      ..globalExcludeModels = updatedProvider.globalExcludeModels
      ..savedModels = updatedProvider.models
      ..lastSelectedModel = updatedProvider.selectedModel
      ..isEnabled = updatedProvider.isEnabled;
    await _storage.saveProvider(entity);
  }

  Future<void> setSelectedModel(String model) async {
    await updateProvider(id: state.activeProviderId, selectedModel: model);
    final provider = state.activeProvider;
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      selectedModel: model,
      availableModels: provider.models,
    );
  }

  Future<void> addProvider() async {
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    // Generate random pastel-ish color
    final random = Random();
    final hue = random.nextDouble() * 360;
    final saturation = 0.5 + random.nextDouble() * 0.3; // 0.5-0.8
    final lightness = 0.4 + random.nextDouble() * 0.2; // 0.4-0.6
    final color = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    final colorHex =
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    final newProvider = ProviderConfig(
      id: newId,
      name: 'New Provider',
      color: colorHex,
      isCustom: true,
      models: [],
    );
    state = state.copyWith(
      providers: [...state.providers, newProvider],
      viewingProviderId: newId,
    );
    await updateProvider(id: newId, name: 'New Provider', color: colorHex);
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

  Future<void> fetchModels() async {
    final provider = state.viewingProvider;
    if (provider.apiKey.isEmpty) {
      state = state.copyWith(error: 'Please enter API Key');
      return;
    }
    state = state.copyWith(isLoadingModels: true, error: null);
    try {
      final dio = Dio();
      final baseUrl = provider.baseUrl.endsWith('/')
          ? provider.baseUrl
          : '${provider.baseUrl}/';
      final response = await dio.get(
        '${baseUrl}models',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${provider.apiKey}',
          },
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final models = data.map((e) => e['id'] as String).toList();
        models.sort();
        String? newSelectedModel = provider.selectedModel;
        if (newSelectedModel == null || !models.contains(newSelectedModel)) {
          newSelectedModel = models.isNotEmpty ? models.first : null;
        }
        await updateProvider(
            id: provider.id, models: models, selectedModel: newSelectedModel);
        state = state.copyWith(isLoadingModels: false);
        await _storage.saveAppSettings(
          activeProviderId: provider.id,
          selectedModel: newSelectedModel,
          availableModels: models,
        );
      } else {
        state = state.copyWith(
            isLoadingModels: false, error: 'Failed: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(isLoadingModels: false, error: 'Error: $e');
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
    final useCustom = mode == 'custom';
    state = state.copyWith(themeMode: mode, useCustomTheme: useCustom);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      themeMode: mode,
      useCustomTheme: useCustom,
    );
  }

  Future<void> toggleThemeMode() async {
    final current = state.themeMode;
    final next = current == 'light' ? 'dark' : 'light';
    await setThemeMode(next);
  }

  Future<void> toggleStreamEnabled() async {
    final newValue = !state.isStreamEnabled;
    state = state.copyWith(isStreamEnabled: newValue);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      isStreamEnabled: newValue,
    );
  }

  Future<void> setSearchEnabled(bool enabled) async {
    if (state.isSearchEnabled == enabled) return;
    state = state.copyWith(isSearchEnabled: enabled);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      isSearchEnabled: enabled,
    );
  }

  Future<void> toggleSearchEnabled() async {
    await setSearchEnabled(!state.isSearchEnabled);
  }

  Future<void> setSearchEngine(String engine) async {
    state = state.copyWith(searchEngine: engine);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      searchEngine: engine,
    );
  }

  Future<void> setSearchRegion(String region) async {
    final normalized = region.trim().toLowerCase();
    if (normalized.isEmpty) return;
    state = state.copyWith(searchRegion: normalized);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      searchRegion: normalized,
    );
  }

  Future<void> setSearchSafeSearch(String safeSearch) async {
    final normalized = safeSearch.trim().toLowerCase();
    if (normalized.isEmpty) return;
    state = state.copyWith(searchSafeSearch: normalized);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      searchSafeSearch: normalized,
    );
  }

  Future<void> setSearchMaxResults(int maxResults) async {
    final clamped = maxResults.clamp(1, 50);
    state = state.copyWith(searchMaxResults: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      searchMaxResults: clamped,
    );
  }

  Future<void> setSearchTimeoutSeconds(int seconds) async {
    final clamped = seconds.clamp(5, 60);
    state = state.copyWith(searchTimeoutSeconds: clamped);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      searchTimeoutSeconds: clamped,
    );
  }

  Future<void> toggleSmartTopicEnabled(bool enabled) async {
    state = state.copyWith(enableSmartTopic: enabled);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      enableSmartTopic: enabled,
    );
  }

  Future<void> setTopicGenerationModel(String? model) async {
    state = state.copyWith(topicGenerationModel: model);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      topicGenerationModel: model,
    );
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
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
    final mode =
        value ? 'custom' : 'system'; // Fallback to system if disabling custom
    state = state.copyWith(useCustomTheme: value, themeMode: mode);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      useCustomTheme: value,
      themeMode: mode,
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
      activeProviderId: state.activeProviderId,
      themeColor: color,
    );
  }

  Future<void> setBackgroundColor(String color) async {
    state = state.copyWith(backgroundColor: color);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
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

    state = state.copyWith(backgroundImagePath: finalPath);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      backgroundImagePath: finalPath,
      clearBackgroundImage: finalPath == null,
    );

    // If a new background image is set, automatically enable custom theme
    if (finalPath != null && finalPath.isNotEmpty) {
      await setUseCustomTheme(true);
    }
  }

  Future<void> setBackgroundBrightness(double brightness) async {
    state = state.copyWith(backgroundBrightness: brightness);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      backgroundBrightness: brightness,
    );
  }

  Future<void> setBackgroundBlur(double blur) async {
    state = state.copyWith(backgroundBlur: blur);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      backgroundBlur: blur,
    );
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      fontSize: size,
    );
  }

  Future<void> setCloseBehavior(int behavior) async {
    state = state.copyWith(closeBehavior: behavior);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      closeBehavior: behavior,
    );
  }

  Future<void> setExecutionSettings({String? model, String? providerId}) async {
    state = state.copyWith(
      executionModel: model,
      executionProviderId: providerId,
    );
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
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
final settingsInitialStateProvider = Provider<SettingsState>((ref) {
  throw UnimplementedError();
});
final settingsPageIndexProvider = StateProvider<int>((ref) => 0);
