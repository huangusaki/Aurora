import 'package:dio/dio.dart';

import '../../features/chat/domain/message.dart';
import '../../features/settings/domain/provider_route_config.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'capability_route_resolver.dart';
import 'chat_capability_handlers.dart';
import 'gemini_native_llm_service.dart';
import 'llm_service.dart';
import 'llm_transport_mode.dart';
import 'openai_llm_service.dart';
import 'tool_schema_sanitizer.dart';

class _ResolvedDelegate {
  final LlmTransportMode mode;
  final Future<LLMResponseChunk> Function(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    String? model,
    String? providerId,
    CancelToken? cancelToken,
  }) getResponse;
  final Stream<LLMResponseChunk> Function(
    List<Message> messages, {
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
    String? model,
    String? providerId,
    CancelToken? cancelToken,
  }) streamResponse;

  const _ResolvedDelegate({
    required this.mode,
    required this.getResponse,
    required this.streamResponse,
  });
}

class ModelRoutedLlmService implements LLMService {
  final SettingsState _settings;
  final CapabilityRouteResolver _resolver = const CapabilityRouteResolver();
  late final OpenAILLMService _openAiCompatService =
      OpenAILLMService(_settings);
  late final GeminiNativeLlmService _geminiNativeService =
      GeminiNativeLlmService(_settings);
  late final OpenAiResponsesChatHandler _responsesHandler =
      OpenAiResponsesChatHandler();
  late final AnthropicMessagesChatHandler _anthropicHandler =
      AnthropicMessagesChatHandler();

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
      return _delegateForOpenAiCompat();
    }

    final route = _resolver.resolve(
      provider: provider,
      capability: ProviderCapability.chat,
      modelName: modelName,
    );
    switch (route.preset) {
      case ProtocolPreset.openaiResponses:
        return _ResolvedDelegate(
          mode: LlmTransportMode.openaiCompat,
          getResponse: (messages,
                  {tools, toolChoice, model, providerId, cancelToken}) =>
              _responsesHandler.getResponse(
            messages,
            tools: tools,
            toolChoice: toolChoice,
            model: modelName,
            provider: provider,
            route: route,
            cancelToken: cancelToken,
          ),
          streamResponse: (messages,
                  {tools, toolChoice, model, providerId, cancelToken}) =>
              _responsesHandler.streamResponse(
            messages,
            tools: tools,
            toolChoice: toolChoice,
            model: modelName,
            provider: provider,
            route: route,
            cancelToken: cancelToken,
          ),
        );
      case ProtocolPreset.anthropicMessages:
        return _ResolvedDelegate(
          mode: LlmTransportMode.openaiCompat,
          getResponse: (messages,
                  {tools, toolChoice, model, providerId, cancelToken}) =>
              _anthropicHandler.getResponse(
            messages,
            tools: tools,
            toolChoice: toolChoice,
            model: modelName,
            provider: provider,
            route: route,
            cancelToken: cancelToken,
          ),
          streamResponse: (messages,
                  {tools, toolChoice, model, providerId, cancelToken}) =>
              _anthropicHandler.streamResponse(
            messages,
            tools: tools,
            toolChoice: toolChoice,
            model: modelName,
            provider: provider,
            route: route,
            cancelToken: cancelToken,
          ),
        );
      case ProtocolPreset.geminiNativeGenerateContent:
        return _delegateForGeminiNative();
      case ProtocolPreset.openaiChatCompletions:
      case ProtocolPreset.geminiOpenaiChatCompletions:
      case ProtocolPreset.customJson:
      case ProtocolPreset.customMultipart:
      case ProtocolPreset.openaiModels:
      case ProtocolPreset.anthropicModels:
      case ProtocolPreset.geminiModels:
      case ProtocolPreset.openaiEmbeddings:
      case ProtocolPreset.geminiEmbedContent:
      case ProtocolPreset.openaiImages:
      case ProtocolPreset.openaiAudioSpeech:
      case ProtocolPreset.openaiAudioTranscriptions:
      case ProtocolPreset.openaiAudioTranslations:
        return _delegateForOpenAiCompat();
    }
  }

  _ResolvedDelegate _delegateForOpenAiCompat() {
    return _ResolvedDelegate(
      mode: LlmTransportMode.openaiCompat,
      getResponse: _openAiCompatService.getResponse,
      streamResponse: _openAiCompatService.streamResponse,
    );
  }

  _ResolvedDelegate _delegateForGeminiNative() {
    return _ResolvedDelegate(
      mode: LlmTransportMode.geminiNative,
      getResponse: _geminiNativeService.getResponse,
      streamResponse: _geminiNativeService.streamResponse,
    );
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
    return resolution.streamResponse(
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
    return resolution.getResponse(
      messages,
      tools: sanitizedTools,
      toolChoice: toolChoice,
      model: model,
      providerId: providerId,
      cancelToken: cancelToken,
    );
  }
}
