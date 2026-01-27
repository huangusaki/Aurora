import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../features/chat/domain/message.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'llm_service.dart';
import '../../core/error/app_exception.dart';
import '../../core/error/app_error_type.dart';

Future<List<Map<String, dynamic>>> _compressImagesTask(
    List<Map<String, dynamic>> apiMessages) async {
  String compressSingleImage(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return base64Encode(bytes);
      int targetWidth = image.width;
      int targetHeight = image.height;
      if (targetWidth > 1920 || targetHeight > 1080) {
        final aspectRatio = targetWidth / targetHeight;
        if (aspectRatio > 1920 / 1080) {
          targetWidth = 1920;
          targetHeight = (1920 / aspectRatio).round();
        } else {
          targetHeight = 1080;
          targetWidth = (1080 * aspectRatio).round();
        }
      }
      final resized =
          (targetWidth != image.width || targetHeight != image.height)
              ? img.copyResize(image, width: targetWidth, height: targetHeight)
              : image;
      final compressed = img.encodeJpg(resized, quality: 85);
      return base64Encode(compressed);
    } catch (e) {
      return base64Encode(bytes);
    }
  }

  final List<Map<String, dynamic>> result = [];
  for (final msg in apiMessages) {
    final Map<String, dynamic> newMsg = Map.from(msg);
    final content = newMsg['content'];
    if (content is List) {
      final List<dynamic> newContentList = [];
      for (final item in content) {
        if (item is Map && item['type'] == 'image_url') {
          final imageUrl = item['image_url']?['url'];
          if (imageUrl is String && imageUrl.startsWith('data:')) {
            final parts = imageUrl.split(',');
            if (parts.length == 2) {
              try {
                final bytes = base64Decode(parts[1]);
                final compressed =
                    compressSingleImage(Uint8List.fromList(bytes));
                newContentList.add({
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$compressed',
                  },
                  if (item.containsKey('thought_signature'))
                    'thought_signature': item['thought_signature'],
                });
                continue;
              } catch (e) {
                newContentList.add(item);
                continue;
              }
            }
          }
        }
        newContentList.add(item);
      }
      newMsg['content'] = newContentList;
    }
    result.add(newMsg);
  }
  return result;
}

