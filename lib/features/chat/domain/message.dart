import 'package:uuid/uuid.dart';

class ToolCall {
  final String id;
  final String type;
  final String name;
  final String arguments;
  const ToolCall({
    required this.id,
    this.type = 'function',
    required this.name,
    required this.arguments,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': {
          'name': name,
          'arguments': arguments,
        }
      };
}

class ToolCallChunk {
  final String? id;
  final String? type;
  final String? name;
  final String? arguments;
  final int? index;
  const ToolCallChunk({
    this.id,
    this.type,
    this.name,
    this.arguments,
    this.index,
  });
  static ToolCallChunk fromToolCall(ToolCall tc) {
    return ToolCallChunk(
        id: tc.id, type: tc.type, name: tc.name, arguments: tc.arguments);
  }
}

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
  final int? tokenCount;
  final List<ToolCall>? toolCalls;
  final String? toolCallId;
  final String role;
  final int? firstTokenMs;
  final int? durationMs;
  final int? promptTokens;
  final int? completionTokens;
  final int? reasoningTokens;
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
    this.toolCalls,
    this.toolCallId,
    this.tokenCount,
    this.firstTokenMs,
    this.durationMs,
    this.promptTokens,
    this.completionTokens,
    this.reasoningTokens,
    String? role,
  }) : role = role ??
            (isUser ? 'user' : (toolCallId != null ? 'tool' : 'assistant'));
  factory Message.user(String content, {List<String> attachments = const []}) {
    return Message(
      id: const Uuid().v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      attachments: attachments,
      role: 'user',
    );
  }
  factory Message.ai(String content,
      {String? reasoningContent,
      List<String> images = const [],
      String? model,
      String? provider,
      double? reasoningDurationSeconds,
      int? tokenCount,
      int? promptTokens,
      int? completionTokens,
      int? reasoningTokens,
      List<ToolCall>? toolCalls}) {
    return Message(
      id: const Uuid().v4(),
      content: content,
      reasoningContent: reasoningContent,
      isUser: false,
      timestamp: DateTime.now(),
      images: images,
      model: model,
      provider: provider,
      reasoningDurationSeconds: reasoningDurationSeconds,
      tokenCount: tokenCount,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      reasoningTokens: reasoningTokens,
      toolCalls: toolCalls,
      role: 'assistant',
    );
  }
  factory Message.tool(String content, {required String toolCallId}) {
    return Message(
      id: const Uuid().v4(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      toolCallId: toolCallId,
      role: 'tool',
    );
  }
  Message copyWith({
    String? id,
    String? content,
    String? reasoningContent,
    bool? isUser,
    DateTime? timestamp,
    List<String>? attachments,
    List<String>? images,
    String? model,
    String? provider,
    double? reasoningDurationSeconds,
    List<ToolCall>? toolCalls,
    String? toolCallId,
    String? role,
    int? tokenCount,
    int? firstTokenMs,
    int? durationMs,
    int? promptTokens,
    int? completionTokens,
    int? reasoningTokens,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
      images: images ?? this.images,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      reasoningDurationSeconds:
          reasoningDurationSeconds ?? this.reasoningDurationSeconds,
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId ?? this.toolCallId,
      role: role ?? this.role,
      tokenCount: tokenCount ?? this.tokenCount,
      firstTokenMs: firstTokenMs ?? this.firstTokenMs,
      durationMs: durationMs ?? this.durationMs,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      reasoningTokens: reasoningTokens ?? this.reasoningTokens,
    );
  }
}
