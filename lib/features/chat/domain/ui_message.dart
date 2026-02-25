import 'package:aurora/shared/services/llm_service.dart';

import 'message.dart';
import 'ui_message_part.dart';

enum UiRole { system, user, assistant, tool }

extension UiRoleCompat on UiRole {
  String get wireName => switch (this) {
        UiRole.system => 'system',
        UiRole.user => 'user',
        UiRole.assistant => 'assistant',
        UiRole.tool => 'tool',
      };

  static UiRole fromWireName(
    String? role, {
    required bool isUser,
    required String? toolCallId,
  }) {
    final normalized = (role ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'system':
        return UiRole.system;
      case 'user':
        return UiRole.user;
      case 'assistant':
        return UiRole.assistant;
      case 'tool':
        return UiRole.tool;
    }
    if (isUser) return UiRole.user;
    if (toolCallId != null) return UiRole.tool;
    return UiRole.assistant;
  }
}

class UiMessage {
  final String id;
  final UiRole role;
  final DateTime timestamp;
  final List<UiMessagePart> parts;

  final String? assistantId;
  final String? requestId;
  final String? model;
  final String? provider;
  final double? reasoningDurationSeconds;
  final int? tokenCount;
  final int? promptTokens;
  final int? completionTokens;
  final int? reasoningTokens;
  final int? firstTokenMs;
  final int? durationMs;

  // Legacy OpenAI-compatible tool_calls. Tool execution output is still modeled
  // as separate tool-role messages in the current codebase.
  final List<ToolCall>? toolCalls;
  final String? toolCallId;

  const UiMessage({
    required this.id,
    required this.role,
    required this.timestamp,
    this.parts = const [],
    this.assistantId,
    this.requestId,
    this.model,
    this.provider,
    this.reasoningDurationSeconds,
    this.tokenCount,
    this.promptTokens,
    this.completionTokens,
    this.reasoningTokens,
    this.firstTokenMs,
    this.durationMs,
    this.toolCalls,
    this.toolCallId,
  });

  bool get isUser => role == UiRole.user;

