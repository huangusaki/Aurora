import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/settings_storage.dart';
import '../data/provider_config_entity.dart';

// Provider Config Model
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
  });

  ProviderConfig copyWith({
    String? name,
    String? apiKey,
    String? baseUrl,
    Map<String, dynamic>? customParameters,
    Map<String, Map<String, dynamic>>? modelSettings,
    List<String>? models,
    String? selectedModel,
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
    );
  }
}

// ... (SettingsState remains mostly same, except if we want to expose params)

// Settings Notifier update


// Settings State
class SettingsState {
  final List<ProviderConfig> providers;
  final String activeProviderId; // Global active provider for Chat
  final String viewingProviderId; // Provider selected in Settings UI for editing
  final bool isLoadingModels;
  final String? error;
  
  // Chat Display Settings
  final String userName;
  final String? userAvatar;
  final String llmName;
  final String? llmAvatar;
  final String themeMode; // system, light, dark

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
  });

  ProviderConfig get activeProvider => providers.firstWhere((p) => p.id == activeProviderId);
  ProviderConfig get viewingProvider => providers.firstWhere((p) => p.id == viewingProviderId, orElse: () => activeProvider);
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
  }) : _storage = storage,
       super(SettingsState(
         providers: initialProviders,
         activeProviderId: initialActiveId,
         viewingProviderId: initialActiveId,
         userName: userName,
         userAvatar: userAvatar,
         llmName: llmName,
          llmAvatar: llmAvatar,
          themeMode: themeMode,
       ));

  // Switch viewing provider (UI only)
  void viewProvider(String id) {
     if (state.viewingProviderId != id) {
        state = state.copyWith(viewingProviderId: id, error: null);
     }
  }



  Future<void> selectProvider(String id) async {
    if (state.activeProviderId != id) {
      // Find the provider we are switching to
      var provider = state.providers.firstWhere((p) => p.id == id);
      
      // Auto-select first model if none selected but models exist
      if (provider.selectedModel == null && provider.models.isNotEmpty) {
          final defaultModel = provider.models.first;
          // Update State locally
          final newProviders = state.providers.map((p) {
             if (p.id == id) {
                return p.copyWith(selectedModel: defaultModel);
             }
             return p;
          }).toList();
          
          state = state.copyWith(providers: newProviders);
          
          // Persist the selection for the provider entity
          // This ensures next time we load (or updateProvider calls) we have it.
          // We can reuse updateProvider logic but that triggers state update again.
          // Let's call updateProvider to be consistent and save to storage.
          await updateProvider(id: id, selectedModel: defaultModel);
          
          // Re-fetch provider from updated state
          provider = state.providers.firstWhere((p) => p.id == id);
      }

      state = state.copyWith(
        activeProviderId: id,
        error: null,
      );
      
      // Save global active provider settings
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
      ..lastSelectedModel = updatedProvider.selectedModel;
      
    await _storage.saveProvider(entity);
  }

  Future<void> setSelectedModel(String model) async {
    await updateProvider(id: state.activeProviderId, selectedModel: model);
    // Also save global app settings to track active provider state
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
      // Do NOT change activeProviderId automatically for chat. 
      // Just switch the VIEW to the new provider so user can edit it.
      viewingProviderId: newId, 
    );
    
    // Save new provider
    await updateProvider(id: newId, name: 'New Provider');
  }

  Future<void> deleteProvider(String id) async {
    final providerToDelete = state.providers.firstWhere((p) => p.id == id, orElse: () => state.providers.first);
    
    if (!providerToDelete.isCustom && id == 'openai') {
       return;
    }
    
    final newProviders = state.providers.where((p) => p.id != id).toList();
    if (newProviders.isEmpty) {
       return;
    }
    
    String newActiveId = state.activeProviderId;
    if (state.activeProviderId == id) {
      // If we deleted the ACTIVE provider, we MUST switch active to something else
      newActiveId = newProviders.first.id;
    }

    String newViewingId = state.viewingProviderId;
    if (state.viewingProviderId == id) {
       // If we deleted the VIEWING provider, switch view to something else
       // Ideally switch to active if available, or first.
       newViewingId = newActiveId; 
    }
    
    state = state.copyWith(
      providers: newProviders,
      activeProviderId: newActiveId,
      viewingProviderId: newViewingId,
    );
    
    await _storage.deleteProvider(id);
    // If active changed, save the new selection
    if (newActiveId != id) {
        await selectProvider(newActiveId); 
    }
  }

  Future<void> fetchModels() async {
    // Fetch models for the provider being VIEWED/EDITED, not necessarily the active chat one.
    final provider = state.viewingProvider;
    
    if (provider.apiKey.isEmpty) {
      state = state.copyWith(error: 'Please enter API Key');
      return;
    }

    state = state.copyWith(isLoadingModels: true, error: null);

    try {
      final dio = Dio();
      final baseUrl = provider.baseUrl.endsWith('/') ? provider.baseUrl : '${provider.baseUrl}/';
      
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

        // Update Provider Config with new models
        await updateProvider(
          id: provider.id,
          models: models,
          selectedModel: newSelectedModel
        );

        state = state.copyWith(isLoadingModels: false);
        
        // Save App Settings
        await _storage.saveAppSettings(
          activeProviderId: provider.id, 
          selectedModel: newSelectedModel, 
          availableModels: models,
        );
        
      } else {
        state = state.copyWith(isLoadingModels: false, error: 'Failed: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(isLoadingModels: false, error: 'Error: $e');
    }
  }

  // Chat Display Settings
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
    // Persist to storage
    await _storage.saveChatDisplaySettings(
      userName: userName ?? state.userName,
      userAvatar: userAvatar,
      llmName: llmName ?? state.llmName,
      llmAvatar: llmAvatar,
    );
  }

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    // Persist to storage
    await _storage.saveAppSettings(
      activeProviderId: state.activeProviderId,
      themeMode: mode,
    );
  }

  Future<void> toggleThemeMode() async {
    final current = state.themeMode;
    // Simple toggle: light ↔ dark
    final next = current == 'light' ? 'dark' : 'light';
    await setThemeMode(next);
  }
}

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  throw UnimplementedError('SettingsStorage must be overridden in main.dart');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  
  // These should ideally be passed from main override too if possible, 
  // but StateNotifierProvider doesn't easily accept args from main override unless we use .family or scoped provider logic via Constructor.
  // Actually, we can use a separate provider for InitialState.
  // Or simpler: The SettingsNotifier expects specific overrides.
  // But wait, if I override settingsProvider in main, that works.
  // Or override loading logic.
  
  // Let's assume we pass Empty defaults here, and rely on main.dart to override THIS provider entirely?
  // No, overriding StateNotifierProvider with an instance is tricky.
  // Better: Define `initialSettingsProvider` storing a State object.
  // But simpler: Just Init empty here (which acts as Loading) and load in Constructor?
  // But I want SYNC init if possible.
  
  // Allow initialization with defaults, logic in main will override properties if we use scoped values?
  // No.
  
  // Let's use the pattern:
  // main.dart loads data.
  // main.dart overrides `settingsInitialStateProvider`.
  // settingsProvider reads `settingsInitialStateProvider` and `storage`.
  
  throw UnimplementedError('settingsProvider must be overridden or dependencies provided');
});

final settingsInitialStateProvider = Provider<SettingsState>((ref) {
  throw UnimplementedError();
});
