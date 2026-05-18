import '../../features/settings/presentation/settings_provider.dart';

class LlmResolvedTarget {
  final ProviderConfig provider;
  final String? selectedModel;

  const LlmResolvedTarget({
    required this.provider,
    required this.selectedModel,
  });
}

class LlmServiceConfig {
  const LlmServiceConfig._();

  static LlmResolvedTarget resolveTarget({
    required SettingsState settings,
    String? providerId,
    String? requestedModel,
  }) {
    final provider = resolveProvider(settings, providerId);
    return LlmResolvedTarget(
      provider: provider,
      selectedModel: resolveSelectedModel(
        provider: provider,
        requestedModel: requestedModel,
      ),
    );
  }

  static ProviderConfig resolveProvider(
    SettingsState settings,
    String? providerId,
  ) {
    if (providerId == null) {
      return settings.activeProvider;
    }
    return settings.providers.firstWhere(
      (provider) => provider.id == providerId,
      orElse: () => settings.activeProvider,
    );
  }

  static String? resolveSelectedModel({
    required ProviderConfig provider,
    required String? requestedModel,
  }) {
    final candidate = requestedModel ?? provider.selectedModel;
    if (candidate == null) return null;
    final normalized = candidate.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  static String emptyApiKeyMessage(SettingsState settings) {
    return settings.language == 'zh'
        ? '错误：API Key 为空。请检查设置。'
        : 'Error: API key is empty. Please check your settings.';
  }

  static String missingModelMessage(SettingsState settings) {
    return settings.language == 'zh'
        ? '错误：未选择模型。请先在设置中为当前 Provider 配置模型。'
        : 'Error: no model selected. Please configure a model for the current provider.';
  }

  static Map<String, dynamic> buildActiveParams({
    required ProviderConfig provider,
    required String selectedModel,
  }) {
    final activeParams = <String, dynamic>{};
    final isExcluded = provider.globalExcludeModels.contains(selectedModel);
    if (!isExcluded) {
      activeParams.addAll(provider.globalSettings);
    }
    final specificModelParams = provider.modelSettings[selectedModel];
    if (specificModelParams != null) {
      activeParams.addAll(specificModelParams);
    }
    return activeParams;
  }

  static Map<String, dynamic> buildRequestParameters({
    required ProviderConfig provider,
    required Map<String, dynamic> activeParams,
  }) {
    final filteredModelParams = Map<String, dynamic>.fromEntries(
      activeParams.entries.where((entry) => !entry.key.startsWith('_aurora_')),
    );
    final providerParams = Map<String, dynamic>.fromEntries(
      provider.customParameters.entries.where((entry) {
        final key = entry.key.toLowerCase();
        return key != 'api_keys' &&
            key != 'base_url' &&
            key != 'id' &&
            key != 'name' &&
            key != 'models' &&
            key != 'color' &&
            key != 'is_custom' &&
            key != 'is_enabled' &&
            !entry.key.startsWith('_aurora_');
      }),
    );
    return {
      ...providerParams,
      ...filteredModelParams,
    };
  }
}
