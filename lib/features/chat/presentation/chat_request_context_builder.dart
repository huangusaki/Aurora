part of 'chat_provider.dart';

class _ChatRequestContext {
  final SettingsState settings;
  final LLMService llmService;
  final ToolManager toolManager;
  final List<Message> messagesForApi;
  final List<Skill> activeSkills;
  final List<Map<String, dynamic>>? tools;
  final bool allowLegacySearchTool;
  final String? currentModel;
  final String currentProviderName;

  const _ChatRequestContext({
    required this.settings,
    required this.llmService,
    required this.toolManager,
    required this.messagesForApi,
    required this.activeSkills,
    required this.tools,
    required this.allowLegacySearchTool,
    required this.currentModel,
    required this.currentProviderName,
  });
}

class _ChatRequestContextBuilder {
  final ChatNotifier _notifier;

  const _ChatRequestContextBuilder({required ChatNotifier notifier})
      : _notifier = notifier;

  Future<_ChatRequestContext> build({
    required String? text,
    required String? apiContent,
    required Assistant? assistant,
  }) async {
    final settings = _notifier._ref.read(settingsProvider);
    final llmService = _notifier._ref.read(llmServiceProvider);
    final toolManager = ToolManager(
      searchRegion: settings.searchRegion,
      searchSafeSearch: settings.searchSafeSearch,
      searchMaxResults: settings.searchMaxResults,
      searchTimeout: Duration(seconds: settings.searchTimeoutSeconds),
    );

    final messagesForApi = List<Message>.from(_notifier.currentState.messages);
    if (apiContent != null) {
      final lastUserIndex = messagesForApi.lastIndexWhere((m) => m.isUser);
      if (lastUserIndex != -1) {
        messagesForApi[lastUserIndex] =
            messagesForApi[lastUserIndex].copyWith(content: apiContent);
      }
    }

    if (assistant != null && assistant.systemPrompt.isNotEmpty) {
      _upsertSystemPrompt(messagesForApi, assistant.systemPrompt);
    }

    if (assistant != null && assistant.enableMemory) {
      final memoryPrompt = await _notifier._ref
          .read(assistantMemoryServiceProvider)
          .buildMemorySystemPrompt(assistant.id);
      if (memoryPrompt.isNotEmpty) {
        _upsertSystemPrompt(messagesForApi, memoryPrompt);
      }
    }

    final activeSkills =
        _resolveActiveSkills(settings: settings, assistant: assistant);
    final nativeGoogleSearchEnabled = _isNativeGoogleSearchEnabled(settings);
    final allowLegacySearchTool =
        settings.isSearchEnabled && !nativeGoogleSearchEnabled;

    List<Map<String, dynamic>>? tools;
    if (allowLegacySearchTool || activeSkills.isNotEmpty) {
      tools = toolManager.getTools(skills: activeSkills);
    }

    if (activeSkills.isNotEmpty) {
      final skillDescriptions =
          activeSkills.map((s) => '- [${s.name}]: ${s.description}').join('\n');
      final routingPrompt = '''
# Specialized Skills
You have access to the following specialized agents. Delegate tasks to them when the user's request matches their capabilities.

## Registry
$skillDescriptions

To invoke a skill, output a skill tag in this exact format:
<skill name="skill_name">natural language task description</skill>
''';
      _upsertSystemPrompt(messagesForApi, routingPrompt);
    }

    await _injectKnowledgeContext(
      settings: settings,
      llmService: llmService,
      assistant: assistant,
      text: text,
      apiContent: apiContent,
      messagesForApi: messagesForApi,
    );

    return _ChatRequestContext(
      settings: settings,
      llmService: llmService,
      toolManager: toolManager,
      messagesForApi: messagesForApi,
      activeSkills: activeSkills,
      tools: tools,
      allowLegacySearchTool: allowLegacySearchTool,
      currentModel: settings.activeProvider.selectedModel,
      currentProviderName: settings.activeProvider.name,
    );
  }

  bool _isNativeGoogleSearchEnabled(SettingsState settings) {
    final provider = settings.activeProvider;
    final rawModelName = provider.selectedModel;
    final modelName = rawModelName?.trim();
    if (modelName == null || modelName.isEmpty) return false;
    final transportMode = resolveModelTransportMode(
      provider: provider,
      modelName: modelName,
    );
    if (transportMode != LlmTransportMode.geminiNative) return false;
    final modelSettings = provider.modelSettings[modelName] ??
        provider.modelSettings[rawModelName];
    final nativeTools = resolveGeminiNativeToolsFromSettings(modelSettings);
    return nativeTools.googleSearch;
  }

