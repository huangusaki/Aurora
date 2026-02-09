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
  String get sendAndRegenerate => 'Send & Regenerate';

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
  String get reset => 'Reset';

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
  String get deepThinking => 'Thinking...';

  @override
  String deepThoughtFinished(String duration) {
    return 'Thought for ${duration}s';
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
  String get assistantAvatar => 'Assistant Avatar';

  @override
  String get globalConfig => 'Global Config';

  @override
  String get excludedModels => 'Excluded Models';

  @override
  String get excludedModelsHint =>
      'Global config will not apply to these models';

  @override
  String get enterModelNameHint => 'Enter model name and press enter to add';

  @override
  String get clickToChangeAvatar => 'Click to change avatar';

  @override
  String get aiInfo => 'AI Info';

  @override
  String get aiName => 'AI Name';

  @override
  String get aiNamePlaceholder => 'Assistant';

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
  String get create => 'Create';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get loading => 'Loading';

  @override
  String get loadingEllipsis => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get success => 'Success';

  @override
  String get failed => 'Failed';

  @override
  String get unknown => 'Unknown';

  @override
  String get settings => 'Settings';

  @override
  String get modelProvider => 'Model Provider';

  @override
  String get chatSettings => 'Chat Settings';

  @override
  String get displaySettings => 'Display Settings';

  @override
  String get dataSettings => 'Data Backup';

  @override
  String get usageStats => 'Usage Statistics';

  @override
  String get agentSkills => 'Skills';

  @override
  String get executionModel => 'Execution Model';

  @override
  String get executionModelHint =>
      'The model used by Worker Agents to execute skills.';

  @override
  String get defaultModelSameAsChat => 'Default (Same as Chat)';

  @override
  String get agentSkillsDescription =>
      'Skills are loaded from the \'./skills\' folder in the application root. Create a folder with a \'SKILL.md\' file to add a new skill.';

  @override
  String get noSkillsFound => 'No skills found in ./skills directory';

  @override
  String get openSkillsFolder => 'Open Skills Folder';

  @override
  String get instructions => 'Instructions';

  @override
  String get tools => 'Tools';

  @override
  String get newSkill => 'New Skill';

  @override
  String get editSkill => 'Edit Skill';

  @override
  String get deleteSkill => 'Delete Skill';

  @override
  String get deleteSkillTitle => 'Delete Skill';

  @override
  String get deleteSkillConfirm =>
      'Are you sure you want to delete this skill? This action cannot be undone.';

  @override
  String get updateSkill => 'Update Skill';

  @override
  String get saveSuccess => 'Saved Successfully';

  @override
  String get skillName => 'Skill Folder Name';

  @override
  String get skillNameHint => 'Enter folder name (e.g. translation_helper)';

  @override
  String get skillMarkdownPlaceholder => 'SKILL.md content...';

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
  String get enableAll => 'Enable All';

  @override
  String get disableAll => 'Disable All';

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
  String get paramKeyPlaceholder => 'e.g. _aurora_image_config';

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
  String get backup => 'Backup';

  @override
  String get backupAndRestore => 'Backup and Restore';

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
    return 'Avg Duration: ${duration}s';
  }

  @override
  String averageFirstToken(String duration) {
    return 'TTFT: ${duration}s';
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
  String get totalTokens => 'Total Tokens';

  @override
  String get tokensPerSecondShort => 'Tokens/s';

  @override
  String get ttft => 'TTFT';

  @override
  String get avgDuration => 'Avg Duration';

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
  String get studio => 'Studio';

  @override
  String get novelWriting => 'Novel Writing';

  @override
  String get taskOrchestration => 'Task Orchestration';

  @override
  String get createTask => 'Create Task';

  @override
  String get pendingTasks => 'Pending Tasks';

  @override
  String get taskDescription => 'Task Description';

  @override
  String get decompose => 'Decompose';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get start => 'Start';

  @override
  String get novelName => 'Novel Name';

  @override
  String get chapterTitle => 'Chapter Title';

  @override
  String get chapters => 'Chapters';

  @override
  String get novelStructure => 'Novel Structure';

  @override
  String get modelConfig => 'Model Config';

  @override
  String get reviewModel => 'Review';

  @override
  String get writerModel => 'Writer Model';

  @override
  String get decomposeModel => 'Structure Model';

  @override
  String get project => 'Project';

  @override
  String get selectProject => 'Select Project';

  @override
  String get createProject => 'New Project';

  @override
  String get deleteProject => 'Delete Project';

  @override
  String get deleteProjectConfirm =>
      'Are you sure you want to delete this project?';

  @override
  String get deleteChapter => 'Delete Chapter';

  @override
  String get deleteChapterConfirm =>
      'Are you sure you want to delete this chapter?';

  @override
  String get writing => 'Writing';

  @override
  String get context => 'World Settings';

  @override
  String get preview => 'Preview';

  @override
  String get stopTask => 'Stop';

  @override
  String get startWriting => 'Start';

  @override
  String get outlineSettings => 'Outline & Settings';

  @override
  String get clearOutline => 'Clear Outline';

  @override
  String get startConceiving => 'Start Conceiving Your Story';

  @override
  String get outlineHint =>
      'Describe your story idea below, and AI will generate a detailed outline.';

  @override
  String get outlinePlaceholder =>
      'E.g. Write a cyberpunk detective novel featuring...';

  @override
  String get generateOutline => 'Generate Outline';

  @override
  String get editOutlinePlaceholder => 'Edit outline here...';

  @override
  String get rerunOutline => 'Rerun Outline';

  @override
  String get rerunOutlineFromLastPromptHint =>
      'Regenerate outline based on the last requirement prompt';

  @override
  String get noRerunnableOutlinePrompt =>
      'No outline requirement prompt to rerun';

  @override
  String get generateChapters => 'Generate Chapters';

  @override
  String get regenerateChapters => 'Regenerate Chapters';

  @override
  String get regenerateChapterOutlineTitle => 'Regenerate Chapter Outline';

  @override
  String get regenerateChapterOutlineConfirm =>
      'This will regenerate chapter outlines based on the latest story outline.\nIf an error occurs, the system will automatically roll back to the current chapter content.';

  @override
  String get continueGenerate => 'Continue';

  @override
  String get clearChaptersWarning =>
      'This will clear all existing chapters and progress.\nIt is recommended to backup important content first.\n\nAre you sure you want to continue?';

  @override
  String get clearAndRegenerate => 'Clear & Regenerate';

  @override
  String get chaptersAndTasks => 'Chapters & Tasks';

  @override
  String get addChapter => 'Add Custom Chapter';

  @override
  String get noTasks => 'No Tasks';

  @override
  String get taskDetails => 'Task Details';

  @override
  String get selectTaskToView => 'Select a task to view details';

  @override
  String get taskRequirement => 'Task Requirements';

  @override
  String get generatedContent => 'Generated Content';

  @override
  String get waitingForGeneration => 'Waiting for generation...';

  @override
  String get worldSettings => 'World Settings';

  @override
  String get autoIncludeHint =>
      'Checked categories will be automatically included during writing';

  @override
  String get clearWorldSettingsTooltip => 'Clear all world settings';

  @override
  String get clearWorldSettingsTitle => 'Clear World Settings';

  @override
  String get clearWorldSettingsConfirm =>
      'Are you sure you want to clear all world settings data?\n(Characters, relationships, locations, foreshadowing/clues, etc.)';

  @override
  String get worldRules => 'World Rules';

  @override
  String get characterSettings => 'Character Settings';

  @override
  String get relationships => 'Relationships';

  @override
  String get locations => 'Locations';

  @override
  String get foreshadowing => 'Foreshadowing/Clues';

  @override
  String get noDataYet => 'No data yet (Auto-extracted after writing)';

  @override
  String get pleaseSelectChapter => 'Please select a chapter first';

  @override
  String get copyFullText => 'Copy Full Text';

  @override
  String get unknownChapter => 'Unknown Chapter';

  @override
  String get noContentYet => 'No content yet';

  @override
  String get allTasksPending => 'Execute all pending tasks sequentially';

  @override
  String get noPendingTasks => 'No executable pending tasks';

  @override
  String get restartAllTasksTooltip =>
      'Reset all task states and regenerate from scratch';

  @override
  String get restartAllTasksTitle => 'Restart All Tasks';

  @override
  String get restartAllTasksConfirm =>
      'Are you sure you want to reset all tasks?\nThis will clear generated content and require regenerating all chapters.';

  @override
  String get restartAllTasksAction => 'Restart';

  @override
  String get executeTask => 'Execute';

  @override
  String get reviewFeedback => 'Review Feedback';

  @override
  String get reject => 'Reject';

  @override
  String get approve => 'Approve';

  @override
  String get rewrite => 'Rewrite';

  @override
  String get pending => 'Pending';

  @override
  String get running => 'Running';

  @override
  String get completed => 'Completed';

  @override
  String get paused => 'Paused';

  @override
  String get reviewing => 'Reviewing';

  @override
  String get decomposing => 'Decomposing';

  @override
  String get needsRevision => 'Needs Revision';

  @override
  String batchProgress(int current, int total) {
    return 'Batch progress: $current/$total';
  }

  @override
  String get projectOnlyKnowledgeBaseHint =>
      'This knowledge base is project-only and never applied in chat.';

  @override
  String get importingEllipsis => 'Importing...';

  @override
  String chapterProgressSummary(int completed, int total, int words) {
    return '$completed/$total chapters · $words words';
  }

  @override
  String get noProjectSelected => 'No Project Selected';

  @override
  String get createYourFirstProject => 'Start Your Creative Journey';

  @override
  String get createProjectDescription =>
      'Create a new project to start building your story outline and chapters.';

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
  String get selectVideo => 'Select Video';

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
  String get footnotes => 'Footnotes';

  @override
  String undefinedFootnote(String id) {
    return 'Undefined footnote: $id';
  }

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
  String searchResultsWithEngine(int count, String engine) {
    return '$count Search Results ($engine)';
  }

  @override
  String citationsCount(int count) {
    return '$count Citations';
  }

  @override
  String get agentResponse => 'Agent Response';

  @override
  String get agentOutput => 'Agent Output';

  @override
  String terminalError(int code) {
    return 'Terminal Error (Code $code)';
  }

  @override
  String get terminalOutput => 'Terminal Output';

  @override
  String get noOutput => '[No output]';

  @override
  String get images => 'Images';

  @override
  String get imageGenerated => 'Image generated';

  @override
  String get imageCopied => 'Image Copied';

  @override
  String get imageCopiedToClipboard => 'Image has been copied to clipboard';

  @override
  String get clipboardError => 'Clipboard Error';

  @override
  String get clipboardAccessFailed =>
      'Failed to access clipboard. Please restart the app completely.';

  @override
  String get copyImage => 'Copy Image';

  @override
  String get saveImage => 'Save Image';

  @override
  String get saveImageAs => 'Save Image As...';

  @override
  String get imageSaved => 'Image saved';

  @override
  String imageSavedToPath(String path) {
    return 'Image saved to $path';
  }

  @override
  String get imageSaveFailed => 'Failed to save image';

  @override
  String get rotateLeft => 'Rotate Left';

  @override
  String get rotateRight => 'Rotate Right';

  @override
  String get flipHorizontal => 'Flip Horizontal';

  @override
  String get flipVertical => 'Flip Vertical';

  @override
  String get zoomIn => 'Zoom In';

  @override
  String get zoomOut => 'Zoom Out';

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
  String get editMessagePlaceholder => 'Edit message...';

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
  String get searchSettings => 'Search Settings';

  @override
  String get searchEngine => 'Search Engine';

  @override
  String get searchRegion => 'Search Region';

  @override
  String get searchSafeSearch => 'Safe Search';

  @override
  String get searchSafeSearchOff => 'Off';

  @override
  String get searchSafeSearchModerate => 'Moderate';

  @override
  String get searchSafeSearchStrict => 'Strict';

  @override
  String get searchMaxResults => 'Max Results';

  @override
  String get searchTimeoutSeconds => 'Timeout (seconds)';

  @override
  String get knowledgeBase => 'Knowledge Base';

  @override
  String get knowledgeBases => 'Knowledge Bases';

  @override
  String get general => 'General';

  @override
  String get enableKnowledgeRetrieval => 'Enable Knowledge Retrieval';

  @override
  String get knowledgeTopKChunks => 'Top K Chunks';

  @override
  String get useEmbeddingRerank => 'Use Embedding Re-rank';

  @override
  String get knowledgeLlmEnhancementMode => 'LLM Enhancement Mode (Optional)';

  @override
  String get knowledgeModeOff => 'off';

  @override
  String get knowledgeModeRewrite => 'rewrite';

  @override
  String get embeddingProvider => 'Embedding Provider';

  @override
  String get embeddingModel => 'Embedding Model';

  @override
  String get noEmbeddingModelsInProvider =>
      'No embedding model found in this provider';

  @override
  String get embeddingModelAutoDetectHint =>
      'Only models whose names include \"embedding\" are listed.';

  @override
  String get createBase => 'Create Base';

  @override
  String get importFiles => 'Import Files';

  @override
  String get deleteBase => 'Delete Base';

  @override
  String get noKnowledgeBaseYetCreateOne =>
      'No knowledge base yet. Create one first.';

  @override
  String get knowledgeActive => 'Active';

  @override
  String knowledgeDocsAndChunks(int docs, int chunks) {
    return 'Docs: $docs  Chunks: $chunks';
  }

  @override
  String get createKnowledgeBase => 'Create Knowledge Base';

  @override
  String get knowledgeBaseName => 'Base Name';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get deleteKnowledgeBase => 'Delete Knowledge Base';

  @override
  String get deleteKnowledgeBaseConfirm =>
      'Delete this knowledge base and all indexed chunks? This cannot be undone.';

  @override
  String get knowledgeFiles => 'Knowledge files';

  @override
  String get importFinished => 'Import Finished';

  @override
  String knowledgeImportSummary(int success, int failed) {
    return 'Success: $success\nFailed: $failed';
  }

  @override
  String knowledgeEnabledWithActiveCount(int count) {
    return 'Enabled • $count active';
  }

  @override
  String get knowledgeGlobalFallbackHint =>
      'Global knowledge bases are used only when no assistant is selected.';

  @override
  String get knowledgeGlobalSelectionLabel => 'Use in Global Mode';

  @override
  String get knowledgeGlobalSelectionHint =>
      'Effective only when no assistant is selected.';

  @override
  String get knowledgeBaseEnabledLabel => 'Knowledge Base Available';

  @override
  String get knowledgeBaseEnabledHint =>
      'If disabled, this base is excluded from all retrieval.';

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
      'Type a message (Enter newline, Ctrl+Enter send, @ model, / presets)';

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
  String get errorLoadingTopics => 'Error loading topics';

  @override
  String get noGroups => 'No groups';

  @override
  String get allChats => 'All';

  @override
  String get requestConfig => 'Request Config';

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

  @override
  String get callTrend => 'Call Trend (Last 30 Days)';

  @override
  String get errorDistribution => 'Error Distribution';

  @override
  String get errorTimeout => 'Timeout';

  @override
  String get errorNetwork => 'Network Error';

  @override
  String get errorBadRequest => 'Bad Request (400)';

  @override
  String get errorUnauthorized => 'Unauthorized (401)';

  @override
  String get errorServerError => 'Server Error (5XX)';

  @override
  String get errorRateLimit => 'Rate Limit (429)';

  @override
  String get errorUnknown => 'Other Error';

  @override
  String get bgDefault => 'Default';

  @override
  String get bgPureBlack => 'Pure Black';

  @override
  String get bgWarm => 'Warm';

  @override
  String get bgCool => 'Cool';

  @override
  String get bgRose => 'Rose';

  @override
  String get bgLavender => 'Lavender';

  @override
  String get bgMint => 'Mint';

  @override
  String get bgSky => 'Sky';

  @override
  String get bgGray => 'Gray';

  @override
  String get bgSunset => 'Sunset';

  @override
  String get bgOcean => 'Ocean';

  @override
  String get bgForest => 'Forest';

  @override
  String get bgDream => 'Dream';

  @override
  String get bgAurora => 'Aurora';

  @override
  String get bgVolcano => 'Volcano';

  @override
  String get bgMidnight => 'Midnight';

  @override
  String get bgDawn => 'Dawn';

  @override
  String get bgNeon => 'Neon';

  @override
  String get bgBlossom => 'Blossom';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get themeCustom => 'Custom';

  @override
  String get customTheme => 'Custom';

  @override
  String get customThemeDescription =>
      'Allow setting custom background image, brightness and blur';

  @override
  String get backgroundStyle => 'Background Style';

  @override
  String get renameSession => 'Rename';

  @override
  String get renameSessionHint => 'Enter new name';

  @override
  String get providerColor => 'Color (Hex)';

  @override
  String get apiKeyPlaceholder => 'sk-xxxxxxxx';

  @override
  String get baseUrlPlaceholder => 'https://api.openai.com/v1';

  @override
  String get apiBaseUrl => 'API Base URL';

  @override
  String get apiKeys => 'API Keys';

  @override
  String apiKeysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keys',
      one: '1 key',
    );
    return '$_temp0';
  }

  @override
  String get addApiKey => 'Add Key';

  @override
  String get autoRotateKeys => 'Auto Rotate';

  @override
  String get editApiKey => 'Edit API Key';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontSizeHint => 'Adjust global text display size';

  @override
  String get backgroundImage => 'Background Image';

  @override
  String get backgroundBlur => 'Background Blur';

  @override
  String get backgroundBrightness => 'Background Brightness';

  @override
  String get selectBackgroundImage => 'Select Background';

  @override
  String get clearBackgroundImage => 'Clear Background';

  @override
  String get cropImage => 'Crop Image';

  @override
  String get generationConfig => 'Generation Config';

  @override
  String get customParams => 'Custom Parameters';

  @override
  String get temperature => 'Temperature';

  @override
  String get temperatureHint => '0.0 - 2.0, lower = more focused';

  @override
  String get maxTokens => 'Max Tokens';

  @override
  String get maxTokensHint => 'Maximum output tokens (e.g. 4096)';

  @override
  String get contextLength => 'Context Length';

  @override
  String get contextLengthHint => 'Number of messages to include in context';

  @override
  String get studioDescription =>
      'Configure and orchestrate your intelligent assistants here';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get webdavConfig => 'WebDAV Configuration';

  @override
  String get webdavUrl => 'WebDAV URL';

  @override
  String get webdavUrlHint => 'https://dav.example.com/dav/';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'email@example.com';

  @override
  String get passwordOrToken => 'Password / App Token';

  @override
  String get testConnection => 'Connection';

  @override
  String get backupNow => 'Backup';

  @override
  String get cloudBackupList => 'Cloud Backups';

  @override
  String get noBackupsOrNotConnected => 'No backups or not connected';

  @override
  String get restore => 'Restore';

  @override
  String get confirmRestore => 'Confirm Restore?';

  @override
  String get restoreWarning =>
      'Restore will attempt to merge cloud data to local. If conflicts exist, local data may be updated. It is recommended to backup current data first.';

  @override
  String get confirmRestoreButton => 'Confirm Restore';

  @override
  String get connectionSuccess => 'Connection successful';

  @override
  String get connectionFailed =>
      'Connection failed: please check configuration';

  @override
  String get connectionError => 'Connection error';

  @override
  String get backupSuccess => 'Backup uploaded successfully';

  @override
  String get backupFailed => 'Backup failed';

  @override
  String get restoreSuccess => 'Data restored successfully';

  @override
  String get restoreFailed => 'Restore failed';

  @override
  String get fetchBackupListFailed => 'Failed to fetch backup list';

  @override
  String get exportSuccess => 'Export successful';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get importSuccess => 'Import successful';

  @override
  String get importFailed => 'Import failed';

  @override
  String get clearDataConfirmTitle => 'Clear all data?';

  @override
  String get clearDataConfirmContent =>
      'This will permanently delete all sessions, messages, and topics. This action cannot be undone. It is recommended to export a backup first.';

  @override
  String get clearDataSuccess => 'Data cleared successfully';

  @override
  String get clearDataFailed => 'Failed to clear data';

  @override
  String get novelWritingDescription =>
      'Configure writing, review, and outline models';

  @override
  String get schedulePlanning => 'Schedule Planning';

  @override
  String get schedulePlanningDescription =>
      'Plan and manage your creative schedule';

  @override
  String get imageManagement => 'Image Management';

  @override
  String get imageManagementDescription =>
      'Organize and manage your project images';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get generating => 'Generating...';

  @override
  String get branch => 'Branch';

  @override
  String get trayShow => 'Show Application';

  @override
  String get trayExit => 'Exit Application';

  @override
  String get confirmClose => 'Confirm Close';

  @override
  String get minimizeToTray => 'Minimize to system tray?';

  @override
  String get minimize => 'Minimize';

  @override
  String get exit => 'Exit';

  @override
  String get rememberChoice => 'Remember my choice';

  @override
  String get closeBehavior => 'Close Behavior';

  @override
  String get askEveryTime => 'Ask every time';

  @override
  String get minimizeToTrayOption => 'Minimize to tray';

  @override
  String get exitApplicationOption => 'Exit application';

  @override
  String get novelPreset => 'Preset';

  @override
  String get selectPreset => 'Select Preset';

  @override
  String get noCustomPresets => 'No custom presets';

  @override
  String get systemDefault => 'System Default';

  @override
  String get systemDefaultRestored => 'System default presets restored';

  @override
  String get restoreSystemDefaultPromptHint =>
      'Restore system default preset prompt';

  @override
  String presetLoaded(String name) {
    return 'Preset loaded: $name';
  }

  @override
  String get newNovelPreset => 'New Preset';

  @override
  String get savePresetHint => 'Will save prompt configurations for all roles.';

  @override
  String presetSaved(String name) {
    return 'Preset \"$name\" saved';
  }

  @override
  String get outline => 'Outline';

  @override
  String get outlineModel => 'Outline Model';

  @override
  String get savePresetOverrideHint =>
      'Save current config and overwrite selected preset';

  @override
  String get selectiveBackup => 'Selective Backup';

  @override
  String get backupChatHistory => 'Chat History';

  @override
  String get backupChatPresets => 'Prompt Presets';

  @override
  String get backupProviderConfigs => 'Model Provider Configs';

  @override
  String get backupStudioContent => 'Studio Content';

  @override
  String get backupAppSettings => 'App Settings';

  @override
  String get backupAssistants => 'Assistants & Memory';

  @override
  String get backupKnowledgeBases => 'Knowledge Bases';

  @override
  String get backupUsageStats => 'Usage Statistics';

  @override
  String get noOptionsSelected => 'Please select at least one option to backup';

  @override
  String get pressAgainToExit => 'Press again to exit';

  @override
  String get pleaseConfigureModel =>
      'Please configure a model in settings first';

  @override
  String get version => 'Version';

  @override
  String get assistantSystem => 'Assistant';

  @override
  String get imagePayload => 'Image Parameters';

  @override
  String get aspectRatio => 'Aspect Ratio';

  @override
  String get imageSize => 'Image Size';

  @override
  String get auto => 'Auto';

  @override
  String get assistantBasicConfig => 'Basic Configuration';

  @override
  String get assistantName => 'Name';

  @override
  String get assistantDescription => 'Description';

  @override
  String get assistantCoreSettings => 'Core Settings';

  @override
  String get assistantCapabilities => 'Capabilities';

  @override
  String get assistantSkillManagement => 'Skill Management';

  @override
  String assistantSkillEnabledCount(int count) {
    return '$count skills enabled';
  }

  @override
  String get assistantLongTermMemory => 'Long-term Memory';

  @override
  String get assistantMemoryConsolidationModel => 'Memory Consolidation Model';

  @override
  String get assistantMemoryFollowCurrentChatModel =>
      'Follow current chat model';

  @override
  String get assistantMemoryGlobalDefaults => 'Memory Configuration';

  @override
  String get assistantMemoryMinNewUserTurns =>
      'Min new user turns before consolidation';

  @override
  String get assistantMemoryIdleSecondsBeforeConsolidation =>
      'Idle seconds before consolidation';

  @override
  String get assistantMemoryMaxBufferedMessages =>
      'Max buffered messages before consolidation';

  @override
  String get assistantMemoryMaxRunsPerDay => 'Max consolidation runs per day';

  @override
  String get assistantMemoryContextWindowSize =>
      'Context window size (K messages)';

  @override
  String get assistantAdvancedSettings => 'Advanced Settings';

  @override
  String get assistantSelectOrCreateHint =>
      'Select or create an assistant to start configuring';

  @override
  String get assistantKnowledgeBindingHint =>
      'When this assistant is selected, only the knowledge bases checked here are used.';

  @override
  String get assistantAvailableSkillsTitle => 'Available Skills';

  @override
  String get assistantNoSkillsAvailable => 'No available skills';

  @override
  String get assistantDeleteTitle => 'Delete Assistant';

  @override
  String assistantDeleteConfirm(String name) {
    return 'Delete assistant \"$name\"? This action cannot be undone.';
  }

  @override
  String get defaultAssistant => 'Default';

  @override
  String get noSpecificAssistant => 'No specific assistant';

  @override
  String get noAssistantDescription => 'No description';

  @override
  String get newAssistant => 'New Assistant';

  @override
  String get cropAvatarTitle => 'Crop Avatar';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get followSystem => 'Follow System';

  @override
  String switchedToTheme(String label) {
    return 'Switched to $label';
  }

  @override
  String get appTagline => 'An elegant cross-platform AI chat assistant';

  @override
  String get back => 'Back';

  @override
  String get rotate => 'Rotate';

  @override
  String translationPromptIntro(String sourceLanguage, String targetLanguage) {
    return 'You are a professional multilingual translator. Please translate the following $sourceLanguage text into $targetLanguage.';
  }

  @override
  String translationPromptIntroAuto(String targetLanguage) {
    return 'You are a professional multilingual translator. Please translate the following text into $targetLanguage.';
  }

  @override
  String get translationPromptRequirements => 'Requirements:';

  @override
  String get translationPromptRequirement1 =>
      '1. Ensure translation is accurate, natural, and idiomatic in the target language.';

  @override
  String get translationPromptRequirement2 =>
      '2. Preserve all line breaks and paragraph structure exactly as in the source.';

  @override
  String get translationPromptRequirement3 =>
      '3. Output only the translated text, without explanations, introductions, or suffixes.';

  @override
  String get translationPromptSourceText => 'Source text:';
}
