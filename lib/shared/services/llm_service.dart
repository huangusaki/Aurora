import 'package:aurora/features/chat/domain/message.dart';

class LLMResponseChunk {
  final String? content;
  final String? reasoning;
  final List<String> images;
  final List<ToolCallChunk>? toolCalls;
  const LLMResponseChunk(
      {this.content, this.reasoning, this.images = const [], this.toolCalls});
}

abstract class LLMService {
  Stream<LLMResponseChunk> streamResponse(List<Message> messages,
      {List<String>? attachments, List<Map<String, dynamic>>? tools});
  Future<LLMResponseChunk> getResponse(List<Message> messages,
      {List<String>? attachments, List<Map<String, dynamic>>? tools});
}