  List<Skill> _resolveActiveSkills({
    required SettingsState settings,
    required Assistant? assistant,
  }) {
    final currentPlatform = Platform.operatingSystem;
    final isMobile = PlatformUtils.isMobile;

    var activeSkills = isMobile
        ? <Skill>[]
        : _notifier._ref
            .read(skillProvider)
            .skills
            .where((s) =>
                s.isEnabled && s.forAI && s.isCompatible(currentPlatform))
            .toList();

    if (assistant != null) {
      if (assistant.skillIds.isEmpty) {
        activeSkills = [];
      } else {
        activeSkills = activeSkills
            .where((s) => assistant.skillIds.contains(s.id))
            .toList();
      }
    }

    return activeSkills;
  }

  Future<void> _injectKnowledgeContext({
    required SettingsState settings,
    required LLMService llmService,
    required Assistant? assistant,
    required String? text,
    required String? apiContent,
    required List<Message> messagesForApi,
  }) async {
    if (!settings.isKnowledgeEnabled) return;

    try {
      final selectedKnowledgeBaseIds = assistant != null
          ? assistant.knowledgeBaseIds
          : settings.activeKnowledgeBaseIds;

      final fallbackQuery = messagesForApi.reversed
          .where((m) => m.role == 'user')
          .map((m) => m.content)
          .firstOrNull;
      final retrievalQuery = (apiContent ?? text ?? fallbackQuery ?? '').trim();

      if (selectedKnowledgeBaseIds.isEmpty || retrievalQuery.isEmpty) {
        return;
      }

      final enhancementMode =
          settings.knowledgeLlmEnhanceMode.trim().toLowerCase();
      var effectiveRetrievalQuery = retrievalQuery;
      if (enhancementMode == 'rewrite') {
        try {
          final rewriteResponse = await llmService.getResponse(
            [
              Message(
                id: const Uuid().v4(),
                role: 'system',
                content: '''
You rewrite user questions for knowledge retrieval.
Rules:
1. Keep the original language.
2. Output a compact query with core entities, constraints, and keywords.
3. Output plain text only.''',
                timestamp: DateTime.now(),
                isUser: false,
              ),
              Message.user(retrievalQuery),
            ],
            model: settings.executionModel ??
                settings.activeProvider.selectedModel,
            providerId:
                settings.executionProviderId ?? settings.activeProviderId,
            cancelToken: _notifier._currentCancelToken,
          );
          final rewritten = rewriteResponse.content?.trim() ?? '';
          if (rewritten.isNotEmpty) {
            effectiveRetrievalQuery = rewritten;
          }
        } catch (_) {
          // Fall back to original user query if rewrite fails.
        }
      }

      final knowledgeStorage = _notifier._ref.read(knowledgeStorageProvider);

      ProviderConfig? embeddingProvider;
      if (settings.knowledgeUseEmbedding) {
        final embeddingProviderId =
            settings.knowledgeEmbeddingProviderId ?? settings.activeProviderId;
        embeddingProvider = settings.providers
            .where((p) => p.id == embeddingProviderId)
            .firstOrNull;
      }

      final kbResult = await knowledgeStorage.retrieveContext(
        query: effectiveRetrievalQuery,
        baseIds: selectedKnowledgeBaseIds,
        topK: settings.knowledgeTopK,
        useEmbedding: settings.knowledgeUseEmbedding,
        embeddingModel: settings.knowledgeEmbeddingModel,
        embeddingProvider: embeddingProvider,
        requiredScope: KnowledgeBaseScope.chat,
      );

      if (kbResult.hasContext) {
        _upsertSystemPrompt(messagesForApi, kbResult.toPromptContext());
      }
    } catch (e) {
      debugPrint('Knowledge retrieval skipped due to error: $e');
    }
  }

  void _upsertSystemPrompt(List<Message> messagesForApi, String prompt) {
    final systemMsg =
        messagesForApi.where((m) => m.role == 'system').firstOrNull;
    if (systemMsg != null) {
      final index = messagesForApi.indexOf(systemMsg);
      final combinedPrompt = systemMsg.content.isEmpty
          ? prompt
          : '${systemMsg.content}\n\n$prompt';
      messagesForApi[index] = systemMsg.copyWith(content: combinedPrompt);
      return;
    }

    messagesForApi.insert(
      0,
      Message(
        id: const Uuid().v4(),
        role: 'system',
        content: prompt,
        timestamp: DateTime.now(),
        isUser: false,
      ),
    );
  }
}
