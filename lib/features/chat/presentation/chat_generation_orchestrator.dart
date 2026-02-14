part of 'chat_provider.dart';

typedef _MainUsageRecorder = void Function({
  required bool success,
  required int durationMs,
  int firstTokenMs,
  int tokenCount,
  int promptTokens,
  int completionTokens,
  int reasoningTokens,
  AppErrorType? errorType,
});

class _ChatGenerationResult {
  final Message aiMessage;
  final int promptTokens;
  final int completionTokens;
  final int reasoningTokens;
  final DateTime? firstContentTime;
  final int turns;

  const _ChatGenerationResult({
    required this.aiMessage,
    required this.promptTokens,
    required this.completionTokens,
    required this.reasoningTokens,
    required this.firstContentTime,
    required this.turns,
  });
}

class _ChatTurnResult {
  final Message aiMessage;
  final int turnDurationMs;
  final int turnFirstTokenMs;
  final int turnTokenCount;
  final int turnPromptTokens;
  final int turnCompletionTokens;
  final int turnReasoningTokens;
  final DateTime? firstContentTime;

  const _ChatTurnResult({
    required this.aiMessage,
    required this.turnDurationMs,
    required this.turnFirstTokenMs,
    required this.turnTokenCount,
    required this.turnPromptTokens,
    required this.turnCompletionTokens,
    required this.turnReasoningTokens,
    required this.firstContentTime,
  });
}

class _ChatGenerationOrchestrator {
  final ChatNotifier _notifier;
  final _ChatRequestContext _requestContext;
  final String _generationId;
  final DateTime _startTime;
  final _MainUsageRecorder _recordMainModelUsage;

  int _promptTokens = 0;
  int _completionTokens = 0;
  int _reasoningTokens = 0;
  DateTime? _firstContentTime;

  _ChatGenerationOrchestrator({
    required ChatNotifier notifier,
    required _ChatRequestContext requestContext,
    required String generationId,
    required DateTime startTime,
    required _MainUsageRecorder recordMainModelUsage,
  })  : _notifier = notifier,
        _requestContext = requestContext,
        _generationId = generationId,
        _startTime = startTime,
        _recordMainModelUsage = recordMainModelUsage;

  bool get _isGenerationActive =>
      _notifier.mounted && _notifier._currentGenerationId == _generationId;

  Future<_ChatGenerationResult> runTurnLoop({
    required Message initialAiMessage,
  }) async {
    final maxOrchestratorTurns =
        _notifier._resolveOrchestratorMaxTurns(_requestContext.settings);
    final actionExecutor = _ChatActionExecutor(
      notifier: _notifier,
      requestContext: _requestContext,
      generationId: _generationId,
    );

    var continueGeneration = true;
    var turns = 0;
    var aiMsg = initialAiMessage;

    while (continueGeneration &&
        turns < maxOrchestratorTurns &&
        _isGenerationActive) {
      turns++;
      continueGeneration = false;

      final turnResult = _requestContext.settings.isStreamEnabled
          ? await _runStreamingTurn(aiMsg)
          : await _runNonStreamingTurn(aiMsg);

      aiMsg = turnResult.aiMessage;
      _firstContentTime = turnResult.firstContentTime ?? _firstContentTime;

      _recordMainModelUsage(
        success: true,
        durationMs: turnResult.turnDurationMs,
        firstTokenMs: turnResult.turnFirstTokenMs,
        tokenCount: turnResult.turnTokenCount,
        promptTokens: turnResult.turnPromptTokens,
        completionTokens: turnResult.turnCompletionTokens,
        reasoningTokens: turnResult.turnReasoningTokens,
      );

      if (!_isGenerationActive) break;

      final actionResult = await actionExecutor.execute(aiMsg);
      aiMsg = actionResult.aiMessage;
      continueGeneration = actionResult.continueGeneration;
    }

    if (_isGenerationActive &&
        turns >= maxOrchestratorTurns &&
        _needsForcedFinalization(aiMsg)) {
      final finalTurnResult = await _runForcedFinalization(aiMsg);
      aiMsg = finalTurnResult.aiMessage;
      _firstContentTime = finalTurnResult.firstContentTime ?? _firstContentTime;
      _recordMainModelUsage(
        success: true,
        durationMs: finalTurnResult.turnDurationMs,
        firstTokenMs: finalTurnResult.turnFirstTokenMs,
        tokenCount: finalTurnResult.turnTokenCount,
        promptTokens: finalTurnResult.turnPromptTokens,
        completionTokens: finalTurnResult.turnCompletionTokens,
        reasoningTokens: finalTurnResult.turnReasoningTokens,
      );
    }

    return _ChatGenerationResult(
      aiMessage: aiMsg,
      promptTokens: _promptTokens,
      completionTokens: _completionTokens,
      reasoningTokens: _reasoningTokens,
      firstContentTime: _firstContentTime,
      turns: turns,
    );
  }