class OpenAILLMService implements LLMService {
  final Dio _dio;
  final SettingsState _settings;
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
  dynamic _sanitizeForLog(dynamic data) {
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
      if (data.startsWith('data:') && data.length > 200) {
        return '${data.substring(0, 50)}...[TRUNCATED ${data.length} chars]';
      }
    }
    return data;
  }

  void _logRequest(String url, Map<String, dynamic> data) {
    try {
      final sanitized = _sanitizeForLog(data);
      print('🔵 [LLM REQUEST] URL: $url');
      print('🔵 [LLM REQUEST] PAYLOAD: ${jsonEncode(sanitized)}');
    } catch (e) {
      print('🔴 [LLM REQUEST LOG ERROR]: $e');
    }
  }

  void _logResponse(dynamic data) {
    try {
      final sanitized = _sanitizeForLog(data);
      print('🟢 [LLM RESPONSE]: ${jsonEncode(sanitized)}');
    } catch (e) {
      print('🔴 [LLM RESPONSE LOG ERROR]: $e');
    }
  }

  @override
  Stream<LLMResponseChunk> streamResponse(List<Message> messages,
      {List<String>? attachments,
      List<Map<String, dynamic>>? tools,
      String? toolChoice,
      String? model,
      String? providerId,
      CancelToken? cancelToken}) async* {
    final provider = providerId != null
        ? _settings.providers.firstWhere((p) => p.id == providerId,
            orElse: () => _settings.activeProvider)
        : _settings.activeProvider;
    final selectedModel = model ?? provider.selectedModel ?? 'gpt-3.5-turbo';
    final apiKey = provider.apiKey;
    final baseUrl = provider.baseUrl.endsWith('/')
        ? provider.baseUrl
        : '${provider.baseUrl}/';
    if (apiKey.isEmpty) {
      yield const LLMResponseChunk(
          content:
              'Error: API Key is not configured. Please check your settings.');
      return;
    }
    try {
      List<Map<String, dynamic>> apiMessages =
          await _buildApiMessages(messages, attachments);
      for (int i = 0; i < apiMessages.length; i++) {
        final msg = apiMessages[i];
        final content = msg['content'];
        if (content is List) {
          for (final part in content) {
            if (part is Map) {
              print('  - type: ${part['type']}');
            }
          }
        }
      }
      apiMessages = await _compressApiMessagesIfNeeded(apiMessages);
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0];
      final timeInstruction = 'Current Date: $dateStr. Today is ${now.year}.';
      final systemMsgIndex =
          apiMessages.indexWhere((m) => m['role'] == 'system');
      if (systemMsgIndex != -1) {
        final oldContent = apiMessages[systemMsgIndex]['content'];
        if (!oldContent.toString().contains('Current Date:')) {
          apiMessages[systemMsgIndex]['content'] =
              '$timeInstruction\n\n$oldContent';
        }
      } else {
        apiMessages.insert(0, {'role': 'system', 'content': timeInstruction});
      }

      // Determine effective model settings
      Map<String, dynamic> activeParams = {};

      // 1. Get Global Settings (if enabled and not excluded)
      final bool isExcluded = provider.globalExcludeModels.contains(selectedModel);
      if (!isExcluded) {
        activeParams.addAll(provider.globalSettings);
      }

      // 2. Override with Specific Model Settings
      if (provider.modelSettings.containsKey(selectedModel)) {
        final specific = provider.modelSettings[selectedModel]!;
        activeParams.addAll(specific);
      }

      final Map<String, dynamic> requestData = {
        'model': selectedModel,
        'messages': apiMessages,
        'stream': true,
        'stream_options': {'include_usage': true},
      };

      if (tools != null) {
        requestData['tools'] = tools;
        if (toolChoice != null) {
          requestData['tool_choice'] = toolChoice;
        }
        final sysIdx = apiMessages.indexWhere((m) => m['role'] == 'system');
        if (sysIdx != -1) {
          final oldContent = apiMessages[sysIdx]['content'];
          final searchGuide = '''
## Web Search Capability
You have access to web search. When you need to search for current information, output a search tag in this exact format:
<search>your search query here</search>

### When to Use
Use search for:
1. **Latest Information**: Current events, news, weather, sports scores
2. **Fact Checking**: Verification of claims or data
3. **Specific Knowledge**: Technical documentation or niche topics not in your training data

### Important Rules
- Output ONLY ONE <search> tag per response when you need to search
- After outputting the search tag, STOP your response and wait for results
- Do NOT make up search results - wait for real data
- When you receive search results, cite sources using `[index](link)` format immediately after the relevant fact
''';
          if (!oldContent.toString().contains('Web Search Capability')) {
            apiMessages[sysIdx]['content'] = '$oldContent\n\n$searchGuide';
          }
        }
      }

      // Add Custom Parameters (Global + Specific merged)
      final filteredParams = Map<String, dynamic>.fromEntries(
        activeParams.entries.where((e) => !e.key.startsWith('_aurora_'))
      );
      // Provider-level customParameters are always added (Base)

      final providerParams = Map<String, dynamic>.fromEntries(
        provider.customParameters.entries.where((e) {
             final key = e.key.toLowerCase();
             return key != 'api_keys' &&
                    key != 'base_url' &&
                    key != 'id' &&
                    key != 'name' &&
                    key != 'models' &&
                    key != 'color' &&
                    key != 'is_custom' &&
                    key != 'is_enabled' &&
                    !e.key.startsWith('_aurora_');
        })
      );
      requestData.addAll(providerParams);
      requestData.addAll(filteredParams);

      // Handle Generation Config (temperature, max_tokens, context_length)
      final generationConfig = activeParams['_aurora_generation_config'];
      if (generationConfig != null && generationConfig is Map) {
         final temp = generationConfig['temperature'];
         if (temp != null && temp.toString().isNotEmpty) {
           final tempVal = double.tryParse(temp.toString());
           if (tempVal != null) requestData['temperature'] = tempVal;
         }
         final maxTok = generationConfig['max_tokens'];
         if (maxTok != null && maxTok.toString().isNotEmpty) {
           final maxTokVal = int.tryParse(maxTok.toString());
           if (maxTokVal != null) requestData['max_tokens'] = maxTokVal;
         }
         // Handle Context Length (Truncate history)
         final ctxLen = generationConfig['context_length'];
         if (ctxLen != null && ctxLen.toString().isNotEmpty) {
           final limit = int.tryParse(ctxLen.toString());
           if (limit != null && limit > 0) {
             apiMessages = _limitContextLength(apiMessages, limit);
             requestData['messages'] = apiMessages; // Update messages in request
           }
         }
      }

      // Handle Thinking Config
      final thinkingConfig = activeParams['_aurora_thinking_config'];
      bool thinkingEnabled = false;
      String thinkingValue = '';
      String thinkingMode = 'auto';

      if (thinkingConfig != null && thinkingConfig is Map) {
         thinkingEnabled = thinkingConfig['enabled'] == true;
         thinkingValue = thinkingConfig['budget']?.toString() ?? '';
         thinkingMode = thinkingConfig['mode']?.toString() ?? 'auto';
      } else {
         thinkingEnabled = activeParams['_aurora_thinking_enabled'] == true;
         thinkingValue = activeParams['_aurora_thinking_value']?.toString() ?? '';
         thinkingMode = activeParams['_aurora_thinking_mode']?.toString() ?? 'auto';
      }

        if (thinkingEnabled) {
          if (thinkingMode == 'auto') {
            final isGemini3 = RegExp(r'gemini[_-]?3[_-]', caseSensitive: false)
                .hasMatch(selectedModel);
            if (isGemini3) {
              thinkingMode = 'reasoning_effort';
            } else if (selectedModel.toLowerCase().contains('gemini')) {
              thinkingMode = 'extra_body';
            } else {
              thinkingMode = 'reasoning_effort';
            }
          }
          if (thinkingValue.isNotEmpty) {
            if (thinkingMode == 'extra_body') {
              final isGemini3 =
                  RegExp(r'gemini[_-]?3[_-]', caseSensitive: false)
                      .hasMatch(selectedModel);
              final int? budgetInt = int.tryParse(thinkingValue);
              if (isGemini3) {
                String thinkingLevel;
                if (budgetInt != null) {
                  if (budgetInt <= 512) {
                    thinkingLevel = 'minimal';
                  } else if (budgetInt <= 1024) {
                    thinkingLevel = 'low';
                  } else if (budgetInt <= 8192) {
                    thinkingLevel = 'medium';
                  } else {
                    thinkingLevel = 'high';
                  }
                } else {
                  thinkingLevel = thinkingValue.toLowerCase();
                }
                requestData['extra_body'] = {
                  'google': {
                    'thinking_config': {
                      'thinkingLevel': thinkingLevel,
                      'includeThoughts': true,
                    }
                  }
                };
              } else {
                requestData['extra_body'] = {
                  'google': {
                    'thinking_config': {
                      if (budgetInt != null) 'thinking_budget': budgetInt,
                      if (budgetInt != null) 'include_thoughts': true,
                      if (budgetInt == null) 'thinkingLevel': thinkingValue,
                      if (budgetInt == null) 'includeThoughts': true,
                    }
                  }
                };
              }
            } else if (thinkingMode == 'reasoning_effort') {
              final isGemini3ForEffort =
                  RegExp(r'gemini[_-]?3[_-]', caseSensitive: false)
                      .hasMatch(selectedModel);
              final int? budgetInt = int.tryParse(thinkingValue);
              if (isGemini3ForEffort && budgetInt != null) {
                String level;
                if (budgetInt <= 512) {
                  level = 'minimal';
                } else if (budgetInt <= 1024) {
                  level = 'low';
                } else if (budgetInt <= 8192) {
                  level = 'medium';
                } else {
                  level = 'high';
                }
                requestData['reasoning_effort'] = level;
              } else {
                requestData['reasoning_effort'] = thinkingValue;
              }
            }
          }
        }


      _logRequest('${baseUrl}chat/completions', requestData);
      final response = await _dio.post(
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
      final stream = response.data.stream as Stream<List<int>>;
      String lineBuffer = '';
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
              print('🟢 [LLM RESPONSE STREAM]: [DONE]');
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
                
                // If we have completion tokens, we use it for token/s calc (legacy usage field)
                // But we now also pass explicit prompt and completion tokens
                if (completionTokens != null || totalTokens != null) {
                  yield LLMResponseChunk(
                    usage: completionTokens ?? totalTokens,
                    promptTokens: promptTokens,
                    completionTokens: completionTokens,
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
                  final String? content = delta['content'];
                  final String? reasoning =
                      delta['reasoning_content'] ?? delta['reasoning'];
                  final toolCalls = delta['tool_calls'];

                  String? imageUrl;
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
                      final List<String> parsedImages = [];
                      for (final imgData in images) {
                        if (imgData is String) {
                          if (imgData.startsWith('http')) {
                            parsedImages.add(imgData);
                          } else if (imgData.startsWith('data:image')) {
                            parsedImages.add(imgData);
                          } else {
                            parsedImages.add('data:image/png;base64,$imgData');
                          }
                        } else if (imgData is Map) {
                          if (imgData['url'] != null) {
                            final url = imgData['url'].toString();
                            parsedImages.add(url.startsWith('http') ||
                                    url.startsWith('data:')
                                ? url
                                : 'data:image/png;base64,$url');
                          } else if (imgData['data'] != null) {
                            parsedImages.add(
                                'data:image/png;base64,${imgData['data']}');
                          } else if (imgData['image_url'] != null) {
                            final imgUrlObj = imgData['image_url'];
                            if (imgUrlObj is Map && imgUrlObj['url'] != null) {
                              parsedImages.add(imgUrlObj['url'].toString());
                            } else if (imgUrlObj is String) {
                              parsedImages.add(imgUrlObj);
                            }
                          }
                        }
                      }
                      if (parsedImages.isNotEmpty) {
                        // Use first image for simplified logic
                        imageUrl = parsedImages.first;
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
                           break;
                        }
                      }
                    }
                  }

                  if (imageUrl != null) {
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
                        parsedToolCalls = (toolCalls as List).map((toolCall) {
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
                        }).toList().cast<ToolCallChunk>();
                      } catch (e) {
                        print('Tool call parse error: $e');
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
              print('LLM Stream Parse Error: $e');
            }
          }
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        print('🔵 [LLM REQUEST CANCELLED]');
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
          print('🔴 [LLM ERROR RESPONSE]: $responseData');
          if (responseData is ResponseBody) {
            final stream = responseData.stream;
            final bytes = await stream
                .fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
            final errorBody = utf8.decode(bytes);
            print('🔴 [LLM ERROR BODY]: $errorBody');
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
      throw AppException(type: errorType, message: errorMsg, statusCode: statusCode);
    } catch (e) {
      if (e is AppException) rethrow; // Pass through our custom exceptions
      throw AppException(
        type: AppErrorType.unknown, 
        message: e.toString()
      );
    }
  }

  String _getMimeType(String path) {
    if (path.toLowerCase().endsWith('png')) return 'image/png';
    if (path.toLowerCase().endsWith('jpg') ||
        path.toLowerCase().endsWith('jpeg')) return 'image/jpeg';
    if (path.toLowerCase().endsWith('webp')) return 'image/webp';
    if (path.toLowerCase().endsWith('gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<List<Map<String, dynamic>>> _buildApiMessages(
      List<Message> messages, List<String>? currentAttachments) async {
    final List<Map<String, dynamic>> result = [];
    for (final m in messages) {
      if (m.role == 'tool') {
        result.add({
          'role': 'tool',
          'tool_call_id': m.toolCallId,
          'content': m.content,
        });
        continue;
      }
      if (m.role == 'assistant' &&
          m.toolCalls != null &&
          m.toolCalls!.isNotEmpty) {
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
        } else if (!m.isUser && hasImages) {
          contentList.add({
            'type': 'text',
            'text': '',
          });
        }
        for (final path in m.attachments) {
          try {
            final file = File(path);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final base64Image = base64Encode(bytes);
              final mimeType = _getMimeType(path);
              contentList.add({
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              });
            }
          } catch (e) {
            contentList.add({
              'type': 'text',
              'text': '[Failed to load image: $path]',
            });
          }
        }
        if (m.images.isNotEmpty) {
          final lastImage = m.images.last;
          if (lastImage.startsWith('data:')) {
            if (!m.isUser) {
              contentList.add({
                'type': 'image_url',
                'image_url': {
                  'url': lastImage,
                },
                'thought_signature': 'skip_thought_signature_validator',
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
      print(
          'Element compression in background failed: $e. Falling back to original.');
      return apiMessages;
    }
  }

  @override
  Future<LLMResponseChunk> getResponse(List<Message> messages,
      {List<String>? attachments,
      List<Map<String, dynamic>>? tools,
      String? toolChoice,
      String? model,
      String? providerId,
      CancelToken? cancelToken}) async {
    final provider = providerId != null
        ? _settings.providers.firstWhere((p) => p.id == providerId,
            orElse: () => _settings.activeProvider)
        : _settings.activeProvider;
    final selectedModel = model ?? provider.selectedModel ?? 'gpt-3.5-turbo';
    final apiKey = provider.apiKey;
    final baseUrl = provider.baseUrl.endsWith('/')
        ? provider.baseUrl
        : '${provider.baseUrl}/';
    if (apiKey.isEmpty) {
      return const LLMResponseChunk(
          content:
              'Error: API Key is not configured. Please check your settings.');
    }
    try {
      List<Map<String, dynamic>> apiMessages =
          await _buildApiMessages(messages, attachments);
      apiMessages = await _compressApiMessagesIfNeeded(apiMessages);
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0];
      final timeInstruction = 'Current Date: $dateStr. Today is ${now.year}.';
      final systemMsgIndex =
          apiMessages.indexWhere((m) => m['role'] == 'system');
      if (systemMsgIndex != -1) {
        final oldContent = apiMessages[systemMsgIndex]['content'];
        if (!oldContent.toString().contains('Current Date:')) {
          apiMessages[systemMsgIndex]['content'] =
              '$timeInstruction\n\n$oldContent';
        }
      } else {
        apiMessages.insert(0, {'role': 'system', 'content': timeInstruction});
      }

      // Determine effective model settings
      Map<String, dynamic> activeParams = {};

      // 1. Get Global Settings (if enabled and not excluded)
      final bool isExcluded = provider.globalExcludeModels.contains(selectedModel);
      if (!isExcluded) {
        activeParams.addAll(provider.globalSettings);
      }

      // 2. Override with Specific Model Settings
      if (provider.modelSettings.containsKey(selectedModel)) {
        final specific = provider.modelSettings[selectedModel]!;
        activeParams.addAll(specific);
      }

      final Map<String, dynamic> requestData = {
        'model': selectedModel,
        'messages': apiMessages,
        'stream': false,
      };

      if (tools != null) {
        requestData['tools'] = tools;
        if (toolChoice != null) {
           requestData['tool_choice'] = toolChoice;
        }
        final sysIdx = apiMessages.indexWhere((m) => m['role'] == 'system');
        if (sysIdx != -1) {
          final oldContent = apiMessages[sysIdx]['content'];
          const searchGuide =
              'You have access to a web search tool. Use it for current information.';
          if (!oldContent.toString().contains('web search tool')) {
             apiMessages[sysIdx]['content'] = '$oldContent\n\n$searchGuide';
          }
        }
      }

      // Add Custom Parameters (Global + Specific merged)
      final filteredParams = Map<String, dynamic>.fromEntries(
        activeParams.entries.where((e) => !e.key.startsWith('_aurora_'))
      );
      // Provider-level customParameters are always added (Base)
      final providerParams = Map<String, dynamic>.fromEntries(
        provider.customParameters.entries.where((e) {
             final key = e.key.toLowerCase();
             return key != 'api_keys' &&
                    key != 'base_url' &&
                    key != 'id' &&
                    key != 'name' &&
                    key != 'models' &&
                    key != 'color' &&
                    key != 'is_custom' &&
                    key != 'is_enabled' &&
                    !e.key.startsWith('_aurora_');
        })
      );
      requestData.addAll(providerParams);
      requestData.addAll(filteredParams);

      // Handle Generation Config (temperature, max_tokens)
      final generationConfig = activeParams['_aurora_generation_config'];
      if (generationConfig != null && generationConfig is Map) {
        final temp = generationConfig['temperature'];
        if (temp != null && temp.toString().isNotEmpty) {
           final tempVal = double.tryParse(temp.toString());
           if (tempVal != null) requestData['temperature'] = tempVal;
        }
         final maxTok = generationConfig['max_tokens'];
         if (maxTok != null && maxTok.toString().isNotEmpty) {
            final maxTokVal = int.tryParse(maxTok.toString());
            if (maxTokVal != null) requestData['max_tokens'] = maxTokVal;
         }
         // Handle Context Length (Truncate history)
         final ctxLen = generationConfig['context_length'];
         if (ctxLen != null && ctxLen.toString().isNotEmpty) {
           final limit = int.tryParse(ctxLen.toString());
           if (limit != null && limit > 0) {
             apiMessages = _limitContextLength(apiMessages, limit);
             requestData['messages'] = apiMessages; // Update messages in request
           }
         }
      }

      // Handle Thinking Config
      final thinkingConfig = activeParams['_aurora_thinking_config'];
      bool thinkingEnabled = false;
      String thinkingValue = '';
      String thinkingMode = 'auto';

      if (thinkingConfig != null && thinkingConfig is Map) {
         thinkingEnabled = thinkingConfig['enabled'] == true;
         thinkingValue = thinkingConfig['budget']?.toString() ?? '';
         thinkingMode = thinkingConfig['mode']?.toString() ?? 'auto';
      } else {
         thinkingEnabled = activeParams['_aurora_thinking_enabled'] == true;
         thinkingValue = activeParams['_aurora_thinking_value']?.toString() ?? '';
         thinkingMode = activeParams['_aurora_thinking_mode']?.toString() ?? 'auto';
      }

        if (thinkingEnabled) {
          if (thinkingMode == 'auto') {
            final isGemini3 = RegExp(r'gemini[_-]?3[_-]', caseSensitive: false)
                .hasMatch(selectedModel);
            if (isGemini3) {
              thinkingMode = 'reasoning_effort';
            } else if (selectedModel.toLowerCase().contains('gemini')) {
              thinkingMode = 'extra_body';
            } else {
              thinkingMode = 'reasoning_effort';
            }
          }
          if (thinkingValue.isNotEmpty) {
            if (thinkingMode == 'extra_body') {
              final int? budgetInt = int.tryParse(thinkingValue);
              requestData['extra_body'] = {
                'google': {
                  'thinking_config': {
                    if (budgetInt != null) 'thinking_budget': budgetInt,
                    if (budgetInt != null) 'include_thoughts': true,
                    if (budgetInt == null) 'thinkingLevel': thinkingValue,
                    if (budgetInt == null) 'includeThoughts': true,
                  }
                }
              };
            } else if (thinkingMode == 'reasoning_effort') {
              final isGemini3ForEffort =
                  RegExp(r'gemini[_-]?3[_-]', caseSensitive: false)
                      .hasMatch(selectedModel);
              final int? budgetInt = int.tryParse(thinkingValue);
              if (isGemini3ForEffort && budgetInt != null) {
                String level;
                if (budgetInt <= 512) {
                  level = 'minimal';
                } else if (budgetInt <= 1024) {
                  level = 'low';
                } else if (budgetInt <= 8192) {
                  level = 'medium';
                } else {
                  level = 'high';
                }
                requestData['reasoning_effort'] = level;
              } else {
                requestData['reasoning_effort'] = thinkingValue;
              }
            }
          }
        }


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
      
      if (data['usage'] != null) {
        final usageData = data['usage'];
        // Legacy usage for token/s (completion tokens preferred)
        usage = usageData['completion_tokens'] ?? usageData['total_tokens'];
        promptTokens = usageData['prompt_tokens'];
        completionTokens = usageData['completion_tokens'];
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
              images.add(img.startsWith('data:') || img.startsWith('http')
                  ? img
                  : 'data:image/png;base64,$img');
            } else if (img is Map) {
              final url = img['url'] ?? img['image_url']?['url'];
              if (url != null) images.add(url.toString());
            }
          }
        }
        if (message['content'] is List) {
          for (final item in message['content']) {
            if (item is Map && item['type'] == 'image_url') {
              final url = item['image_url']?['url'];
              if (url != null) images.add(url);
            }
          }
        }
        final String? finishReason = choices[0]['finish_reason'];
        return LLMResponseChunk(
            content: content,
            reasoning: reasoning,
            images: images,
            toolCalls: toolCalls,
            usage: usage,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            finishReason: finishReason);
      }
      return const LLMResponseChunk(content: '');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        print('🔵 [LLM REQUEST CANCELLED]');
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
          print('🔴 [LLM ERROR RESPONSE]: $data');
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
      throw AppException(type: errorType, message: errorMsg, statusCode: statusCode);
    } catch (e) {
      if (e is AppException) rethrow; // Pass through our custom exceptions
      throw AppException(
        type: AppErrorType.unknown, 
        message: e.toString()
      );
    }
  }

  List<Map<String, dynamic>> _limitContextLength(
      List<Map<String, dynamic>> messages, int limit) {
    if (messages.length <= limit) return messages;

    final systemMessages =
        messages.where((m) => m['role'] == 'system').toList();
    final otherMessages =
        messages.where((m) => m['role'] != 'system').toList();

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
}
