import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:archive/archive.dart';
import '../../features/chat/domain/message.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'llm_service.dart';
import '../../core/error/app_exception.dart';
import '../../core/error/app_error_type.dart';
import '../utils/app_logger.dart';

part 'openai/openai_attachments.dart';
part 'openai/openai_provider_compat.dart';
part 'openai/openai_request_builder.dart';

class OpenAILLMService implements LLMService {
  final Dio _dio;
  final SettingsState _settings;
  final Map<String, String> _imageThoughtSignatureByUrl = {};
  OpenAILLMService(this._settings)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 300),
          sendTimeout: const Duration(seconds: 60),
          headers: {
            'Connection': 'keep-alive',
            'User-Agent': 'Aurora/1.0 (Flutter; Dio)',
          },
        ));

  String? _normalizeThoughtSignature(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    return value;
  }

  String? _extractThoughtSignatureFromImageItem(dynamic item) {
    if (item is! Map) return null;
    final snake = _normalizeThoughtSignature(item['thought_signature']);
    if (snake != null) return snake;
    final camel = _normalizeThoughtSignature(item['thoughtSignature']);
    if (camel != null) return camel;
    final nested = item['image_url'];
    if (nested is Map) {
      final nestedSnake =
          _normalizeThoughtSignature(nested['thought_signature']);
      if (nestedSnake != null) return nestedSnake;
      return _normalizeThoughtSignature(nested['thoughtSignature']);
    }
    return null;
  }

  void _rememberImageThoughtSignature(String? imageUrl, String? signature) {
    if (imageUrl == null || imageUrl.isEmpty || signature == null) return;
    _imageThoughtSignatureByUrl[imageUrl] = signature;
    // Prevent unbounded growth when many generated images appear in one run.
    if (_imageThoughtSignatureByUrl.length > 128) {
      _imageThoughtSignatureByUrl
          .remove(_imageThoughtSignatureByUrl.keys.first);
    }
  }

  String _resolveOutgoingThoughtSignature(String imageUrl) {
    final cached = _imageThoughtSignatureByUrl[imageUrl];
    if (cached != null && cached.trim().isNotEmpty) return cached;
    // TODO(usaki): Temporary fallback for proxy chains that drop or rename
    // thought_signature during OpenAI<->Gemini conversion.
    // Proper fix: persist per-image thought_signature in message state and send
    // the original signature value end-to-end (no synthetic sentinel).
    // Remove this sentinel once translator compatibility is verified.
    return 'skip_thought_signature_validator';
  }

  void _debugLog(String message,
      {String level = 'DEBUG', String category = 'GENERAL'}) {
    assert(() {
      final normalizedMessage = message.replaceAll('\n', r'\n');
      switch (level.toUpperCase()) {
        case 'ERROR':
          AppLogger.error('LLM', normalizedMessage, category: category);
          break;
        case 'WARN':
          AppLogger.warn('LLM', normalizedMessage, category: category);
          break;
        case 'INFO':
          AppLogger.info('LLM', normalizedMessage, category: category);
          break;
        case 'DEBUG':
        default:
          AppLogger.debug('LLM', normalizedMessage, category: category);
          break;
      }
      return true;
    }());
  }

  dynamic _sanitizeForLog(dynamic data) {
    if (data is ResponseBody) {
      return {
        'content_type': 'ResponseBody',
        'status_code': data.statusCode,
        if (data.statusMessage != null) 'status_message': data.statusMessage,
        'headers': data.headers,
        'stream': '[OMITTED_STREAM]',
      };
    }
    if (data is Map) {
      return data.map((k, v) {
        if (k == 'b64_json' && v is String && v.length > 200) {
          return MapEntry(
              k, '${v.substring(0, 50)}...[TRUNCATED ${v.length} chars]');
        }
        if (k == 'url' &&
            v is String &&
            v.startsWith('data:') &&
            v.length > 200) {
          return MapEntry(
              k, '${v.substring(0, 50)}...[TRUNCATED ${v.length} chars]');
        }
        return MapEntry(k, _sanitizeForLog(v));
      });
    } else if (data is List) {
      return data.map((i) => _sanitizeForLog(i)).toList();
    } else if (data is String) {
      if (data.length > 800) {
        return '${data.substring(0, 200)}...[TRUNCATED ${data.length} chars]';
      }
      if (data.startsWith('data:') && data.length > 200) {
        return '${data.substring(0, 50)}...[TRUNCATED ${data.length} chars]';
      }
    }
    return data;
  }

  void _logEvent(String category, dynamic payload, {String level = 'DEBUG'}) {
    assert(() {
      final sanitized = _sanitizeForLog(payload);
      var effectiveCategory = category;
      var effectiveLevel = level.toUpperCase();
      dynamic effectivePayload = sanitized;
      try {
        jsonEncode(sanitized);
      } catch (e) {
        effectivePayload = 'Log serialization failed: $e';
        effectiveLevel = 'ERROR';
        effectiveCategory = 'LOG_SERIALIZATION';
      }
      switch (effectiveLevel) {
        case 'ERROR':
          AppLogger.error('LLM', 'event',
              category: effectiveCategory, data: effectivePayload);
          break;
        case 'WARN':
          AppLogger.warn('LLM', 'event',
              category: effectiveCategory, data: effectivePayload);
          break;
        case 'INFO':
          AppLogger.info('LLM', 'event',
              category: effectiveCategory, data: effectivePayload);
          break;
        case 'DEBUG':
        default:
          AppLogger.debug('LLM', 'event',
              category: effectiveCategory, data: effectivePayload);
          break;
      }
      return true;
    }());
  }

  void _logRequest(String url, Map<String, dynamic> data) {
    assert(() {
      try {
        AppLogger.llmRequest(url: url, payload: _sanitizeForLog(data));
      } catch (e) {
        AppLogger.error('LLM', 'Request log error: $e',
            category: 'REQUEST_LOG');
      }
      return true;
    }());
  }

  void _logResponse(dynamic data) {
    assert(() {
      try {
        AppLogger.llmResponse(payload: _sanitizeForLog(data));
      } catch (e) {
        AppLogger.error('LLM', 'Response log error: $e',
            category: 'RESPONSE_LOG');
      }
      return true;
    }());
  }

  @override
  Stream<LLMResponseChunk> streamResponse(List<Message> messages,
      {List<Map<String, dynamic>>? tools,
      String? toolChoice,
      String? model,
      String? providerId,
      CancelToken? cancelToken}) async* {
    final provider = _resolveProvider(providerId);
    final selectedModel = _resolveSelectedModel(
      provider: provider,
      requestedModel: model,
    );
    if (selectedModel == null) {
      yield LLMResponseChunk(content: _missingModelMessage());
      return;
    }
    if (provider.apiKey.isEmpty) {
      yield LLMResponseChunk(content: _emptyApiKeyMessage());
      return;
    }
    try {
      final prepared = await _buildPreparedChatRequest(
        messages: messages,
        provider: provider,
        selectedModel: selectedModel,
        stream: true,
        tools: tools,
        toolChoice: toolChoice,
      );
      final baseUrl = prepared.baseUrl;
      final apiKey = prepared.apiKey;
      final requestData = prepared.requestData;

      _logRequest('${baseUrl}chat/completions', requestData);
      Response<ResponseBody> response;
      try {
        response = await _dio.post(
          '${baseUrl}chat/completions',
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Accept': 'text/event-stream',
            },
            responseType: ResponseType.stream,
          ),
          data: requestData,
          cancelToken: cancelToken,
        );
      } on DioException catch (e) {
        final isGemini = selectedModel.toLowerCase().contains('gemini');
        if (isGemini &&
            e.type == DioExceptionType.badResponse &&
            e.response?.statusCode == 400 &&
            requestData.containsKey('stream_options')) {
          final retryData = Map<String, dynamic>.from(requestData)
            ..remove('stream_options');
          _debugLog(
              'Gemini backend rejected stream_options (400). Retrying without it.');
          _logRequest('${baseUrl}chat/completions', retryData);
          response = await _dio.post(
            '${baseUrl}chat/completions',
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'Accept': 'text/event-stream',
              },
              responseType: ResponseType.stream,
            ),
            data: retryData,
            cancelToken: cancelToken,
          );
        } else {
          rethrow;
        }
      }
      final stream = response.data!.stream as Stream<List<int>>;
      String lineBuffer = '';
      bool isInThoughtTag = false;

      await for (final chunk
          in stream.cast<List<int>>().transform(utf8.decoder)) {
        lineBuffer += chunk;
        while (lineBuffer.contains('\n')) {
          final nlIndex = lineBuffer.indexOf('\n');
          final line = lineBuffer.substring(0, nlIndex).trim();
          lineBuffer = lineBuffer.substring(nlIndex + 1);
          if (line.isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              _debugLog('DONE', category: 'STREAM');
              return;
            }
            try {
              final json = jsonDecode(data);
              _logResponse(json);
              if (json['usage'] != null) {
                final usage = json['usage'];
                final int? completionTokens = usage['completion_tokens'];
                final int? promptTokens = usage['prompt_tokens'];
                final int? totalTokens = usage['total_tokens'];
                int? reasoningTokens;
                if (usage['completion_tokens_details'] != null) {
                  reasoningTokens = usage['completion_tokens_details']
                      ['reasoning_tokens'] as int?;
                } else if (usage['reasoning_tokens'] != null) {
                  reasoningTokens = usage['reasoning_tokens'] as int?;
                }

                // Total generated = completion + reasoning (hidden or visible)
                final int totalGenerated =
                    (completionTokens ?? 0) + (reasoningTokens ?? 0);
                // Absolute total consumption for tokenCount display
                final int totalConsume = (promptTokens ?? 0) + totalGenerated;

                if (completionTokens != null || totalTokens != null) {
                  yield LLMResponseChunk(
                    usage: totalConsume > 0
                        ? totalConsume
                        : (totalTokens ?? completionTokens),
                    promptTokens: promptTokens,
                    completionTokens: completionTokens,
                    reasoningTokens: reasoningTokens,
                  );
                }
              }
              final choicesRaw = json['choices'];
              if (choicesRaw == null) continue;
              final choices = choicesRaw as List;
              if (choices.isNotEmpty) {
                final delta = choices[0]['delta'];
                if (delta != null) {
                  final finishReason = choices[0]['finish_reason'];
                  final String? rawContent = delta['content'];
                  String? content = rawContent;
                  String? reasoning =
                      delta['reasoning_content'] ?? delta['reasoning'];

                  // 1. Handle Gemini Google Thinking Metadata
                  final bool isGoogleThought =
                      delta['extra_content']?['google']?['thought'] == true;
                  if (isGoogleThought && content != null) {
                    reasoning = (reasoning ?? '') + content;
                    content = null;
                  }

                  // 2. Handle XML-style tags (<thought> or <think>)
                  if (content != null) {
                    // Check for start tags
                    if (content.contains('<thought>')) {
                      isInThoughtTag = true;
                      final parts = content.split('<thought>');
                      final before = parts[0];
                      final after = parts.sublist(1).join('<thought>');
                      content = before.isEmpty ? null : before;
                      reasoning = (reasoning ?? '') + after;
                    } else if (content.contains('<think>')) {
                      isInThoughtTag = true;
                      final parts = content.split('<think>');
                      final before = parts[0];
                      final after = parts.sublist(1).join('<think>');
                      content = before.isEmpty ? null : before;
                      reasoning = (reasoning ?? '') + after;
                    }

                    // Check for end tags
                    if (content != null &&
                        (content.contains('</thought>') ||
                            content.contains('</think>'))) {
                      final isEndThought = content.contains('</thought>');
                      final tag = isEndThought ? '</thought>' : '</think>';
                      final parts = content.split(tag);
                      final inside = parts[0];
                      final outside = parts.sublist(1).join(tag);

                      reasoning = (reasoning ?? '') + inside;
                      content = outside.isEmpty ? null : outside;
                      isInThoughtTag = false;
                    } else if (isInThoughtTag) {
                      // If we are currently inside a tag, all content goes to reasoning
                      reasoning = (reasoning ?? '') + content!;
                      content = null;
                    }
                  }
                  final toolCalls = delta['tool_calls'];

                  String? imageUrl;
                  String? imageThoughtSignature;
                  if (choices[0]['b64_json'] != null) {
                    imageUrl =
                        'data:image/png;base64,${choices[0]['b64_json']}';
                  } else if (choices[0]['url'] != null) {
                    imageUrl = choices[0]['url'];
                  }
                  if (imageUrl == null) {
                    if (delta['b64_json'] != null) {
                      imageUrl = 'data:image/png;base64,${delta['b64_json']}';
                    } else if (delta['url'] != null) {
                      imageUrl = delta['url'];
                    } else if (delta['image'] != null) {
                      final imgVal = delta['image'];
                      if (imgVal.toString().startsWith('http')) {
                        imageUrl = imgVal;
                      } else {
                        imageUrl = 'data:image/png;base64,$imgVal';
                      }
                    } else if (delta['inline_data'] != null) {
                      final inlineData = delta['inline_data'];
                      if (inlineData is Map) {
                        final mimeType = inlineData['mime_type'] ?? 'image/png';
                        final data = inlineData['data'];
                        if (data != null) {
                          imageUrl = 'data:$mimeType;base64,$data';
                        }
                      }
                    } else if (delta['parts'] != null &&
                        delta['parts'] is List) {
                      final parts = delta['parts'] as List;
                      for (final part in parts) {
                        if (part is Map && part['inline_data'] != null) {
                          final inlineData = part['inline_data'];
                          if (inlineData is Map) {
                            final mimeType =
                                inlineData['mime_type'] ?? 'image/png';
                            final data = inlineData['data'];
                            if (data != null) {
                              imageUrl = 'data:$mimeType;base64,$data';
                              break;
                            }
                          }
                        }
                      }
                    } else if (delta['images'] != null &&
                        delta['images'] is List) {
                      final images = delta['images'] as List;
                      for (final imgData in images) {
                        String? candidateUrl;
                        String? candidateSignature =
                            _extractThoughtSignatureFromImageItem(imgData);
                        if (imgData is String) {
                          if (imgData.startsWith('http') ||
                              imgData.startsWith('data:image')) {
                            candidateUrl = imgData;
                          } else {
                            candidateUrl = 'data:image/png;base64,$imgData';
                          }
                        } else if (imgData is Map) {
                          if (imgData['url'] != null) {
                            final url = imgData['url'].toString();
                            candidateUrl = (url.startsWith('http') ||
                                    url.startsWith('data:'))
                                ? url
                                : 'data:image/png;base64,$url';
                          } else if (imgData['data'] != null) {
                            candidateUrl =
                                'data:image/png;base64,${imgData['data']}';
                          } else if (imgData['image_url'] != null) {
                            final imgUrlObj = imgData['image_url'];
                            if (imgUrlObj is Map && imgUrlObj['url'] != null) {
                              candidateUrl = imgUrlObj['url'].toString();
                              candidateSignature ??=
                                  _extractThoughtSignatureFromImageItem(
                                      imgUrlObj);
                            } else if (imgUrlObj is String) {
                              candidateUrl = imgUrlObj;
                            }
                          }
                        }
                        if (candidateUrl != null && candidateUrl.isNotEmpty) {
                          imageUrl = candidateUrl;
                          imageThoughtSignature = candidateSignature;
                          break;
                        }
                      }
                    }
                  }
                  if (delta['content'] is List) {
                    final contentList = delta['content'] as List;
                    for (final item in contentList) {
                      if (item is Map && item['type'] == 'image_url') {
                        final url = item['image_url']?['url'];
                        if (url != null) {
                          imageUrl = url;
                          imageThoughtSignature =
                              _extractThoughtSignatureFromImageItem(item);
                          break;
                        }
                      }
                    }
                  }

                  if (imageUrl != null) {
                    _rememberImageThoughtSignature(
                        imageUrl, imageThoughtSignature);
                    yield LLMResponseChunk(
                        content: '',
                        images: [imageUrl],
                        finishReason: finishReason);
                  } else if (content != null ||
                      reasoning != null ||
                      (toolCalls != null && toolCalls is List) ||
                      finishReason != null) {
                    // Yield chunk if we have content, reasoning, tools, OR a finish reason
                    List<ToolCallChunk>? parsedToolCalls;
                    if (toolCalls != null && toolCalls is List) {
                      try {
                        parsedToolCalls = (toolCalls)
                            .map((toolCall) {
                              final int? index = toolCall['index'];
                              final String? id = toolCall['id'];
                              final String? type = toolCall['type'];
                              final Map? function = toolCall['function'];
                              String? name;
                              String? arguments;
                              if (function != null) {
                                name = function['name'];
                                arguments = function['arguments'];
                              }
                              return ToolCallChunk(
                                  index: index,
                                  id: id,
                                  type: type,
                                  name: name,
                                  arguments: arguments);
                            })
                            .toList()
                            .cast<ToolCallChunk>();
                      } catch (e) {
                        _debugLog('Tool call parse error: $e');
                        parsedToolCalls = null;
                      }
                    }
                    yield LLMResponseChunk(
                        content: content,
                        reasoning: reasoning,
                        toolCalls: parsedToolCalls,
                        finishReason: finishReason);
                  }
                }
              }
            } catch (e) {
              _debugLog('LLM Stream Parse Error: $e');
            }
          }
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _debugLog('Request was cancelled by the user.',
            level: 'INFO', category: 'REQUEST_CANCELLED');
        return;
      }
      final statusCode = e.response?.statusCode;
      String errorMsg = 'HTTP Error';
      AppErrorType errorType = AppErrorType.unknown;

      // Determine Error Type
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorType = AppErrorType.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        errorType = AppErrorType.network;
      } else if (e.type == DioExceptionType.badResponse) {
        if (statusCode == 400) {
          errorType = AppErrorType.badRequest;
        } else if (statusCode == 401 || statusCode == 403) {
          errorType = AppErrorType.unauthorized;
        } else if (statusCode == 429) {
          errorType = AppErrorType.rateLimit;
        } else if (statusCode != null && statusCode >= 500) {
          errorType = AppErrorType.serverError;
        }
      }

      try {
        if (e.response?.data != null) {
          final responseData = e.response?.data;
          _logEvent('ERROR_RESPONSE', responseData, level: 'ERROR');
          if (responseData is ResponseBody) {
            final stream = responseData.stream;
            final bytes = await stream
                .fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
            final errorBody = utf8.decode(bytes);
            _logEvent('ERROR_BODY', errorBody, level: 'ERROR');
            try {
              final json = jsonDecode(errorBody);
              if (json is Map) {
                final error = json['error'];
                if (error is Map) {
                  errorMsg = 'HTTP $statusCode: ${error['message'] ?? error}';
                } else if (json['message'] != null) {
                  errorMsg = 'HTTP $statusCode: ${json['message']}';
                } else {
                  errorMsg = 'HTTP $statusCode: $errorBody';
                }
              } else {
                errorMsg = 'HTTP $statusCode: $errorBody';
              }
            } catch (_) {
              errorMsg = 'HTTP $statusCode: $errorBody';
            }
          } else if (responseData is Map) {
            final error = responseData['error'];
            if (error is Map && error['message'] != null) {
              errorMsg = 'HTTP $statusCode: ${error['message']}';
            } else if (responseData['message'] != null) {
              errorMsg = 'HTTP $statusCode: ${responseData['message']}';
            } else {
              errorMsg = 'HTTP $statusCode: $responseData';
            }
          } else if (responseData is String) {
            errorMsg = 'HTTP $statusCode: $responseData';
          } else {
            errorMsg = 'HTTP $statusCode: ${e.message}';
          }
        } else {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
              errorMsg = 'Connection Timeout';
              break;
            case DioExceptionType.sendTimeout:
              errorMsg = 'Send Timeout';
              break;
            case DioExceptionType.receiveTimeout:
              errorMsg = 'Receive Timeout';
              break;
            case DioExceptionType.connectionError:
              errorMsg = 'Connection Error: ${e.message}';
              break;
            default:
              errorMsg = 'Network Error: ${e.message}';
          }
        }
      } catch (readError) {
        errorMsg = 'HTTP $statusCode: ${e.message}';
      }
      throw AppException(
          type: errorType, message: errorMsg, statusCode: statusCode);
    } catch (e) {
      if (e is AppException) rethrow; // Pass through our custom exceptions
      throw AppException(type: AppErrorType.unknown, message: e.toString());
    }
  }

  String _getMimeType(String path) {
    final p = path.toLowerCase();
    // Images
    if (p.endsWith('png')) return 'image/png';
    if (p.endsWith('jpg') || p.endsWith('jpeg')) return 'image/jpeg';
    if (p.endsWith('webp')) return 'image/webp';
    if (p.endsWith('gif')) return 'image/gif';
    if (p.endsWith('bmp')) return 'image/bmp';

    // Audio
    if (p.endsWith('mp3')) return 'audio/mpeg';
    if (p.endsWith('wav')) return 'audio/wav';
    if (p.endsWith('m4a')) return 'audio/x-m4a';
    if (p.endsWith('flac')) return 'audio/flac';
    if (p.endsWith('ogg')) return 'audio/ogg';
    if (p.endsWith('opus')) return 'audio/opus';
    if (p.endsWith('aac')) return 'audio/aac';

    // Video
    if (p.endsWith('mp4')) return 'video/mp4';
    if (p.endsWith('mov')) return 'video/quicktime';
    if (p.endsWith('avi')) return 'video/x-msvideo';
    if (p.endsWith('webm')) return 'video/webm';
    if (p.endsWith('mkv')) return 'video/x-matroska';
    if (p.endsWith('flv')) return 'video/x-flv';
    if (p.endsWith('3gp')) return 'video/3gpp';
    if (p.endsWith('mpg') || p.endsWith('mpeg')) return 'video/mpeg';

    // Documents
    if (p.endsWith('pdf')) return 'application/pdf';
    if (p.endsWith('txt')) return 'text/plain';
    if (p.endsWith('md')) return 'text/markdown';
    if (p.endsWith('csv')) return 'text/csv';
    if (p.endsWith('json')) return 'application/json';
    if (p.endsWith('xml')) return 'application/xml';
    if (p.endsWith('yaml') || p.endsWith('yml')) return 'text/yaml';
    if (p.endsWith('docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (p.endsWith('doc')) return 'application/msword';
    if (p.endsWith('xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (p.endsWith('xls')) return 'application/vnd.ms-excel';
    if (p.endsWith('pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (p.endsWith('ppt')) return 'application/vnd.ms-powerpoint';

    return 'application/octet-stream';
  }

  Future<List<Map<String, dynamic>>> _buildApiMessages(
      List<Message> messages) async {
    final List<Map<String, dynamic>> result = [];
    final Set<String> knownToolCallIds = {};
    for (final m in messages) {
      if (m.role == 'tool') {
        final toolCallId = m.toolCallId;
        if (toolCallId != null && knownToolCallIds.contains(toolCallId)) {
          result.add({
            'role': 'tool',
            'tool_call_id': toolCallId,
            'content': m.content,
          });
        } else {
          // Some OpenAI-compatible backends (notably Gemini compatibility layers)
          // reject tool-role messages unless they correspond to an assistant tool_call.
          // Aurora's built-in web search uses a <search> tag workflow instead of
          // tool_calls, so we degrade gracefully by sending it as plain user context.
          String toolName = 'Tool';
          if (toolCallId != null && toolCallId.startsWith('search_')) {
            toolName = 'SearchWeb';
          }
          result.add({
            'role': 'user',
            'content': '<result name="$toolName">\n${m.content}\n</result>',
          });
        }
        continue;
      }
      if (m.role == 'assistant' &&
          m.content.trim().isEmpty &&
          (m.toolCalls == null || m.toolCalls!.isEmpty) &&
          m.attachments.isEmpty &&
          m.images.isEmpty) {
        continue;
      }
      if (m.role == 'assistant' &&
          m.toolCalls != null &&
          m.toolCalls!.isNotEmpty) {
        knownToolCallIds.addAll(m.toolCalls!.map((tc) => tc.id));
        result.add({
          'role': 'assistant',
          'content': m.content.isEmpty ? null : m.content,
          'tool_calls': m.toolCalls!
              .map((tc) => {
                    'id': tc.id,
                    'type': 'function',
                    'function': {'name': tc.name, 'arguments': tc.arguments}
                  })
              .toList(),
        });
        continue;
      }
      final hasAttachments = m.attachments.isNotEmpty;
      final hasImages = m.images.isNotEmpty;
      if (!hasAttachments && !hasImages) {
        result.add({
          'role': m.role,
          'content': m.content,
        });
        continue;
      }
      {
        final List<Map<String, dynamic>> contentList = [];
        if (m.content.isNotEmpty) {
          contentList.add({
            'type': 'text',
            'text': m.content,
          });
        }
        for (final path in m.attachments) {
          try {
            final file = File(path);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final base64Data = base64Encode(bytes);
              final mimeType = _getMimeType(path);

              if (mimeType.startsWith('image/') ||
                  mimeType.startsWith('audio/') ||
                  mimeType.startsWith('video/') ||
                  mimeType == 'application/pdf') {
                // 由于反代层 (CLIProxyAPI) 目前仅处理 'image_url' 类型并从中提取 MIME，
                // 我们必须统一使用该字段以确保音频/视频/PDF能被正确转发给 Gemini。
                contentList.add({
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Data',
                  },
                });
              } else if (mimeType
                      .endsWith('officedocument.wordprocessingml.document') ||
                  mimeType == 'application/msword') {
                // Perform deep extraction (Text + Images) for Word documents
                final docxParts = _extractDocxContent(
                    bytes, path.split(Platform.pathSeparator).last);
                if (docxParts.isNotEmpty) {
                  contentList.addAll(docxParts);
                } else {
                  // Fallback to binary transmission via image_url (the only multimodal channel we have)
                  contentList.add({
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:$mimeType;base64,$base64Data',
                    },
                  });
                }
              } else if (mimeType.contains('officedocument') ||
                  mimeType == 'application/vnd.ms-excel' ||
                  mimeType == 'application/vnd.ms-powerpoint' ||
                  mimeType == 'application/vnd.ms-excel') {
                // Other Office documents: send as binary via image_url and hope for the best
                contentList.add({
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Data',
                  },
                });
              } else if (mimeType.startsWith('text/') ||
                  mimeType == 'application/json' ||
                  mimeType == 'application/xml') {
                try {
                  final textContent = await file.readAsString();
                  contentList.add({
                    'type': 'text',
                    'text':
                        '--- File: ${path.split(Platform.pathSeparator).last} ---\n$textContent\n--- End File ---',
                  });
                } catch (e) {
                  // Fallback to placeholder if read fails (e.g. encoding issue)
                  contentList.add({
                    'type': 'text',
                    'text':
                        '[Attached File: ${path.split(Platform.pathSeparator).last} ($mimeType)]',
                  });
                }
              } else {
                // Fallback for other documents: send as text or metadata if possible
                // For now, just a placeholder indicator
                contentList.add({
                  'type': 'text',
                  'text':
                      '[Attached File: ${path.split(Platform.pathSeparator).last} ($mimeType)]',
                });
              }
            }
          } catch (e) {
            contentList.add({
              'type': 'text',
              'text': '[Failed to load file: $path]',
            });
          }
        }
        if (m.images.isNotEmpty) {
          final lastImage = m.images.last;
          // TODO(usaki): Promote to structured image parts in Message model so
          // we can preserve per-image metadata (including thought_signature)
          // across full multi-image histories instead of last-image fallback.
          if (lastImage.startsWith('data:')) {
            if (!m.isUser) {
              contentList.add({
                'type': 'image_url',
                'image_url': {
                  'url': lastImage,
                },
                'thought_signature':
                    _resolveOutgoingThoughtSignature(lastImage),
              });
            } else {
              contentList.add({
                'type': 'image_url',
                'image_url': {
                  'url': lastImage,
                },
              });
            }
          }
        }
        result.add({
          'role': m.role,
          'content': contentList,
        });
      }
    }
    return result;
  }

  int _estimateRequestSize(List<Map<String, dynamic>> apiMessages) {
    try {
      final json = jsonEncode(apiMessages);
      return utf8.encode(json).length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _compressApiMessagesIfNeeded(
      List<Map<String, dynamic>> apiMessages) async {
    const maxSizeBytes = 4 * 1024 * 1024;
    final currentSize = _estimateRequestSize(apiMessages);
    if (currentSize <= maxSizeBytes) {
      return apiMessages;
    }
    try {
      return await compute(_compressImagesTask, apiMessages);
    } catch (e) {
      _debugLog(
          'Element compression in background failed: $e. Falling back to original.');
      return apiMessages;
    }
  }

  @override
  Future<LLMResponseChunk> getResponse(List<Message> messages,
      {List<Map<String, dynamic>>? tools,
      String? toolChoice,
      String? model,
      String? providerId,
      CancelToken? cancelToken}) async {
    final provider = _resolveProvider(providerId);
    final selectedModel = _resolveSelectedModel(
      provider: provider,
      requestedModel: model,
    );
    if (selectedModel == null) {
      return LLMResponseChunk(content: _missingModelMessage());
    }
    if (provider.apiKey.isEmpty) {
      return LLMResponseChunk(content: _emptyApiKeyMessage());
    }
    try {
      final prepared = await _buildPreparedChatRequest(
        messages: messages,
        provider: provider,
        selectedModel: selectedModel,
        stream: false,
        tools: tools,
        toolChoice: toolChoice,
      );
      final baseUrl = prepared.baseUrl;
      final apiKey = prepared.apiKey;
      final requestData = prepared.requestData;

      _logRequest('${baseUrl}chat/completions', requestData);
      final response = await _dio.post(
        '${baseUrl}chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
        cancelToken: cancelToken,
      );
      final data = response.data;
      _logResponse(data);
      int? usage;
      int? promptTokens;
      int? completionTokens;

      int? reasoningTokens;
      if (data['usage'] != null) {
        final usageData = data['usage'];
        promptTokens = usageData['prompt_tokens'] as int?;
        completionTokens = usageData['completion_tokens'] as int?;

        if (usageData['completion_tokens_details'] != null) {
          reasoningTokens = usageData['completion_tokens_details']
              ['reasoning_tokens'] as int?;
        } else if (usageData['reasoning_tokens'] != null) {
          reasoningTokens = usageData['reasoning_tokens'] as int?;
        }
      }
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        final message = choices[0]['message'];
        final String? content = message['content'];
        final String? reasoning =
            (message['reasoning_content'] ?? message['reasoning'])?.toString();
        List<ToolCallChunk>? toolCalls;
        if (message['tool_calls'] != null) {
          toolCalls = (message['tool_calls'] as List).map((tc) {
            return ToolCallChunk(
              id: tc['id'],
              type: tc['type'],
              name: tc['function']['name'],
              arguments: tc['function']['arguments'],
            );
          }).toList();
        }
        List<String> images = [];
        if (message['images'] != null && message['images'] is List) {
          for (final img in message['images']) {
            if (img is String) {
              final normalized =
                  img.startsWith('data:') || img.startsWith('http')
                      ? img
                      : 'data:image/png;base64,$img';
              images.add(normalized);
            } else if (img is Map) {
              final url = img['url'] ?? img['image_url']?['url'];
              if (url != null) {
                final normalized = url.toString();
                images.add(normalized);
                _rememberImageThoughtSignature(
                    normalized, _extractThoughtSignatureFromImageItem(img));
              }
            }
          }
        }
        if (message['content'] is List) {
          for (final item in message['content']) {
            if (item is Map && item['type'] == 'image_url') {
              final url = item['image_url']?['url'];
              if (url != null) {
                final normalized = url.toString();
                images.add(normalized);
                _rememberImageThoughtSignature(
                    normalized, _extractThoughtSignatureFromImageItem(item));
              }
            }
          }
        }
        final String? finishReason = choices[0]['finish_reason'];

        // Final token calculation
        final int totalGenerated =
            (completionTokens ?? 0) + (reasoningTokens ?? 0);
        usage = (promptTokens ?? 0) + totalGenerated;
        if (usage == 0 && data['usage'] != null) {
          usage = data['usage']['total_tokens'] as int?;
        }

        return LLMResponseChunk(
            content: content,
            reasoning: reasoning,
            images: images,
            toolCalls: toolCalls,
            usage: usage,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            reasoningTokens: reasoningTokens,
            finishReason: finishReason);
      }
      return const LLMResponseChunk(content: '');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _debugLog('Request was cancelled by the user.',
            level: 'INFO', category: 'REQUEST_CANCELLED');
        return const LLMResponseChunk(content: '');
      }
      final statusCode = e.response?.statusCode;
      String errorMsg = 'HTTP Error';
      AppErrorType errorType = AppErrorType.unknown;

      // Determine Error Type
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorType = AppErrorType.timeout;
      } else if (e.type == DioExceptionType.connectionError) {
        errorType = AppErrorType.network;
      } else if (e.type == DioExceptionType.badResponse) {
        if (statusCode == 400) {
          errorType = AppErrorType.badRequest;
        } else if (statusCode == 401 || statusCode == 403) {
          errorType = AppErrorType.unauthorized;
        } else if (statusCode == 429) {
          errorType = AppErrorType.rateLimit;
        } else if (statusCode != null && statusCode >= 500) {
          errorType = AppErrorType.serverError;
        }
      }

      try {
        if (e.response?.data != null) {
          final data = e.response?.data;
          _logEvent('ERROR_RESPONSE', data, level: 'ERROR');
          if (data is Map) {
            final error = data['error'];
            if (error is Map && error['message'] != null) {
              errorMsg = 'HTTP $statusCode: ${error['message']}';
            } else if (data['message'] != null) {
              errorMsg = 'HTTP $statusCode: ${data['message']}';
            } else {
              errorMsg = 'HTTP $statusCode: $data';
            }
          } else if (data is String) {
            try {
              final json = jsonDecode(data);
              if (json is Map) {
                final error = json['error'];
                if (error is Map && error['message'] != null) {
                  errorMsg = 'HTTP $statusCode: ${error['message']}';
                } else if (json['message'] != null) {
                  errorMsg = 'HTTP $statusCode: ${json['message']}';
                } else {
                  errorMsg = 'HTTP $statusCode: $data';
                }
              } else {
                errorMsg = 'HTTP $statusCode: $data';
              }
            } catch (_) {
              errorMsg = 'HTTP $statusCode: $data';
            }
          } else {
            errorMsg = 'HTTP $statusCode: ${e.message}';
          }
        } else {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
              errorMsg = 'Connection Timeout';
              break;
            case DioExceptionType.sendTimeout:
              errorMsg = 'Send Timeout';
              break;
            case DioExceptionType.receiveTimeout:
              errorMsg = 'Receive Timeout';
              break;
            case DioExceptionType.connectionError:
              errorMsg = 'Connection Error: ${e.message}';
              break;
            default:
              errorMsg = 'Network Error: ${e.message}';
          }
        }
      } catch (readError) {
        errorMsg = 'HTTP $statusCode: ${e.message}';
      }
      throw AppException(
          type: errorType, message: errorMsg, statusCode: statusCode);
    } catch (e) {
      if (e is AppException) rethrow; // Pass through our custom exceptions
      throw AppException(type: AppErrorType.unknown, message: e.toString());
    }
  }

  List<Map<String, dynamic>> _limitContextLength(
      List<Map<String, dynamic>> messages, int limit) {
    if (messages.length <= limit) return messages;

    final systemMessages =
        messages.where((m) => m['role'] == 'system').toList();
    final otherMessages = messages.where((m) => m['role'] != 'system').toList();

    // If limit is less than system messages count, only return system messages (up to limit)
    if (limit <= systemMessages.length) {
      return systemMessages.take(limit).toList();
    }

    // Available slots for other messages
    final available = limit - systemMessages.length;
    // Take the LAST 'available' messages (most recent)
    final keptOthers = otherMessages.length > available
        ? otherMessages.sublist(otherMessages.length - available)
        : otherMessages;

    return [...systemMessages, ...keptOthers];
  }

  List<Map<String, dynamic>> _extractDocxContent(
      Uint8List bytes, String fileName) {
    final List<Map<String, dynamic>> parts = [];
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Extract Text
      final documentFile = archive.findFile('word/document.xml');
      if (documentFile != null) {
        final content = utf8.decode(documentFile.content as List<int>);

        // Simple regex to extract text within <w:t> tags
        final tRegExp = RegExp(r'<w:t[^>]*>(.*?)<\/w:t>');

        // Find all paragraph nodes <w:p>
        final pRegExp = RegExp(r'<w:p[^>]*>(.*?)<\/w:p>');
        final pMatches = pRegExp.allMatches(content);

        final StringBuffer sb = StringBuffer();
        for (final pMatch in pMatches) {
          final pContent = pMatch.group(1) ?? '';
          final tMatches = tRegExp.allMatches(pContent);
          for (final tMatch in tMatches) {
            sb.write(tMatch.group(1));
          }
          sb.write('\n'); // Add newline after each paragraph
        }

        final text = sb.toString().trim();
        if (text.isNotEmpty) {
          parts.add({
            'type': 'text',
            'text':
                '--- File: $fileName (Text Content) ---\n$text\n--- End Text ---',
          });
        }
      }

      // 2. Extract Images (word/media/)
      for (final file in archive) {
        if (file.name.startsWith('word/media/') && file.isFile) {
          final ext = file.name.split('.').last.toLowerCase();
          String? mimeType;
          if (ext == 'png') {
            mimeType = 'image/png';
          } else if (ext == 'jpg' || ext == 'jpeg') {
            mimeType = 'image/jpeg';
          } else if (ext == 'gif') {
            mimeType = 'image/gif';
          } else if (ext == 'webp') {
            mimeType = 'image/webp';
          }

          if (mimeType != null) {
            final imgBytes = file.content as List<int>;
            parts.add({
              'type': 'image_url',
              'image_url': {
                'url':
                    'data:$mimeType;base64,${base64Encode(Uint8List.fromList(imgBytes))}',
              },
            });
          }
        }
      }
    } catch (e) {
      _debugLog('Docx deep processing failed: $e',
          level: 'WARN', category: 'DOCX_PARSE');
    }
    return parts;
  }
}
