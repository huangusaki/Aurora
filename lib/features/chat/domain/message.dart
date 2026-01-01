class Message {
  final String id;
  final String content;
  final String? reasoningContent; // Chain of Thought
  final bool isUser;
  final DateTime timestamp;

  final List<String> attachments; // List of local file paths
  final List<String> images; // List of generated image data (Base64)

  final String? model;
  final String? provider;

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

  factory Message.ai(String content, {String? reasoningContent, List<String> images = const [], String? model, String? provider}) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      reasoningContent: reasoningContent,
      isUser: false,
      timestamp: DateTime.now(),
      images: images,
      model: model,
      provider: provider,
    );
  }
}
