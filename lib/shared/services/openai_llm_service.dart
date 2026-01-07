import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
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
      List<Map<String, dynamic>> apiMessages =
          _buildApiMessages(messages, attachments);
      
      // Early debug: Log message count and structure
      for (int i = 0; i < apiMessages.length; i++) {
        final msg = apiMessages[i];
        final role = msg['role'];
        final content = msg['content'];
        if (content is List) {
          for (final part in content) {
            if (part is Map) {
              print('  - type: ${part['type']}');
            }
          }
        } else if (content is String) {
        }
      }
      
      // Compress images if request size exceeds threshold
      apiMessages = _compressApiMessagesIfNeeded(apiMessages);
      // Add System Time Prompt (Always)
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0]; // YYYY-MM-DD
      final timeInstruction = 'Current Date: $dateStr. Today is ${now.year}.';
      
      final systemMsgIndex = apiMessages.indexWhere((m) => m['role'] == 'system');
      if (systemMsgIndex != -1) {
           final oldContent = apiMessages[systemMsgIndex]['content'];
           // Avoid duplicating if already present (basic check)
           if (!oldContent.toString().contains('Current Date:')) {
             apiMessages[systemMsgIndex]['content'] = '$timeInstruction\n\n$oldContent';
           }
      } else {
         apiMessages.insert(0, {
           'role': 'system', 
           'content': timeInstruction
         });
      }

      final Map<String, dynamic> requestData = {
        'model': model,
        'messages': apiMessages,
        'stream': true,
      };
      if (tools != null) {
        requestData['tools'] = tools;
        if (toolChoice != null) {
          requestData['tool_choice'] = toolChoice;
        }
        
        // Add Search Tool Guidelines if search_web is available
        // Locate system message again (it might have moved or been created above)
        final sysIdx = apiMessages.indexWhere((m) => m['role'] == 'system');
        if (sysIdx != -1) {
           final oldContent = apiMessages[sysIdx]['content'];
           final searchGuide = '''
## Web Search Tool Usage Guide (`search_web`)

### When to Use
Activate the search tool in these scenarios:
1. **Latest Information**: Queries about current events, news, weather, or sports scores.
2. **Fact Checking**: Verification of claims or data.
3. **Specific Knowledge**: Technical documentation, API references, or niche topics not in your training data.

**Region Note**: Prefer using `region: "us-en"` for high-quality, uncensored results, even for Chinese queries. Only use `zh-cn` if local Chinese news is explicitly required.

### Citation Rules (STRICT)
You MUST cite your sources using the format `[index](link)`.
- **Immediate Placement**: Citations must be placed *immediately* after the relevant sentence or clause, before the period if possible.
- **No Summary List**: Do NOT include a "References" or "Sources" section at the end of your response.
- **Multiple Sources**: If a fact is supported by multiple sources, list them together: `[1](link1) [2](link2)`.

### Response Guidelines
- **Synthesize**: Combine information from multiple results into a coherent narrative. Don't just list them.
- **Objectivity**: Report facts as found. If sources conflict, explicitly state the discrepancy.
- **Completeness**: If search results are insufficient, honestly state what is missing rather than hallucinating.

### Example
✅ Correct:
> "Stable Diffusion 3 was released in early 2024[1](https://stability.ai), featuring improved text handling[2](https://techcrunch.com)."

❌ Incorrect:
> "Stable Diffusion 3 was released in early 2024 and has better text."
> Sources:
> 1. https://stability.ai
''';
           // Only add if not already present
           if (!oldContent.toString().contains('Web Search Tool Usage Guide')) {
              apiMessages[sysIdx]['content'] = '$oldContent\n\n$searchGuide';
           } 
        }
      }
      requestData.addAll(provider.customParameters);
      if (provider.modelSettings.containsKey(model)) {
        requestData.addAll(provider.modelSettings[model]!);
      }
      
      // Debug: Log message structure
      for (int i = 0; i < apiMessages.length; i++) {
        final msg = apiMessages[i];
        final content = msg['content'];
        if (content is List) {
          for (final part in content) {
            if (part is Map) {
              print('  - type: ${part['type']}, hasImageUrl: ${part['image_url'] != null}');
            }
          }
        } else {
        }
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
          }
        }
      }
    } on DioException catch (e) {
      // Rethrow to let caller handle and record as failure
      final statusCode = e.response?.statusCode;
      String errorMsg = 'HTTP Error';
      
      // Try to read error details from response body
      try {
        if (e.response?.data != null) {
          final responseData = e.response?.data;
          if (responseData is ResponseBody) {
            final stream = responseData.stream;
            final bytes = await stream.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
            final errorBody = utf8.decode(bytes);
            // Try to parse as JSON for better error message
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
          // No response data, use Dio's error type
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
      
      throw Exception(errorMsg);
    } catch (e) {
      // Rethrow all other exceptions
      rethrow;
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
      final hasImages = m.images.isNotEmpty;
      
      // If no attachments and no model-generated images, return simple message
      if (!hasAttachments && !hasImages) {
        return {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        };
      }
      
      // Build multipart content with text, attachments, and/or model-generated images
      {
        final List<Map<String, dynamic>> contentList = [];
        
        // Always add text content (even if empty) for assistant messages with images
        // Some APIs require text in all messages
        if (m.content.isNotEmpty) {
          contentList.add({
            'type': 'text',
            'text': m.content,
          });
        } else if (!m.isUser && hasImages) {
          // Add empty text placeholder for assistant messages with only images
          contentList.add({
            'type': 'text',
            'text': '',
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
        // Include model-generated images (already base64 data URLs or http URLs)
        // CLIProxyAPI expects image_url format and auto-converts to Gemini inlineData
        // For multi-turn editing, only use the LAST image (final/larger one, not draft)
        if (m.images.isNotEmpty) {
          final lastImage = m.images.last;
          // Debug: Log image URL format
          if (lastImage.startsWith('data:')) {
          }
          
          // Only add if it's a valid data URL
          if (lastImage.startsWith('data:')) {
            // For assistant messages, add thought_signature to bypass Gemini's validation
            // This is needed for multi-turn image editing (Gemini 3 requirement)
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
          } else {
          }
        }
        return {
          'role': m.isUser ? 'user' : 'assistant',
          'content': contentList,
        };
      }
    }).toList();
  }

  /// Compress image bytes to 1080p JPG format
  /// Returns compressed base64 string or original if compression fails
  String _compressImageToBase64(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return base64Encode(bytes);
      
      // Calculate target dimensions (max 1920x1080, maintain aspect ratio)
      int targetWidth = image.width;
      int targetHeight = image.height;
      
      if (targetWidth > 1920 || targetHeight > 1080) {
        final aspectRatio = targetWidth / targetHeight;
        if (aspectRatio > 1920 / 1080) {
          // Width is the limiting factor
          targetWidth = 1920;
          targetHeight = (1920 / aspectRatio).round();
        } else {
          // Height is the limiting factor
          targetHeight = 1080;
          targetWidth = (1080 * aspectRatio).round();
        }
      }
      
      // Resize if needed
      final resized = (targetWidth != image.width || targetHeight != image.height)
          ? img.copyResize(image, width: targetWidth, height: targetHeight)
          : image;
      
      // Encode as JPG with quality 85
      final compressed = img.encodeJpg(resized, quality: 85);
      return base64Encode(compressed);
    } catch (e) {
      return base64Encode(bytes);
    }
  }

  /// Estimate the size of the request payload in bytes
  int _estimateRequestSize(List<Map<String, dynamic>> apiMessages) {
    try {
      final json = jsonEncode(apiMessages);
      return utf8.encode(json).length;
    } catch (e) {
      return 0;
    }
  }

  /// Compress images in API messages if total size exceeds threshold (4MB)
  List<Map<String, dynamic>> _compressApiMessagesIfNeeded(
      List<Map<String, dynamic>> apiMessages) {
    const maxSizeBytes = 4 * 1024 * 1024; // 4MB threshold
    
    final currentSize = _estimateRequestSize(apiMessages);
    if (currentSize <= maxSizeBytes) {
      return apiMessages; // No compression needed
    }
    
    
    // Deep copy and compress images
    return apiMessages.map((msg) {
      final content = msg['content'];
      if (content is List) {
        final compressedContent = content.map((item) {
          if (item is Map && item['type'] == 'image_url') {
            final imageUrl = item['image_url']?['url'];
            if (imageUrl is String && imageUrl.startsWith('data:')) {
              // Extract base64 data and compress
              final parts = imageUrl.split(',');
              if (parts.length == 2) {
                try {
                  final bytes = base64Decode(parts[1]);
                  final compressed = _compressImageToBase64(Uint8List.fromList(bytes));
                  return {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,$compressed',
                    },
                  };
                } catch (e) {
                }
              }
            }
          }
          return item;
        }).toList();
        return {...msg, 'content': compressedContent};
      }
      return msg;
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
      List<Map<String, dynamic>> apiMessages =
          _buildApiMessages(messages, attachments);
      // Compress images if request size exceeds threshold
      apiMessages = _compressApiMessagesIfNeeded(apiMessages);
      // Add System Time Prompt (Always)
      final now = DateTime.now();
      final dateStr = now.toIso8601String().split('T')[0]; // YYYY-MM-DD
      final timeInstruction = 'Current Date: $dateStr. Today is ${now.year}.';
      
      final systemMsgIndex = apiMessages.indexWhere((m) => m['role'] == 'system');
      if (systemMsgIndex != -1) {
           final oldContent = apiMessages[systemMsgIndex]['content'];
           if (!oldContent.toString().contains('Current Date:')) {
             apiMessages[systemMsgIndex]['content'] = '$timeInstruction\n\n$oldContent';
           }
      } else {
         apiMessages.insert(0, {
           'role': 'system', 
           'content': timeInstruction
         });
      }

      final Map<String, dynamic> requestData = {
        'model': model,
        'messages': apiMessages,
        'stream': false,
      };
      if (tools != null) {
        requestData['tools'] = tools;
        if (toolChoice != null) {
           requestData['tool_choice'] = toolChoice;
        }
        
        // Add Search Tool Guidelines if search_web is available
        final sysIdx = apiMessages.indexWhere((m) => m['role'] == 'system');
        if (sysIdx != -1) {
           final oldContent = apiMessages[sysIdx]['content'];
           final searchGuide = 'You have access to a web search tool. Use it for current information.';
           if (!oldContent.toString().contains('web search tool')) {
              apiMessages[sysIdx]['content'] = '$oldContent\n\n$searchGuide';
           }
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
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        final message = choices[0]['message'];
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
      // Rethrow to let caller handle and record as failure
      final statusCode = e.response?.statusCode;
      String errorMsg = 'HTTP Error';
      
      try {
        if (e.response?.data != null) {
          final data = e.response?.data;
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
            // Try to parse as JSON
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
          // No response data, use Dio's error type
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
      } catch (_) {
        errorMsg = 'HTTP $statusCode: ${e.message}';
      }
      
      throw Exception(errorMsg);
    } catch (e) {
      // Rethrow all other exceptions
      rethrow;
    }
  }
}
