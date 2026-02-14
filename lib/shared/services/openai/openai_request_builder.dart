part of '../openai_llm_service.dart';

class _PreparedChatRequest {
  final String baseUrl;
  final String apiKey;
  final Map<String, dynamic> requestData;

  _PreparedChatRequest({
    required this.baseUrl,
    required this.apiKey,
    required this.requestData,
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
    if (candidate == null) {
      return null;
    }
    final normalized = candidate.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
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

  Map<String, dynamic> _buildActiveParams(
      ProviderConfig provider, String selectedModel) {
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

  void _applyProviderAndModelParams({
    required Map<String, dynamic> requestData,
    required Map<String, dynamic> activeParams,
    required ProviderConfig provider,
  }) {
    final filteredParams = Map<String, dynamic>.fromEntries(
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
    requestData.addAll(providerParams);
    requestData.addAll(filteredParams);
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
    final baseUrl = _normalizeBaseUrl(provider.baseUrl);
    var apiMessages = await _buildApiMessages(messages);
    apiMessages = _sanitizeOutgoingImageMessages(
      apiMessages,
      selectedModel: selectedModel,
      baseUrl: baseUrl,
    );
    apiMessages = _applyGeminiImageEditFallback(
      apiMessages,
      selectedModel: selectedModel,
      baseUrl: baseUrl,
    );
    apiMessages = await _compressApiMessagesIfNeeded(apiMessages);
    _injectSystemInstructions(apiMessages);

    final activeParams = _buildActiveParams(provider, selectedModel);
    final requestData = <String, dynamic>{
      'model': selectedModel,
      'messages': apiMessages,
      'stream': stream,
      if (stream) 'stream_options': {'include_usage': true},
    };

    if (tools != null && tools.isNotEmpty) {
      requestData['tools'] = tools;
      if (toolChoice != null) {
        requestData['tool_choice'] = toolChoice;
      }
    }

    _applyProviderAndModelParams(
      requestData: requestData,
      activeParams: activeParams,
      provider: provider,
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
    );

    return _PreparedChatRequest(
      baseUrl: baseUrl,
      apiKey: provider.apiKey,
      requestData: requestData,
    );
  }
}
