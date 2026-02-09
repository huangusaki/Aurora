class BackupOptions {
  final bool includeChatHistory;
  final bool includeChatPresets;
  final bool includeProviderConfigs;
  final bool includeStudioContent;
  final bool includeAppSettings;
  final bool includeAssistants;
  final bool includeKnowledgeBases;
  final bool includeUsageStats;

  const BackupOptions({
    this.includeChatHistory = true,
    this.includeChatPresets = true,
    this.includeProviderConfigs = true,
    this.includeStudioContent = true,
    this.includeAppSettings = true,
    this.includeAssistants = true,
    this.includeKnowledgeBases = true,
    this.includeUsageStats = true,
  });

  BackupOptions copyWith({
    bool? includeChatHistory,
    bool? includeChatPresets,
    bool? includeProviderConfigs,
    bool? includeStudioContent,
    bool? includeAppSettings,
    bool? includeAssistants,
    bool? includeKnowledgeBases,
    bool? includeUsageStats,
  }) {
    return BackupOptions(
      includeChatHistory: includeChatHistory ?? this.includeChatHistory,
      includeChatPresets: includeChatPresets ?? this.includeChatPresets,
      includeProviderConfigs:
          includeProviderConfigs ?? this.includeProviderConfigs,
      includeStudioContent: includeStudioContent ?? this.includeStudioContent,
      includeAppSettings: includeAppSettings ?? this.includeAppSettings,
      includeAssistants: includeAssistants ?? this.includeAssistants,
      includeKnowledgeBases:
          includeKnowledgeBases ?? this.includeKnowledgeBases,
      includeUsageStats: includeUsageStats ?? this.includeUsageStats,
    );
  }

  bool get isNoneSelected =>
      !includeChatHistory &&
      !includeChatPresets &&
      !includeProviderConfigs &&
      !includeStudioContent &&
      !includeAppSettings &&
      !includeAssistants &&
      !includeKnowledgeBases &&
      !includeUsageStats;
}
