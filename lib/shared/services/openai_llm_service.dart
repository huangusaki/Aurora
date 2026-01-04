import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../features/chat/domain/message.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'llm_service.dart';

class OpenAILLMService implements LLMService {
  final Dio _dio;
  final SettingsState _settings;
  
  OpenAILLMService(this._settings) : _dio = Dio(BaseOptions(
    // Timeouts to prevent infinite waits and CF 524 errors
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 300), // 5 minutes for image generation
    sendTimeout: const Duration(seconds: 60),
    // Headers that some proxies/CDNs require
    headers: {
      'Connection': 'keep-alive',
      'User-Agent': 'Aurora/1.0 (Flutter; Dio)',
    },
  ));
  @override
  Stream<LLMResponseChunk> streamResponse(List<Message> messages,
      {List<String>? attachments,
      List<Map<String, dynamic>>? tools,
      String? toolChoice}) async* {
    final provider = _settings.activeProvider;
    final model = _settings.selectedModel ?? 'gpt-3.5-turbo';
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
      final List<Map<String, dynamic>> apiMessages =
          _buildApiMessages(messages, attachments);
      final Map<String, dynamic> requestData = {
        'model': model,
        'messages': apiMessages,
        'stream': true,
      };
      if (tools != null) {
        print('DEBUG: streamResponse - attaching ${tools.length} tools to request');
        requestData['tools'] = tools;
        if (toolChoice != null) {
          requestData['tool_choice'] = toolChoice;
        }
        // Force System Prompt for Tools
        final now = DateTime.now();
        final dateStr = now.toIso8601String().split('T')[0]; // YYYY-MM-DD
        final systemInstruction = 'Current Date: $dateStr. Today is ${now.year}. Use this date for all searches.';
        
        final systemMsgIndex = apiMessages.indexWhere((m) => m['role'] == 'system');
        if (systemMsgIndex != -1) {
             final oldContent = apiMessages[systemMsgIndex]['content'];
             apiMessages[systemMsgIndex]['content'] = '$systemInstruction\n\n$oldContent';
        } else {
           apiMessages.insert(0, {
             'role': 'system', 
             'content': '''$systemInstruction
## Tools
You have access to a `search_web` tool. Use it when the user asks for real-time information, news, or specific technical documentation.

## Citation Format (CRITICAL)
Search results include an `index` and `link`. You MUST cite your sources using Markdown links in the format `[index](link)`.
- **Placement**: Citations must immediately follow the relevant information.
- **Do not** list all citations at the end.
- **Example**: "Google released Gemini in 2023.[1](https://google.com/gemini) It competes with GPT-4.[2](https://openai.com)"

## Response Style
- Summarize the search results directly.
- Do not say "Based on the search results" repeatedly.
- If results are conflicting, mention the discrepancy.'''
           });
        }
      }
      requestData.addAll(provider.customParameters);
      if (provider.modelSettings.containsKey(model)) {
        requestData.addAll(provider.modelSettings[model]!);
      }
      
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
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          if (data.contains('"images"') && data.length > 1000) {
            print('DEBUG: Found images chunk, length=${data.length}');
          }
          try {
            final json = jsonDecode(data);
            final choices = json['choices'] as List;
            if (choices.isNotEmpty) {
              final delta = choices[0]['delta'];
              if (delta != null) {
                final String? content = delta['content'];
                final String? reasoning =
                    delta['reasoning_content'] ?? delta['reasoning'];
                if (content != null || reasoning != null) {
                  yield LLMResponseChunk(
                      content: content, reasoning: reasoning);
                }
                
                // Handle Tool Calls (Stream)
                final toolCalls = delta['tool_calls'];
                if (toolCalls != null && toolCalls is List) {
                   for (final toolCall in toolCalls) {
                     final int? index = toolCall['index'];
                     final String? id = toolCall['id'];
                     final String? type = toolCall['type'];
                     final Map? function = toolCall['function'];
                     
                     if (function != null) {
                       final String? name = function['name'];
                       final String? arguments = function['arguments'];
                       if (name != null || arguments != null) {
                          print('DEBUG: Stream received tool call chunk: index=$index name=$name args=$arguments');
                       }
                       yield LLMResponseChunk(
                         toolCalls: [
                           ToolCallChunk(
                             index: index, 
                             id: id, 
                             type: type, 
                             name: name, 
                             arguments: arguments
                           )
                         ]
                       );
                     }
                   }
                }
                String? imageUrl;
                if (choices[0]['b64_json'] != null) {
                  imageUrl = 'data:image/png;base64,${choices[0]['b64_json']}';
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
                  } else if (delta['parts'] != null && delta['parts'] is List) {
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
                    print('DEBUG: Found delta[images] list');
                    final images = delta['images'] as List;
                    if (images.isNotEmpty) {
                      final imgData = images[0];
                      print(
                          'DEBUG: imgData type=${imgData.runtimeType}, value=${imgData.toString().substring(0, imgData.toString().length > 100 ? 100 : imgData.toString().length)}...');
                      if (imgData is String) {
                        if (imgData.startsWith('http')) {
                          imageUrl = imgData;
                        } else if (imgData.startsWith('data:image')) {
                          imageUrl = imgData;
                        } else {
                          imageUrl = 'data:image/png;base64,$imgData';
                        }
                      } else if (imgData is Map) {
                        print(
                            'DEBUG: imgData is Map, keys=${imgData.keys.toList()}');
                        if (imgData['url'] != null) {
                          final url = imgData['url'].toString();
                          imageUrl =
                              url.startsWith('http') || url.startsWith('data:')
                                  ? url
                                  : 'data:image/png;base64,$url';
                        } else if (imgData['data'] != null) {
                          imageUrl = 'data:image/png;base64,${imgData['data']}';
                        } else if (imgData['image_url'] != null) {
                          print(
                              'DEBUG: Found image_url field, type=${imgData['image_url'].runtimeType}');
                          final imgUrlObj = imgData['image_url'];
                          if (imgUrlObj is Map && imgUrlObj['url'] != null) {
                            imageUrl = imgUrlObj['url'].toString();
                            print(
                                'DEBUG: Extracted imageUrl (first 50 chars): ${imageUrl!.substring(0, imageUrl!.length > 50 ? 50 : imageUrl!.length)}');
                          } else if (imgUrlObj is String) {
                            imageUrl = imgUrlObj;
                          }
                        }
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
                        yield LLMResponseChunk(content: '', images: [url]);
                      }
                    }
                  }
                }
                if (imageUrl != null) {
                  yield LLMResponseChunk(content: '', images: [imageUrl]);
                }
              }
            }
          } catch (e) {
            print('DEBUG: JSON parse error: $e for data length ${data.length}');
          }
        }
      }
    } on DioException catch (e) {
      yield LLMResponseChunk(content: 'Connection Error: ${e.message}');
    } catch (e) {
      yield LLMResponseChunk(content: 'Unexpected Error: $e');
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

  List<Map<String, dynamic>> _buildApiMessages(
      List<Message> messages, List<String>? currentAttachments) {
    return messages.map((m) {
      if (m.role == 'tool') {
        // Tool Output Message
        return {
          'role': 'tool',
          'tool_call_id': m.toolCallId,
          'content': m.content,
        };
      }
      if (m.role == 'assistant' && m.toolCalls != null && m.toolCalls!.isNotEmpty) {
        // Assistant Message with Tool Calls
        return {
          'role': 'assistant',
          'content': m.content.isEmpty ? null : m.content,
          'tool_calls': m.toolCalls!.map((tc) => {
            'id': tc.id,
            'type': 'function',
            'function': {
              'name': tc.name,
              'arguments': tc.arguments
            }
          }).toList(),
        };
      }
      final hasAttachments = m.attachments.isNotEmpty;
      if (!hasAttachments) {
        return {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        };
      } else {
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
            if (file.existsSync()) {
              final bytes = file.readAsBytesSync();
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
        return {
          'role': m.isUser ? 'user' : 'assistant',
          'content': contentList,
        };
      }
    }).toList();
  }

  @override
  Future<LLMResponseChunk> getResponse(List<Message> messages,
      {List<String>? attachments,
      List<Map<String, dynamic>>? tools,
      String? toolChoice}) async {
    final provider = _settings.activeProvider;
    final model = _settings.selectedModel ?? 'gpt-3.5-turbo';
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
      final List<Map<String, dynamic>> apiMessages =
          _buildApiMessages(messages, attachments);
      final Map<String, dynamic> requestData = {
        'model': model,
        'messages': apiMessages,
        'stream': false,
      };
      if (tools != null) {
        print('DEBUG: getResponse - attaching ${tools.length} tools to request');
        requestData['tools'] = tools;
        if (toolChoice != null) {
           requestData['tool_choice'] = toolChoice;
        }
        // Force System Prompt for Tools
        // Force System Prompt for Tools
        final systemMsgIndex = apiMessages.indexWhere((m) => m['role'] == 'system');
        final now = DateTime.now();
        final dateStr = now.toIso8601String().split('T')[0];
        final systemInstruction = 'Current Date: $dateStr. Today is ${now.year}. Use this date for all searches.';
        
        if (systemMsgIndex != -1) {
           final oldContent = apiMessages[systemMsgIndex]['content'];
           apiMessages[systemMsgIndex]['content'] = '$systemInstruction\n\n$oldContent';
        } else {
           apiMessages.insert(0, {
             'role': 'system', 
             'content': '$systemInstruction\nYou are a helpful assistant with access to a web search tool. Use it for current information.'
           });
        }
      }
      requestData.addAll(provider.customParameters);
      if (provider.modelSettings.containsKey(model)) {
        requestData.addAll(provider.modelSettings[model]!);
      }

      final response = await _dio.post(
        '${baseUrl}chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      final data = response.data;
      // print('DEBUG: raw response data: $data'); // Too verbose?
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        final message = choices[0]['message'];
        print('DEBUG: getResponse - Model: $model - Raw tool_calls: ${message['tool_calls']}');
        final String? content = message['content'];
        // Handle deepseek reasoning (often in reasoning_content)
        final String? reasoning = (message['reasoning_content'] ?? message['reasoning'])?.toString();
        
        List<ToolCall>? toolCalls;
        if (message['tool_calls'] != null) {
          toolCalls = (message['tool_calls'] as List).map((tc) {
            return ToolCall(
              id: tc['id'],
              type: tc['type'],
              name: tc['function']['name'],
              arguments: tc['function']['arguments'],
            );
          }).toList();
        }

        // Extract images from response
        List<String> images = [];
        
        // Check for images in message
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
        
        // Check for content as list (multimodal response)
        if (message['content'] is List) {
          for (final item in message['content']) {
            if (item is Map && item['type'] == 'image_url') {
              final url = item['image_url']?['url'];
              if (url != null) images.add(url);
            }
          }
        }
        
        return LLMResponseChunk(content: content, reasoning: reasoning, images: images, toolCalls: toolCalls != null ? toolCalls.map((tc) => ToolCallChunk.fromToolCall(tc)).toList() : null);
      }
      return const LLMResponseChunk(content: '');
    } on DioException catch (e) {
      return LLMResponseChunk(content: 'Connection Error: ${e.message}');
    } catch (e) {
      return LLMResponseChunk(content: 'Unexpected Error: $e');
    }
  }
}
