part of 'chat_provider.dart';

class _ChatPersistence {
  final ChatNotifier _notifier;

  const _ChatPersistence({required ChatNotifier notifier})
      : _notifier = notifier;

  Future<Message> persist({
    required String generationId,
    required int startSaveIndex,
    required DateTime startTime,
    required DateTime? firstContentTime,
    required String? assistantIdForRequest,
    required int promptTokens,
    required int completionTokens,
    required int reasoningTokens,
    required Message aiMessage,
  }) async {
    if (_notifier._currentGenerationId != generationId) {
      return aiMessage;
    }

    final messages = _notifier.currentState.messages;
    final durationMs = DateTime.now().difference(startTime).inMilliseconds;
    final firstTokenMs = firstContentTime?.difference(startTime).inMilliseconds;

    if (messages.length <= startSaveIndex) {
      _notifier._setLoadingAndUnread(
        isLoading: false,
        hasUnreadResponse: true,
      );
      return aiMessage;
    }

    final unsaved = messages.sublist(startSaveIndex);
    final updatedMessages = List<Message>.from(_notifier.currentState.messages);
    var finalAiMessage = aiMessage;

    for (var i = 0; i < unsaved.length; i++) {
      if (_notifier._currentGenerationId != generationId) {
        break;
      }

      var message = unsaved[i];
      if ((message.requestId ?? '').isEmpty) {
        message = message.copyWith(requestId: generationId);
      }
      if (assistantIdForRequest != null &&
          (message.assistantId ?? '').isEmpty) {
        message = message.copyWith(assistantId: assistantIdForRequest);
      }

      if (!message.isUser &&
          message.role != 'tool' &&
          i == unsaved.length - 1) {
        message = message.copyWith(
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          reasoningTokens: reasoningTokens,
          tokenCount: (promptTokens > 0 || completionTokens > 0)
              ? (promptTokens + completionTokens + reasoningTokens)
              : message.tokenCount,
          durationMs: durationMs,
          firstTokenMs: firstTokenMs,
        );
      }

      // 保存前压缩图片：UI 保留原图显示，数据库存储压缩版本
      if (!message.isUser && message.images.isNotEmpty) {
        try {
          final compressed = await compressImageDataUrls(message.images);
          message = message.copyWith(images: compressed);
        } catch (e) {
          debugPrint('[IMAGE_COMPRESS] Persistence compression failed: $e');
        }
      }

      final dbId =
          await _notifier._storage.saveMessage(message, _notifier._sessionId);
      if (!_notifier.mounted) {
        break;
      }

      final stateIndex = startSaveIndex + i;
      if (stateIndex < updatedMessages.length) {
        final savedMessage = message.copyWith(id: dbId);
        updatedMessages[stateIndex] = savedMessage;
        if (!message.isUser &&
            message.role != 'tool' &&
            i == unsaved.length - 1) {
          finalAiMessage = savedMessage;
        }
      }
    }

    if (_notifier.mounted && _notifier._currentGenerationId == generationId) {
      _notifier._setMessagesWithLoading(
        messages: updatedMessages,
        isLoading: false,
        hasUnreadResponse: true,
      );
      _notifier._ref.read(sessionsProvider.notifier).loadSessions();
    }

    return finalAiMessage;
  }
}
