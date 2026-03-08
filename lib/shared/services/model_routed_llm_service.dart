import 'package:dio/dio.dart';

import '../../features/chat/domain/message.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'gemini_native_llm_service.dart';
import 'gemini_native_endpoint.dart';
import 'llm_service.dart';
import 'llm_transport_mode.dart';
import 'openai_llm_service.dart';
import 'tool_schema_sanitizer.dart';

class _ResolvedDelegate {
  final LLMService service;
  final LlmTransportMode mode;

  const _ResolvedDelegate(this.service, this.mode);
}

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

  _ResolvedDelegate _resolveDelegateResolution({
    String? model,
    String? providerId,
  }) {
    final provider = _resolveProvider(providerId);
    final modelName = _resolveModel(provider: provider, requestedModel: model);
    if (modelName == null) {
      // No model selected: fall back to OpenAI-compatible request shape.
      return _ResolvedDelegate(
          _openAiCompatService, LlmTransportMode.openaiCompat);
    }

    final transportMode = resolveModelTransportMode(
      provider: provider,
      modelName: modelName,
    );
    if (transportMode == LlmTransportMode.openaiCompat) {
      return _ResolvedDelegate(
          _openAiCompatService, LlmTransportMode.openaiCompat);
    }
    if (transportMode == LlmTransportMode.geminiNative) {
      return _ResolvedDelegate(
          _geminiNativeService, LlmTransportMode.geminiNative);
    }
    if (_shouldUseGeminiNativeInAuto(
        provider: provider, modelName: modelName)) {
      return _ResolvedDelegate(
          _geminiNativeService, LlmTransportMode.geminiNative);
    }
    return _ResolvedDelegate(
        _openAiCompatService, LlmTransportMode.openaiCompat);
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
    final overrideBaseUrl =
        modelSettings?[auroraTransportBaseUrlKey]?.toString().trim();
    if (overrideBaseUrl != null && overrideBaseUrl.isNotEmpty) {
      return looksLikeGeminiNativeBaseUrl(overrideBaseUrl);
    }
    return looksLikeGeminiNativeBaseUrl(baseUrl);
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
    final resolution = _resolveDelegateResolution(
      model: model,
      providerId: providerId,
    );
    final sanitizedTools = ToolSchemaSanitizer.sanitizeToolsForTransportMode(
      tools,
      resolution.mode,
    );
    return resolution.service.streamResponse(
      messages,
      tools: sanitizedTools,
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
    final resolution = _resolveDelegateResolution(
      model: model,
      providerId: providerId,
    );
    final sanitizedTools = ToolSchemaSanitizer.sanitizeToolsForTransportMode(
      tools,
      resolution.mode,
    );
    return resolution.service.getResponse(
      messages,
      tools: sanitizedTools,
      toolChoice: toolChoice,
      model: model,
      providerId: providerId,
      cancelToken: cancelToken,
    );
  }
}
