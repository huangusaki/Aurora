class Message {
  final String id;
  final String content;
  final String? reasoningContent;
  final bool isUser;
  final DateTime timestamp;
  final List<String> attachments;
  final List<String> images;
  final String? model;
  final String? provider;
  final double? reasoningDurationSeconds;

  const Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.reasoningContent,
    this.attachments = const [],
    this.images = const [],
    this.model,
    this.provider,
    this.reasoningDurationSeconds,
  });

  factory Message.user(String content, {List<String> attachments = const []}) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      attachments: attachments,
    );
  }

  factory Message.ai(String content,
      {String? reasoningContent,
      List<String> images = const [],
      String? model,
      String? provider,
      double? reasoningDurationSeconds}) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      reasoningContent: reasoningContent,
      isUser: false,
      timestamp: DateTime.now(),
      images: images,
      model: model,
      provider: provider,
      reasoningDurationSeconds: reasoningDurationSeconds,
    );
  }
}
