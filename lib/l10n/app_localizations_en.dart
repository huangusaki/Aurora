// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aurora';

  @override
  String get newChat => 'New Chat';

  @override
  String get searchChatHistory => 'Search chat history';

  @override
  String get send => 'Send';

  @override
  String get retry => 'Retry';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get history => 'History';

  @override
  String get modelNotSelected => 'Model Not Selected';

  @override
  String get closeComparison => 'Close Comparison';

  @override
  String get bilingualComparison => 'Bilingual Comparison';

  @override
  String get clear => 'Clear';

  @override
  String get translating => 'Translating...';

  @override
  String get translationResultPlaceholder =>
      'Translation result will be shown here';

  @override
  String get selectModel => 'Select Model';

  @override
  String get switchModel => 'Switch Model';

  @override
  String get deepThinking => 'Deep Thinking...';

  @override
  String deepThoughtFinished(String duration) {
    return 'Deep Thought (${duration}s)';
  }

  @override
  String get thoughtChain => 'Chain of Thought';

  @override
  String get camera => 'Camera';

  @override
  String get photos => 'Photos';

  @override
  String get userSettings => 'User Settings';

  @override
  String get chatExperience => 'Chat Experience';

  @override
  String get smartTopicGeneration => 'Smart Topic Generation';

  @override
  String get smartTopicDescription =>
      'Use LLM to automatically summarize chat titles';

  @override
  String get generationModel => 'Generation Model';

  @override
  String get notSelectedFallback => 'Not Selected (Fallback to truncate)';

  @override
  String get userInfo => 'User Info';

  @override
  String get userName => 'User Name';

  @override
  String get userAvatar => 'User Avatar';

  @override
  String get clickToChangeAvatar => 'Tap to change avatar';

  @override
  String get aiInfo => 'AI Info';

  @override
  String get aiName => 'AI Name';

  @override
  String get aiAvatar => 'AI Avatar';

  @override
  String get pleaseEnter => 'Please enter';

  @override
  String changeAvatarTitle(String target) {
    return 'Change $target Avatar';
  }

  @override
  String get removeAvatar => 'Remove Avatar';

  @override
  String permissionRequired(String name) {
    return '$name Permission Required';
  }

  @override
  String permissionContent(String name) {
    return 'Please grant access to $name in settings to take photos.';
  }

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get selectGenerationModel => 'Select Topic Generation Model';

  @override
  String get pickImageFailed => 'Failed to pick image';

  @override
  String get textTranslation => 'Translate';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get sourceText => 'Source';

  @override
  String get targetText => 'Translation';

  @override
  String get enterTextToTranslate => 'Enter text to translate...';

  @override
  String get translateButton => 'Translate';

  @override
  String get compareMode => 'Compare Mode';

  @override
  String get enableCompare => 'Enable Compare Mode';

  @override
  String get disableCompare => 'Disable Compare Mode';

  @override
  String get translationPlaceholder => 'Translation result will appear here';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get selectOrNewTopic => 'Please select or start a new topic';

  @override
  String get startNewChat => 'New Chat';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get loading => 'Loading';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get failed => 'Failed';

  @override
  String get settings => 'Settings';

  @override
  String get modelProvider => 'Model Provider';

  @override
  String get chatSettings => 'Chat Settings';

  @override
  String get displaySettings => 'UI Settings';

  @override
  String get dataSettings => 'Data Settings';

  @override
  String get usageStats => 'Usage Statistics';

  @override
  String get providerName => 'Provider Name';

  @override
  String get currentProvider => 'Current Provider';

  @override
  String get selectProvider => 'Select Provider';

  @override
  String get addProvider => 'Add Provider';

  @override
  String get deleteProvider => 'Delete Provider';

  @override
  String get deleteProviderConfirm =>
      'Are you sure you want to delete this provider? This action cannot be undone.';

  @override
  String get renameProvider => 'Rename Provider';

  @override
  String get enterProviderName => 'Enter provider name';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get noModelSelected => 'No model selected';

  @override
  String get enabledStatus => 'Enabled Status';

  @override
  String get availableModels => 'Available Models';

  @override
  String get refreshList => 'Refresh List';

  @override
  String get fetchModelList => 'Fetch Model List';

  @override
  String get noModelsData =>
      'No models available. Please configure and click to fetch.';

  @override
  String get noModelsFetch => 'No models. Please click to fetch.';

  @override
  String get modelConfig => 'Configuration';

  @override
  String get configureModelParams => 'Configure parameters for this model';

  @override
  String get paramsHigherPriority =>
      'These parameters have higher priority than global settings';

  @override
  String get noCustomParams => 'No custom parameters';

  @override
  String get addCustomParam => 'Add Custom Parameter';

  @override
  String get editParam => 'Edit Parameter';

  @override
  String get paramKey => 'Key';

  @override
  String get paramValue => 'Value';

  @override
  String get paramType => 'Type';

  @override
  String get typeText => 'Text';

  @override
  String get typeNumber => 'Number';

  @override
  String get typeBoolean => 'Boolean';

  @override
  String get typeJson => 'JSON';

  @override
  String get formatError => 'Format error';

  @override
  String get selectTopicModel => 'Select topic generation model';

  @override
  String get noModelFallback =>
      'Will fallback to default truncation if no model selected';

  @override
  String get selectImage => 'Select Image';

  @override
  String get cropAvatar => 'Crop Avatar';

  @override
  String get themeAndUiComingSoon => 'Theme and UI settings (Coming soon)';

  @override
  String get language => 'Language';

  @override
  String get languageChinese => 'Chinese (Simplified)';

  @override
  String get languageEnglish => 'English';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get totalCalls => 'Total Calls';

  @override
  String get modelCallDistribution => 'Model Call Distribution';

  @override
  String get clearStats => 'Clear Statistics';

  @override
  String get clearStatsConfirm =>
      'Are you sure you want to clear all usage statistics? This action cannot be undone.';

  @override
  String get clearData => 'Clear Data';

  @override
  String get clearDataConfirm =>
      'Are you sure you want to clear all statistics?';

  @override
  String get noUsageData => 'No usage data';

  @override
  String callsCount(int count) {
    return '$count calls';
  }

  @override
  String successCount(int count) {
    return '$count success';
  }

  @override
  String failureCount(int count) {
    return '$count failed';
  }

  @override
  String averageDuration(String duration) {
    return 'Avg: ${duration}s';
  }

  @override
  String averageFirstToken(String duration) {
    return 'FirstToken: ${duration}s';
  }

  @override
  String totalTokensCount(int count) {
    return 'Total: $count Tokens';
  }

  @override
  String tokensPerSecond(String tps) {
    return 'Token/s: $tps';
  }

  @override
  String get mobileSettings => 'Mobile Settings';

  @override
  String get mobileSettingsHint =>
      'Please use the settings button in the top navigation bar to access full settings';

  @override
  String get user => 'User';

  @override
  String get translation => 'Translation';

  @override
  String get theme => 'Theme';

  @override
  String get model => 'Model';

  @override
  String get stats => 'Stats';

  @override
  String get about => 'About';

  @override
  String get aboutAurora => 'About Aurora';

  @override
  String get crossPlatformLlmClient => 'A cross-platform LLM client';

  @override
  String get githubProject => 'GitHub Project';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectFromGallery => 'Select from Gallery';

  @override
  String get selectFile => 'Select File';

  @override
  String get stopGenerating => 'Stop Generating';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get contentCopied => 'Content copied';

  @override
  String get thinking => 'Thinking';

  @override
  String get thinkingProcess => 'Thinking Process';

  @override
  String get expandThinking => 'Expand thinking';

  @override
  String get collapseThinking => 'Collapse thinking';

  @override
  String get searchWeb => 'Search Web';

  @override
  String get searchResults => 'Search Results';

  @override
  String get imageGenerated => 'Image generated';

  @override
  String get saveImage => 'Save Image';

  @override
  String get imageSaved => 'Image saved';

  @override
  String get imageSaveFailed => 'Failed to save image';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get earlier => 'Earlier';

  @override
  String get deleteChat => 'Delete Chat';

  @override
  String get deleteChatConfirm => 'Are you sure you want to delete this chat?';

  @override
  String get pinChat => 'Pin Chat';

  @override
  String get unpinChat => 'Unpin Chat';

  @override
  String get noMessages => 'No messages';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get editApiKey => 'Edit API Key';

  @override
  String get editBaseUrl => 'Edit API Base URL';

  @override
  String get sourceLanguage => 'Source Language';

  @override
  String get targetLanguage => 'Target Language';

  @override
  String get autoDetect => 'Auto Detect';

  @override
  String get english => 'English';

  @override
  String get japanese => 'Japanese';

  @override
  String get korean => 'Korean';

  @override
  String get simplifiedChinese => 'Simplified Chinese';

  @override
  String get traditionalChinese => 'Traditional Chinese';

  @override
  String get russian => 'Russian';

  @override
  String get french => 'French';

  @override
  String get german => 'German';

  @override
  String get streamOutput => 'Stream Output';

  @override
  String get enableSearch => 'Enable Search';

  @override
  String get searchEngine => 'Search Engine';

  @override
  String get clearContext => 'Clear Context';

  @override
  String get clearContextConfirm =>
      'Are you sure you want to clear the context? This cannot be undone.';

  @override
  String get streamEnabled => 'Stream Output Enabled';

  @override
  String get streamDisabled => 'Stream Output Disabled';

  @override
  String get searchEnabled => 'Web Search Enabled';

  @override
  String get searchDisabled => 'Web Search Disabled';

  @override
  String get desktopInputHint =>
      'Type something... (Enter for new line, Ctrl + Enter to send, @ to switch model)';

  @override
  String get mobileInputHint => 'Type something...';

  @override
  String get topics => 'Topic Groups';

  @override
  String get createTopic => 'New Group';

  @override
  String get editTopic => 'Edit Group';

  @override
  String get deleteTopic => 'Delete Group';

  @override
  String get deleteTopicConfirm =>
      'Delete this group? Sessions will be moved to the default group.';

  @override
  String get topicNamePlaceholder => 'Group Name';

  @override
  String get allChats => 'All';

  @override
  String get thinkingConfig => 'Thinking Config';

  @override
  String get enableThinking => 'Enable Thinking';

  @override
  String get thinkingBudget => 'Thinking Budget';

  @override
  String get thinkingBudgetHint =>
      'Enter number (e.g. 1024) or level (e.g. low, high)';

  @override
  String get transmissionMode => 'Transmission Mode';

  @override
  String get modeAuto => 'Smart Auto';

  @override
  String get modeExtraBody => 'Extra Body (Google)';

  @override
  String get modeReasoningEffort => 'Reasoning Effort (OpenAI)';

  @override
  String get providers => 'Providers';

  @override
  String get promptPresets => 'Prompt Presets';

  @override
  String get defaultPreset => 'Default';

  @override
  String get newPreset => 'New Custom Preset';

  @override
  String get editPreset => 'Edit Preset';

  @override
  String get managePresets => 'Manage Presets';

  @override
  String get presetName => 'Preset Name';

  @override
  String get presetDescription => 'Description (Optional)';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get savePreset => 'Save Preset';

  @override
  String get selectPresetHint => 'Select a preset to edit or create a new one.';

  @override
  String get presetNamePlaceholder => 'e.g., Python Expert';

  @override
  String get presetDescriptionPlaceholder => 'Optional description...';

  @override
  String get systemPromptPlaceholder => 'Enter system prompt here...';

  @override
  String get noPresets => 'No presets found';

  @override
  String get deletePreset => 'Delete Preset';

  @override
  String deletePresetConfirmation(String name) {
    return 'Are you sure you want to delete preset \"$name\"?';
  }

  @override
  String get fillRequiredFields => 'Please fill in all required fields';
}
