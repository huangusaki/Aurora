import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../features/settings/domain/provider_route_config.dart';
import '../../features/settings/presentation/settings_provider.dart';
import '../utils/app_logger.dart';
import 'capability_route_resolver.dart';
import 'gemini_native_endpoint.dart';

class ImageGenerationResult {
  final List<String> images;
  final String? revisedPrompt;

  const ImageGenerationResult({
    this.images = const [],
    this.revisedPrompt,
  });
}

class SpeechGenerationResult {
  final Uint8List bytes;
  final String contentType;

  const SpeechGenerationResult({
    required this.bytes,
    required this.contentType,
  });
}

class AudioTextResult {
  final String text;
  final String? language;

  const AudioTextResult({
    required this.text,
    this.language,
  });
}

class ProviderCapabilityGateway {
  ProviderCapabilityGateway({
    Dio? dio,
    CapabilityRouteResolver? resolver,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 300),
                sendTimeout: const Duration(seconds: 120),
                headers: const {
                  'Connection': 'keep-alive',
                  'User-Agent': 'Aurora/1.0 (Flutter; Dio)',
                },
              ),
            ),
        _resolver = resolver ?? const CapabilityRouteResolver();

  final Dio _dio;
  final CapabilityRouteResolver _resolver;

  Future<List<String>> fetchModels({
    required ProviderConfig provider,
    ResolvedCapabilityRoute? route,
  }) async {
    final resolvedRoute = route ??
        _resolver.resolve(
          provider: provider,
          capability: ProviderCapability.models,
        );
    final apiKey = resolvedRoute.effectiveApiKey(provider);
    final uri = resolvedRoute.buildUri(apiKey: apiKey);
    final headers = resolvedRoute.buildHeaders(
      apiKey: apiKey,
      extra: const {'Accept': 'application/json'},
    );
    final response = await _performRequest(
      provider: provider,
      capability: ProviderCapability.models,
      route: resolvedRoute,
      uri: uri,
      options: Options(
        method: resolvedRoute.method,
        headers: headers,
      ),
    );
    return _parseModelList(resolvedRoute.preset, response.data);
  }

  Future<List<List<double>>> embedTexts({
    required ProviderConfig provider,
    required String model,
    required List<String> inputs,
  }) async {
    final route = _resolver.resolve(
      provider: provider,
      capability: ProviderCapability.embeddings,
      modelName: model,
    );
    final apiKey = route.effectiveApiKey(provider);
    final uri = route.buildUri(model: model, apiKey: apiKey);
    final body =
        _buildEmbeddingBody(route.preset, model: model, inputs: inputs);
    final headers = route.buildHeaders(
      apiKey: apiKey,
      extra: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    final response = await _performRequest(
      provider: provider,
      capability: ProviderCapability.embeddings,
      route: route,
      uri: uri,
      model: model,
      data: body,
      options: Options(
        method: route.method,
        headers: headers,
      ),
    );
    return _parseEmbeddingResponse(route.preset, response.data);
  }

  Future<ImageGenerationResult> generateImages({
    required ProviderConfig provider,
    required String model,
    required String prompt,
    int n = 1,
    String? imageSize,
    String? aspectRatio,
  }) async {
    final route = _resolver.resolve(
      provider: provider,
      capability: ProviderCapability.images,
      modelName: model,
    );
    final apiKey = route.effectiveApiKey(provider);
    final uri = route.buildUri(model: model, apiKey: apiKey);
    final body = switch (route.preset) {
      ProtocolPreset.openaiResponses => <String, dynamic>{
          'model': model,
          'input': prompt,
          'tools': const [
            {'type': 'image_generation'}
          ],
        },
      _ => <String, dynamic>{
          'model': model,
          'prompt': prompt,
          'n': n,
          if (imageSize != null && imageSize.trim().isNotEmpty)
            'size': imageSize,
          if (aspectRatio != null && aspectRatio.trim().isNotEmpty)
            'aspect_ratio': aspectRatio,
        },
    };
    final headers = route.buildHeaders(
      apiKey: apiKey,
      extra: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    final response = await _performRequest(
      provider: provider,
      capability: ProviderCapability.images,
      route: route,
      uri: uri,
      model: model,
      data: body,
      options: Options(
        method: route.method,
        headers: headers,
      ),
    );
    return _parseImageResponse(route.preset, response.data);
  }

  Future<SpeechGenerationResult> synthesizeSpeech({
    required ProviderConfig provider,
    required String model,
    required String input,
    String voice = 'alloy',
    String format = 'mp3',
  }) async {
    final route = _resolver.resolve(
      provider: provider,
      capability: ProviderCapability.speech,
      modelName: model,
    );
    final apiKey = route.effectiveApiKey(provider);
    final uri = route.buildUri(model: model, apiKey: apiKey);
    final body = {
      'model': model,
      'input': input,
      'voice': voice,
      'response_format': format,
    };
    final headers = route.buildHeaders(
      apiKey: apiKey,
      extra: const {
        'Accept': '*/*',
        'Content-Type': 'application/json',
      },
    );
    final response = await _performRequest<List<int>>(
      provider: provider,
      capability: ProviderCapability.speech,
      route: route,
      uri: uri,
      model: model,
      data: body,
      options: Options(
        method: route.method,
        responseType: ResponseType.bytes,
        headers: headers,
      ),
    );
    final bytes = response.data == null
        ? Uint8List(0)
        : Uint8List.fromList(response.data!);
    return SpeechGenerationResult(
      bytes: bytes,
      contentType:
          response.headers.value(Headers.contentTypeHeader) ?? 'audio/mpeg',
    );
  }

  Future<AudioTextResult> transcribeAudio({
    required ProviderConfig provider,
    required String model,
    required String filePath,
    String? prompt,
  }) {
    return _sendAudioTextRequest(
      provider: provider,
      capability: ProviderCapability.transcriptions,
      model: model,
      filePath: filePath,
      prompt: prompt,
    );
  }

  Future<AudioTextResult> translateAudio({
    required ProviderConfig provider,
    required String model,
    required String filePath,
    String? prompt,
  }) {
    return _sendAudioTextRequest(
      provider: provider,
      capability: ProviderCapability.translations,
      model: model,
      filePath: filePath,
      prompt: prompt,
    );
  }

  Future<AudioTextResult> _sendAudioTextRequest({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required String model,
    required String filePath,
    String? prompt,
  }) async {
    final resolvedRoute = _resolver.resolve(
      provider: provider,
      capability: capability,
      modelName: model,
    );
    final route = _normalizeLegacyAudioTextRoute(resolvedRoute);
    return switch (route.preset) {
      ProtocolPreset.geminiNativeGenerateContent =>
        _sendGeminiNativeAudioChatRequest(
          provider: provider,
          capability: capability,
          route: route,
          model: model,
          filePath: filePath,
          prompt: prompt,
        ),
      ProtocolPreset.openaiChatCompletions ||
      ProtocolPreset.geminiOpenaiChatCompletions ||
      ProtocolPreset.customJson =>
        _sendOpenAiCompatibleAudioChatRequest(
          provider: provider,
          capability: capability,
          route: route,
          model: model,
          filePath: filePath,
          prompt: prompt,
        ),
      ProtocolPreset.customMultipart => _sendAudioMultipartRequest(
          provider: provider,
          capability: capability,
          route: route,
          model: model,
          filePath: filePath,
          prompt: prompt,
        ),
      _ => throw UnsupportedError(
          'Preset ${route.preset.wireName} is not supported for ${capability.wireName}.',
        ),
    };
  }

  Future<AudioTextResult> _sendAudioMultipartRequest({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute route,
    required String model,
    required String filePath,
    String? prompt,
  }) async {
    final apiKey = route.effectiveApiKey(provider);
    final uri = route.buildUri(model: model, apiKey: apiKey);
    final file = await MultipartFile.fromFile(
      filePath,
      filename: filePath.split(Platform.pathSeparator).last,
    );
    final data = FormData.fromMap({
      'model': model,
      'file': file,
      if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt,
    });
    final headers = route.buildHeaders(
      apiKey: apiKey,
      extra: const {'Accept': 'application/json'},
    );
    final response = await _performRequest(
      provider: provider,
      capability: capability,
      route: route,
      uri: uri,
      model: model,
      data: data,
      options: Options(
        method: route.method,
        headers: headers,
      ),
    );
    return _parseAudioTextResponse(response.data);
  }

  Future<AudioTextResult> _sendOpenAiCompatibleAudioChatRequest({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute route,
    required String model,
    required String filePath,
    String? prompt,
  }) async {
    final effectivePath =
        route.path?.trim().isNotEmpty == true ? route.path : 'chat/completions';
    final effectiveRoute = isOfficialGeminiNativeBaseUrl(route.baseUrl)
        ? route.copyWith(
            baseUrl: normalizeGeminiOpenAIBaseUrl(route.baseUrl),
            path: effectivePath,
          )
        : route.copyWith(path: effectivePath);
    final apiKey = effectiveRoute.effectiveApiKey(provider);
    final uri = effectiveRoute.buildUri(model: model, apiKey: apiKey);
    final bytes = await File(filePath).readAsBytes();
    final body = _buildOpenAiCompatibleAudioTextBody(
      capability: capability,
      model: model,
      filePath: filePath,
      bytes: bytes,
      prompt: prompt,
    );
    final headers = effectiveRoute.buildHeaders(
      apiKey: apiKey,
      extra: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    final response = await _performRequest(
      provider: provider,
      capability: capability,
      route: effectiveRoute,
      uri: uri,
      model: model,
      data: body,
      options: Options(
        method: effectiveRoute.method,
        headers: headers,
      ),
    );
    return _parseOpenAiCompatibleAudioChatResponse(response.data);
  }

  Future<AudioTextResult> _sendGeminiNativeAudioChatRequest({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute route,
    required String model,
    required String filePath,
    String? prompt,
  }) async {
    final effectiveRoute = route.copyWith(
      baseUrl: normalizeGeminiNativeBaseUrl(route.baseUrl),
      path: route.path?.trim().isNotEmpty == true
          ? route.path
          : '{model}:generateContent',
    );
    final apiKey = effectiveRoute.effectiveApiKey(provider);
    final uri = effectiveRoute.buildUri(model: model, apiKey: apiKey);
    final bytes = await File(filePath).readAsBytes();
    final body = _buildGeminiNativeAudioTextBody(
      capability: capability,
      model: model,
      filePath: filePath,
      bytes: bytes,
      prompt: prompt,
    );
    final headers = effectiveRoute.buildHeaders(
      apiKey: apiKey,
      extra: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    final response = await _performRequest(
      provider: provider,
      capability: capability,
      route: effectiveRoute,
      uri: uri,
      model: model,
      data: body,
      options: Options(
        method: effectiveRoute.method,
        headers: headers,
      ),
    );
    return _parseGeminiNativeAudioChatResponse(response.data);
  }

  ResolvedCapabilityRoute _normalizeLegacyAudioTextRoute(
    ResolvedCapabilityRoute route,
  ) {
    if (route.preset != ProtocolPreset.openaiAudioTranscriptions &&
        route.preset != ProtocolPreset.openaiAudioTranslations) {
      return route;
    }
    if (route.baseUrl.toLowerCase().contains('anthropic.com')) {
      return route;
    }
    if (looksLikeGeminiNativeBaseUrl(route.baseUrl)) {
      return route.copyWith(
        preset: ProtocolPreset.geminiNativeGenerateContent,
        baseUrl: normalizeGeminiNativeBaseUrl(route.baseUrl),
        path: '{model}:generateContent',
      );
    }
    if (isOfficialGeminiNativeBaseUrl(route.baseUrl)) {
      return route.copyWith(
        preset: ProtocolPreset.geminiOpenaiChatCompletions,
        baseUrl: normalizeGeminiOpenAIBaseUrl(route.baseUrl),
        path: 'chat/completions',
      );
    }
    return route.copyWith(
      preset: ProtocolPreset.openaiChatCompletions,
      path: 'chat/completions',
    );
  }

  Future<Response<T>> _performRequest<T>({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute route,
    required Uri uri,
    required Options options,
    Object? data,
    String? model,
  }) async {
    if (!route.enabled) {
      throw StateError(
          'Capability route ${route.capability.wireName} is disabled.');
    }
    final startedAt = DateTime.now();
    logCapabilityRequest(
      provider: provider,
      capability: capability,
      route: route,
      uri: uri,
      method: options.method ?? route.method,
      model: model,
      headers: options.headers,
      body: data,
    );
    try {
      final response = await _dio.requestUri<T>(
        uri,
        data: data,
        options: options,
      );
      logCapabilityResponse(
        provider: provider,
        capability: capability,
        route: route,
        uri: uri,
        method: options.method ?? route.method,
        model: model,
        response: response,
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
      return response;
    } on DioException catch (error, stackTrace) {
      logCapabilityError(
        provider: provider,
        capability: capability,
        route: route,
        uri: uri,
        method: options.method ?? route.method,
        model: model,
        error: error,
        durationMs: DateTime.now().difference(startedAt).inMilliseconds,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'CAPABILITY',
        'exception',
        category: capability.wireName.toUpperCase(),
        data: {
          ..._logContext(
            provider: provider,
            capability: capability,
            route: route,
            uri: uri,
            method: options.method ?? route.method,
            model: model,
          ),
          'duration_ms': DateTime.now().difference(startedAt).inMilliseconds,
          'error': error.toString(),
          'stack_trace': stackTrace.toString(),
        },
      );
      rethrow;
    }
  }

  List<String> _parseModelList(ProtocolPreset preset, dynamic payload) {
    final normalized = _normalizePayload(payload);
    if (normalized is! Map) {
      throw const FormatException('Model list payload is not a JSON object.');
    }
    final result = <String>{};
    switch (preset) {
      case ProtocolPreset.anthropicModels:
        final data = normalized['data'];
        if (data is List) {
          for (final item in data.whereType<Map>()) {
            final id = item['id']?.toString().trim();
            if (id != null && id.isNotEmpty) {
              result.add(id);
            }
          }
        }
        break;
      case ProtocolPreset.geminiModels:
        final data = normalized['models'];
        if (data is List) {
          for (final item in data.whereType<Map>()) {
            final name = item['name']?.toString().trim();
            if (name == null || name.isEmpty) continue;
            result.add(
              name.startsWith('models/')
                  ? name.substring('models/'.length)
                  : name,
            );
          }
        }
        break;
      default:
        final data = normalized['data'];
        if (data is List) {
          for (final item in data.whereType<Map>()) {
            final id = item['id']?.toString().trim();
            if (id != null && id.isNotEmpty) {
              result.add(id);
            }
          }
        }
        break;
    }
    final models = result.toList()..sort();
    return models;
  }

  Object _buildEmbeddingBody(
    ProtocolPreset preset, {
    required String model,
    required List<String> inputs,
  }) {
    return switch (preset) {
      ProtocolPreset.geminiEmbedContent => {
          'model': model.startsWith('models/') ? model : 'models/$model',
          'content': {
            'parts':
                inputs.map((item) => {'text': item}).toList(growable: false),
          },
          'taskType': 'SEMANTIC_SIMILARITY',
        },
      _ => {
          'model': model,
          'input': inputs,
        },
    };
  }

  List<List<double>> _parseEmbeddingResponse(
    ProtocolPreset preset,
    dynamic payload,
  ) {
    final normalized = _normalizePayload(payload);
    if (normalized is! Map) {
      throw const FormatException('Embedding payload is not a JSON object.');
    }
    if (preset == ProtocolPreset.geminiEmbedContent) {
      final embeddings = normalized['embeddings'];
      if (embeddings is List) {
        return embeddings
            .whereType<Map>()
            .map((entry) => _readGeminiEmbedding(entry))
            .toList(growable: false);
      }
      final single = normalized['embedding'];
      if (single is Map) {
        return [_readGeminiEmbedding(single)];
      }
    }
    final data = normalized['data'];
    if (data is! List) {
      throw const FormatException(
          'OpenAI embedding payload does not contain data[].');
    }
    return data
        .whereType<Map>()
        .map((entry) => (entry['embedding'] as List? ?? const [])
            .map((value) => (value as num).toDouble())
            .toList())
        .toList(growable: false);
  }

  List<double> _readGeminiEmbedding(Map entry) {
    final values = entry['values'] ?? entry['embedding'] ?? entry['vector'];
    if (values is! List) return const [];
    return values.map((value) => (value as num).toDouble()).toList();
  }

  ImageGenerationResult _parseImageResponse(
    ProtocolPreset preset,
    dynamic payload,
  ) {
    final normalized = _normalizePayload(payload);
    final images = <String>[];
    String? revisedPrompt;
    if (preset == ProtocolPreset.openaiResponses) {
      final output = normalized is Map ? normalized['output'] : null;
      if (output is List) {
        for (final item in output.whereType<Map>()) {
          final result = item['result'];
          if (result is String && result.isNotEmpty) {
            images.add('data:image/png;base64,$result');
          }
          final url = item['url']?.toString();
          if (url != null && url.isNotEmpty) {
            images.add(url);
          }
        }
      }
      return ImageGenerationResult(images: images);
    }
    if (normalized is! Map) {
      throw const FormatException(
          'Image generation payload is not a JSON object.');
    }
    final data = normalized['data'];
    if (data is List) {
      for (final item in data.whereType<Map>()) {
        final url = item['url']?.toString();
        final b64 = item['b64_json']?.toString();
        if (url != null && url.isNotEmpty) {
          images.add(url);
        } else if (b64 != null && b64.isNotEmpty) {
          images.add('data:image/png;base64,$b64');
        }
        revisedPrompt ??= item['revised_prompt']?.toString();
      }
    }
    return ImageGenerationResult(images: images, revisedPrompt: revisedPrompt);
  }

  AudioTextResult _parseAudioTextResponse(dynamic payload) {
    final normalized = _normalizePayload(payload);
    if (normalized is String) {
      return AudioTextResult(text: normalized);
    }
    if (normalized is Map) {
      return AudioTextResult(
        text: normalized['text']?.toString() ??
            normalized['output_text']?.toString() ??
            '',
        language: normalized['language']?.toString(),
      );
    }
    throw const FormatException('Audio text payload has unsupported format.');
  }

  AudioTextResult _parseOpenAiCompatibleAudioChatResponse(dynamic payload) {
    final normalized = _normalizePayload(payload);
    if (normalized is! Map) {
      throw const FormatException('Audio chat payload is not a JSON object.');
    }
    final choices = normalized['choices'];
    if (choices is List) {
      for (final choice in choices.whereType<Map>()) {
        final message = choice['message'];
        if (message is Map) {
          final text = _extractChatMessageText(message['content']);
          if (text.isNotEmpty) {
            return AudioTextResult(text: text);
          }
        }
      }
    }
    throw const FormatException(
      'Audio chat payload does not contain assistant text.',
    );
  }

  AudioTextResult _parseGeminiNativeAudioChatResponse(dynamic payload) {
    final normalized = _normalizePayload(payload);
    if (normalized is! Map) {
      throw const FormatException(
        'Gemini native audio payload is not a JSON object.',
      );
    }
    final candidates = normalized['candidates'];
    if (candidates is List) {
      for (final candidate in candidates.whereType<Map>()) {
        final content = candidate['content'];
        if (content is! Map) continue;
        final parts = content['parts'];
        if (parts is! List) continue;
        final texts = <String>[];
        for (final part in parts.whereType<Map>()) {
          final text = part['text']?.toString().trim();
          if (text != null && text.isNotEmpty) {
            texts.add(text);
          }
        }
        if (texts.isNotEmpty) {
          return AudioTextResult(text: texts.join('\n').trim());
        }
      }
    }
    throw const FormatException(
      'Gemini native audio payload does not contain assistant text.',
    );
  }

  String _extractChatMessageText(dynamic content) {
    if (content is String) {
      return content.trim();
    }
    if (content is List) {
      final parts = <String>[];
      for (final item in content) {
        if (item is String) {
          final text = item.trim();
          if (text.isNotEmpty) {
            parts.add(text);
          }
          continue;
        }
        if (item is! Map) continue;
        final text = item['text']?.toString().trim() ??
            item['content']?.toString().trim() ??
            item['output_text']?.toString().trim();
        if (text != null && text.isNotEmpty) {
          parts.add(text);
        }
      }
      return parts.join('\n').trim();
    }
    return '';
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

  void logCapabilityRequest({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute route,
    required Uri uri,
    required String method,
    Map<String, dynamic>? headers,
    Object? body,
    String? model,
  }) {
    AppLogger.info(
      'CAPABILITY',
      'request',
      category: capability.wireName.toUpperCase(),
      data: {
        ..._logContext(
          provider: provider,
          capability: capability,
          route: route,
          uri: uri,
          method: method,
          model: model,
        ),
        if (headers != null && headers.isNotEmpty) 'headers': headers,
        if (body != null) 'body': _describeLogPayload(body),
      },
    );
  }

  void logCapabilityResponse({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute route,
    required Uri uri,
    required String method,
    required Response response,
    required int durationMs,
    String? model,
  }) {
    AppLogger.info(
      'CAPABILITY',
      'response',
      category: capability.wireName.toUpperCase(),
      data: {
        ..._logContext(
          provider: provider,
          capability: capability,
          route: route,
          uri: uri,
          method: method,
          model: model,
        ),
        'duration_ms': durationMs,
        'status_code': response.statusCode,
        if ((response.statusMessage ?? '').trim().isNotEmpty)
          'status_message': response.statusMessage,
        'headers': response.headers.map,
        'body': _describeLogPayload(response.data),
      },
    );
  }

  void logCapabilityError({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute route,
    required Uri uri,
    required String method,
    required DioException error,
    required int durationMs,
    required StackTrace stackTrace,
    String? model,
  }) {
    AppLogger.error(
      'CAPABILITY',
      'request_failed',
      category: capability.wireName.toUpperCase(),
      data: {
        ..._logContext(
          provider: provider,
          capability: capability,
          route: route,
          uri: uri,
          method: method,
          model: model,
        ),
        'duration_ms': durationMs,
        'error': {
          'type': error.type.name,
          if ((error.message ?? '').trim().isNotEmpty) 'message': error.message,
          'status_code': error.response?.statusCode,
          if ((error.response?.statusMessage ?? '').trim().isNotEmpty)
            'status_message': error.response?.statusMessage,
          if (error.response != null) 'headers': error.response!.headers.map,
          if (error.response != null)
            'body': _describeLogPayload(error.response!.data),
        },
        'stack_trace': stackTrace.toString(),
      },
    );
  }

  Map<String, dynamic> _logContext({
    required ProviderConfig provider,
    required ProviderCapability capability,
    required ResolvedCapabilityRoute route,
    required Uri uri,
    required String method,
    String? model,
  }) {
    return {
      'capability': capability.wireName,
      'provider_id': provider.id,
      'provider_name': provider.name,
      if (model != null && model.trim().isNotEmpty) 'model': model,
      'route': {
        'preset': route.preset.wireName,
        'enabled': route.enabled,
        'method': method,
        'base_url': route.baseUrl,
        'path': route.path,
        'auth_mode': route.authMode.wireName,
        if (route.authHeaderName != null)
          'auth_header_name': route.authHeaderName,
        if (route.authQueryKey != null) 'auth_query_key': route.authQueryKey,
        if (route.fallbackPreset != null)
          'fallback_preset': route.fallbackPreset!.wireName,
      },
      'url': uri.toString(),
    };
  }

  Object? _describeLogPayload(Object? payload) {
    if (payload == null) return null;
    if (payload is FormData) {
      return {
        'type': 'multipart/form-data',
        'fields': {
          for (final field in payload.fields)
            field.key: _describeLogPayload(field.value),
        },
        'files': payload.files
            .map(
              (entry) => {
                'field': entry.key,
                ..._describeMultipartFile(entry.value),
              },
            )
            .toList(growable: false),
      };
    }
    if (payload is MultipartFile) {
      return _describeMultipartFile(payload);
    }
    if (payload is Uint8List) {
      return {
        'type': 'bytes',
        'length': payload.lengthInBytes,
      };
    }
    if (payload is List<int>) {
      return {
        'type': 'bytes',
        'length': payload.length,
      };
    }
    if (payload is Map) {
      return payload.map(
        (key, value) => MapEntry(key.toString(), _describeLogPayload(value)),
      );
    }
    if (payload is Iterable) {
      return payload.map(_describeLogPayload).toList(growable: false);
    }
    if (payload is String) {
      final normalized = _normalizePayload(payload);
      if (normalized is! String) {
        return _describeLogPayload(normalized);
      }
      return _truncateLoggedString(normalized);
    }
    return payload;
  }

  Map<String, dynamic> _describeMultipartFile(MultipartFile file) {
    return {
      if ((file.filename ?? '').trim().isNotEmpty) 'filename': file.filename,
      'length': file.length,
      if (file.contentType != null) 'content_type': file.contentType.toString(),
    };
  }

  String _truncateLoggedString(String value, {int maxLength = 800}) {
    if (value.startsWith('data:') && value.length > 200) {
      return '${value.substring(0, 64)}...[TRUNCATED ${value.length} chars]';
    }
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, 200)}...[TRUNCATED ${value.length} chars]';
  }

  Map<String, dynamic> _buildOpenAiCompatibleAudioTextBody({
    required ProviderCapability capability,
    required String model,
    required String filePath,
    required Uint8List bytes,
    String? prompt,
  }) {
    return {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': _audioPromptForCapability(capability, prompt: prompt),
            },
            {
              'type': 'input_audio',
              'input_audio': {
                'data': base64Encode(bytes),
                'format': _audioFormatForPath(filePath),
              },
            },
          ],
        },
      ],
    };
  }

  Map<String, dynamic> _buildGeminiNativeAudioTextBody({
    required ProviderCapability capability,
    required String model,
    required String filePath,
    required Uint8List bytes,
    String? prompt,
  }) {
    return {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': _audioPromptForCapability(capability, prompt: prompt),
            },
            {
              'inlineData': {
                'mimeType': _mimeTypeForPath(filePath),
                'data': base64Encode(bytes),
              },
            },
          ],
        },
      ],
    };
  }

  String _audioPromptForCapability(
    ProviderCapability capability, {
    String? prompt,
  }) {
    final normalizedPrompt = prompt?.trim();
    if (normalizedPrompt != null && normalizedPrompt.isNotEmpty) {
      return normalizedPrompt;
    }
    return capability == ProviderCapability.transcriptions
        ? 'Transcribe this audio. Return only the transcript text.'
        : 'Translate this audio into English. Return only the translated text.';
  }

  String _audioFormatForPath(String filePath) {
    final normalized = filePath.toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) {
      return 'wav';
    }
    return normalized.substring(dotIndex + 1);
  }

  String _mimeTypeForPath(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.mp3')) return 'audio/mpeg';
    if (normalized.endsWith('.wav')) return 'audio/wav';
    if (normalized.endsWith('.m4a')) return 'audio/x-m4a';
    if (normalized.endsWith('.aac')) return 'audio/aac';
    if (normalized.endsWith('.ogg')) return 'audio/ogg';
    if (normalized.endsWith('.flac')) return 'audio/flac';
    return 'application/octet-stream';
  }
}
