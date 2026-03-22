import 'package:aurora/features/chat/domain/message.dart';

sealed class ChatMessageContentBlock {
  const ChatMessageContentBlock();
}

enum ChatTextPresentation { plain, markdown }

class ChatTextBlock extends ChatMessageContentBlock {
  const ChatTextBlock({
    required this.text,
    required this.presentation,
    this.animate = false,
  });

  final String text;
  final ChatTextPresentation presentation;
  final bool animate;
}

class ChatReasoningBlock extends ChatMessageContentBlock {
  const ChatReasoningBlock({
    required this.content,
    this.isRunning = false,
    this.duration,
    this.startTime,
  });

  final String content;
  final bool isRunning;
  final double? duration;
  final DateTime? startTime;
}

class ChatToolOutputBlock extends ChatMessageContentBlock {
  const ChatToolOutputBlock(this.content);

  final String content;
}

class ChatAttachmentsBlock extends ChatMessageContentBlock {
  const ChatAttachmentsBlock(this.paths);

  final List<String> paths;
}

class ChatImagesBlock extends ChatMessageContentBlock {
  const ChatImagesBlock(this.urls);

  final List<String> urls;
}

class ChatLoadingBlock extends ChatMessageContentBlock {
  const ChatLoadingBlock(this.label);

  final String label;
}

class ChatFooterBlock extends ChatMessageContentBlock {
  const ChatFooterBlock(this.message);

  final Message message;
}

class ChatMessageRenderData {
  const ChatMessageRenderData({required this.blocks});

  final List<ChatMessageContentBlock> blocks;
}
