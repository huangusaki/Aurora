import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/error/app_error_type.dart';
import '../../core/error/app_exception.dart';
import '../../features/chat/domain/message.dart';
import '../../features/settings/presentation/settings_provider.dart';
import '../utils/app_logger.dart';
import '../utils/llm_stream_log_accumulator.dart';
import 'capability_route_resolver.dart';
import 'llm_service.dart';

abstract class RoutedChatHandler {
  Future<LLMResponseChunk> getResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    required String model,
    required ProviderConfig provider,
    required ResolvedCapabilityRoute route,
    CancelToken? cancelToken,
  });

  Stream<LLMResponseChunk> streamResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    required String model,
    required ProviderConfig provider,
    required ResolvedCapabilityRoute route,
    CancelToken? cancelToken,
  });
}

class OpenAiResponsesChatHandler implements RoutedChatHandler {
  OpenAiResponsesChatHandler({
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 300),
                sendTimeout: const Duration(seconds: 120),
              ),
            );

  final Dio _dio;

  @override
  Future<LLMResponseChunk> getResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    required String model,
    required ProviderConfig provider,
    required ResolvedCapabilityRoute route,
    CancelToken? cancelToken,
  }) async {
    final apiKey = route.effectiveApiKey(provider);
    final uri = route.buildUri(model: model, apiKey: apiKey);
    final requestData = _buildRequestData(
      messages: messages,
      model: model,
      tools: tools,
      toolChoice: toolChoice,
      stream: false,
    );
    _logRequest(uri.toString(), requestData);
    final response = await _dio.postUri(
      uri,
      data: requestData,
      options: Options(
        headers: route.buildHeaders(
          apiKey: apiKey,
          extra: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ),
      cancelToken: cancelToken,
    );
    final payload = _normalizePayload(response.data);
    _logResponse(payload);
    return _parseNonStreamingResponse(payload);
  }

  @override
  Stream<LLMResponseChunk> streamResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    required String model,
    required ProviderConfig provider,
    required ResolvedCapabilityRoute route,
    CancelToken? cancelToken,
  }) async* {
    final apiKey = route.effectiveApiKey(provider);
    final uri = route.buildUri(model: model, apiKey: apiKey);
    final requestData = _buildRequestData(
      messages: messages,
      model: model,
      tools: tools,
      toolChoice: toolChoice,
      stream: true,
    );
    _logRequest(uri.toString(), requestData);
    final streamLog = LlmStreamLogAccumulator(
      providerId: provider.id,
      model: model,
    );
    final response = await _dio.postUri<ResponseBody>(
      uri,
      data: requestData,
      options: Options(
        responseType: ResponseType.stream,
        headers: route.buildHeaders(
          apiKey: apiKey,
          extra: const {
            'Accept': 'text/event-stream',
            'Content-Type': 'application/json',
          },
        ),
      ),
      cancelToken: cancelToken,
    );
    final body = response.data;
    if (body == null) return;
    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    final toolArgBuffers = <String, StringBuffer>{};
    await for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || !line.startsWith('data:')) continue;
      final data = line.substring(5).trimLeft();
      if (data == '[DONE]') {
        streamLog.recordDoneMarkerSeen();
        break;
      }
      final payload = _normalizePayload(data);
      if (payload is! Map) continue;
      streamLog.recordSseEvent();
      final type = payload['type']?.toString();
      if (type == 'response.output_text.delta') {
        final delta = payload['delta']?.toString();
        if (delta != null && delta.isNotEmpty) {
          streamLog.recordEmission(content: delta);
          yield LLMResponseChunk(content: delta);
        }
        continue;
      }
      if (type == 'response.reasoning.delta') {
        final delta = payload['delta']?.toString();
        if (delta != null && delta.isNotEmpty) {
          streamLog.recordEmission(reasoning: delta);
          yield LLMResponseChunk(reasoning: delta);
        }
        continue;
      }
      if (type == 'response.function_call_arguments.delta') {
        final id = payload['item_id']?.toString() ?? 'tool_0';
        final delta = payload['delta']?.toString() ?? '';
        if (delta.isNotEmpty) {
          final buffer = toolArgBuffers.putIfAbsent(id, StringBuffer.new);
          buffer.write(delta);
          streamLog.recordEmission();
          yield LLMResponseChunk(
            toolCalls: [
              ToolCallChunk(
                id: id,
                type: 'function',
                arguments: delta,
              ),
            ],
          );
        }
        continue;
      }
      if (type == 'response.output_item.added') {
        final item = payload['item'];
        if (item is Map && item['type']?.toString() == 'function_call') {
          final id = item['id']?.toString();
          final name = item['name']?.toString();
          yield LLMResponseChunk(
            toolCalls: [
              ToolCallChunk(
                id: id,
                type: 'function',
                name: name,
              ),
            ],
          );
        }
        continue;
      }
      if (type == 'response.completed') {
        final responseData = payload['response'];
        if (responseData is Map) {
          final usage = _usageFromResponsesPayload(responseData);
          if (usage != null) {
            streamLog.recordUsage(
              usage: usage.usage,
              promptTokens: usage.promptTokens,
              completionTokens: usage.completionTokens,
              reasoningTokens: usage.reasoningTokens,
            );
            yield usage;
          }
          final completed = _parseNonStreamingResponse(responseData);
          if ((completed.images.isNotEmpty) ||
              completed.finishReason != null ||
              completed.toolCalls != null) {
            yield completed;
          }
        }
      }
    }
    streamLog.logCompleted();
  }

  Map<String, dynamic> _buildRequestData({
    required List<Message> messages,
    required String model,
    required List<Map<String, dynamic>>? tools,
    required String? toolChoice,
    required bool stream,
  }) {
    final input = <Map<String, dynamic>>[];
    for (final message in messages) {
      final role = message.role.toLowerCase();
      final content = <Map<String, dynamic>>[];
      final text = message.content.trim();
      if (text.isNotEmpty) {
        content.add({
          'type': role == 'assistant' ? 'output_text' : 'input_text',
          'text': text,
        });
      }
      for (final image in message.images) {
        final imageUrl = image.trim();
        if (imageUrl.isEmpty) continue;
        content.add({
          'type': 'input_image',
          'image_url': imageUrl,
        });
      }
      for (final attachment in message.attachments) {
        final fileName = attachment.split(Platform.pathSeparator).last;
        content.add({
          'type': role == 'assistant' ? 'output_text' : 'input_text',
          'text': '[Attached File: $fileName]',
        });
      }
      if (role == 'tool') {
        content.add({
          'type': 'input_text',
          'text':
              '[Tool Result ${message.toolCallId ?? ''}] ${message.content}',
        });
      }
      if (content.isEmpty) continue;
      input.add({
        'type': 'message',
        'role': role == 'system' ? 'system' : role,
        'content': content,
      });
    }
    final requestData = <String, dynamic>{
      'model': model,
      'input': input,
      if (stream) 'stream': true,
    };
    final convertedTools = _convertTools(tools);
    if (convertedTools.isNotEmpty) {
      requestData['tools'] = convertedTools;
    }
    final convertedToolChoice = _convertToolChoice(toolChoice);
    if (convertedToolChoice != null) {
      requestData['tool_choice'] = convertedToolChoice;
    }
    return requestData;
  }

  List<Map<String, dynamic>> _convertTools(List<Map<String, dynamic>>? tools) {
    if (tools == null) return const [];
    final result = <Map<String, dynamic>>[];
    for (final tool in tools) {
      final type = tool['type']?.toString();
      if (type != 'function') continue;
      final function = tool['function'];
      if (function is! Map) continue;
      result.add({
        'type': 'function',
        'name': function['name'],
        if (function['description'] != null)
          'description': function['description'],
        'parameters': function['parameters'] ?? const {'type': 'object'},
      });
    }
    return result;
  }

  dynamic _convertToolChoice(String? toolChoice) {
    final raw = toolChoice?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('function:')) {
      final name = raw.substring('function:'.length).trim();
      if (name.isEmpty) return 'auto';
      return {'type': 'function', 'name': name};
    }
    return raw;
  }

  LLMResponseChunk _parseNonStreamingResponse(dynamic payload) {
    final normalized = _normalizePayload(payload);
    if (normalized is! Map) {
      throw AppException(
        type: AppErrorType.unknown,
        message: 'Responses API payload is not a JSON object.',
      );
    }
    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final images = <String>[];
    final toolCalls = <ToolCallChunk>[];
    final output = normalized['output'];
    if (output is List) {
      for (final item in output.whereType<Map>()) {
        final type = item['type']?.toString();
        if (type == 'message') {
          final content = item['content'];
          if (content is List) {
            for (final part in content.whereType<Map>()) {
              final partType = part['type']?.toString();
              if (partType == 'output_text') {
                contentBuffer.write(part['text']?.toString() ?? '');
              } else if (partType == 'reasoning') {
                reasoningBuffer.write(part['text']?.toString() ?? '');
              } else if (partType == 'output_image' ||
                  partType == 'image_generation_call') {
                final imageBase64 = part['result']?.toString();
                final imageUrl = part['url']?.toString();
                if (imageBase64 != null && imageBase64.isNotEmpty) {
                  images.add('data:image/png;base64,$imageBase64');
                } else if (imageUrl != null && imageUrl.isNotEmpty) {
                  images.add(imageUrl);
                }
              }
            }
          }
        } else if (type == 'function_call') {
          toolCalls.add(
            ToolCallChunk(
              id: item['id']?.toString(),
              type: 'function',
              name: item['name']?.toString(),
              arguments: item['arguments']?.toString(),
            ),
          );
        } else if (type == 'image_generation_call') {
          final imageBase64 = item['result']?.toString();
          final imageUrl = item['url']?.toString();
          if (imageBase64 != null && imageBase64.isNotEmpty) {
            images.add('data:image/png;base64,$imageBase64');
          } else if (imageUrl != null && imageUrl.isNotEmpty) {
            images.add(imageUrl);
          }
        }
      }
    }
    final usage = _usageFromResponsesPayload(normalized);
    return LLMResponseChunk(
      content: contentBuffer.isEmpty ? '' : contentBuffer.toString(),
      reasoning: reasoningBuffer.isEmpty ? null : reasoningBuffer.toString(),
      images: images,
      toolCalls: toolCalls.isEmpty ? null : toolCalls,
      usage: usage?.usage,
      promptTokens: usage?.promptTokens,
      completionTokens: usage?.completionTokens,
      reasoningTokens: usage?.reasoningTokens,
      finishReason: normalized['status']?.toString(),
    );
  }
}