  bool _needsForcedFinalization(Message aiMsg) {
    return aiMsg.content.isEmpty ||
        aiMsg.content.contains('<search>') ||
        aiMsg.content.contains('<skill');
  }

  List<String> _mergeStreamingImages(
      List<String> existing, List<String> incoming) {
    if (incoming.isEmpty) return existing;
    // Some OpenAI-compatible image backends emit iterative updates for the same
    // image index in separate chunks. For the common single-image path, keep
    // only the newest frame instead of appending duplicates.
    if (incoming.length == 1 && existing.length <= 1) {
      final next = incoming.first;
      if (existing.isNotEmpty && existing.first == next) return existing;
      return [next];
    }
    return [...existing, ...incoming];
  }

  Future<_ChatTurnResult> _runStreamingTurn(Message aiMsg) async {
    final turnStartTime = DateTime.now();
    DateTime? turnFirstContentTime;
    DateTime? reasoningStartTime;
    var turnPromptTokens = 0;
    var turnCompletionTokens = 0;
    var turnReasoningTokens = 0;
    var turnTokenCount = 0;

    final responseStream = _requestContext.llmService.streamResponse(
      _requestContext.messagesForApi,
      tools: _requestContext.tools,
      cancelToken: _notifier._currentCancelToken,
    );

    await for (final chunk in responseStream) {
      if (!_isGenerationActive) break;

      if (chunk.promptTokens != null) {
        _promptTokens = chunk.promptTokens!;
        turnPromptTokens = chunk.promptTokens!;
      }
      if (chunk.completionTokens != null) {
        _completionTokens = chunk.completionTokens!;
        turnCompletionTokens = chunk.completionTokens!;
      }
      if (chunk.reasoningTokens != null) {
        _reasoningTokens = chunk.reasoningTokens!;
        turnReasoningTokens = chunk.reasoningTokens!;
      }
      if (chunk.usage != null && chunk.usage! > 0) {
        turnTokenCount = chunk.usage!;
      }

      if (chunk.reasoning != null && chunk.reasoning!.isNotEmpty) {
        reasoningStartTime ??= DateTime.now();
        _firstContentTime ??= DateTime.now();
        turnFirstContentTime ??= DateTime.now();
      }

      double? reasoningDuration = aiMsg.reasoningDurationSeconds;
      if (reasoningDuration == null &&
          reasoningStartTime != null &&
          chunk.content != null &&
          chunk.content!.isNotEmpty) {
        reasoningDuration =
            DateTime.now().difference(reasoningStartTime).inMilliseconds /
                1000.0;
      }

      if (_firstContentTime == null) {
        final hasContent = chunk.content != null;
        final hasReasoning = chunk.reasoning != null;
        final hasImages = chunk.images.isNotEmpty;
        final hasToolCalls =
            chunk.toolCalls != null && chunk.toolCalls!.isNotEmpty;
        if (hasContent || hasReasoning || hasImages || hasToolCalls) {
          _firstContentTime = DateTime.now();
          turnFirstContentTime ??= DateTime.now();
        }
      }

      if (chunk.finishReason == 'malformed_function_call') {
        aiMsg = Message(
          id: aiMsg.id,
          content:
              '${aiMsg.content}${chunk.content ?? ''}\n\n> ⚠️ **System Error**: The AI backend returned a "malformed_function_call" error. This usually means the model tried to call a tool but failed to generate a valid request format. Please try again or switch models.',
          reasoningContent:
              (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
          isUser: false,
          timestamp: aiMsg.timestamp,
          attachments: aiMsg.attachments,
          images: _mergeStreamingImages(aiMsg.images, chunk.images),
          model: aiMsg.model,
          provider: aiMsg.provider,
          reasoningDurationSeconds: reasoningDuration,
          tokenCount: chunk.usage ?? aiMsg.tokenCount,
          promptTokens: _promptTokens > 0 ? _promptTokens : aiMsg.promptTokens,
          completionTokens: _completionTokens > 0
              ? _completionTokens
              : aiMsg.completionTokens,
          reasoningTokens:
              _reasoningTokens > 0 ? _reasoningTokens : aiMsg.reasoningTokens,
          firstTokenMs:
              _firstContentTime?.difference(_startTime).inMilliseconds,
          toolCalls:
              _notifier._mergeToolCalls(aiMsg.toolCalls, chunk.toolCalls),
        );
        _notifier._upsertTrailingMessage(aiMsg);
        break;
      }

      aiMsg = Message(
        id: aiMsg.id,
        content: aiMsg.content + (chunk.content ?? ''),
        reasoningContent:
            (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
        isUser: false,
        timestamp: aiMsg.timestamp,
        attachments: aiMsg.attachments,
        images: _mergeStreamingImages(aiMsg.images, chunk.images),
        model: aiMsg.model,
        provider: aiMsg.provider,
        reasoningDurationSeconds: reasoningDuration,
        tokenCount: chunk.usage ?? aiMsg.tokenCount,
        promptTokens: _promptTokens > 0 ? _promptTokens : aiMsg.promptTokens,
        completionTokens:
            _completionTokens > 0 ? _completionTokens : aiMsg.completionTokens,
        reasoningTokens:
            _reasoningTokens > 0 ? _reasoningTokens : aiMsg.reasoningTokens,
        firstTokenMs: _firstContentTime?.difference(_startTime).inMilliseconds,
        toolCalls: _notifier._mergeToolCalls(aiMsg.toolCalls, chunk.toolCalls),
      );
      _notifier._upsertTrailingMessage(aiMsg);
    }

    if (_isGenerationActive &&
        aiMsg.reasoningDurationSeconds == null &&
        reasoningStartTime != null) {
      final duration =
          DateTime.now().difference(reasoningStartTime).inMilliseconds / 1000.0;
      aiMsg = aiMsg.copyWith(reasoningDurationSeconds: duration);
      _notifier._upsertTrailingMessage(aiMsg);
    }

    final turnDurationMs =
        DateTime.now().difference(turnStartTime).inMilliseconds;
    final turnFirstTokenMs =
        turnFirstContentTime?.difference(turnStartTime).inMilliseconds ?? 0;
    final effectiveTurnTokenCount = turnTokenCount > 0
        ? turnTokenCount
        : (turnPromptTokens + turnCompletionTokens + turnReasoningTokens);

    return _ChatTurnResult(
      aiMessage: aiMsg,
      turnDurationMs: turnDurationMs,
      turnFirstTokenMs: turnFirstTokenMs,
      turnTokenCount: effectiveTurnTokenCount,
      turnPromptTokens: turnPromptTokens,
      turnCompletionTokens: turnCompletionTokens,
      turnReasoningTokens: turnReasoningTokens,
      firstContentTime: _firstContentTime,
    );
  }

  Future<_ChatTurnResult> _runNonStreamingTurn(Message aiMsg) async {
    final turnStartTime = DateTime.now();
    final response = await _requestContext.llmService.getResponse(
      _requestContext.messagesForApi,
      tools: _requestContext.tools,
      cancelToken: _notifier._currentCancelToken,
    );

    _firstContentTime ??= DateTime.now();
    final turnFirstContentTime = DateTime.now();

    var turnPromptTokens = 0;
    var turnCompletionTokens = 0;
    var turnReasoningTokens = 0;

    if (response.promptTokens != null) {
      _promptTokens = response.promptTokens!;
      turnPromptTokens = response.promptTokens!;
    }
    if (response.completionTokens != null) {
      _completionTokens = response.completionTokens!;
      turnCompletionTokens = response.completionTokens!;
    }
    if (response.reasoningTokens != null) {
      _reasoningTokens = response.reasoningTokens!;
      turnReasoningTokens = response.reasoningTokens!;
    }

    final turnTokenCount = response.usage ??
        (turnPromptTokens + turnCompletionTokens + turnReasoningTokens);
    final turnDurationMs =
        DateTime.now().difference(turnStartTime).inMilliseconds;
    final turnFirstTokenMs =
        turnFirstContentTime.difference(turnStartTime).inMilliseconds;

    if (_isGenerationActive) {
      aiMsg = Message(
        id: aiMsg.id,
        content: response.content ?? '',
        reasoningContent: response.reasoning,
        isUser: false,
        timestamp: aiMsg.timestamp,
        attachments: aiMsg.attachments,
        images: response.images,
        model: aiMsg.model,
        provider: aiMsg.provider,
        tokenCount: response.usage,
        promptTokens: response.promptTokens,
        completionTokens: response.completionTokens,
        reasoningTokens: response.reasoningTokens,
        firstTokenMs: _firstContentTime!.difference(_startTime).inMilliseconds,
        toolCalls: response.toolCalls
            ?.map((tc) => ToolCall(
                  id: tc.id ?? '',
                  type: tc.type ?? 'function',
                  name: tc.name ?? '',
                  arguments: tc.arguments ?? '',
                ))
            .toList(),
        durationMs: turnDurationMs,
      );
      _notifier._upsertTrailingMessage(aiMsg);
    }

    return _ChatTurnResult(
      aiMessage: aiMsg,
      turnDurationMs: turnDurationMs,
      turnFirstTokenMs: turnFirstTokenMs,
      turnTokenCount: turnTokenCount,
      turnPromptTokens: turnPromptTokens,
      turnCompletionTokens: turnCompletionTokens,
      turnReasoningTokens: turnReasoningTokens,
      firstContentTime: _firstContentTime,
    );
  }

  Future<_ChatTurnResult> _runForcedFinalization(Message aiMsg) async {
    final cleanedContent = aiMsg.content
        .replaceAll(RegExp(r'<search>.*?</search>', dotAll: true), '')
        .replaceAll(
            RegExp(r'''<skill\s+name=["'].*?["']>.*?</skill>''', dotAll: true),
            '')
        .trim();
    aiMsg = aiMsg.copyWith(content: cleanedContent);

    final finalizeInstruction = _requestContext.settings.language == 'zh'
        ? '请根据已有工具/技能结果直接给出答案，不要再调用搜索或技能。如果信息不足，请如实说明。'
        : 'Please answer directly based on the existing tool/skill results and do not call search or skills again. If information is insufficient, say so honestly.';
    _requestContext.messagesForApi.add(
      Message(
        id: const Uuid().v4(),
        role: 'user',
        content: finalizeInstruction,
        timestamp: DateTime.now(),
        isUser: false,
      ),
    );

    aiMsg = Message.ai('',
        model: _requestContext.currentModel,
        provider: _requestContext.currentProviderName);

    final newMessages = List<Message>.from(_notifier.currentState.messages);
    while (newMessages.isNotEmpty &&
        !newMessages.last.isUser &&
        newMessages.last.content.isEmpty) {
      newMessages.removeLast();
    }
    newMessages.add(aiMsg);
    _notifier._setMessages(newMessages);

    final finalTurnStartTime = DateTime.now();
    DateTime? finalTurnFirstContentTime;
    var finalTurnPromptTokens = 0;
    var finalTurnCompletionTokens = 0;
    var finalTurnReasoningTokens = 0;
    var finalTurnTokenCount = 0;

    final finalStream = _requestContext.llmService.streamResponse(
      _requestContext.messagesForApi,
      tools: null,
      cancelToken: _notifier._currentCancelToken,
    );

    await for (final chunk in finalStream) {
      if (!_isGenerationActive) break;

      if (chunk.promptTokens != null) {
        _promptTokens = chunk.promptTokens!;
        finalTurnPromptTokens = chunk.promptTokens!;
      }
      if (chunk.completionTokens != null) {
        _completionTokens = chunk.completionTokens!;
        finalTurnCompletionTokens = chunk.completionTokens!;
      }
      if (chunk.reasoningTokens != null) {
        _reasoningTokens = chunk.reasoningTokens!;
        finalTurnReasoningTokens = chunk.reasoningTokens!;
      }
      if (chunk.usage != null && chunk.usage! > 0) {
        finalTurnTokenCount = chunk.usage!;
      }

      if (_firstContentTime == null &&
          (chunk.content != null || chunk.reasoning != null)) {
        _firstContentTime = DateTime.now();
      }
      if (finalTurnFirstContentTime == null &&
          (chunk.content != null ||
              chunk.reasoning != null ||
              chunk.images.isNotEmpty ||
              (chunk.toolCalls != null && chunk.toolCalls!.isNotEmpty))) {
        finalTurnFirstContentTime = DateTime.now();
      }

      aiMsg = Message(
        id: aiMsg.id,
        content: aiMsg.content + (chunk.content ?? ''),
        reasoningContent:
            (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
        isUser: false,
        timestamp: aiMsg.timestamp,
        model: aiMsg.model,
        provider: aiMsg.provider,
        tokenCount: chunk.usage ?? aiMsg.tokenCount,
        promptTokens: _promptTokens > 0 ? _promptTokens : aiMsg.promptTokens,
        completionTokens:
            _completionTokens > 0 ? _completionTokens : aiMsg.completionTokens,
        reasoningTokens:
            _reasoningTokens > 0 ? _reasoningTokens : aiMsg.reasoningTokens,
        firstTokenMs: _firstContentTime?.difference(_startTime).inMilliseconds,
      );
      _notifier._upsertTrailingMessage(aiMsg);
    }

    final finalTurnDurationMs =
        DateTime.now().difference(finalTurnStartTime).inMilliseconds;
    final finalTurnFirstTokenMs = finalTurnFirstContentTime
            ?.difference(finalTurnStartTime)
            .inMilliseconds ??
        0;
    final effectiveFinalTurnTokenCount = finalTurnTokenCount > 0
        ? finalTurnTokenCount
        : (finalTurnPromptTokens +
            finalTurnCompletionTokens +
            finalTurnReasoningTokens);

    return _ChatTurnResult(
      aiMessage: aiMsg,
      turnDurationMs: finalTurnDurationMs,
      turnFirstTokenMs: finalTurnFirstTokenMs,
      turnTokenCount: effectiveFinalTurnTokenCount,
      turnPromptTokens: finalTurnPromptTokens,
      turnCompletionTokens: finalTurnCompletionTokens,
      turnReasoningTokens: finalTurnReasoningTokens,
      firstContentTime: _firstContentTime,
    );
  }
}
