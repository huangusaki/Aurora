part of 'chat_provider.dart';

class _ChatActionResult {
  final bool continueGeneration;
  final Message aiMessage;

  const _ChatActionResult({
    required this.continueGeneration,
    required this.aiMessage,
  });

  factory _ChatActionResult.stop(Message aiMessage) {
    return _ChatActionResult(continueGeneration: false, aiMessage: aiMessage);
  }

  factory _ChatActionResult.continueWith(Message aiMessage) {
    return _ChatActionResult(continueGeneration: true, aiMessage: aiMessage);
  }
}

class _ChatActionExecutor {
  static final RegExp _searchPattern =
      RegExp(r'<search>(.*?)</search>', dotAll: true);
  static final RegExp _skillPattern =
      RegExp(r'''<skill\s+name=["'](.*?)["']>(.*?)</skill>''', dotAll: true);

  final ChatNotifier _notifier;
  final _ChatRequestContext _requestContext;
  final String _generationId;

  const _ChatActionExecutor({
    required ChatNotifier notifier,
    required _ChatRequestContext requestContext,
    required String generationId,
  })  : _notifier = notifier,
        _requestContext = requestContext,
        _generationId = generationId;

  bool get _isGenerationActive =>
      _notifier.mounted && _notifier._currentGenerationId == _generationId;

  Future<_ChatActionResult> execute(Message aiMsg) async {
    final searchMatch = _searchPattern.firstMatch(aiMsg.content);
    if (searchMatch != null) {
      if (!_requestContext.allowLegacySearchTool) {
        return _ChatActionResult.stop(
            _cleanTagFromDisplay(aiMsg, _searchPattern));
      }
      return _handleSearch(aiMsg, searchMatch);
    }

    final skillMatch = _skillPattern.firstMatch(aiMsg.content);
    if (skillMatch != null) {
      return _handleSkillTag(aiMsg, skillMatch);
    }

    if (aiMsg.toolCalls != null && aiMsg.toolCalls!.isNotEmpty) {
      return _handleLegacyToolCalls(aiMsg);
    }

    return _ChatActionResult.stop(aiMsg);
  }

  Future<_ChatActionResult> _handleSearch(
      Message aiMsg, RegExpMatch searchMatch) async {
    final searchQuery = searchMatch.group(1)?.trim() ?? '';
    if (searchQuery.isEmpty || !_isGenerationActive) {
      return _ChatActionResult.stop(aiMsg);
    }

    aiMsg = _cleanTagFromDisplay(aiMsg, _searchPattern);

    String searchResult;
    try {
      searchResult = await _requestContext.toolManager.executeTool(
        'SearchWeb',
        {'query': searchQuery},
        preferredEngine: _requestContext.settings.searchEngine,
        skills: _requestContext.activeSkills,
      );
    } catch (e) {
      searchResult = jsonEncode({'error': e.toString()});
    }

    if (!_isGenerationActive) {
      return _ChatActionResult.stop(aiMsg);
    }

    final toolCallId = 'search_${const Uuid().v4().substring(0, 8)}';
    final toolMsg = Message.tool(searchResult, toolCallId: toolCallId);
    _notifier._appendMessage(toolMsg);

    _requestContext.messagesForApi
        .add(aiMsg.copyWith(content: '<search>$searchQuery</search>'));
    _requestContext.messagesForApi.add(
      Message(
        id: const Uuid().v4(),
        role: 'user',
        content:
            '<result name="SearchWeb">\n$searchResult\n</result>\n\nPlease synthesize the above results.',
        timestamp: DateTime.now(),
        isUser: false,
      ),
    );

    final nextAi = Message.ai('',
        model: _requestContext.currentModel,
        provider: _requestContext.currentProviderName);
    _notifier._appendMessage(nextAi);

    return _ChatActionResult.continueWith(nextAi);
  }

  Future<_ChatActionResult> _handleSkillTag(
      Message aiMsg, RegExpMatch skillMatch) async {
    final skillName = skillMatch.group(1)?.trim() ?? '';
    final skillQuery = skillMatch.group(2)?.trim() ?? '';
    if (skillName.isEmpty || !_isGenerationActive) {
      return _ChatActionResult.stop(aiMsg);
    }

    aiMsg = _cleanTagFromDisplay(aiMsg, _skillPattern);

    final originalUserMsg = _notifier.currentState.messages
        .lastWhere((m) => m.isUser, orElse: () => Message.user(''));

    String executionResult;
    try {
      final allowedSkills = _requestContext.activeSkills;
      final skill = allowedSkills.firstWhere(
        (s) => s.name == skillName,
        orElse: () => throw Exception(
            'Skill "$skillName" not found. Allowed: ${allowedSkills.map((s) => s.name).join(', ')}'),
      );
      executionResult = await _executeSkill(
        skill: skill,
        query: skillQuery,
        originalRequest: originalUserMsg.content,
      );
    } catch (e) {
      executionResult = 'Error executing skill: $e';
    }

    if (!_isGenerationActive) {
      return _ChatActionResult.stop(aiMsg);
    }

    _requestContext.messagesForApi.add(aiMsg.copyWith(
        content: '<skill name="$skillName">$skillQuery</skill>'));
    _requestContext.messagesForApi.add(
      Message(
        id: const Uuid().v4(),
        role: 'user',
        content:
            '<result name="$skillName">\n$executionResult\n</result>\n\nPlease provide a final human-readable response based only on the above result. If the result JSON includes `exitCode` != 0, non-empty `stderr`, or an `error` field, explicitly report execution failure and include the key error message. Do not claim success unless the result clearly indicates success.',
        timestamp: DateTime.now(),
        isUser: false,
      ),
    );

    final nextAi = Message.ai('',
        model: _requestContext.currentModel,
        provider: _requestContext.currentProviderName);
    _notifier._appendMessage(nextAi);

    return _ChatActionResult.continueWith(nextAi);
  }

