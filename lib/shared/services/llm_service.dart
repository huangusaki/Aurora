import 'package:aurora/features/chat/domain/message.dart';

class LLMResponseChunk {
  final String? content;
  final String? reasoning;
  final List<String> images;
  const LLMResponseChunk(
      {this.content, this.reasoning, this.images = const []});
}

abstract class LLMService {
  Stream<LLMResponseChunk> streamResponse(List<Message> messages,
      {List<String>? attachments});
  Future<LLMResponseChunk> getResponse(List<Message> messages,
      {List<String>? attachments});
}
