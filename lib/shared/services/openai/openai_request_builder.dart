part of '../openai_llm_service.dart';

class _PreparedChatRequest {
  final String baseUrl;
  final String apiKey;
  final Map<String, dynamic> requestData;
  final Uri endpointUri;
  final ResolvedCapabilityRoute route;

  _PreparedChatRequest({
    required this.baseUrl,
    required this.apiKey,
    required this.requestData,
    required this.endpointUri,
    required this.route,
  });
}

extension _OpenAIRequestBuilder on OpenAILLMService {
  static const String _webSearchGuide = '''
## Web Search Capability
You have access to web search. When you need to search for current information, output a search tag in this exact format:
<search>your search query here</search>

### When to Use
Use search for:
1. **Latest Information**: Current events, news, weather, sports scores
2. **Fact Checking**: Verification of claims or data
3. **Specific Knowledge**: Technical documentation or niche topics not in your training data

### Important Rules
- Output ONLY ONE <search> tag per response when you need to search
- After outputting the search tag, STOP your response and wait for results
- Do NOT make up search results - wait for real data
- When you receive search results, cite sources using `[index](link)` format immediately after the relevant fact
''';

  String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  void _upsertSystemInstruction({
    required List<Map<String, dynamic>> apiMessages,
    required String marker,
    required String instruction,
    required bool prepend,
  }) {
    final systemMsgIndex = apiMessages.indexWhere((m) => m['role'] == 'system');
    if (systemMsgIndex == -1) {
      apiMessages.insert(0, {'role': 'system', 'content': instruction});
      return;
    }
    final oldContent = apiMessages[systemMsgIndex]['content']?.toString() ?? '';
    if (oldContent.contains(marker)) {
      return;
    }
    if (oldContent.isEmpty) {
      apiMessages[systemMsgIndex]['content'] = instruction;
      return;
    }
    apiMessages[systemMsgIndex]['content'] =
        prepend ? '$instruction\n\n$oldContent' : '$oldContent\n\n$instruction';
  }

  void _injectSystemInstructions(List<Map<String, dynamic>> apiMessages) {
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T')[0];
    final timeInstruction = 'Current Date: $dateStr.';
    _upsertSystemInstruction(
      apiMessages: apiMessages,
      marker: 'Current Date:',
      instruction: timeInstruction,
      prepend: true,
    );
    if (_settings.isSearchEnabled) {
      _upsertSystemInstruction(
        apiMessages: apiMessages,
        marker: 'Web Search Capability',
        instruction: _webSearchGuide,
        prepend: false,
      );
    }
  }

  void _applyGenerationConfig({
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> activeParams,
    required List<Map<String, dynamic>> apiMessages,
  }) {
    final generationConfig = activeParams['_aurora_generation_config'];
    if (generationConfig == null || generationConfig is! Map) {
      return;
    }

    final temp = generationConfig['temperature'];
    if (temp != null && temp.toString().isNotEmpty) {
      final tempVal = double.tryParse(temp.toString());
      if (tempVal != null) {
        requestData['temperature'] = tempVal;
      }
    }
    final maxTok = generationConfig['max_tokens'];
    if (maxTok != null && maxTok.toString().isNotEmpty) {
      final maxTokVal = int.tryParse(maxTok.toString());
      if (maxTokVal != null) {
        requestData['max_tokens'] = maxTokVal;
      }
    }
    final ctxLen = generationConfig['context_length'];
    if (ctxLen != null && ctxLen.toString().isNotEmpty) {
      final limit = int.tryParse(ctxLen.toString());
      if (limit != null && limit > 0) {
        requestData['messages'] = _limitContextLength(apiMessages, limit);
      }
    }
  }

  Future<_PreparedChatRequest> _buildPreparedChatRequest({
    required List<Message> messages,
    required ProviderConfig provider,
    required String selectedModel,
    required bool stream,
    List<Map<String, dynamic>>? tools,
    String? toolChoice,
  }) async {
    final route = const CapabilityRouteResolver().resolve(
      provider: provider,
      capability: ProviderCapability.chat,
      modelName: selectedModel,
    );
    final baseUrl = _normalizeBaseUrl(route.baseUrl);
    final activeParams = LlmServiceConfig.buildActiveParams(
      provider: provider,
      selectedModel: selectedModel,
    );
    var apiMessages = await _buildApiMessages(messages);
    apiMessages = _sanitizeOutgoingImageMessages(
      apiMessages,
      selectedModel: selectedModel,
      baseUrl: baseUrl,
    );
    if (resolveGeminiProxyAssistantImageRewrite(activeParams)) {
      apiMessages = _applyGeminiImageEditFallback(
        apiMessages,
        selectedModel: selectedModel,
        baseUrl: baseUrl,
      );
    }
    apiMessages = await _compressApiMessagesIfNeeded(apiMessages);
    _injectSystemInstructions(apiMessages);

    final requestData = <String, dynamic>{
      'model': selectedModel,
      'messages': apiMessages,
      'stream': stream,
      if (stream) 'stream_options': {'include_usage': true},
    };

    if (tools != null && tools.isNotEmpty) {
      requestData['tools'] = tools;
      if (toolChoice != null) {
        final raw = toolChoice.trim();
        if (raw.isNotEmpty) {
          if (raw.startsWith('{') || raw.startsWith('[')) {
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map || decoded is List) {
                requestData['tool_choice'] = decoded;
              } else {
                requestData['tool_choice'] = toolChoice;
              }
            } catch (_) {
              requestData['tool_choice'] = toolChoice;
            }
          } else if (raw.startsWith('function:')) {
            final name = raw.substring('function:'.length).trim();
            requestData['tool_choice'] = name.isEmpty
                ? toolChoice
                : {
                    'type': 'function',
                    'function': {'name': name},
                  };
          } else {
            requestData['tool_choice'] = toolChoice;
          }
        }
      }
    }

    requestData.addAll(
      LlmServiceConfig.buildRequestParameters(
        provider: provider,
        activeParams: activeParams,
      ),
    );
    _applyGenerationConfig(
      requestData: requestData,
      activeParams: activeParams,
      apiMessages: apiMessages,
    );

    _applyThinkingConfigToRequest(
      requestData: requestData,
      activeParams: activeParams,
      selectedModel: selectedModel,
      baseUrl: baseUrl,
    );
    _ensureReasoningEffortCompatibleMaxTokens(
      requestData: requestData,
      selectedModel: selectedModel,
    );
    _applyImageConfigToRequest(
      requestData: requestData,
      activeParams: activeParams,
      selectedModel: selectedModel,
      routePreset: route.preset,
    );
    final apiKey = route.effectiveApiKey(provider);
    final endpointUri = route.buildUri(
      model: selectedModel,
      stream: stream,
      apiKey: apiKey,
    );

    return _PreparedChatRequest(
      baseUrl: baseUrl,
      apiKey: apiKey,
      requestData: requestData,
      endpointUri: endpointUri,
      route: route,
    );
  }
}
