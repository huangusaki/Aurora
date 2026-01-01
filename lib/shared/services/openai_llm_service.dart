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

  OpenAILLMService(this._settings) : _dio = Dio();

  @override
  Stream<LLMResponseChunk> streamResponse(List<Message> messages, {List<String>? attachments}) async* {
    final provider = _settings.activeProvider;
    final model = _settings.selectedModel ?? 'gpt-3.5-turbo';
    final apiKey = provider.apiKey;
    final baseUrl = provider.baseUrl.endsWith('/') ? provider.baseUrl : '${provider.baseUrl}/';

    if (apiKey.isEmpty) {
      yield const LLMResponseChunk(content: 'Error: API Key is not configured. Please check your settings.');
      return;
    }

    try {
      final List<Map<String, dynamic>> apiMessages = _buildApiMessages(messages, attachments);
      
      // Merge parameters: Default < Custom Global < Model Specific
      final Map<String, dynamic> requestData = {
        'model': model,
        'messages': apiMessages,
        'stream': true,
      };
      
      // Add global custom params
      requestData.addAll(provider.customParameters);
      
      // Add/Override with model-specific params
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
      
      // SSE Parsing Logic with Line Buffering for Large Payloads (e.g., Base64 images)
      String lineBuffer = '';
      
      await for (final chunk in stream.cast<List<int>>().transform(utf8.decoder)) {
        // Append chunk to buffer
        lineBuffer += chunk;
        
        // Process complete lines (ending with \n)
        while (lineBuffer.contains('\n')) {
           final nlIndex = lineBuffer.indexOf('\n');
           final line = lineBuffer.substring(0, nlIndex).trim();
           lineBuffer = lineBuffer.substring(nlIndex + 1);
           
           if (line.isEmpty) continue;
           if (!line.startsWith('data: ')) continue;
           
           final data = line.substring(6).trim();
           if (data == '[DONE]') return;

            // Debug Logging for Image Generation Issues
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
                  // Handle reasoning_content for models like DeepSeek (supports both keys)
                  final String? reasoning = delta['reasoning_content'] ?? delta['reasoning']; 
                  
                  if (content != null || reasoning != null) {
                    yield LLMResponseChunk(content: content, reasoning: reasoning);
                  }

                  // --- Custom Image Handling (Gemini/OpenAI/VLLM Custom Fields) ---
                  // Some proxies return images in 'image', 'images' (list), 'b64_json', or 'url' fields inside delta
                  String? imageUrl;
                  
                  // Check standard OpenAI DALL-E style (though usually non-streaming, some proxies stream it)
                  if (choices[0]['b64_json'] != null) {
                    imageUrl = 'data:image/png;base64,${choices[0]['b64_json']}';
                  } else if (choices[0]['url'] != null) {
                    imageUrl = choices[0]['url'];
                  }
                  
                  // Check Delta fields
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
                      } 
                      // Gemini Native 'inline_data' support (passed through by some proxies)
                      else if (delta['inline_data'] != null) {
                         final inlineData = delta['inline_data'];
                         if (inlineData is Map) {
                            final mimeType = inlineData['mime_type'] ?? 'image/png';
                            final data = inlineData['data'];
                            if (data != null) {
                               imageUrl = 'data:$mimeType;base64,$data';
                            }
                         }
                      }
                      // Gemini 'parts' support (if proxy returns parts array in delta)
                      else if (delta['parts'] != null && delta['parts'] is List) {
                         final parts = delta['parts'] as List;
                         for (final part in parts) {
                            if (part is Map && part['inline_data'] != null) {
                               final inlineData = part['inline_data'];
                               if (inlineData is Map) {
                                  final mimeType = inlineData['mime_type'] ?? 'image/png';
                                  final data = inlineData['data'];
                                  if (data != null) {
                                     imageUrl = 'data:$mimeType;base64,$data';
                                     break; // Assume one image per chunk for now
                                  }
                               }
                            }
                         }
                      }
                      // Reference Implementation: 'images' list support
                      else if (delta['images'] != null && delta['images'] is List) {
                         print('DEBUG: Found delta[images] list');
                         final images = delta['images'] as List;
                         if (images.isNotEmpty) {
                            final imgData = images[0];
                            print('DEBUG: imgData type=${imgData.runtimeType}, value=${imgData.toString().substring(0, imgData.toString().length > 100 ? 100 : imgData.toString().length)}...');
                            if (imgData is String) {
                               if (imgData.startsWith('http')) {
                                  imageUrl = imgData;
                               } else if (imgData.startsWith('data:image')) {
                                  imageUrl = imgData;
                               } else {
                                  imageUrl = 'data:image/png;base64,$imgData';
                               }
                            } else if (imgData is Map) {
                               print('DEBUG: imgData is Map, keys=${imgData.keys.toList()}');
                               // Check for url, data, image_url
                               if (imgData['url'] != null) {
                                  final url = imgData['url'].toString();
                                  imageUrl = url.startsWith('http') || url.startsWith('data:') ? url : 'data:image/png;base64,$url';
                               } else if (imgData['data'] != null) {
                                  imageUrl = 'data:image/png;base64,${imgData['data']}';
                               } else if (imgData['image_url'] != null) {
                                  print('DEBUG: Found image_url field, type=${imgData['image_url'].runtimeType}');
                                  final imgUrlObj = imgData['image_url'];
                                  if (imgUrlObj is Map && imgUrlObj['url'] != null) {
                                     imageUrl = imgUrlObj['url'].toString();
                                     print('DEBUG: Extracted imageUrl (first 50 chars): ${imageUrl!.substring(0, imageUrl!.length > 50 ? 50 : imageUrl!.length)}');
                                  } else if (imgUrlObj is String) {
                                     imageUrl = imgUrlObj;
                                  }
                               }
                            }
                         }
                      }
                  }
                  
                  // Reference Implementation: Check if content is actually a List (Multimodal response in stream?)
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
              // Ignore JSON parse errors (might be incomplete chunks, but buffering should handle this)
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

  // ... (keep _buildApiMessages as is, it's inside the class but not shown in this replacement chunk range if I replace the whole method)
  
  // Helper to detect mime type (simple check)
  String _getMimeType(String path) {
    if (path.toLowerCase().endsWith('png')) return 'image/png';
    if (path.toLowerCase().endsWith('jpg') || path.toLowerCase().endsWith('jpeg')) return 'image/jpeg';
    if (path.toLowerCase().endsWith('webp')) return 'image/webp';
    if (path.toLowerCase().endsWith('gif')) return 'image/gif';
    return 'image/jpeg'; // fallback
  }

  // Build API messages with support for Vision (Base64 Images)
  List<Map<String, dynamic>> _buildApiMessages(List<Message> messages, List<String>? currentAttachments) {
    return messages.map((m) {
      // Determine if this message has attachments
      // Note: 'currentAttachments' arg is technically redundant if 'm' already has them, 
      // but strictly speaking, the last message corresponds to the current user input 
      // which might be passing attachments separately in some flows. 
      // However, ChatNotifier appends message first, so m.attachments is the source of truth.
      
      final hasAttachments = m.attachments.isNotEmpty;

      if (!hasAttachments) {
        return {
           'role': m.isUser ? 'user' : 'assistant',
           'content': m.content,
        };
      } else {
        // Handle Multimodal Content
        final List<Map<String, dynamic>> contentList = [];
        
        // 1. Text Content
        if (m.content.isNotEmpty) {
          contentList.add({
            'type': 'text',
            'text': m.content,
          });
        }

        // 2. Image Content
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
             // If image load fails, append error text so user knows
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
  Future<String> getResponse(List<Message> messages) async {
    final buffer = StringBuffer();
    await for (final chunk in streamResponse(messages)) {
      if (chunk.content != null) buffer.write(chunk.content);
    }
    return buffer.toString();
  }
}
