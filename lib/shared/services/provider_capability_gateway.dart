import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../features/settings/domain/provider_route_config.dart';
import '../../features/settings/presentation/settings_provider.dart';
import '../utils/app_logger.dart';
import 'capability_route_resolver.dart';

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
    final response = await _dio.requestUri(
      uri,
      options: Options(
        method: resolvedRoute.method,
        headers: resolvedRoute.buildHeaders(
          apiKey: apiKey,
          extra: const {'Accept': 'application/json'},
        ),
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
    final response = await _dio.requestUri(
      uri,
      data: _buildEmbeddingBody(route.preset, model: model, inputs: inputs),
      options: Options(
        method: route.method,
        headers: route.buildHeaders(
          apiKey: apiKey,
          extra: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
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
    final response = await _dio.requestUri(
      uri,
      data: body,
      options: Options(
        method: route.method,
        headers: route.buildHeaders(
          apiKey: apiKey,
          extra: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
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
    final response = await _dio.requestUri<List<int>>(
      uri,
      data: {
        'model': model,
        'input': input,
        'voice': voice,
        'format': format,
      },
      options: Options(
        method: route.method,
        responseType: ResponseType.bytes,
        headers: route.buildHeaders(
          apiKey: apiKey,
          extra: const {
            'Accept': '*/*',
            'Content-Type': 'application/json',
          },
        ),
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
    final route = _resolver.resolve(
      provider: provider,
      capability: capability,
      modelName: model,
    );
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
    final response = await _dio.requestUri(
      uri,
      data: data,
      options: Options(
        method: route.method,
        headers: route.buildHeaders(
          apiKey: apiKey,
          extra: const {'Accept': 'application/json'},
        ),
      ),
    );
    return _parseAudioTextResponse(response.data);
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
    required ProviderCapability capability,
    required Uri uri,
    required Object body,
  }) {
    AppLogger.info(
      'CAPABILITY',
      'request',
      category: capability.wireName.toUpperCase(),
      data: {
        'capability': capability.wireName,
        'url': uri.toString(),
        'body': body,
      },
    );
  }
}
