import 'package:dio/dio.dart';

import '../../features/chat/domain/message.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'gemini_native_llm_service.dart';
import 'llm_service.dart';
import 'llm_transport_mode.dart';
import 'openai_llm_service.dart';

class ModelRoutedLlmService implements LLMService {
  final SettingsState _settings;
  late final OpenAILLMService _openAiCompatService =
      OpenAILLMService(_settings);
  late final GeminiNativeLlmService _geminiNativeService =
      GeminiNativeLlmService(_settings);

  ModelRoutedLlmService(this._settings);

  ProviderConfig _resolveProvider(String? providerId) {
    if (providerId == null) {
      return _settings.activeProvider;
    }
    return _settings.providers.firstWhere(
      (provider) => provider.id == providerId,
      orElse: () => _settings.activeProvider,
    );
  }

  String? _resolveModel({
    required ProviderConfig provider,
    required String? requestedModel,
  }) {
    final candidate = requestedModel ?? provider.selectedModel;
    if (candidate == null) return null;
    final normalized = candidate.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  LLMService _resolveDelegate({
    String? model,
    String? providerId,
  }) {
    final provider = _resolveProvider(providerId);
    final modelName = _resolveModel(provider: provider, requestedModel: model);
    if (modelName == null) {
      return _openAiCompatService;
    }

    final transportMode = resolveModelTransportMode(
      provider: provider,
      modelName: modelName,
    );
    if (transportMode == LlmTransportMode.openaiCompat) {
      return _openAiCompatService;
    }
    if (transportMode == LlmTransportMode.geminiNative) {
      return _geminiNativeService;
    }
    if (_shouldUseGeminiNativeInAuto(
        provider: provider, modelName: modelName)) {
      return _geminiNativeService;
    }
    return _openAiCompatService;
  }

  bool _shouldUseGeminiNativeInAuto({
    required ProviderConfig provider,
    required String modelName,
  }) {
    final modelSettings = provider.modelSettings[modelName];
    final nativeTools = resolveGeminiNativeToolsFromSettings(modelSettings);
    if (nativeTools.hasAnyEnabled) {
      return true;
    }

    final normalizedModel = modelName.trim().toLowerCase();
    final looksLikeGemini = normalizedModel.startsWith('gemini') ||
        normalizedModel.contains('/gemini') ||
        normalizedModel.contains('gemini-');
    if (!looksLikeGemini) return false;

    final baseUrl = provider.baseUrl.trim();
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.host.isEmpty) return false;
    return uri.host.toLowerCase().contains('generativelanguage.googleapis.com');
  }

  @override
  Stream<LLMResponseChunk> streamResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    String? model,
    String? providerId,
    CancelToken? cancelToken,
  }) {
    final delegate = _resolveDelegate(
      model: model,
      providerId: providerId,
    );
    return delegate.streamResponse(
      messages,
      tools: tools,
      toolChoice: toolChoice,
      model: model,
      providerId: providerId,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<LLMResponseChunk> getResponse(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    String? model,
    String? providerId,
    CancelToken? cancelToken,
  }) {
    final delegate = _resolveDelegate(
      model: model,
      providerId: providerId,
    );
    return delegate.getResponse(
      messages,
      tools: tools,
      toolChoice: toolChoice,
      model: model,
      providerId: providerId,
      cancelToken: cancelToken,
    );
  }
}
