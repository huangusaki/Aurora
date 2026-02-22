import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/error/app_error_type.dart';
import '../../core/error/app_exception.dart';
import '../../features/chat/domain/message.dart';
import '../../features/settings/presentation/settings_provider.dart';
import '../utils/app_logger.dart';
import 'llm_service.dart';
import 'llm_transport_mode.dart';

class GeminiNativeLlmService implements LLMService {
  static const String _officialBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/';

  final Dio _dio;
  final SettingsState _settings;

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

  ProviderConfig _resolveProvider(String? providerId) {
    if (providerId == null) {
      return _settings.activeProvider;
    }
    return _settings.providers.firstWhere(
      (provider) => provider.id == providerId,
      orElse: () => _settings.activeProvider,
    );
  }

  String? _resolveSelectedModel({
    required ProviderConfig provider,
    required String? requestedModel,
  }) {
    final candidate = requestedModel ?? provider.selectedModel;
    if (candidate == null) return null;
    final normalized = candidate.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String _emptyApiKeyMessage() {
    return _settings.language == 'zh'
        ? '错误：API Key 为空。请检查设置。'
        : 'Error: API key is empty. Please check your settings.';
  }

  String _missingModelMessage() {
    return _settings.language == 'zh'
        ? '错误：未选择模型。请先在设置中为当前 Provider 配置模型。'
        : 'Error: no model selected. Please configure a model for the current provider.';
  }

  Map<String, dynamic> _buildActiveParams(
    ProviderConfig provider,
    String selectedModel,
  ) {
    final activeParams = <String, dynamic>{};
    final isExcluded = provider.globalExcludeModels.contains(selectedModel);
    if (!isExcluded) {
      activeParams.addAll(provider.globalSettings);
    }
    final specificModelParams = provider.modelSettings[selectedModel];
    if (specificModelParams != null) {
      activeParams.addAll(specificModelParams);
    }
    return activeParams;
  }

  Map<String, dynamic> _buildProviderParams(
    ProviderConfig provider,
    Map<String, dynamic> activeParams,
  ) {
    final filteredModelParams = Map<String, dynamic>.fromEntries(
      activeParams.entries.where((entry) => !entry.key.startsWith('_aurora_')),
    );
    final providerParams = Map<String, dynamic>.fromEntries(
      provider.customParameters.entries.where((entry) {
        final key = entry.key.toLowerCase();
        return key != 'api_keys' &&
            key != 'base_url' &&
            key != 'id' &&
            key != 'name' &&
            key != 'models' &&
            key != 'color' &&
            key != 'is_custom' &&
            key != 'is_enabled' &&
            !entry.key.startsWith('_aurora_');
      }),
    );
    final merged = <String, dynamic>{};
    merged.addAll(providerParams);
    merged.addAll(filteredModelParams);
    return merged;
  }

  String _resolveNativeBaseUrl({
    required ProviderConfig provider,
    required Map<String, dynamic> activeParams,
  }) {
    final override = activeParams[auroraTransportBaseUrlKey]?.toString().trim();
    if (override != null && override.isNotEmpty) {
      return _normalizeNativeBaseUrl(override);
    }

    final providerBase = provider.baseUrl.trim();
    if (providerBase.contains('generativelanguage.googleapis.com')) {
      return _normalizeNativeBaseUrl(providerBase);
    }
    return _officialBaseUrl;
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

  String _normalizeNativeBaseUrl(String rawBase) {
    final parsed = Uri.tryParse(rawBase.trim());
    if (parsed == null || parsed.host.isEmpty) return _officialBaseUrl;

    final pathSegments =
        parsed.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (pathSegments.isNotEmpty &&
        pathSegments.last.toLowerCase() == 'openai') {
      pathSegments.removeLast();
    }
    if (pathSegments.isEmpty) {
      pathSegments.add('v1beta');
    }

    final normalized = parsed.replace(
      pathSegments: pathSegments,
      query: null,
      fragment: null,
    );
    var base = normalized.toString();
    if (!base.endsWith('/')) {
      base = '$base/';
    }
    return base;
  }

  String _modelResourcePath(String model) {
    final normalized = model.trim();
    if (normalized.startsWith('models/') ||
        normalized.startsWith('publishers/')) {
      return normalized;
    }
    return 'models/$normalized';
  }

  Uri _buildGenerateUri({
    required String baseUrl,
    required String model,
    required bool stream,
  }) {
    final method = stream ? 'streamGenerateContent' : 'generateContent';
    final endpoint = '$baseUrl${_modelResourcePath(model)}:$method';
    if (stream) {
      return Uri.parse('$endpoint?alt=sse');
    }
    return Uri.parse(endpoint);
  }

  void _logRequest(Uri uri, Map<String, dynamic> data) {
    AppLogger.llmRequest(url: uri.toString(), payload: data);
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
        requestData: requestData, activeParams: activeParams);
    _applyToolsConfig(
      requestData: requestData,
      activeParams: activeParams,
      tools: tools,
      toolChoice: toolChoice,
    );

    final providerParams = _buildProviderParams(provider, activeParams);
    requestData.addAll(providerParams);

    requestData.remove('model');
    requestData.remove('messages');
    requestData.remove('stream');
    requestData.remove('stream_options');
    requestData.remove('extra_body');
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
    final parts = <Map<String, dynamic>>[];
    final file = File(attachmentPath);
    final filename = attachmentPath.split(Platform.pathSeparator).last;
    if (!await file.exists()) {
      parts.add({'text': '[Failed to load file: $attachmentPath]'});
      return parts;
    }

    final mimeType = _getMimeType(attachmentPath);
    if (mimeType.startsWith('text/') ||
        mimeType == 'application/json' ||
        mimeType == 'application/xml') {
      try {
        final textContent = await file.readAsString();
        parts.add({
          'text': '--- File: $filename ---\n$textContent\n--- End File ---',
        });
        return parts;
      } catch (_) {
        parts.add({'text': '[Attached File: $filename ($mimeType)]'});
        return parts;
      }
    }

    try {
      final bytes = await file.readAsBytes();
      parts.add({
        'inlineData': {
          'mimeType': mimeType,
          'data': base64Encode(bytes),
        }
      });
      return parts;
    } catch (_) {
      parts.add({'text': '[Attached File: $filename ($mimeType)]'});
      return parts;
    }
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
          'mimeType': _guessMimeTypeFromUrl(image),
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

  String _guessMimeTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.png')) return 'image/png';
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return 'image/jpeg';
    if (lower.contains('.webp')) return 'image/webp';
    if (lower.contains('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  String _getMimeType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('png')) return 'image/png';
    if (p.endsWith('jpg') || p.endsWith('jpeg')) return 'image/jpeg';
    if (p.endsWith('webp')) return 'image/webp';
    if (p.endsWith('gif')) return 'image/gif';
    if (p.endsWith('bmp')) return 'image/bmp';
    if (p.endsWith('mp3')) return 'audio/mpeg';
    if (p.endsWith('wav')) return 'audio/wav';
    if (p.endsWith('m4a')) return 'audio/x-m4a';
    if (p.endsWith('flac')) return 'audio/flac';
    if (p.endsWith('ogg')) return 'audio/ogg';
    if (p.endsWith('opus')) return 'audio/opus';
    if (p.endsWith('aac')) return 'audio/aac';
    if (p.endsWith('mp4')) return 'video/mp4';
    if (p.endsWith('mov')) return 'video/quicktime';
    if (p.endsWith('avi')) return 'video/x-msvideo';
    if (p.endsWith('webm')) return 'video/webm';
    if (p.endsWith('mkv')) return 'video/x-matroska';
    if (p.endsWith('flv')) return 'video/x-flv';
    if (p.endsWith('3gp')) return 'video/3gpp';
    if (p.endsWith('mpg') || p.endsWith('mpeg')) return 'video/mpeg';
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

  void _applyGenerationConfig({
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> activeParams,
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

    final thinkingConfig = _buildThinkingConfig(activeParams);
    if (thinkingConfig.isNotEmpty) {
      generationConfig['thinkingConfig'] = thinkingConfig;
    }

    if (generationConfig.isNotEmpty) {
      requestData['generationConfig'] = generationConfig;
    }
  }

  Map<String, dynamic> _buildThinkingConfig(Map<String, dynamic> activeParams) {
    final thinkingConfig = activeParams['_aurora_thinking_config'];
    if (thinkingConfig is! Map) return {};
    if (thinkingConfig['enabled'] != true) return {};

    final raw = thinkingConfig['budget']?.toString().trim() ?? '';
    if (raw.isEmpty) return {};

    final result = <String, dynamic>{'includeThoughts': true};
    final numeric = int.tryParse(raw);
    if (numeric != null) {
      if (numeric >= 0) {
        result['thinkingBudget'] = numeric;
      }
      return result;
    }

    result['thinkingLevel'] = _normalizeThinkingLevel(raw.toLowerCase());
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
      final parameters = fn['parameters'];

      declarations.add({
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (parameters is Map) 'parameters': parameters,
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
    final provider = _resolveProvider(providerId);
    final selectedModel = _resolveSelectedModel(
      provider: provider,
      requestedModel: model,
    );
    if (selectedModel == null) {
      yield LLMResponseChunk(content: _missingModelMessage());
      return;
    }

    final activeParams = _buildActiveParams(provider, selectedModel);
    final apiKey = _resolveNativeApiKey(
      provider: provider,
      activeParams: activeParams,
    );
    if (apiKey.isEmpty) {
      yield LLMResponseChunk(content: _emptyApiKeyMessage());
      return;
    }

    final baseUrl = _resolveNativeBaseUrl(
      provider: provider,
      activeParams: activeParams,
    );
    final uri = _buildGenerateUri(
      baseUrl: baseUrl,
      model: selectedModel,
      stream: true,
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

      _logRequest(uri, requestData);
      final response = await _dio.postUri<ResponseBody>(
        uri,
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
            'x-goog-api-key': apiKey,
          },
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
            AppLogger.debug('LLM', 'DONE', category: 'STREAM');
            return;
          }

          dynamic parsed;
          try {
            parsed = jsonDecode(data);
          } catch (_) {
            AppLogger.warn(
              'LLM',
              'Failed to parse Gemini SSE payload',
              category: 'STREAM_PARSE',
              data: {'payload': data},
            );
            continue;
          }

          _logResponse(parsed);
          final usageChunk = _usageChunkFromUsageMetadata(
            parsed is Map ? parsed['usageMetadata'] : null,
          );
          if (usageChunk != null) {
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

          yield LLMResponseChunk(
            content: contentDelta.isEmpty ? null : contentDelta,
            reasoning: reasoningDelta.isEmpty ? null : reasoningDelta,
            toolCalls: toolCallDelta,
            images: responseView.images,
            finishReason: finishReason,
          );
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        AppLogger.info(
          'LLM',
          'Request was cancelled by the user.',
          category: 'REQUEST_CANCELLED',
        );
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
    final provider = _resolveProvider(providerId);
    final selectedModel = _resolveSelectedModel(
      provider: provider,
      requestedModel: model,
    );
    if (selectedModel == null) {
      return LLMResponseChunk(content: _missingModelMessage());
    }

    final activeParams = _buildActiveParams(provider, selectedModel);
    final apiKey = _resolveNativeApiKey(
      provider: provider,
      activeParams: activeParams,
    );
    if (apiKey.isEmpty) {
      return LLMResponseChunk(content: _emptyApiKeyMessage());
    }

    final baseUrl = _resolveNativeBaseUrl(
      provider: provider,
      activeParams: activeParams,
    );
    final uri = _buildGenerateUri(
      baseUrl: baseUrl,
      model: selectedModel,
      stream: false,
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
      _logRequest(uri, requestData);

      final response = await _dio.postUri(
        uri,
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-goog-api-key': apiKey,
          },
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
