import 'package:aurora/features/chat/domain/message.dart';

class LLMResponseChunk {
  final String? content;
  final String? reasoning;
  final List<String> images;

  const LLMResponseChunk({this.content, this.reasoning, this.images = const []});
}

abstract class LLMService {
  /// Sends a message and returns a stream of response chunks.
  Stream<LLMResponseChunk> streamResponse(List<Message> messages, {List<String>? attachments});
  
  /// Sends a message and returns the full response.
  Future<String> getResponse(List<Message> messages);
}

