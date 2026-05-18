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
    required UiMessage uiMessage,
    required MessageTransformContext transformContext,
    required bool isGenerating,
    required bool animateStreamingContent,
    required String loadingLabel,
  }) {
    final transformedUiMessage = chatMessageTransformers.visualTransform(
      uiMessage,
      transformContext,
    );
    final contentText = transformedUiMessage.text;
    final reasoningText = transformedUiMessage.reasoning;
    final isTool = transformedUiMessage.role == UiRole.tool;
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
          duration: transformedUiMessage.reasoningDurationSeconds,
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
          streamingActive: isGenerating && !message.isUser,
        ),
      );
    }
    if (transformedUiMessage.attachments.isNotEmpty) {
      blocks.add(ChatAttachmentsBlock(transformedUiMessage.attachments));
    }
    if (transformedUiMessage.images.isNotEmpty) {
      blocks.add(ChatImagesBlock(transformedUiMessage.images));
    }
    if ((message.tokenCount != null && message.tokenCount! > 0) ||
        message.durationMs != null) {
      blocks.add(ChatFooterBlock(message));
    }
    return ChatMessageRenderData(blocks: blocks);
  }

  static ChatMessageRenderData assembleMerged({
    required List<Message> messages,
    required List<UiMessage> uiMessages,
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

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final uiMessage = uiMessages[i];
      final reasoning = uiMessage.reasoning;
      if (reasoning == null || reasoning.isEmpty) continue;
      if (allReasoning.isNotEmpty) {
        allReasoning.write('\n\n');
      }
      allReasoning.write(reasoning);
      totalReasoningDuration += uiMessage.reasoningDurationSeconds ?? 0;
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

    int? latestNonToolIndex;
    for (var i = messages.length - 1; i >= 0; i -= 1) {
      if (messages[i].role != 'tool') {
        latestNonToolIndex = i;
        break;
      }
    }

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.role == 'tool') continue;
      final ui = chatMessageTransformers.visualTransform(
        uiMessages[i],
        transformContext,
      );
      if (ui.text.isNotEmpty) {
        blocks.add(
          ChatTextBlock(
            text: ui.text,
            presentation: ChatTextPresentation.markdown,
            animate: animateStreamingContent,
            streamingActive: isGenerating &&
                latestNonToolIndex != null &&
                i == latestNonToolIndex,
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

    final latestUi = uiMessages.last;
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