  String get text {
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is UiTextPart) {
        buffer.write(part.text);
      }
    }
    return buffer.toString();
  }

  String? get reasoning {
    final buffer = StringBuffer();
    var hasAny = false;
    for (final part in parts) {
      if (part is UiReasoningPart) {
        buffer.write(part.text);
        hasAny = true;
      }
    }
    if (!hasAny) return null;
    final merged = buffer.toString();
    return merged.isEmpty ? null : merged;
  }

  List<String> get attachments => parts
      .whereType<UiAttachmentPart>()
      .map((p) => p.path)
      .where((p) => p.trim().isNotEmpty)
      .toList(growable: false);

  List<String> get images => parts
      .whereType<UiImagePart>()
      .map((p) => p.url)
      .where((p) => p.trim().isNotEmpty)
      .toList(growable: false);

  UiSearchRequestPart? get firstSearchRequest {
    for (final part in parts) {
      if (part is UiSearchRequestPart) return part;
    }
    return null;
  }

  UiSkillRequestPart? get firstSkillRequest {
    for (final part in parts) {
      if (part is UiSkillRequestPart) return part;
    }
    return null;
  }

  UiMessage copyWith({
    String? id,
    UiRole? role,
    DateTime? timestamp,
    List<UiMessagePart>? parts,
    Object? assistantId = _sentinel,
    Object? requestId = _sentinel,
    Object? model = _sentinel,
    Object? provider = _sentinel,
    Object? reasoningDurationSeconds = _sentinel,
    Object? tokenCount = _sentinel,
    Object? promptTokens = _sentinel,
    Object? completionTokens = _sentinel,
    Object? reasoningTokens = _sentinel,
    Object? firstTokenMs = _sentinel,
    Object? durationMs = _sentinel,
    Object? toolCalls = _sentinel,
    Object? toolCallId = _sentinel,
  }) {
    return UiMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      parts: parts ?? this.parts,
      assistantId:
          assistantId == _sentinel ? this.assistantId : assistantId as String?,
      requestId: requestId == _sentinel ? this.requestId : requestId as String?,
      model: model == _sentinel ? this.model : model as String?,
      provider: provider == _sentinel ? this.provider : provider as String?,
      reasoningDurationSeconds: reasoningDurationSeconds == _sentinel
          ? this.reasoningDurationSeconds
          : reasoningDurationSeconds as double?,
      tokenCount:
          tokenCount == _sentinel ? this.tokenCount : tokenCount as int?,
      promptTokens:
          promptTokens == _sentinel ? this.promptTokens : promptTokens as int?,
      completionTokens: completionTokens == _sentinel
          ? this.completionTokens
          : completionTokens as int?,
      reasoningTokens: reasoningTokens == _sentinel
          ? this.reasoningTokens
          : reasoningTokens as int?,
      firstTokenMs:
          firstTokenMs == _sentinel ? this.firstTokenMs : firstTokenMs as int?,
      durationMs:
          durationMs == _sentinel ? this.durationMs : durationMs as int?,
      toolCalls: toolCalls == _sentinel
          ? this.toolCalls
          : toolCalls as List<ToolCall>?,
      toolCallId:
          toolCallId == _sentinel ? this.toolCallId : toolCallId as String?,
    );
  }

  factory UiMessage.fromLegacy(Message message) {
    final role = UiRoleCompat.fromWireName(
      message.role,
      isUser: message.isUser,
      toolCallId: message.toolCallId,
    );
    final parts = <UiMessagePart>[];
    if (message.content.isNotEmpty) {
      parts.add(UiTextPart(message.content));
    }
    final reasoning = message.reasoningContent;
    if (reasoning != null && reasoning.isNotEmpty) {
      parts.add(UiReasoningPart(reasoning));
    }
    for (final path in message.attachments) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      parts.add(UiAttachmentPart(path: trimmed));
    }
    for (final image in message.images) {
      final trimmed = image.trim();
      if (trimmed.isEmpty) continue;
      parts.add(UiImagePart(url: trimmed));
    }
    return UiMessage(
      id: message.id,
      role: role,
      timestamp: message.timestamp,
      parts: parts,
      assistantId: message.assistantId,
      requestId: message.requestId,
      model: message.model,
      provider: message.provider,
      reasoningDurationSeconds: message.reasoningDurationSeconds,
      tokenCount: message.tokenCount,
      promptTokens: message.promptTokens,
      completionTokens: message.completionTokens,
      reasoningTokens: message.reasoningTokens,
      firstTokenMs: message.firstTokenMs,
      durationMs: message.durationMs,
      toolCalls: message.toolCalls,
      toolCallId: message.toolCallId,
    );
  }

  Message toLegacy() {
    final content = text;
    final reasoningContent = reasoning;
    return Message(
      id: id,
      role: role.wireName,
      content: content,
      reasoningContent: reasoningContent,
      isUser: isUser,
      timestamp: timestamp,
      assistantId: assistantId,
      requestId: requestId,
      attachments: attachments,
      images: images,
      model: model,
      provider: provider,
      reasoningDurationSeconds: reasoningDurationSeconds,
      tokenCount: tokenCount,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      reasoningTokens: reasoningTokens,
      firstTokenMs: firstTokenMs,
      durationMs: durationMs,
      toolCalls: toolCalls,
      toolCallId: toolCallId,
    );
  }

  UiMessage appendChunk(LLMResponseChunk chunk) {
    final nextParts = List<UiMessagePart>.from(parts);

    final contentDelta = chunk.content;
    if (contentDelta != null && contentDelta.isNotEmpty) {
      final index = nextParts.lastIndexWhere((p) => p is UiTextPart);
      if (index == -1) {
        nextParts.add(UiTextPart(contentDelta));
      } else {
        final prev = nextParts[index] as UiTextPart;
        nextParts[index] = prev.copyWith(text: prev.text + contentDelta);
      }
    }

    final reasoningDelta = chunk.reasoning;
    if (reasoningDelta != null && reasoningDelta.isNotEmpty) {
      final index = nextParts.lastIndexWhere((p) => p is UiReasoningPart);
      if (index == -1) {
        nextParts.add(UiReasoningPart(reasoningDelta));
      } else {
        final prev = nextParts[index] as UiReasoningPart;
        nextParts[index] = prev.copyWith(text: prev.text + reasoningDelta);
      }
    }

    if (chunk.images.isNotEmpty) {
      final knownImageUrls = nextParts
          .whereType<UiImagePart>()
          .map((p) => p.url.trim())
          .where((u) => u.isNotEmpty)
          .toSet();
      for (final img in chunk.images) {
        final trimmed = img.trim();
        if (trimmed.isEmpty || knownImageUrls.contains(trimmed)) continue;
        knownImageUrls.add(trimmed);
        nextParts.add(UiImagePart(url: trimmed));
      }
    }

    final mergedToolCalls = _mergeToolCalls(toolCalls, chunk.toolCalls);
    return copyWith(
      parts: nextParts,
      toolCalls: mergedToolCalls,
    );
  }

  UiMessage replaceText(String text) {
    final nextParts = List<UiMessagePart>.from(parts)
      ..removeWhere((p) => p is UiTextPart);
    if (text.isNotEmpty) {
      nextParts.insert(0, UiTextPart(text));
    }
    return copyWith(parts: nextParts);
  }
}

List<ToolCall>? _mergeToolCalls(
  List<ToolCall>? existing,
  List<ToolCallChunk>? chunks,
) {
  if (chunks == null || chunks.isEmpty) return existing;
  final merged =
      existing != null ? List<ToolCall>.from(existing) : <ToolCall>[];
  for (final chunk in chunks) {
    final index = chunk.index ?? 0;
    if (index >= merged.length) {
      merged.add(ToolCall(
        id: chunk.id ?? '',
        type: chunk.type ?? 'function',
        name: chunk.name ?? '',
        arguments: chunk.arguments ?? '',
      ));
      continue;
    }

    final prev = merged[index];
    merged[index] = ToolCall(
      id: prev.id.isEmpty ? (chunk.id ?? '') : prev.id,
      type: prev.type == 'function' ? (chunk.type ?? 'function') : prev.type,
      name: prev.name + (chunk.name ?? ''),
      arguments: prev.arguments + (chunk.arguments ?? ''),
    );
  }
  return merged;
}

const Object _sentinel = Object();
