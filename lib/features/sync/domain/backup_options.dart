class BackupOptions {
  final bool includeChatHistory;
  final bool includeChatPresets;
  final bool includeProviderConfigs;
  final bool includeStudioContent;

  const BackupOptions({
    this.includeChatHistory = true,
    this.includeChatPresets = true,
    this.includeProviderConfigs = true,
    this.includeStudioContent = true,
  });

  BackupOptions copyWith({
    bool? includeChatHistory,
    bool? includeChatPresets,
    bool? includeProviderConfigs,
    bool? includeStudioContent,
  }) {
    return BackupOptions(
      includeChatHistory: includeChatHistory ?? this.includeChatHistory,
      includeChatPresets: includeChatPresets ?? this.includeChatPresets,
      includeProviderConfigs: includeProviderConfigs ?? this.includeProviderConfigs,
      includeStudioContent: includeStudioContent ?? this.includeStudioContent,
    );
  }

  bool get isNoneSelected =>
      !includeChatHistory &&
      !includeChatPresets &&
      !includeProviderConfigs &&
      !includeStudioContent;
}
