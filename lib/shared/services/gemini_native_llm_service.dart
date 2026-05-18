import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/error/app_error_type.dart';
import '../../core/error/app_exception.dart';
import '../../features/chat/domain/message.dart';
import '../../features/settings/domain/provider_route_config.dart';
import '../../features/settings/presentation/settings_provider.dart';
import '../utils/app_logger.dart';
import '../utils/file_snapshot_cache.dart';
import '../utils/llm_stream_log_accumulator.dart';
import 'attachment_mime.dart';
import 'capability_route_resolver.dart';
import 'gemini_native_endpoint.dart';
import 'llm_service.dart';
import 'llm_service_config.dart';
import 'llm_transport_mode.dart';

final RegExp _gemini3ImageModelPattern =
    RegExp(r'gemini.*3.*image.*', caseSensitive: false);
const String _omittedBase64LogValue = '[BASE64_OMITTED]';

String _normalizeGeminiModelName(String modelName) {
  return modelName
      .trim()
      .toLowerCase()
      .replaceAll('（', '(')
      .replaceAll('）', ')')
      .replaceAll(RegExp(r'\s+'), '');
}

bool _isGemini3ImageModel(String modelName) {
  final normalized = _normalizeGeminiModelName(modelName);
  if (normalized.isEmpty) return false;
  return _gemini3ImageModelPattern.hasMatch(normalized);
}

class GeminiNativeLlmService implements LLMService {
  final Dio _dio;
  final SettingsState _settings;
  final FileSnapshotCache<List<Map<String, dynamic>>> _attachmentPartsCache =
      FileSnapshotCache<List<Map<String, dynamic>>>(maxEntries: 32);

