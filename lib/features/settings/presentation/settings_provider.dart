import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/settings_storage.dart';
import '../data/provider_config_entity.dart';

class ProviderConfig {
  final String id;
  final String name;
  final String apiKey;
  final String baseUrl;
  final bool isCustom;
  final Map<String, dynamic> customParameters;
  final Map<String, Map<String, dynamic>> modelSettings;
  final List<String> models;
  final String? selectedModel;
  final bool isEnabled;
  ProviderConfig({
    required this.id,
    required this.name,
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.isCustom = false,
    this.customParameters = const {},
    this.modelSettings = const {},
    this.models = const [],
    this.selectedModel,
    this.isEnabled = true,
  });
  ProviderConfig copyWith({
    String? name,
    String? apiKey,
    String? baseUrl,
    Map<String, dynamic>? customParameters,
    Map<String, Map<String, dynamic>>? modelSettings,
    List<String>? models,
    String? selectedModel,
    bool? isEnabled,
  }) {
    return ProviderConfig(
      id: id,
      name: name ?? this.name,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      isCustom: isCustom,
      customParameters: customParameters ?? this.customParameters,
      modelSettings: modelSettings ?? this.modelSettings,
      models: models ?? this.models,
      selectedModel: selectedModel ?? this.selectedModel,
      isEnabled: isEnabled ?? this.isEnabled,
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
  final String searchEngine;
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
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsStorage _storage;
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
          searchEngine: searchEngine,
        ));
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
    String? apiKey,
    String? baseUrl,
    Map<String, dynamic>? customParameters,
    Map<String, Map<String, dynamic>>? modelSettings,
    List<String>? models,
    String? selectedModel,
    bool? isEnabled,
  }) async {
    final newProviders = state.providers.map((p) {
      if (p.id == id) {
        return p.copyWith(
          name: name,
          apiKey: apiKey,
          baseUrl: baseUrl,
          customParameters: customParameters,
          modelSettings: modelSettings,
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
      ..apiKey = updatedProvider.apiKey
      ..baseUrl = updatedProvider.baseUrl
      ..isCustom = updatedProvider.isCustom
      ..customParametersJson = jsonEncode(updatedProvider.customParameters)
      ..modelSettingsJson = jsonEncode(updatedProvider.modelSettings)
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
    state = state.copyWith(themeMode: mode);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      themeMode: mode,
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

  Future<void> toggleSearchEnabled() async {
    final newValue = !state.isSearchEnabled;
    state = state.copyWith(isSearchEnabled: newValue);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      isSearchEnabled: newValue,
    );
  }

  Future<void> setSearchEngine(String engine) async {
    state = state.copyWith(searchEngine: engine);
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      searchEngine: engine,
    );
  }
}

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  throw UnimplementedError('SettingsStorage must be overridden in main.dart');
});
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  throw UnimplementedError(
      'settingsProvider must be overridden or dependencies provided');
});
final settingsInitialStateProvider = Provider<SettingsState>((ref) {
  throw UnimplementedError();
});