  Future<_ChatActionResult> _handleLegacyToolCalls(Message aiMsg) async {
    if (!_isGenerationActive) {
      return _ChatActionResult.stop(aiMsg);
    }

    _requestContext.messagesForApi.add(aiMsg);

    for (final tc in aiMsg.toolCalls!) {
      String toolResult;
      try {
        if (tc.name == 'call_skill') {
          toolResult = await _executeLegacySkillCall(tc.arguments);
        } else {
          final args = jsonDecode(tc.arguments);
          toolResult = await _requestContext.toolManager.executeTool(
            tc.name,
            args,
            preferredEngine: _requestContext.settings.searchEngine,
            skills: _requestContext.activeSkills,
          );
        }
      } catch (e) {
        toolResult = jsonEncode({'error': e.toString()});
      }

      if (!_isGenerationActive) {
        return _ChatActionResult.stop(aiMsg);
      }

      final toolMsg = Message.tool(toolResult, toolCallId: tc.id);
      _requestContext.messagesForApi.add(toolMsg);
      _notifier._appendMessage(toolMsg);
    }

    final nextAi = Message.ai('',
        model: _requestContext.currentModel,
        provider: _requestContext.currentProviderName);
    _notifier._appendMessage(nextAi);
    return _ChatActionResult.continueWith(nextAi);
  }

  Future<String> _executeLegacySkillCall(String rawArguments) async {
    final args = _decodeSkillArgs(rawArguments);

    var skillName = args['skill_name'];
    if (skillName == null && args.containsKey('skill_args')) {
      final nested = args['skill_args'];
      if (nested is Map) {
        skillName = nested['skill_name'];
      } else if (nested is String) {
        try {
          final nestedMap = jsonDecode(nested);
          skillName = nestedMap['skill_name'];
        } catch (_) {
          // Ignore malformed nested skill args.
        }
      }
    }

    var query =
        args['query'] ?? args['request'] ?? args['task'] ?? args['content'];
    if (query == null) {
      final fallback = Map<String, dynamic>.from(args);
      fallback.remove('skill_name');
      query = jsonEncode(fallback);
    }

    final allowedSkills = _requestContext.activeSkills;
    final skill = allowedSkills.firstWhere(
      (s) => s.name == skillName,
      orElse: () => throw Exception(
          'Skill "$skillName" not found. Allowed: ${allowedSkills.map((s) => s.name).join(', ')}'),
    );

    return _executeSkill(skill: skill, query: query.toString());
  }

  Map<String, dynamic> _decodeSkillArgs(String rawArguments) {
    if (rawArguments.startsWith('{')) {
      return jsonDecode(rawArguments);
    }

    try {
      return jsonDecode(rawArguments);
    } catch (_) {
      return {'query': rawArguments, 'skill_name': 'unknown'};
    }
  }

  Future<String> _executeSkill({
    required Skill skill,
    required String query,
    String? originalRequest,
  }) async {
    final workerService = WorkerService(_requestContext.llmService);
    return workerService.executeSkillTask(
      skill,
      query,
      originalRequest: originalRequest,
      model: _requestContext.settings.executionModel,
      providerId: _requestContext.settings.executionProviderId,
      maxTurns: _notifier._resolveSkillWorkerMaxTurns(_requestContext.settings,
          skill: skill),
      mode: _notifier._resolveSkillWorkerMode(_requestContext.settings,
          skill: skill),
      onUsage: ({
        required bool success,
        required int promptTokens,
        required int completionTokens,
        required int reasoningTokens,
        required int durationMs,
        AppErrorType? errorType,
      }) {
        _notifier._recordExecutionModelUsage(
          settings: _requestContext.settings,
          success: success,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          reasoningTokens: reasoningTokens,
          durationMs: durationMs,
          errorType: errorType,
        );
      },
    );
  }

  Message _cleanTagFromDisplay(Message aiMsg, RegExp pattern) {
    final cleaned =
        aiMsg.copyWith(content: aiMsg.content.replaceAll(pattern, '').trim());
    _notifier._upsertTrailingMessage(cleaned);
    return cleaned;
  }
}