  GeminiNativeLlmService(this._settings)
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 300),
            sendTimeout: const Duration(seconds: 60),
            headers: {
              'Connection': 'keep-alive',
              'User-Agent': 'Aurora/1.0 (Flutter; Dio)',
            },
          ),
        );

  Duration _resolveRequestTimeout() {
    return Duration(seconds: _settings.llmRequestTimeoutSeconds);
  }

  String _resolveNativeBaseUrl({
    required ProviderConfig provider,
    required Map<String, dynamic> activeParams,
  }) {
    final override = activeParams[auroraTransportBaseUrlKey]?.toString().trim();
    if (override != null && override.isNotEmpty) {
      return normalizeGeminiNativeBaseUrl(override);
    }

    final providerBase = provider.baseUrl.trim();
    if (providerBase.isNotEmpty) {
      if (providerBase.toLowerCase().contains('api.openai.com')) {
        return officialGeminiNativeBaseUrl;
      }
      return normalizeGeminiNativeBaseUrl(providerBase);
    }
    return officialGeminiNativeBaseUrl;
  }

  String _resolveNativeApiKey({
    required ProviderConfig provider,
    required Map<String, dynamic> activeParams,
  }) {
    final override = activeParams[auroraTransportApiKeyKey]?.toString().trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return provider.apiKey;
  }

  Object? _summarizePayloadForLog(
    Object? value, {
    String? keyHint,
  }) {
    if (value is Map) {
      final summarized = <String, dynamic>{};
      value.forEach((key, child) {
        final textKey = key.toString();
        summarized[textKey] = _summarizePayloadForLog(
          child,
          keyHint: textKey,
        );
      });
      return summarized;
    }
    if (value is List) {
      return value
          .map((item) => _summarizePayloadForLog(item, keyHint: keyHint))
          .toList();
    }
    if (value is String) {
      final lowerKey = keyHint?.trim().toLowerCase();
      if (lowerKey == 'data') {
        return _omittedBase64LogValue;
      }
      if (lowerKey == 'text' && value.length > 8192) {
        return '${value.substring(0, 512)}...[TRUNCATED ${value.length} chars]';
      }
    }
    return value;
  }

  void _logRequest(Uri uri, Map<String, dynamic> data) {
    AppLogger.llmRequest(
      url: uri.toString(),
      payload: _summarizePayloadForLog(data),
    );
  }

  void _logResponse(Object? payload) {
    AppLogger.llmResponse(payload: payload);
  }

  Future<Map<String, dynamic>> _buildRequestData({
    required List<Message> messages,
    required ProviderConfig provider,
    required String selectedModel,
    required Map<String, dynamic> activeParams,
    required List<Map<String, dynamic>>? tools,
    required String? toolChoice,
  }) async {
    final requestData = <String, dynamic>{};
    final mappedMessages = await _buildGeminiMessages(messages);

    requestData['contents'] = mappedMessages.contents;
    if (mappedMessages.systemInstruction != null) {
      requestData['systemInstruction'] = mappedMessages.systemInstruction;
    }

    _applyGenerationConfig(
      requestData: requestData,
      activeParams: activeParams,
      selectedModel: selectedModel,
    );
    _applyToolsConfig(
      requestData: requestData,
      activeParams: activeParams,
      tools: tools,
      toolChoice: toolChoice,
    );

    requestData.addAll(
      LlmServiceConfig.buildRequestParameters(
        provider: provider,
        activeParams: activeParams,
      ),
    );

    requestData.remove('model');
    requestData.remove('messages');
    requestData.remove('stream');
    requestData.remove('stream_options');
    requestData.remove('extra_body');
    requestData.remove('image_config');
    requestData.remove('reasoning_effort');
    requestData.remove('tool_choice');
    requestData.remove('system');

    return requestData;
  }

  Future<_GeminiMessageBuildResult> _buildGeminiMessages(
    List<Message> messages,
  ) async {
    final systemTexts = <String>[];
    final contents = <Map<String, dynamic>>[];
    final toolCallNameById = <String, String>{};
    var unnamedToolCallCounter = 0;

    for (final message in messages) {
      final role = message.role.toLowerCase();

      if (role == 'system') {
        final text = message.content.trim();
        if (text.isNotEmpty) {
          systemTexts.add(text);
        }
        continue;
      }

      if (role == 'assistant' && (message.toolCalls?.isNotEmpty ?? false)) {
        final parts = <Map<String, dynamic>>[];
        if (message.content.trim().isNotEmpty) {
          parts.add({'text': message.content});
        }
        for (final toolCall in message.toolCalls!) {
          final callName =
              toolCall.name.trim().isEmpty ? 'tool' : toolCall.name;
          final normalizedId = toolCall.id.trim().isEmpty
              ? 'tool_call_${unnamedToolCallCounter++}_$callName'
              : toolCall.id.trim();
          toolCallNameById[normalizedId] = callName;
          parts.add({
            'functionCall': {
              'name': callName,
              'args': _decodeFunctionArguments(toolCall.arguments),
            },
          });
        }
        if (parts.isNotEmpty) {
          contents.add({
            'role': 'model',
            'parts': parts,
          });
        }
        continue;
      }

      if (role == 'tool') {
        final parts = _buildToolResponseParts(
          message: message,
          toolCallNameById: toolCallNameById,
        );
        if (parts.isNotEmpty) {
          contents.add({
            'role': 'user',
            'parts': parts,
          });
        }
        continue;
      }

      final parts = await _buildPartsForMessage(message);
      if (parts.isEmpty) continue;

      final mappedRole =
          role == 'assistant' || role == 'model' ? 'model' : 'user';
      contents.add({
        'role': mappedRole,
        'parts': parts,
      });
    }

    Map<String, dynamic>? systemInstruction;
    if (systemTexts.isNotEmpty) {
      systemInstruction = {
        'parts': [
          {'text': systemTexts.join('\n\n')}
        ],
      };
    }

    return _GeminiMessageBuildResult(
      contents: contents,
      systemInstruction: systemInstruction,
    );
  }

  dynamic _decodeFunctionArguments(String rawArguments) {
    final trimmed = rawArguments.trim();
    if (trimmed.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map || decoded is List) {
        return decoded;
      }
      return {'value': decoded};
    } catch (_) {
      return {'raw': rawArguments};
    }
  }

  List<Map<String, dynamic>> _buildToolResponseParts({
    required Message message,
    required Map<String, String> toolCallNameById,
  }) {
    final id = message.toolCallId?.trim() ?? '';
    final name = id.isNotEmpty
        ? (toolCallNameById[id] ?? _inferToolNameFromId(id))
        : 'tool';

    final responseValue = _decodeStructuredToolResult(message.content);
    return [
      {
        'functionResponse': {
          'name': name,
          'response': {'result': responseValue},
        },
      }
    ];
  }

  dynamic _decodeStructuredToolResult(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return '';
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return content;
    }
  }

  String _inferToolNameFromId(String id) {
    if (id.startsWith('search_')) return 'SearchWeb';
    return 'tool';
  }

  Future<List<Map<String, dynamic>>> _buildPartsForMessage(
    Message message,
  ) async {
    final parts = <Map<String, dynamic>>[];

    if (message.content.trim().isNotEmpty) {
      parts.add({'text': message.content});
    }

    for (final attachmentPath in message.attachments) {
      parts.addAll(await _buildPartsFromAttachment(attachmentPath));
    }

    for (final image in message.images) {
      final part = _buildImagePart(image);
      if (part != null) {
        parts.add(part);
      }
    }
    return parts;
  }

  Future<List<Map<String, dynamic>>> _buildPartsFromAttachment(
    String attachmentPath,
  ) async {
    final cachedParts = await _attachmentPartsCache.getOrLoad(
      attachmentPath,
      (snapshot) async {
        final mimeType = AttachmentMime.fromPath(snapshot.path);
        final filename = snapshot.fileName;
        if (AttachmentMime.isTextLike(mimeType)) {
          try {
            final textContent = await snapshot.file.readAsString();
            return [
              {
                'text':
                    '--- File: $filename ---\n$textContent\n--- End File ---',
              }
            ];
          } catch (_) {
            return [
              {'text': '[Attached File: $filename ($mimeType)]'}
            ];
          }
        }

        try {
          final bytes = await snapshot.file.readAsBytes();
          return [
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Encode(bytes),
              }
            }
          ];
        } catch (_) {
          return [
            {'text': '[Attached File: $filename ($mimeType)]'}
          ];
        }
      },
    );

    if (cachedParts == null || cachedParts.isEmpty) {
      return [
        {'text': '[Failed to load file: $attachmentPath]'}
      ];
    }
    return cloneStructuredMapList(cachedParts);
  }

  Map<String, dynamic>? _buildImagePart(String image) {
    if (image.isEmpty) return null;

    if (image.startsWith('data:')) {
      final parsed = _parseDataUrl(image);
      if (parsed != null) {
        return {
          'inlineData': {
            'mimeType': parsed.mimeType,
            'data': parsed.data,
          }
        };
      }
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return {
        'fileData': {
          'mimeType': AttachmentMime.guessImageFromUrl(image),
          'fileUri': image,
        }
      };
    }

    return {
      'inlineData': {
        'mimeType': 'image/png',
        'data': image,
      }
    };
  }

  _DataUrlPayload? _parseDataUrl(String input) {
    final match = RegExp(r'^data:([^;]+);base64,(.+)$', caseSensitive: false)
        .firstMatch(input);
    if (match == null) return null;
    final mime = match.group(1);
    final data = match.group(2);
    if (mime == null || data == null || mime.isEmpty || data.isEmpty) {
      return null;
    }
    return _DataUrlPayload(mimeType: mime, data: data);
  }

  void _applyGenerationConfig({
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> activeParams,
    required String selectedModel,
  }) {
    final generationConfig = <String, dynamic>{};
    final auroraGeneration = activeParams['_aurora_generation_config'];
    if (auroraGeneration is Map) {
      final temp = auroraGeneration['temperature'];
      if (temp != null && temp.toString().trim().isNotEmpty) {
        final value = double.tryParse(temp.toString().trim());
        if (value != null) {
          generationConfig['temperature'] = value;
        }
      }
      final maxTokens = auroraGeneration['max_tokens'];
      if (maxTokens != null && maxTokens.toString().trim().isNotEmpty) {
        final value = int.tryParse(maxTokens.toString().trim());
        if (value != null && value > 0) {
          generationConfig['maxOutputTokens'] = value;
        }
      }
    }

    final thinkingConfig = _buildThinkingConfig(
      activeParams: activeParams,
      selectedModel: selectedModel,
    );
    if (thinkingConfig.isNotEmpty) {
      generationConfig['thinkingConfig'] = thinkingConfig;
    }

    final imageConfig = _buildImageConfig(
      activeParams: activeParams,
      selectedModel: selectedModel,
    );
    if (imageConfig.isNotEmpty) {
      generationConfig['imageConfig'] = imageConfig;
    }

    if (generationConfig.isNotEmpty) {
      requestData['generationConfig'] = generationConfig;
    }
  }

  Map<String, dynamic> _buildImageConfig({
    required Map<String, dynamic> activeParams,
    required String selectedModel,
  }) {
    if (!selectedModel.toLowerCase().contains('image')) {
      return const <String, dynamic>{};
    }

    final imageConfig = resolveAuroraImageConfig(activeParams);
    final result = <String, dynamic>{
      if (imageConfig.aspectRatio != null)
        'aspectRatio': imageConfig.aspectRatio,
      if (imageConfig.imageSize != null) 'imageSize': imageConfig.imageSize,
    };
    if (result.isEmpty) {
      return const <String, dynamic>{};
    }
    return result;
  }

  Map<String, dynamic> _buildThinkingConfig({
    required Map<String, dynamic> activeParams,
    required String selectedModel,
  }) {
    final result = <String, dynamic>{};
    final thinkingConfig = activeParams['_aurora_thinking_config'];
    if (thinkingConfig is Map && thinkingConfig['enabled'] == true) {
      final raw = thinkingConfig['budget']?.toString().trim() ?? '';
      if (raw.isNotEmpty) {
        result['includeThoughts'] = true;
        final numeric = int.tryParse(raw);
        if (numeric != null) {
          if (numeric >= 0) {
            result['thinkingBudget'] = numeric;
          }
        } else {
          result['thinkingLevel'] = _normalizeThinkingLevel(raw.toLowerCase());
        }
      }
    }

    final imageConfig = resolveAuroraImageConfig(activeParams);
    if (_isGemini3ImageModel(selectedModel) &&
        imageConfig.includeThoughts != null) {
      result['includeThoughts'] = imageConfig.includeThoughts;
    }

    return result;
  }

  String _normalizeThinkingLevel(String raw) {
    switch (raw) {
      case 'minimal':
      case 'min':
      case 'mini':
      case 'tiny':
      case 'least':
      case 'lowest':
        return 'minimal';
      case 'low':
      case 'l':
      case 'small':
        return 'low';
      case 'medium':
      case 'med':
      case 'mid':
      case 'middle':
      case 'm':
        return 'medium';
      case 'xhigh':
      case 'xh':
      case 'veryhigh':
      case 'ultra':
      case 'max':
      case 'extreme':
      case 'high':
      case 'h':
      case 'big':
      case 'strong':
      default:
        return 'high';
    }
  }

  void _applyToolsConfig({
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> activeParams,
    required List<Map<String, dynamic>>? tools,
    required String? toolChoice,
  }) {
    final nativeTools = resolveGeminiNativeToolsFromSettings(activeParams);
    final requestTools = <Map<String, dynamic>>[];

    if (nativeTools.googleSearch) {
      requestTools.add({'google_search': {}});
    }
    if (nativeTools.urlContext) {
      requestTools.add({'url_context': {}});
    }
    if (nativeTools.codeExecution) {
      requestTools.add({'code_execution': {}});
    }

    final declarations = _convertFunctionDeclarations(tools);
    if (declarations.isNotEmpty) {
      requestTools.add({'functionDeclarations': declarations});
    }

    if (requestTools.isNotEmpty) {
      requestData['tools'] = requestTools;
    }

    final toolConfig = _buildToolConfig(
      toolChoice: toolChoice,
      declarations: declarations,
    );
    if (toolConfig != null) {
      requestData['toolConfig'] = toolConfig;
    }
  }

  List<Map<String, dynamic>> _convertFunctionDeclarations(
    List<Map<String, dynamic>>? tools,
  ) {
    if (tools == null || tools.isEmpty) return const [];

    final declarations = <Map<String, dynamic>>[];
    for (final tool in tools) {
      final type = tool['type']?.toString();
      if (type != 'function') continue;
      final fn = tool['function'];
      if (fn is! Map) continue;
      final name = fn['name']?.toString().trim();
      if (name == null || name.isEmpty) continue;
      final description = fn['description']?.toString().trim();
      Map<String, dynamic>? parameters;
      final rawParameters = fn['parameters'];
      if (rawParameters is Map) {
        parameters = rawParameters.map((k, v) => MapEntry('$k', v));
      }

      declarations.add({
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (parameters != null) 'parameters': parameters,
      });
    }
    return declarations;
  }

  Map<String, dynamic>? _buildToolConfig({
    required String? toolChoice,
    required List<Map<String, dynamic>> declarations,
  }) {
    final raw = toolChoice?.trim();
    if (raw == null || raw.isEmpty) return null;

    final lower = raw.toLowerCase();
    if (lower == 'none') {
      return {
        'functionCallingConfig': {'mode': 'NONE'}
      };
    }
    if (lower == 'auto') {
      return {
        'functionCallingConfig': {'mode': 'AUTO'}
      };
    }
    if (lower == 'required') {
      return {
        'functionCallingConfig': {'mode': 'ANY'}
      };
    }

    var functionName = raw;
    if (raw.startsWith('function:')) {
      functionName = raw.substring('function:'.length).trim();
    }
    if (functionName.isEmpty) {
      return null;
    }

    final hasDeclaration =
        declarations.any((item) => item['name'] == functionName);
    return {
      'functionCallingConfig': {
        'mode': 'ANY',
        if (hasDeclaration) 'allowedFunctionNames': [functionName],
      }
    };
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString().trim());
  }

  LLMResponseChunk? _usageChunkFromUsageMetadata(dynamic rawUsage) {
    if (rawUsage is! Map) return null;
    final promptTokens = _toInt(rawUsage['promptTokenCount']);
    final completionTokens = _toInt(rawUsage['candidatesTokenCount']);
    final reasoningTokens = _toInt(rawUsage['thoughtsTokenCount']);
    var totalTokens = _toInt(rawUsage['totalTokenCount']);

    if (totalTokens == null) {
      final total = (promptTokens ?? 0) +
          (completionTokens ?? 0) +
          (reasoningTokens ?? 0);
      if (total > 0) totalTokens = total;
    }

    if (promptTokens == null &&
        completionTokens == null &&
        reasoningTokens == null &&
        totalTokens == null) {
      return null;
    }

    return LLMResponseChunk(
      usage: totalTokens,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      reasoningTokens: reasoningTokens,
    );
  }

  _GeminiResponseView _extractResponseView(dynamic rawResponse) {
    if (rawResponse is! Map) return const _GeminiResponseView();
    final candidates = rawResponse['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return const _GeminiResponseView();
    }

    final first = candidates.first;
    if (first is! Map) return const _GeminiResponseView();
    final finishReason =
        _normalizeFinishReason(first['finishReason']?.toString());
    final content = first['content'];
    if (content is! Map) {
      return _GeminiResponseView(finishReason: finishReason);
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      return _GeminiResponseView(finishReason: finishReason);
    }

    final contentBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final images = <String>[];
    final toolCalls = <ToolCallChunk>[];
    var toolIndex = 0;

    for (final part in parts) {
      if (part is! Map) continue;

      final text = part['text']?.toString();
      if (text != null && text.isNotEmpty) {
        if (part['thought'] == true) {
          reasoningBuffer.write(text);
        } else {
          contentBuffer.write(text);
        }
      }

      final functionCall = part['functionCall'];
      if (functionCall is Map) {
        final name = functionCall['name']?.toString() ?? '';
        final args = functionCall['args'];
        final argsText =
            args == null ? '' : (args is String ? args : jsonEncode(args));
        final id =
            functionCall['id']?.toString() ?? 'gemini_tool_call_$toolIndex';
        toolCalls.add(
          ToolCallChunk(
            index: toolIndex,
            id: id,
            type: 'function',
            name: name,
            arguments: argsText,
          ),
        );
        toolIndex++;
      }

      final inlineData = part['inlineData'] ?? part['inline_data'];
      if (inlineData is Map) {
        final mimeType =
            inlineData['mimeType'] ?? inlineData['mime_type'] ?? 'image/png';
        final data = inlineData['data']?.toString();
        if (data != null && data.isNotEmpty) {
          images.add('data:$mimeType;base64,$data');
        }
      }

      final fileData = part['fileData'] ?? part['file_data'];
      if (fileData is Map) {
        final uri = fileData['fileUri'] ?? fileData['uri'] ?? fileData['url'];
        if (uri != null && uri.toString().isNotEmpty) {
          images.add(uri.toString());
        }
      }
    }

    return _GeminiResponseView(
      content: contentBuffer.isEmpty ? null : contentBuffer.toString(),
      reasoning: reasoningBuffer.isEmpty ? null : reasoningBuffer.toString(),
      toolCalls: toolCalls.isEmpty ? null : toolCalls,
      images: images,
      finishReason: finishReason,
    );
  }

  String? _normalizeFinishReason(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    switch (lower) {
      case 'malformed_function_call':
        return 'malformed_function_call';
      case 'safety':
      case 'blocked':
      case 'recitation':
        return 'content_filter';
      default:
        return lower;
    }
  }

  String _streamDelta({
    required String previous,
    required String incoming,
  }) {
    if (incoming.isEmpty) return '';
    if (previous.isEmpty) return incoming;
    if (incoming == previous) return '';
    if (incoming.startsWith(previous)) {
      return incoming.substring(previous.length);
    }
    return incoming;
  }

  String _mergeStreamState({
    required String previous,
    required String incoming,
  }) {
    if (incoming.isEmpty) return previous;
    if (previous.isEmpty) return incoming;
    if (incoming.startsWith(previous)) return incoming;
    if (previous.endsWith(incoming)) return previous;
    return '$previous$incoming';
  }

  List<ToolCallChunk>? _diffToolCallChunks({
    required List<ToolCallChunk>? incoming,
    required Map<int, String> emittedNames,
    required Map<int, String> emittedArgs,
    required Map<int, String> emittedIds,
  }) {
    if (incoming == null || incoming.isEmpty) return null;
    final out = <ToolCallChunk>[];
    for (final chunk in incoming) {
      final index = chunk.index ?? 0;
      final currentName = chunk.name ?? '';
      final currentArgs = chunk.arguments ?? '';
      final prevName = emittedNames[index] ?? '';
      final prevArgs = emittedArgs[index] ?? '';
      final prevId = emittedIds[index] ?? '';

      final deltaName = _streamDelta(previous: prevName, incoming: currentName);
      final deltaArgs = _streamDelta(previous: prevArgs, incoming: currentArgs);

      emittedNames[index] =
          _mergeStreamState(previous: prevName, incoming: currentName);
      emittedArgs[index] =
          _mergeStreamState(previous: prevArgs, incoming: currentArgs);
      emittedIds[index] = chunk.id ?? prevId;

      if (deltaName.isEmpty && deltaArgs.isEmpty) continue;
      out.add(
        ToolCallChunk(
          index: index,
          id: prevId.isEmpty ? chunk.id : null,
          type: chunk.type,
          name: deltaName,
          arguments: deltaArgs,
        ),
      );
    }
    return out.isEmpty ? null : out;
  }

  AppErrorType _inferErrorType(DioException e, int? statusCode) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AppErrorType.timeout;
    }
    if (e.type == DioExceptionType.connectionError) {
      return AppErrorType.network;
    }
    if (e.type == DioExceptionType.badResponse) {
      if (statusCode == 400) {
        return AppErrorType.badRequest;
      }
      if (statusCode == 401 || statusCode == 403) {
        return AppErrorType.unauthorized;
      }
      if (statusCode == 429) {
        return AppErrorType.rateLimit;
      }
      if (statusCode != null && statusCode >= 500) {
        return AppErrorType.serverError;
      }
    }
    return AppErrorType.unknown;
  }

  Future<String> _extractDioErrorMessage(
    DioException e, {
    required int? statusCode,
  }) async {
    final responseData = e.response?.data;
    if (responseData == null) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection Timeout';
        case DioExceptionType.sendTimeout:
          return 'Send Timeout';
        case DioExceptionType.receiveTimeout:
          return 'Receive Timeout';
        case DioExceptionType.connectionError:
          return 'Connection Error: ${e.message}';
        default:
          return 'Network Error: ${e.message}';
      }
    }

    if (responseData is ResponseBody) {
      final bytes = await responseData.stream
          .fold<List<int>>([], (previous, chunk) => previous..addAll(chunk));
      final text = utf8.decode(bytes, allowMalformed: true);
      _logResponse(text);
      return _normalizeErrorMessage(source: text, statusCode: statusCode);
    }

    _logResponse(responseData);
    return _normalizeErrorMessage(source: responseData, statusCode: statusCode);
  }

  String _normalizeErrorMessage({
    required Object source,
    required int? statusCode,
  }) {
    dynamic parsed = source;
    if (source is String) {
      final trimmed = source.trim();
      if (trimmed.isNotEmpty && trimmed.startsWith('{')) {
        try {
          parsed = jsonDecode(trimmed);
        } catch (_) {}
      }
    }

    if (parsed is Map) {
      final error = parsed['error'];
      if (error is Map && error['message'] != null) {
        return 'HTTP $statusCode: ${error['message']}';
      }
      if (parsed['message'] != null) {
        return 'HTTP $statusCode: ${parsed['message']}';
      }
    }
    return 'HTTP $statusCode: $source';
  }

  @override
  Stream<LLMResponseChunk> streamResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    String? model,
    String? providerId,
    CancelToken? cancelToken,
  }) async* {
    final resolved = LlmServiceConfig.resolveTarget(
      settings: _settings,
      providerId: providerId,
      requestedModel: model,
    );
    final provider = resolved.provider;
    final selectedModel = resolved.selectedModel;
    if (selectedModel == null) {
      yield LLMResponseChunk(
        content: LlmServiceConfig.missingModelMessage(_settings),
      );
      return;
    }

    final activeParams = LlmServiceConfig.buildActiveParams(
      provider: provider,
      selectedModel: selectedModel,
    );
    final apiKey = _resolveNativeApiKey(
      provider: provider,
      activeParams: activeParams,
    );
    if (apiKey.isEmpty) {
      yield LLMResponseChunk(
        content: LlmServiceConfig.emptyApiKeyMessage(_settings),
      );
      return;
    }
    LlmStreamLogAccumulator? streamLog;

    var route = const CapabilityRouteResolver().resolve(
      provider: provider,
      capability: ProviderCapability.chat,
      modelName: selectedModel,
      forcePreset: ProtocolPreset.geminiNativeGenerateContent,
    );
    route = route.copyWith(
      baseUrl: _resolveNativeBaseUrl(
        provider: provider,
        activeParams: activeParams,
      ),
    );
    final uri = route.buildUri(
      model: selectedModel,
      stream: true,
      apiKey: route.effectiveApiKey(provider),
    );

    try {
      final requestData = await _buildRequestData(
        messages: messages,
        provider: provider,
        selectedModel: selectedModel,
        activeParams: activeParams,
        tools: tools,
        toolChoice: toolChoice,
      );
      final timeout = _resolveRequestTimeout();
      streamLog = LlmStreamLogAccumulator(
        providerId: provider.id,
        model: selectedModel,
      );

      _logRequest(uri, requestData);
      final response = await _dio.postUri<ResponseBody>(
        uri,
        data: requestData,
        options: Options(
          headers: route.buildHeaders(
            apiKey: apiKey,
            extra: const {
              'Content-Type': 'application/json',
              'Accept': 'text/event-stream',
            },
          ),
          sendTimeout: timeout,
          receiveTimeout: timeout,
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
      );

      final responseBody = response.data;
      if (responseBody == null) return;

      final stream =
          responseBody.stream.cast<List<int>>().transform(utf8.decoder);
      var lineBuffer = '';
      var emittedContent = '';
      var emittedReasoning = '';
      String? emittedFinishReason;
      final emittedToolNames = <int, String>{};
      final emittedToolArgs = <int, String>{};
      final emittedToolIds = <int, String>{};
      var done = false;

      await for (final chunk in stream) {
        lineBuffer += chunk;

        while (lineBuffer.contains('\n')) {
          final newlineIndex = lineBuffer.indexOf('\n');
          final rawLine = lineBuffer.substring(0, newlineIndex);
          lineBuffer = lineBuffer.substring(newlineIndex + 1);

          final line = rawLine.trim();
          if (line.isEmpty || !line.startsWith('data:')) {
            continue;
          }

          final data = line.substring(5).trim();
          if (data.isEmpty) continue;
          if (data == '[DONE]') {
            streamLog.recordDoneMarkerSeen();
            done = true;
            break;
          }

          dynamic parsed;
          try {
            parsed = jsonDecode(data);
            streamLog.recordSseEvent();
          } catch (_) {
            streamLog.recordParseError();
            AppLogger.warn(
              'LLM',
              'Failed to parse Gemini SSE payload',
              category: 'STREAM_PARSE',
              data: {'payload': data},
            );
            continue;
          }

          final usageChunk = _usageChunkFromUsageMetadata(
            parsed is Map ? parsed['usageMetadata'] : null,
          );
          if (usageChunk != null) {
            streamLog.recordUsage(
              usage: usageChunk.usage,
              promptTokens: usageChunk.promptTokens,
              completionTokens: usageChunk.completionTokens,
              reasoningTokens: usageChunk.reasoningTokens,
            );
            streamLog.recordEmission();
            yield usageChunk;
          }

          final responseView = _extractResponseView(parsed);
          final incomingContent = responseView.content ?? '';
          final incomingReasoning = responseView.reasoning ?? '';

          final contentDelta = _streamDelta(
            previous: emittedContent,
            incoming: incomingContent,
          );
          final reasoningDelta = _streamDelta(
            previous: emittedReasoning,
            incoming: incomingReasoning,
          );
          emittedContent = _mergeStreamState(
            previous: emittedContent,
            incoming: incomingContent,
          );
          emittedReasoning = _mergeStreamState(
            previous: emittedReasoning,
            incoming: incomingReasoning,
          );

          final toolCallDelta = _diffToolCallChunks(
            incoming: responseView.toolCalls,
            emittedNames: emittedToolNames,
            emittedArgs: emittedToolArgs,
            emittedIds: emittedToolIds,
          );

          String? finishReason;
          if (responseView.finishReason != null &&
              responseView.finishReason != emittedFinishReason) {
            finishReason = responseView.finishReason;
            emittedFinishReason = responseView.finishReason;
          }

          if (contentDelta.isEmpty &&
              reasoningDelta.isEmpty &&
              (toolCallDelta == null || toolCallDelta.isEmpty) &&
              responseView.images.isEmpty &&
              finishReason == null) {
            continue;
          }

          streamLog.recordEmission(
            content: contentDelta.isEmpty ? null : contentDelta,
            reasoning: reasoningDelta.isEmpty ? null : reasoningDelta,
            imageCount: responseView.images.length,
            finishReason: finishReason,
          );
          yield LLMResponseChunk(
            content: contentDelta.isEmpty ? null : contentDelta,
            reasoning: reasoningDelta.isEmpty ? null : reasoningDelta,
            toolCalls: toolCallDelta,
            images: responseView.images,
            finishReason: finishReason,
          );
        }
        if (done) break;
      }
      streamLog.logCompleted();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        streamLog?.logCancelled();
        return;
      }
      final statusCode = e.response?.statusCode;
      final errorMsg = await _extractDioErrorMessage(
        e,
        statusCode: statusCode,
      );
      throw AppException(
        type: _inferErrorType(e, statusCode),
        message: errorMsg,
        statusCode: statusCode,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(type: AppErrorType.unknown, message: e.toString());
    }
  }

  @override
  Future<LLMResponseChunk> getResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    String? model,
    String? providerId,
    CancelToken? cancelToken,
  }) async {
    final resolved = LlmServiceConfig.resolveTarget(
      settings: _settings,
      providerId: providerId,
      requestedModel: model,
    );
    final provider = resolved.provider;
    final selectedModel = resolved.selectedModel;
    if (selectedModel == null) {
      return LLMResponseChunk(
        content: LlmServiceConfig.missingModelMessage(_settings),
      );
    }

    final activeParams = LlmServiceConfig.buildActiveParams(
      provider: provider,
      selectedModel: selectedModel,
    );
    final apiKey = _resolveNativeApiKey(
      provider: provider,
      activeParams: activeParams,
    );
    if (apiKey.isEmpty) {
      return LLMResponseChunk(
        content: LlmServiceConfig.emptyApiKeyMessage(_settings),
      );
    }

    var route = const CapabilityRouteResolver().resolve(
      provider: provider,
      capability: ProviderCapability.chat,
      modelName: selectedModel,
      forcePreset: ProtocolPreset.geminiNativeGenerateContent,
    );
    route = route.copyWith(
      baseUrl: _resolveNativeBaseUrl(
        provider: provider,
        activeParams: activeParams,
      ),
    );
    final uri = route.buildUri(
      model: selectedModel,
      stream: false,
      apiKey: route.effectiveApiKey(provider),
    );

    try {
      final requestData = await _buildRequestData(
        messages: messages,
        provider: provider,
        selectedModel: selectedModel,
        activeParams: activeParams,
        tools: tools,
        toolChoice: toolChoice,
      );
      final timeout = _resolveRequestTimeout();
      _logRequest(uri, requestData);

      final response = await _dio.postUri(
        uri,
        data: requestData,
        options: Options(
          headers: route.buildHeaders(
            apiKey: apiKey,
            extra: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
        cancelToken: cancelToken,
      );

      final payload = response.data;
      _logResponse(payload);

      final usageChunk = _usageChunkFromUsageMetadata(
        payload is Map ? payload['usageMetadata'] : null,
      );
      final responseView = _extractResponseView(payload);

      return LLMResponseChunk(
        content: responseView.content ?? '',
        reasoning: responseView.reasoning,
        images: responseView.images,
        toolCalls: responseView.toolCalls,
        usage: usageChunk?.usage,
        promptTokens: usageChunk?.promptTokens,
        completionTokens: usageChunk?.completionTokens,
        reasoningTokens: usageChunk?.reasoningTokens,
        finishReason: responseView.finishReason,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        AppLogger.info(
          'LLM',
          'Request was cancelled by the user.',
          category: 'REQUEST_CANCELLED',
        );
        return const LLMResponseChunk(content: '');
      }
      final statusCode = e.response?.statusCode;
      final errorMsg = await _extractDioErrorMessage(
        e,
        statusCode: statusCode,
      );
      throw AppException(
        type: _inferErrorType(e, statusCode),
        message: errorMsg,
        statusCode: statusCode,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(type: AppErrorType.unknown, message: e.toString());
    }
  }
}

class _GeminiMessageBuildResult {
  final List<Map<String, dynamic>> contents;
  final Map<String, dynamic>? systemInstruction;

  const _GeminiMessageBuildResult({
    required this.contents,
    this.systemInstruction,
  });
}

class _GeminiResponseView {
  final String? content;
  final String? reasoning;
  final List<ToolCallChunk>? toolCalls;
  final List<String> images;
  final String? finishReason;

  const _GeminiResponseView({
    this.content,
    this.reasoning,
    this.toolCalls,
    this.images = const [],
    this.finishReason,
  });
}

class _DataUrlPayload {
  final String mimeType;
  final String data;

  const _DataUrlPayload({
    required this.mimeType,
    required this.data,
  });
}
