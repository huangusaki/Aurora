import 'dart:async';

import 'package:aurora/features/chat/domain/message.dart';
import 'package:aurora/shared/services/llm_service.dart';

class MockLLMService implements LLMService {
  @override
  Future<String> getResponse(List<Message> messages) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a mock response to: "${messages.isNotEmpty ? messages.last.content : ''}"';
  }

  @override
  Stream<LLMResponseChunk> streamResponse(List<Message> messages, {List<String>? attachments}) async* {
    final response = 'This is a streaming mock response to: "${messages.isNotEmpty ? messages.last.content : 'EMPTY'}"';
    for (var i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      yield LLMResponseChunk(content: response[i]);
    }
  }
}

