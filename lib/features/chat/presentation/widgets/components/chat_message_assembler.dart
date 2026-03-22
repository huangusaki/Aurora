import 'dart:convert';

import '../../../domain/chat_message_transformers.dart';
import '../../../domain/message.dart';
import '../../../domain/message_transformer.dart';
import '../../../domain/ui_message.dart';
import 'chat_message_content.dart';

class ChatMessageAssembler {
  const ChatMessageAssembler._();

  static ChatMessageRenderData assembleSingle({
    required Message message,
    required MessageTransformContext transformContext,
    required bool isGenerating,
    required bool animateStreamingContent,
    required String loadingLabel,
  }) {
    final uiMessage = chatMessageTransformers.visualTransform(
      UiMessage.fromLegacy(message),
      transformContext,
    );
    final contentText = uiMessage.text;
    final reasoningText = uiMessage.reasoning;
    final isTool = uiMessage.role == UiRole.tool;
    final blocks = <ChatMessageContentBlock>[];

    if (!message.isUser &&
        isGenerating &&
        contentText.isEmpty &&
        (reasoningText == null || reasoningText.isEmpty)) {
      blocks.add(ChatLoadingBlock(loadingLabel));
    }
    if (!message.isUser && reasoningText != null && reasoningText.isNotEmpty) {
      blocks.add(
        ChatReasoningBlock(
          content: reasoningText,
          isRunning: isGenerating,
          duration: uiMessage.reasoningDurationSeconds,
          startTime: message.timestamp,
        ),
      );
    }
    if (isTool) {
      if (contentText.isNotEmpty) {
        blocks.add(ChatToolOutputBlock(contentText));
      }
    } else if (contentText.isNotEmpty) {
      blocks.add(
        ChatTextBlock(
          text: contentText,
          presentation: message.isUser
              ? ChatTextPresentation.plain
              : ChatTextPresentation.markdown,
          animate: animateStreamingContent,
        ),
      );
    }
    if (uiMessage.attachments.isNotEmpty) {
      blocks.add(ChatAttachmentsBlock(uiMessage.attachments));
    }
    if (uiMessage.images.isNotEmpty) {
      blocks.add(ChatImagesBlock(uiMessage.images));
    }
    if ((message.tokenCount != null && message.tokenCount! > 0) ||
        message.durationMs != null) {
      blocks.add(ChatFooterBlock(message));
    }
    return ChatMessageRenderData(blocks: blocks);
  }

  static ChatMessageRenderData assembleMerged({
    required List<Message> messages,
    required MessageTransformContext transformContext,
    required bool isGenerating,
    required bool animateStreamingContent,
    required String loadingLabel,
  }) {
    final blocks = <ChatMessageContentBlock>[];
    final lastMessage = messages.last;

    final allReasoning = StringBuffer();
    double totalReasoningDuration = 0;
    DateTime? firstReasoningTimestamp;
    bool hasActiveReasoning = false;

    for (final message in messages) {
      final reasoning = UiMessage.fromLegacy(message).reasoning;
      if (reasoning == null || reasoning.isEmpty) continue;
      if (allReasoning.isNotEmpty) {
        allReasoning.write('\n\n');
      }
      allReasoning.write(reasoning);
      totalReasoningDuration +=
          UiMessage.fromLegacy(message).reasoningDurationSeconds ?? 0;
      firstReasoningTimestamp ??= message.timestamp;
      if (isGenerating && message == lastMessage) {
        hasActiveReasoning = true;
      }
    }
    if (allReasoning.isNotEmpty) {
      blocks.add(
        ChatReasoningBlock(
          content: allReasoning.toString(),
          isRunning: hasActiveReasoning,
          duration: totalReasoningDuration > 0 ? totalReasoningDuration : null,
          startTime: firstReasoningTimestamp,
        ),
      );
    }

    final mergedSearchResults = <Map<String, dynamic>>[];
    final otherToolOutputs = <String>[];
    for (final message in messages) {
      if (message.role != 'tool') continue;
      try {
        final data = jsonDecode(message.content) as Map<String, dynamic>?;
        if (data != null && data['results'] is List) {
          for (final result in data['results'] as List) {
            if (result is Map<String, dynamic>) {
              mergedSearchResults.add(result);
            }
          }
        } else if (data != null) {
          otherToolOutputs.add(message.content);
        } else {
          otherToolOutputs.add(jsonEncode({'message': message.content}));
        }
      } catch (_) {
        otherToolOutputs.add(jsonEncode({'message': message.content}));
      }
    }

    if (mergedSearchResults.isNotEmpty) {
      blocks.add(
        ChatToolOutputBlock(jsonEncode({'results': mergedSearchResults})),
      );
    }
    for (final output in otherToolOutputs) {
      blocks.add(ChatToolOutputBlock(output));
    }

    for (final message in messages) {
      if (message.role == 'tool') continue;
      final ui = chatMessageTransformers.visualTransform(
        UiMessage.fromLegacy(message),
        transformContext,
      );
      if (ui.text.isNotEmpty) {
        blocks.add(
          ChatTextBlock(
            text: ui.text,
            presentation: ChatTextPresentation.markdown,
            animate: animateStreamingContent,
          ),
        );
      }
      if (ui.attachments.isNotEmpty) {
        blocks.add(ChatAttachmentsBlock(ui.attachments));
      }
      if (ui.images.isNotEmpty) {
        blocks.add(ChatImagesBlock(ui.images));
      }
    }

    final latestUi = UiMessage.fromLegacy(lastMessage);
    final latestText = chatMessageTransformers
        .visualTransform(latestUi, transformContext)
        .text;
    final latestReasoning = latestUi.reasoning;
    if (isGenerating &&
        latestUi.role != UiRole.tool &&
        latestText.isEmpty &&
        (latestReasoning?.isEmpty ?? true) &&
        (lastMessage.toolCalls == null || lastMessage.toolCalls!.isEmpty)) {
      blocks.add(ChatLoadingBlock(loadingLabel));
    }

    Message? lastNonTool;
    for (final message in messages) {
      if (message.role != 'tool') {
        lastNonTool = message;
      }
    }
    if (lastNonTool != null && !isGenerating) {
      if ((lastNonTool.tokenCount != null && lastNonTool.tokenCount! > 0) ||
          lastNonTool.durationMs != null) {
        blocks.add(ChatFooterBlock(lastNonTool));
      }
    }

    return ChatMessageRenderData(blocks: blocks);
  }
}