class AnthropicMessagesChatHandler implements RoutedChatHandler {
  AnthropicMessagesChatHandler({
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 300),
                sendTimeout: const Duration(seconds: 120),
              ),
            );

  final Dio _dio;

  @override
  Future<LLMResponseChunk> getResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    required String model,
    required ProviderConfig provider,
    required ResolvedCapabilityRoute route,
    CancelToken? cancelToken,
  }) async {
    final apiKey = route.effectiveApiKey(provider);
    final uri = route.buildUri(model: model, apiKey: apiKey);
    final payload = _buildRequestData(
      messages: messages,
      model: model,
      tools: tools,
      toolChoice: toolChoice,
      stream: false,
    );
    _logRequest(uri.toString(), payload);
    final response = await _dio.postUri(
      uri,
      data: payload,
      options: Options(
        headers: route.buildHeaders(
          apiKey: apiKey,
          extra: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ),
      cancelToken: cancelToken,
    );
    final normalized = _normalizePayload(response.data);
    _logResponse(normalized);
    return _parseAnthropicMessage(normalized);
  }

  @override
  Stream<LLMResponseChunk> streamResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    required String model,
    required ProviderConfig provider,
    required ResolvedCapabilityRoute route,
    CancelToken? cancelToken,
  }) async* {
    final apiKey = route.effectiveApiKey(provider);
    final uri = route.buildUri(model: model, apiKey: apiKey);
    final payload = _buildRequestData(
      messages: messages,
      model: model,
      tools: tools,
      toolChoice: toolChoice,
      stream: true,
    );
    _logRequest(uri.toString(), payload);
    final streamLog = LlmStreamLogAccumulator(
      providerId: provider.id,
      model: model,
    );
    final response = await _dio.postUri<ResponseBody>(
      uri,
      data: payload,
      options: Options(
        responseType: ResponseType.stream,
        headers: route.buildHeaders(
          apiKey: apiKey,
          extra: const {
            'Accept': 'text/event-stream',
            'Content-Type': 'application/json',
          },
        ),
      ),
      cancelToken: cancelToken,
    );
    final body = response.data;
    if (body == null) return;
    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || !line.startsWith('data:')) continue;
      final data = line.substring(5).trimLeft();
      if (data == '[DONE]') {
        streamLog.recordDoneMarkerSeen();
        break;
      }
      final payload = _normalizePayload(data);
      if (payload is! Map) continue;
      streamLog.recordSseEvent();
      final type = payload['type']?.toString();
      if (type == 'content_block_delta') {
        final delta = payload['delta'];
        if (delta is Map) {
          final deltaType = delta['type']?.toString();
          if (deltaType == 'text_delta') {
            final text = delta['text']?.toString();
            if (text != null && text.isNotEmpty) {
              streamLog.recordEmission(content: text);
              yield LLMResponseChunk(content: text);
            }
          } else if (deltaType == 'thinking_delta') {
            final text = delta['thinking']?.toString();
            if (text != null && text.isNotEmpty) {
              streamLog.recordEmission(reasoning: text);
              yield LLMResponseChunk(reasoning: text);
            }
          } else if (deltaType == 'input_json_delta') {
            final partial = delta['partial_json']?.toString();
            if (partial != null && partial.isNotEmpty) {
              yield LLMResponseChunk(
                toolCalls: [
                  ToolCallChunk(
                    type: 'function',
                    arguments: partial,
                  ),
                ],
              );
            }
          }
        }
      } else if (type == 'content_block_start') {
        final block = payload['content_block'];
        if (block is Map && block['type']?.toString() == 'tool_use') {
          yield LLMResponseChunk(
            toolCalls: [
              ToolCallChunk(
                id: block['id']?.toString(),
                type: 'function',
                name: block['name']?.toString(),
              ),
            ],
          );
        }
      } else if (type == 'message_delta') {
        final usage = payload['usage'];
        if (usage is Map) {
          final promptTokens = (usage['input_tokens'] as num?)?.toInt();
          final completionTokens = (usage['output_tokens'] as num?)?.toInt();
          if (promptTokens != null || completionTokens != null) {
            final usageChunk = LLMResponseChunk(
              usage: (promptTokens ?? 0) + (completionTokens ?? 0),
              promptTokens: promptTokens,
              completionTokens: completionTokens,
            );
            streamLog.recordUsage(
              usage: usageChunk.usage,
              promptTokens: promptTokens,
              completionTokens: completionTokens,
              reasoningTokens: null,
            );
            yield usageChunk;
          }
        }
      } else if (type == 'message_stop') {
        streamLog.recordEmission();
      }
    }
    streamLog.logCompleted();
  }

  Map<String, dynamic> _buildRequestData({
    required List<Message> messages,
    required String model,
    required List<Map<String, dynamic>>? tools,
    required String? toolChoice,
    required bool stream,
  }) {
    final systemMessages = <String>[];
    final anthropicMessages = <Map<String, dynamic>>[];
    for (final message in messages) {
      final role = message.role.toLowerCase();
      if (role == 'system') {
        final text = message.content.trim();
        if (text.isNotEmpty) {
          systemMessages.add(text);
        }
        continue;
      }
      if (role == 'tool') {
        anthropicMessages.add({
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': message.toolCallId,
              'content': message.content,
            }
          ],
        });
        continue;
      }
      final content = <Map<String, dynamic>>[];
      final text = message.content.trim();
      if (text.isNotEmpty) {
        content.add({'type': 'text', 'text': text});
      }
      for (final image in message.images) {
        if (image.startsWith('data:')) {
          final match = RegExp(r'^data:([^;]+);base64,(.+)$').firstMatch(image);
          if (match != null) {
            content.add({
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': match.group(1),
                'data': match.group(2),
              }
            });
          }
        } else if (image.startsWith('http://') ||
            image.startsWith('https://')) {
          content.add({'type': 'text', 'text': image});
        }
      }
      if (message.toolCalls?.isNotEmpty ?? false) {
        for (final toolCall in message.toolCalls!) {
          final input = _decodeJson(toolCall.arguments);
          content.add({
            'type': 'tool_use',
            'id': toolCall.id,
            'name': toolCall.name,
            'input': input is Map ? input : {'value': input},
          });
        }
      }
      if (content.isEmpty) continue;
      anthropicMessages.add({
        'role': role == 'assistant' ? 'assistant' : 'user',
        'content': content,
      });
    }
    final payload = <String, dynamic>{
      'model': model,
      'messages': anthropicMessages,
      if (systemMessages.isNotEmpty) 'system': systemMessages.join('\n\n'),
      if (stream) 'stream': true,
      'max_tokens': 4096,
    };
    if (tools != null && tools.isNotEmpty) {
      payload['tools'] = tools
          .where((tool) => tool['type']?.toString() == 'function')
          .map((tool) {
        final function = tool['function'] as Map? ?? const {};
        return {
          'name': function['name'],
          if (function['description'] != null)
            'description': function['description'],
          'input_schema': function['parameters'] ?? const {'type': 'object'},
        };
      }).toList();
    }
    final rawToolChoice = toolChoice?.trim();
    if (rawToolChoice != null && rawToolChoice.isNotEmpty) {
      payload['tool_choice'] = rawToolChoice == 'required'
          ? {'type': 'any'}
          : (rawToolChoice.startsWith('function:')
              ? {
                  'type': 'tool',
                  'name': rawToolChoice.substring('function:'.length).trim(),
                }
              : {'type': rawToolChoice});
    }
    return payload;
  }

  LLMResponseChunk _parseAnthropicMessage(dynamic payload) {
    final normalized = _normalizePayload(payload);
    if (normalized is! Map) {
      throw AppException(
        type: AppErrorType.unknown,
        message: 'Anthropic message payload is not a JSON object.',
      );
    }
    final text = StringBuffer();
    final reasoning = StringBuffer();
    final toolCalls = <ToolCallChunk>[];
    final content = normalized['content'];
    if (content is List) {
      for (final block in content.whereType<Map>()) {
        final type = block['type']?.toString();
        if (type == 'text') {
          text.write(block['text']?.toString() ?? '');
        } else if (type == 'thinking') {
          reasoning.write(block['thinking']?.toString() ?? '');
        } else if (type == 'tool_use') {
          toolCalls.add(
            ToolCallChunk(
              id: block['id']?.toString(),
              type: 'function',
              name: block['name']?.toString(),
              arguments: jsonEncode(block['input'] ?? const {}),
            ),
          );
        }
      }
    }
    final usage = normalized['usage'];
    final promptTokens =
        usage is Map ? (usage['input_tokens'] as num?)?.toInt() : null;
    final completionTokens =
        usage is Map ? (usage['output_tokens'] as num?)?.toInt() : null;
    return LLMResponseChunk(
      content: text.toString(),
      reasoning: reasoning.isEmpty ? null : reasoning.toString(),
      toolCalls: toolCalls.isEmpty ? null : toolCalls,
      usage: (promptTokens ?? 0) + (completionTokens ?? 0),
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      finishReason: normalized['stop_reason']?.toString(),
    );
  }
}

LLMResponseChunk? _usageFromResponsesPayload(Map responseData) {
  final usage = responseData['usage'];
  if (usage is! Map) return null;
  final promptTokens = (usage['input_tokens'] as num?)?.toInt();
  final completionTokens = (usage['output_tokens'] as num?)?.toInt();
  final reasoningTokens = (usage['reasoning_tokens'] as num?)?.toInt();
  final totalTokens = (usage['total_tokens'] as num?)?.toInt() ??
      ((promptTokens ?? 0) + (completionTokens ?? 0) + (reasoningTokens ?? 0));
  return LLMResponseChunk(
    usage: totalTokens,
    promptTokens: promptTokens,
    completionTokens: completionTokens,
    reasoningTokens: reasoningTokens,
  );
}

dynamic _decodeJson(String raw) {
  try {
    return jsonDecode(raw);
  } catch (_) {
    return raw;
  }
}

dynamic _normalizePayload(dynamic payload) {
  if (payload is String) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) return payload;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return payload;
    }
  }
  return payload;
}

void _logRequest(String url, Map<String, dynamic> data) {
  AppLogger.llmRequest(url: url, payload: data);
}

void _logResponse(dynamic payload) {
  AppLogger.llmResponse(payload: payload);
}
