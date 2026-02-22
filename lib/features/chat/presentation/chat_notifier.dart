part of 'chat_provider.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final ChatStorage _storage;
  String _sessionId;
  final void Function(String newId)? onSessionCreated;
  final void Function()? onStateChanged;
  String _currentGenerationId = '';
  CancelToken? _currentCancelToken;
  double? _savedScrollOffset;
  final List<VoidCallback> _listeners = [];
  ChatNotifier({
    required Ref ref,
    required ChatStorage storage,
    required String sessionId,
    this.onSessionCreated,
    this.onStateChanged,
  })  : _ref = ref,
        _storage = storage,
        _sessionId = sessionId,
        super(const ChatState()) {
    if (_sessionId != 'chat' && _sessionId != 'new_chat') {
      _loadHistory();
    }
  }
  void addLocalListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeLocalListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyLocalListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  bool _isDisposed = false;
  @override
  bool get mounted => !_isDisposed;
  String get currentModel {
    // Assistant specific model config removed per user request
    return _ref.read(settingsProvider).activeProvider.selectedModel ?? '';
  }

  String get currentProvider {
    // Assistant specific provider config removed per user request
    return _ref.read(settingsProvider).activeProviderId;
  }

  @override
  set state(ChatState value) {
    if (_isDisposed) return;
    super.state = value;
    onStateChanged?.call();
    _notifyLocalListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _currentCancelToken?.cancel();
    _currentCancelToken = null;
    super.dispose();
  }

  ChatState get currentState => state;
  double? get savedScrollOffset => _savedScrollOffset;
  void setAutoScrollEnabled(bool enabled) {
    if (state.isAutoScrollEnabled != enabled) {
      state = state.copyWith(isAutoScrollEnabled: enabled);
    }
  }

  void saveScrollOffset(double offset) {
    _savedScrollOffset = offset;
  }

  void abortGeneration() {
    _currentGenerationId = '';
    _currentCancelToken?.cancel('User aborted generation');
    _currentCancelToken = null;
    state = state.copyWith(isLoading: false);
  }

  void markAsRead() {
    if (state.hasUnreadResponse) {
      state = state.copyWith(hasUnreadResponse: false);
    }
  }

  Future<void> _loadHistory() async {
    await Future.microtask(() {});
    if (!mounted) return;
    state = state.copyWith(isLoadingHistory: true);
    if (_sessionId == 'translation') {
      await _storage.sanitizeTranslationUserMessages();
    }
    final messages = await _storage.loadHistory(_sessionId);
    if (!mounted) return;
    String? restoredPresetName;
    final session = await _storage.getSession(_sessionId);
    // Only restore Preset name for display purposes; Assistant is now global.
    if (session?.presetId != null && session!.presetId!.isNotEmpty) {
      final presets = _ref.read(settingsProvider).presets;
      final match = presets.where((p) => p.id == session.presetId);
      if (match.isNotEmpty) {
        restoredPresetName = match.first.name;
      }
    } else {
      // Fallback: try to match system prompt to a preset
      final systemMsg = messages.where((m) => m.role == 'system').firstOrNull;
      if (systemMsg != null) {
        final presets = _ref.read(settingsProvider).presets;
        final match = presets.where((p) => p.systemPrompt == systemMsg.content);
        if (match.isNotEmpty) {
          restoredPresetName = match.first.name;
        }
      }
    }
    state = state.copyWith(
      messages: messages,
      isLoadingHistory: false,
      activePresetName: restoredPresetName,
    );
  }

  Future<String> sendMessage(String? text,
      {List<String> attachments = const [], String? apiContent}) async {
    if (!mounted) return _sessionId;

    if (state.isLoading && text != null) {
      return _sessionId;
    }
    if (text != null && text.trim().isEmpty && attachments.isEmpty) {
      return _sessionId;
    }

    final generationId = const Uuid().v4();
    _startGeneration(generationId);

    final sessionPreparation = await _prepareSessionForMessage(text);
    if (sessionPreparation.earlyReturnSessionId != null) {
      return sessionPreparation.earlyReturnSessionId!;
    }
    if (!mounted) return _sessionId;

    final assistant = _resolveSelectedAssistant();
    final assistantIdForRequest = assistant?.id;

    if (text != null) {
      final appended = await _appendUserMessageForRequest(
        text: text,
        attachments: attachments,
        generationId: generationId,
        assistantIdForRequest: assistantIdForRequest,
      );
      if (!appended) return _sessionId;
    }

    if (sessionPreparation.newRealId != null &&
        sessionPreparation.oldId == 'new_chat' &&
        onSessionCreated != null) {
      onSessionCreated!(sessionPreparation.newRealId!);
    }

    onStateChanged?.call();
    state =
        state.copyWith(isLoading: true, error: null, hasUnreadResponse: false);
    final startSaveIndex = state.messages.length;
    final startTime = DateTime.now();

    try {
      final requestContext = await _ChatRequestContextBuilder(notifier: this)
          .build(text: text, apiContent: apiContent, assistant: assistant);
      if (!mounted || _currentGenerationId != generationId) {
        return _sessionId;
      }

      final initialAiMessage = _createInitialAiMessage(
        model: requestContext.currentModel,
        provider: requestContext.currentProviderName,
        generationId: generationId,
        assistantIdForRequest: assistantIdForRequest,
      );
      _appendMessage(initialAiMessage);

      final orchestrator = _ChatGenerationOrchestrator(
        notifier: this,
        requestContext: requestContext,
        generationId: generationId,
        startTime: startTime,
        recordMainModelUsage: ({
          required bool success,
          required int durationMs,
          int firstTokenMs = 0,
          int tokenCount = 0,
          int promptTokens = 0,
          int completionTokens = 0,
          int reasoningTokens = 0,
          AppErrorType? errorType,
        }) {
          final currentModel = requestContext.currentModel;
          if (currentModel == null || currentModel.isEmpty) return;
          _ref.read(usageStatsProvider.notifier).incrementUsage(
                currentModel,
                success: success,
                durationMs: durationMs,
                firstTokenMs: firstTokenMs,
                tokenCount: tokenCount,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                reasoningTokens: reasoningTokens,
                errorType: errorType,
              );
        },
      );

      final generationResult =
          await orchestrator.runTurnLoop(initialAiMessage: initialAiMessage);

      final persistedAiMessage = await _ChatPersistence(notifier: this).persist(
        generationId: generationId,
        startSaveIndex: startSaveIndex,
        startTime: startTime,
        firstContentTime: generationResult.firstContentTime,
        assistantIdForRequest: assistantIdForRequest,
        promptTokens: generationResult.promptTokens,
        completionTokens: generationResult.completionTokens,
        reasoningTokens: generationResult.reasoningTokens,
        aiMessage: generationResult.aiMessage,
      );

      if (_currentGenerationId == generationId &&
          assistant != null &&
          assistant.enableMemory &&
          persistedAiMessage.content.trim().isNotEmpty) {
        unawaited(
          _ref.read(assistantMemoryServiceProvider).onRequestCompleted(
                assistant: assistant,
                settings: requestContext.settings,
                requestId: generationId,
              ),
        );
      }

      if (_currentGenerationId == generationId) {
        final activeProvider = requestContext.settings.activeProvider;
        if (activeProvider.autoRotateKeys &&
            activeProvider.apiKeys.length > 1) {
          _ref.read(settingsProvider.notifier).rotateApiKey(activeProvider.id);
        }
      }
    } catch (e) {
      _handleSendMessageError(
        error: e,
        generationId: generationId,
        startTime: startTime,
      );
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }

    return _sessionId;
  }

  void _startGeneration(String generationId) {
    _currentGenerationId = generationId;
    _currentCancelToken?.cancel();
    _currentCancelToken = CancelToken();
  }

  Future<_SessionPreparationResult> _prepareSessionForMessage(
      String? text) async {
    final oldId = _sessionId;
    String? newRealId;

    if (text != null && (_sessionId == 'chat' || _sessionId == 'new_chat')) {
      final title = text.length > 15 ? '${text.substring(0, 15)}...' : text;
      final topicId = _ref.read(selectedTopicIdProvider);
      final realId = await _storage.createSession(
        title: title,
        topicId: topicId,
        presetId: '',
      );

      if (!mounted) {
        return _SessionPreparationResult(
          oldId: oldId,
          earlyReturnSessionId: realId,
        );
      }

      _sessionId = realId;
      newRealId = realId;

      _generateTopic(text).then((smartTitle) async {
        if (smartTitle != title && smartTitle.isNotEmpty) {
          await _storage.updateSessionTitle(realId, smartTitle);
          _ref.read(sessionsProvider.notifier).loadSessions();
        }
      });
    } else if (text != null && state.messages.isEmpty) {
      if (!mounted) {
        return _SessionPreparationResult(
          oldId: oldId,
          earlyReturnSessionId: _sessionId,
        );
      }

      final title = text.length > 15 ? '${text.substring(0, 15)}...' : text;
      await _storage.updateSessionTitle(_sessionId, title);

      if (!mounted) {
        return _SessionPreparationResult(
          oldId: oldId,
          earlyReturnSessionId: _sessionId,
        );
      }

      _ref.read(sessionsProvider.notifier).loadSessions();
      final currentSessionId = _sessionId;
      _generateTopic(text).then((smartTitle) async {
        if (!mounted) return;
        if (smartTitle != title && smartTitle.isNotEmpty) {
          await _storage.updateSessionTitle(currentSessionId, smartTitle);
          if (!mounted) return;
          _ref.read(sessionsProvider.notifier).loadSessions();
        }
      });
    }

    return _SessionPreparationResult(oldId: oldId, newRealId: newRealId);
  }

  Future<bool> _appendUserMessageForRequest({
    required String text,
    required List<String> attachments,
    required String generationId,
    required String? assistantIdForRequest,
  }) async {
    if (!mounted) return false;

    final userMessage = Message.user(text, attachments: attachments).copyWith(
      assistantId: assistantIdForRequest,
      requestId: generationId,
    );
    final dbId = await _storage.saveMessage(userMessage, _sessionId);

    if (!mounted) return false;

    final userMessageWithDbId = userMessage.copyWith(id: dbId);
    state = state.copyWith(messages: [...state.messages, userMessageWithDbId]);
    if (_sessionId != 'translation') {
      _ref.read(sessionsProvider.notifier).loadSessions();
    }
    return true;
  }

  Assistant? _resolveSelectedAssistant() {
    final assistantState = _ref.read(assistantProvider);
    if (assistantState.selectedAssistantId == null) {
      return null;
    }
    return assistantState.assistants
        .where((a) => a.id == assistantState.selectedAssistantId)
        .firstOrNull;
  }

  Message _createInitialAiMessage({
    required String? model,
    required String provider,
    required String generationId,
    required String? assistantIdForRequest,
  }) {
    return Message.ai('', model: model, provider: provider).copyWith(
      assistantId: assistantIdForRequest,
      requestId: generationId,
    );
  }

  void _appendMessage(Message message) {
    if (!mounted) return;
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void _upsertTrailingMessage(Message message) {
    final newMessages = List<Message>.from(state.messages);
    if (newMessages.isNotEmpty && newMessages.last.id == message.id) {
      newMessages.removeLast();
    }
    newMessages.add(message);
    if (mounted) {
      state = state.copyWith(messages: newMessages);
    }
  }

  void _setMessages(List<Message> messages) {
    if (!mounted) return;
    state = state.copyWith(messages: messages);
  }

  void _setMessagesWithLoading({
    required List<Message> messages,
    required bool isLoading,
    required bool hasUnreadResponse,
  }) {
    if (!mounted) return;
    state = state.copyWith(
      messages: messages,
      isLoading: isLoading,
      hasUnreadResponse: hasUnreadResponse,
    );
  }

  void _setLoadingAndUnread({
    required bool isLoading,
    required bool hasUnreadResponse,
  }) {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: isLoading,
      hasUnreadResponse: hasUnreadResponse,
    );
  }

  void _recordExecutionModelUsage({
    required SettingsState settings,
    required bool success,
    required int promptTokens,
    required int completionTokens,
    required int reasoningTokens,
    required int durationMs,
    AppErrorType? errorType,
  }) {
    final executionModel = settings.executionModel;
    if (executionModel == null || executionModel.isEmpty) return;

    _ref.read(usageStatsProvider.notifier).incrementUsage(
          executionModel,
          success: success,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          reasoningTokens: reasoningTokens,
          durationMs: durationMs,
          errorType: errorType,
        );
  }

  void _handleSendMessageError({
    required Object error,
    required String generationId,
    required DateTime startTime,
  }) {
    if (_currentGenerationId != generationId || !mounted) return;

    var errorMessage = error.toString();
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring(11);
    }

    final messages = List<Message>.from(state.messages);
    if (messages.isNotEmpty && !messages.last.isUser) {
      final lastMsg = messages.last;
      final language = _ref.read(settingsProvider).language;
      final requestFailedTitle = language == 'zh' ? '请求失败' : 'Request failed';
      messages[messages.length - 1] = Message(
        id: lastMsg.id,
        content: '⚠️ **$requestFailedTitle**\n\n$errorMessage',
        isUser: false,
        timestamp: lastMsg.timestamp,
        model: lastMsg.model,
        provider: lastMsg.provider,
      );
    }

    if (mounted) {
      state = state.copyWith(
          messages: messages, isLoading: false, error: errorMessage);
    }

    final currentModel =
        _ref.read(settingsProvider).activeProvider.selectedModel;
    if (currentModel == null || currentModel.isEmpty) {
      return;
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    var errorType = AppErrorType.unknown;
    if (error is AppException) {
      errorType = error.type;
    }

    _ref.read(usageStatsProvider.notifier).incrementUsage(
          currentModel,
          success: false,
          durationMs: duration,
          errorType: errorType,
        );

    if (error is AppException) {
      final shouldRotate = errorType == AppErrorType.unauthorized ||
          errorType == AppErrorType.rateLimit;
      if (shouldRotate) {
        final provider = _ref.read(settingsProvider).activeProvider;
        if (provider.apiKeys.length > 1) {
          _ref.read(settingsProvider.notifier).rotateApiKey(provider.id);
        }
      }
    }
  }

  int _resolveOrchestratorMaxTurns(SettingsState settings) {
    return _resolveTurnLimit(
      sources: [
        settings.activeProvider.customParameters,
        settings.activeProvider.globalSettings,
      ],
      keys: const [
        'orchestrator_max_turns',
        'orchestratorMaxTurns',
        '_aurora_max_turns',
        'max_turns',
        'maxTurns',
      ],
      fallback: 8,
      min: 1,
      max: 50,
    );
  }

  int _resolveSkillWorkerMaxTurns(SettingsState settings, {Skill? skill}) {
    final sources = <Map<String, dynamic>>[];
    if (skill != null) {
      sources.add(skill.metadata);
    }
    sources.add(settings.activeProvider.customParameters);
    sources.add(settings.activeProvider.globalSettings);

    return _resolveTurnLimit(
      sources: sources,
      keys: const [
        'skill_max_turns',
        'skillMaxTurns',
        'worker_max_turns',
        'workerMaxTurns',
        'subagent_max_turns',
        'subagentMaxTurns',
        '_aurora_skill_max_turns',
        'max_turns',
        'maxTurns',
      ],
      fallback: 10,
      min: 1,
      max: 30,
    );
  }

  SkillWorkerMode _resolveSkillWorkerMode(SettingsState settings,
      {Skill? skill}) {
    final sources = <Map<String, dynamic>>[];
    if (skill != null) {
      sources.add(skill.metadata);
    }
    sources.add(settings.activeProvider.customParameters);
    sources.add(settings.activeProvider.globalSettings);

    return _resolveWorkerMode(
          sources: sources,
          keys: const [
            'worker_mode',
            'workerMode',
            'skill_worker_mode',
            'skillWorkerMode',
            'subagent_mode',
            'subagentMode',
            '_aurora_worker_mode',
            '_aurora_skill_worker_mode',
          ],
        ) ??
        SkillWorkerMode.reasoner;
  }

  SkillWorkerMode? _resolveWorkerMode({
    required List<Map<String, dynamic>> sources,
    required List<String> keys,
  }) {
    for (final source in sources) {
      for (final key in keys) {
        if (!source.containsKey(key)) continue;
        final parsed = _parseWorkerMode(source[key]);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  SkillWorkerMode? _parseWorkerMode(dynamic value) {
    if (value is! String) return null;
    switch (value.trim().toLowerCase()) {
      case 'executor':
      case 'execute':
      case 'tool_executor':
      case 'tool-executor':
        return SkillWorkerMode.executor;
      case 'reasoner':
      case 'reason':
      case 'planner':
        return SkillWorkerMode.reasoner;
      default:
        return null;
    }
  }

  int _resolveTurnLimit({
    required List<Map<String, dynamic>> sources,
    required List<String> keys,
    required int fallback,
    required int min,
    required int max,
  }) {
    for (final source in sources) {
      for (final key in keys) {
        if (!source.containsKey(key)) continue;
        final parsed = _parsePositiveInt(source[key]);
        if (parsed != null) {
          return parsed.clamp(min, max).toInt();
        }
      }
    }
    return fallback.clamp(min, max).toInt();
  }

  int? _parsePositiveInt(dynamic value) {
    if (value is int) return value > 0 ? value : null;
    if (value is num) {
      final n = value.toInt();
      return n > 0 ? n : null;
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  List<ToolCall>? _mergeToolCalls(
      List<ToolCall>? existing, List<ToolCallChunk>? chunks) {
    if (chunks == null || chunks.isEmpty) return existing;
    final merged =
        existing != null ? List<ToolCall>.from(existing) : <ToolCall>[];
    for (final chunk in chunks) {
      final index = chunk.index ?? 0;
      if (index >= merged.length) {
        merged.add(ToolCall(
            id: chunk.id ?? '',
            type: chunk.type ?? 'function',
            name: chunk.name ?? '',
            arguments: chunk.arguments ?? ''));
      } else {
        final prev = merged[index];
        merged[index] = ToolCall(
            id: (prev.id == '' ? (chunk.id ?? '') : prev.id),
            type: (prev.type == 'function'
                ? (chunk.type ?? 'function')
                : prev.type),
            name: prev.name + (chunk.name ?? ''),
            arguments: prev.arguments + (chunk.arguments ?? ''));
      }
    }
    return merged;
  }

  Future<void> deleteMessage(String id) async {
    final newMessages = state.messages.where((m) => m.id != id).toList();
    state = state.copyWith(messages: newMessages);
    await _storage.deleteMessage(id, sessionId: _sessionId);
    if (_sessionId != 'translation') {
      _ref.read(sessionsProvider.notifier).loadSessions();
    }
  }

  Future<void> editMessage(String id, String newContent,
      {List<String>? newAttachments}) async {
    final index = state.messages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final oldMsg = state.messages[index];
    final updatedAttachments = newAttachments ?? oldMsg.attachments;
    final newMsg = Message(
      id: oldMsg.id,
      content: newContent,
      isUser: oldMsg.isUser,
      timestamp: oldMsg.timestamp,
      reasoningContent: oldMsg.reasoningContent,
      attachments: updatedAttachments,
      images: newAttachments != null ? const [] : oldMsg.images,
    );
    final newMessages = List<Message>.from(state.messages);
    newMessages[index] = newMsg;
    state = state.copyWith(messages: newMessages);
    await _storage.updateMessage(newMsg);
  }

  Future<void> regenerateResponse(String rootMessageId) async {
    final index = state.messages.indexWhere((m) => m.id == rootMessageId);
    if (index == -1) return;
    abortGeneration();
    await Future.delayed(const Duration(milliseconds: 100));
    final rootMsg = state.messages[index];
    List<Message> historyToKeep;

    // Determine the user message to update
    Message? userMsgToUpdate;

    if (rootMsg.isUser) {
      historyToKeep = state.messages.sublist(0, index + 1);
      userMsgToUpdate = rootMsg;
    } else {
      if (index == 0) return;
      historyToKeep = state.messages.sublist(0, index);
      // The last message in historyToKeep (which is index - 1 in original list) is the user message
      userMsgToUpdate = historyToKeep.last;
    }

    if (userMsgToUpdate.isUser) {
      final updatedUserMsg =
          userMsgToUpdate.copyWith(timestamp: DateTime.now());
      await _storage.updateMessage(updatedUserMsg);
      historyToKeep[historyToKeep.length - 1] = updatedUserMsg;
      _ref.read(sessionsProvider.notifier).loadSessions();
    }

    final oldMessages = state.messages;
    state = state.copyWith(
        messages: historyToKeep,
        isLoading: true,
        error: null,
        isAutoScrollEnabled: true);
    final idsToDelete =
        oldMessages.skip(historyToKeep.length).map((m) => m.id).toList();
    for (final mid in idsToDelete) {
      await _storage.deleteMessage(mid, sessionId: _sessionId);
    }
    if (_sessionId != 'translation') {
      await _ref.read(sessionsProvider.notifier).loadSessions();
    }
    await sendMessage(null);
  }

  Future<void> clearContext() async {
    if (_sessionId == 'new_chat') {
      state = state.copyWith(messages: [], isLoading: false, error: null);
      return;
    }
    if (_sessionId == 'translation') {
      await _storage.clearSessionMessages(_sessionId);
      state = state.copyWith(messages: [], isLoading: false, error: null);
      return;
    }
    await _storage.clearSessionMessages(_sessionId);
    state = state.copyWith(messages: []);
  }

  void toggleSearch() {
    _ref.read(settingsProvider.notifier).toggleSearchEnabled();
  }

  Future<void> _updateSystemMessageInternal(String template) async {
    final settingsState = _ref.read(settingsProvider);
    final user = settingsState.userName;
    final system = Platform.operatingSystem;
    final lang = settingsState.language;
    String deviceName = Platform.localHostname;
    String clipboardContent = '';
    if (template.contains('{clipboard}')) {
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        clipboardContent = data?.text ?? '';
      } catch (e) {
        debugPrint('Failed to get clipboard data: $e');
      }
    }
    String prompt = template
        .replaceAll('{time}', DateTime.now().toString())
        .replaceAll('{user_name}', user)
        .replaceAll('{system}', system)
        .replaceAll('{device}', deviceName)
        .replaceAll('{language}', lang)
        .replaceAll('{clipboard}', clipboardContent);
    final messages = List<Message>.from(state.messages);
    final index = messages.indexWhere((m) => m.role == 'system');
    if (index != -1) {
      final oldMsg = messages[index];
      final newMsg = oldMsg.copyWith(content: prompt);
      messages[index] = newMsg;
      await _storage.updateMessage(newMsg);
    } else {
      final newMsg = Message(
        id: const Uuid().v4(),
        role: 'system',
        content: prompt,
        timestamp: DateTime.now(),
        isUser: false,
      );
      messages.insert(0, newMsg);
      await _storage.saveMessage(newMsg, _sessionId);
    }
    state = state.copyWith(messages: messages);
  }

  Future<void> updateSystemPrompt(String template, [String? presetName]) async {
    await _updateSystemMessageInternal(template);

    // Preset Mode: Activate Preset
    state = state.copyWith(
      activePresetName: presetName,
    );

    debugPrint(
        '[PresetSave] updateSystemPrompt called with presetName: $presetName, sessionId: $_sessionId');
    if (presetName != null) {
      final settingsState = _ref.read(settingsProvider);
      final presets = settingsState.presets;
      final match = presets.where((p) => p.name == presetName);
      if (match.isNotEmpty) {
        final newPresetId = match.first.id;
        if (_sessionId != 'chat' && _sessionId != 'new_chat') {
          await _storage.updateSessionPreset(_sessionId, newPresetId);
        }
      }
    } else {
      if (_sessionId != 'chat' && _sessionId != 'new_chat') {
        await _storage.updateSessionPreset(_sessionId, '');
      }
    }
    // Force global trigger update for indicators
    _ref.read(chatStateUpdateTriggerProvider.notifier).state++;
  }

  void setSearchEngine(SearchEngine engine) {
    _ref.read(settingsProvider.notifier).setSearchEngine(engine.name);
  }

  Future<String> _generateTopic(String text) async {
    final settings = _ref.read(settingsProvider);
    if (!settings.enableSmartTopic || settings.topicGenerationModel == null) {
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final parts = settings.topicGenerationModel!.split('@');
    if (parts.length != 2) {
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final providerId = parts[0];
    final modelId = parts[1];
    final imageModelRegex = RegExp(
      r'(dall-e|gpt-image|midjourney|mj-|flux|stable-diffusion|sd-|sdxl|imagen|cogview|qwen-image)',
      caseSensitive: false,
    );
    if (imageModelRegex.hasMatch(modelId)) {
      debugPrint(
          'Skipping smart topic generation: Image model detected ($modelId)');
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final providerIndex =
        settings.providers.indexWhere((p) => p.id == providerId);
    if (providerIndex == -1) {
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final provider = settings.providers[providerIndex];
    if (!provider.isEnabled ||
        !provider.models.contains(modelId) ||
        !provider.isModelEnabled(modelId)) {
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final tempProviders = List<ProviderConfig>.from(settings.providers);
    tempProviders[providerIndex] =
        tempProviders[providerIndex].copyWith(selectedModel: modelId);
    final tempSettings = settings.copyWith(
      activeProviderId: providerId,
      providers: tempProviders,
    );
    final tempLLMService = ModelRoutedLlmService(tempSettings);
    try {
      final inputContent = text.length > 3000 ? text.substring(0, 3000) : text;
      final prompt =
          '''Analyze the conversation in <content> and generate a concise title.
Rules:
1. Language: Use the same language as the conversation.
2. Length: Max 10 characters or 5 words.
3. Style: Concise, no punctuation, no special symbols.
4. Output: The title text only.
<content>
$inputContent
</content>''';
      final response = await tempLLMService.getResponse([Message.user(prompt)]);
      final generatedTitle = response.content?.trim() ?? '';
      if (generatedTitle.isNotEmpty) {
        var cleanTitle = generatedTitle.replaceAll('"', '').replaceAll("'", "");
        if (cleanTitle.length > 20) {
          cleanTitle = cleanTitle.substring(0, 20);
        }
        return cleanTitle;
      }
    } catch (e) {
      debugPrint('Error generating topic: $e');
    }
    return text.length > 15 ? '${text.substring(0, 15)}...' : text;
  }
}

class _SessionPreparationResult {
  final String oldId;
  final String? newRealId;
  final String? earlyReturnSessionId;

  const _SessionPreparationResult({
    required this.oldId,
    this.newRealId,
    this.earlyReturnSessionId,
  });
}
