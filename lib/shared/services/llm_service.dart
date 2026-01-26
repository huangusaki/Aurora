import 'package:aurora/features/chat/domain/message.dart';
import 'package:dio/dio.dart';

class LLMResponseChunk {
  final String? content;
  final String? reasoning;
  final List<String> images;
  final List<ToolCallChunk>? toolCalls;
  final int? usage;
  final int? promptTokens;
  final int? completionTokens;
  final String? finishReason;
  const LLMResponseChunk(
      {this.content,
      this.reasoning,
      this.images = const [],
      this.toolCalls,
      this.usage,
      this.promptTokens,
      this.completionTokens,
      this.finishReason});
}

abstract class LLMService {
  Stream<LLMResponseChunk> streamResponse(List<Message> messages,
      {List<String>? attachments,
      List<Map<String, dynamic>>? tools,
      String? toolChoice,
      String? model,
      CancelToken? cancelToken});
  Future<LLMResponseChunk> getResponse(List<Message> messages,
      {List<String>? attachments,
      List<Map<String, dynamic>>? tools,
      String? toolChoice,
      String? model,
      CancelToken? cancelToken});
}
