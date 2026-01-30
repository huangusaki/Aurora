import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/settings_provider.dart';
import '../../settings/presentation/usage_stats_provider.dart';
import 'package:aurora/shared/services/openai_llm_service.dart';
import '../domain/message.dart';
import 'package:aurora/shared/services/llm_service.dart';
import '../data/chat_storage.dart';
import '../data/session_entity.dart';
import 'package:aurora/shared/services/tool_manager.dart';
import 'package:aurora/shared/services/worker_service.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:uuid/uuid.dart';
import 'topic_provider.dart';
import '../../skills/presentation/skill_provider.dart';
import '../../skills/domain/skill_entity.dart';
import '../../../core/error/app_error_type.dart';
import '../../../core/error/app_exception.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

enum SearchEngine { duckduckgo, google, bing }

final llmServiceProvider = Provider<LLMService>((ref) {
  final settings = ref.watch(settingsProvider);
  return OpenAILLMService(settings);
});

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool hasUnreadResponse;
  final bool isAutoScrollEnabled;
  final bool isStreaming;
  final String? currentStreamContent;
  final String? currentStreamReasoning;
  final double? currentReasoningTimer;
  final bool isStreamEnabled;
  final bool isLoadingHistory;
  final String? activePresetName;
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.hasUnreadResponse = false,
    this.isAutoScrollEnabled = true,
    this.isStreaming = false,
    this.currentStreamContent,
    this.currentStreamReasoning,
    this.currentReasoningTimer,
    this.isStreamEnabled = true,
    this.isLoadingHistory = false,
    this.activePresetName,
  });
  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? hasUnreadResponse,
    bool? isAutoScrollEnabled,
    bool? isStreaming,
    String? currentStreamContent,
    String? currentStreamReasoning,
    double? currentReasoningTimer,
    bool? isStreamEnabled,
    bool? isLoadingHistory,
    Object? activePresetName = _sentinel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasUnreadResponse: hasUnreadResponse ?? this.hasUnreadResponse,
      isAutoScrollEnabled: isAutoScrollEnabled ?? this.isAutoScrollEnabled,
      isStreaming: isStreaming ?? this.isStreaming,
      currentStreamContent: currentStreamContent ?? this.currentStreamContent,
      currentStreamReasoning:
          currentStreamReasoning ?? this.currentStreamReasoning,
      currentReasoningTimer:
          currentReasoningTimer ?? this.currentReasoningTimer,
      isStreamEnabled: isStreamEnabled ?? this.isStreamEnabled,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      activePresetName: activePresetName == _sentinel
          ? this.activePresetName
          : activePresetName as String?,
    );
  }
}

const Object _sentinel = Object();

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final ChatStorage _storage;
  String _sessionId;
  final void Function(String newId)? onSessionCreated;
  final void Function()? onStateChanged;
  String _currentGenerationId = '';
  CancelToken? _currentCancelToken;
  double? _savedScrollOffset;
  final List<VoidCallback> _listeners = [];
  ChatNotifier({
    required Ref ref,
    required ChatStorage storage,
    required String sessionId,
    this.onSessionCreated,
    this.onStateChanged,
  })  : _ref = ref,
        _storage = storage,
        _sessionId = sessionId,
        super(const ChatState()) {
    if (_sessionId != 'chat' && _sessionId != 'new_chat') {
      _loadHistory();
    }
  }
  void addLocalListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeLocalListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyLocalListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  bool _isDisposed = false;
  bool get mounted => !_isDisposed;

  @override
  set state(ChatState value) {
    if (_isDisposed) return;
    super.state = value;
    onStateChanged?.call();
    _notifyLocalListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _currentCancelToken?.cancel();
    _currentCancelToken = null;
    super.dispose();
  }

  ChatState get currentState => state;
  double? get savedScrollOffset => _savedScrollOffset;
  void setAutoScrollEnabled(bool enabled) {
    if (state.isAutoScrollEnabled != enabled) {
      state = state.copyWith(isAutoScrollEnabled: enabled);
    }
  }

  void saveScrollOffset(double offset) {
    _savedScrollOffset = offset;
  }

  void abortGeneration() {
    _currentGenerationId = '';
    _currentCancelToken?.cancel('User aborted generation');
    _currentCancelToken = null;
    state = state.copyWith(isLoading: false);
  }

  void markAsRead() {
    if (state.hasUnreadResponse) {
      state = state.copyWith(hasUnreadResponse: false);
    }
  }

  Future<void> _loadHistory() async {
    await Future.microtask(() {});
    if (!mounted) return;
    state = state.copyWith(isLoadingHistory: true);
    final messages = await _storage.loadHistory(_sessionId);
    if (!mounted) return;
    String? restoredPresetName;
    final session = await _storage.getSession(_sessionId);
    if (session?.presetId != null) {
      if (session!.presetId!.isEmpty) {
        restoredPresetName = null;
      } else {
        final presets = _ref.read(settingsProvider).presets;
        final match = presets.where((p) => p.id == session.presetId);
        if (match.isNotEmpty) {
          restoredPresetName = match.first.name;
        }
      }
    } else {
      final systemMsg = messages.where((m) => m.role == 'system').firstOrNull;
      if (systemMsg != null) {
        final presets = _ref.read(settingsProvider).presets;
        final appSettings =
            await _ref.read(settingsStorageProvider).loadAppSettings();
        if (appSettings?.lastPresetId != null) {
          final match = presets.where((p) => p.id == appSettings!.lastPresetId);
          if (match.isNotEmpty) {
            restoredPresetName = match.first.name;
          }
        }
      }
    }
    state = state.copyWith(
      messages: messages,
      isLoadingHistory: false,
      activePresetName: restoredPresetName,
    );
  }

  Future<String> sendMessage(String? text,
      {List<String> attachments = const [], String? apiContent}) async {
    if (!mounted) return _sessionId;
    
    if (state.isLoading && text != null) {
      return _sessionId;
    }
    if (text != null && text.trim().isEmpty && attachments.isEmpty)
      return _sessionId;
    final myGenerationId = const Uuid().v4();
    _currentGenerationId = myGenerationId;
    _currentCancelToken?.cancel();
    _currentCancelToken = CancelToken();
    final oldId = _sessionId;
    String? newRealId;
    if (text != null && (_sessionId == 'chat' || _sessionId == 'new_chat')) {
      final title = text.length > 15 ? '${text.substring(0, 15)}...' : text;
      final topicId = _ref.read(selectedTopicIdProvider);
      
      // Don't use currentPresetId for new chats to avoid "leaking" presets
      final realId = await _storage.createSession(
          title: title, topicId: topicId, presetId: '');
      
      if (!mounted) return realId;

      _sessionId = realId; // Update internal ID first to ensure consistency
      newRealId = realId;

      _generateTopic(text).then((smartTitle) async {
        if (smartTitle != title && smartTitle.isNotEmpty) {
          await _storage.updateSessionTitle(realId, smartTitle);
          _ref.read(sessionsProvider.notifier).loadSessions();
        }
      });
    } else if (text != null && state.messages.isEmpty) {
      if (!mounted) return _sessionId;
      final title = text.length > 15 ? '${text.substring(0, 15)}...' : text;
      await _storage.updateSessionTitle(_sessionId, title);
      
      if (!mounted) return _sessionId;
      _ref.read(sessionsProvider.notifier).loadSessions();
      final currentSessionId = _sessionId;
      _generateTopic(text).then((smartTitle) async {
        if (!mounted) return;
        if (smartTitle != title && smartTitle.isNotEmpty) {
          await _storage.updateSessionTitle(currentSessionId, smartTitle);
          if (!mounted) return;
          _ref.read(sessionsProvider.notifier).loadSessions();
        }
      });
    }
    
    if (text != null) {
      if (!mounted) return _sessionId;
      final content = apiContent ?? text;
      final userMessage = Message.user(content, attachments: attachments);
      final dbId = await _storage.saveMessage(userMessage, _sessionId);
      
      if (!mounted) return _sessionId;
      final userMessageWithDbId = userMessage.copyWith(id: dbId);
      state = state.copyWith(
        messages: [...state.messages, userMessageWithDbId],
      );
    }

    // Now it's safe to redirect, as state already contains the user message
    if (newRealId != null && oldId == 'new_chat' && onSessionCreated != null) {
      onSessionCreated!(newRealId);
    }
    onStateChanged?.call();
    state =
        state.copyWith(isLoading: true, error: null, hasUnreadResponse: false);
    final startSaveIndex = state.messages.length;
    final startTime = DateTime.now();
    int promptTokens = 0;
    int completionTokens = 0;
    try {
      final messagesForApi = List<Message>.from(state.messages);
      final settings = _ref.read(settingsProvider);
      final llmService = _ref.read(llmServiceProvider);
      final toolManager = ToolManager();
      final currentModel = settings.activeProvider?.selectedModel;
      final currentProvider = settings.activeProvider?.name;
      var aiMsg =
          Message.ai('', model: currentModel, provider: currentProvider);
      state = state.copyWith(messages: [...state.messages, aiMsg]);
      final currentPlatform = Platform.operatingSystem;
      final isMobile = PlatformUtils.isMobile;
      final activeSkills = isMobile 
          ? <Skill>[] 
          : _ref.read(skillProvider).skills.where((s) => s.isEnabled && s.forAI && s.isCompatible(currentPlatform)).toList();
      List<Map<String, dynamic>>? tools;
      if (settings.isSearchEnabled || activeSkills.isNotEmpty) {
        tools = toolManager.getTools(skills: activeSkills);
      }

      // Inject ONLY Descriptions for Routing
      if (activeSkills.isNotEmpty) {
        final skillDescriptions = activeSkills.map((s) => '- [${s.name}]: ${s.description}').join('\n');
        final routingPrompt = '''
# Specialized Skills
You have access to the following specialized agents. Delegate tasks to them when the user's request matches their capabilities.

## Registry
$skillDescriptions

To invoke a skill, usage of the `call_skill` tool is mandatory. Provide the `skill_name` and a detailed `query` for the worker agent.
''';
        final systemMsg = messagesForApi.where((m) => m.role == 'system').firstOrNull;
        if (systemMsg != null) {
          final index = messagesForApi.indexOf(systemMsg);
          messagesForApi[index] = systemMsg.copyWith(
            content: '${systemMsg.content}\n\n$routingPrompt'
          );
        } else {
          messagesForApi.insert(0, Message(
            id: const Uuid().v4(),
            role: 'system',
            content: routingPrompt,
            timestamp: DateTime.now(),
            isUser: false,
          ));
        }
        
        // Add call_skill tool
        final callSkillTool = {
          'type': 'function',
          'function': {
            'name': 'call_skill',
            'description': 'Route a complex task to a specialized worker agent with full documentation access.',
            'parameters': {
              'type': 'object',
              'required': ['skill_name', 'query'],
              'properties': {
                'skill_name': {'type': 'string', 'description': 'The exact identifier of the skill from the registry'},
                'query': {'type': 'string', 'description': 'The full natural language task description for the worker'}
              }
            }
          }
        };
        // Merge with existing tools
        tools ??= [];
        tools.add(callSkillTool);
      }
      bool continueGeneration = true;
      int turns = 0;
      DateTime? firstContentTime;
      while (continueGeneration &&
          turns < 3 &&
          _currentGenerationId == myGenerationId &&
          mounted) {
        turns++;
        continueGeneration = false;
        if (settings.isStreamEnabled) {
          final responseStream = llmService.streamResponse(
            messagesForApi,
            tools: tools,
            cancelToken: _currentCancelToken,
          );
          DateTime? reasoningStartTime;
          await for (final chunk in responseStream) {
            if (_currentGenerationId != myGenerationId || !mounted) break;
            if (chunk.promptTokens != null) promptTokens = chunk.promptTokens!;
            if (chunk.completionTokens != null) completionTokens = chunk.completionTokens!;
            if (chunk.reasoning != null && chunk.reasoning!.isNotEmpty) {
              reasoningStartTime ??= DateTime.now();
              firstContentTime ??= DateTime.now();
            }
            double? duration = aiMsg.reasoningDurationSeconds;
            if (duration == null &&
                reasoningStartTime != null &&
                chunk.content != null &&
                chunk.content!.isNotEmpty) {
              duration =
                  DateTime.now().difference(reasoningStartTime).inMilliseconds /
                      1000.0;
            }
            // Track first content token time
            if (firstContentTime == null) {
              final hasContent = chunk.content != null;
              final hasReasoning = chunk.reasoning != null;
              final hasImages = chunk.images.isNotEmpty;
              final hasToolCalls =
                  chunk.toolCalls != null && chunk.toolCalls!.isNotEmpty;
              
              /*
              print('DEBUG: chunk received. hasContent=$hasContent, '
                  'hasReasoning=$hasReasoning, hasImages=$hasImages, '
                  'content="${chunk.content}", reasoning="${chunk.reasoning}"');
              */

              if (hasContent || hasReasoning || hasImages || hasToolCalls) {
                // print('DEBUG: FirstToken captured!');
                firstContentTime = DateTime.now();
              }
            }
            if (chunk.finishReason == 'malformed_function_call') {
               aiMsg = Message(
                id: aiMsg.id,
                content: aiMsg.content + (chunk.content ?? '') + '\n\n> ⚠️ **System Error**: The AI backend returned a "malformed_function_call" error. This usually means the model tried to call a tool but failed to generate a valid request format. Please try again or switch models.',
                reasoningContent: (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
                isUser: false,
                timestamp: aiMsg.timestamp,
                attachments: aiMsg.attachments,
                images: [...aiMsg.images, ...chunk.images],
                model: aiMsg.model,
                provider: aiMsg.provider,
                reasoningDurationSeconds: duration,
                tokenCount: chunk.usage ?? aiMsg.tokenCount,
                promptTokens: promptTokens > 0 ? promptTokens : aiMsg.promptTokens,
                completionTokens: completionTokens > 0 ? completionTokens : aiMsg.completionTokens,
                toolCalls: _mergeToolCalls(aiMsg.toolCalls, chunk.toolCalls),
              );
              if (!mounted) break;
              final newMessages = List<Message>.from(state.messages);
              if (newMessages.isNotEmpty && newMessages.last.id == aiMsg.id) {
                newMessages.removeLast();
              }
              newMessages.add(aiMsg);
              state = state.copyWith(messages: newMessages);
              continueGeneration = false;
              break; 
            }
            aiMsg = Message(
              id: aiMsg.id,
              content: aiMsg.content + (chunk.content ?? ''),
              reasoningContent:
                  (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
              isUser: false,
              timestamp: aiMsg.timestamp,
              attachments: aiMsg.attachments,
              images: [...aiMsg.images, ...chunk.images],
              model: aiMsg.model,
              provider: aiMsg.provider,
              reasoningDurationSeconds: duration,
              tokenCount: chunk.usage ?? aiMsg.tokenCount,
              promptTokens: promptTokens > 0 ? promptTokens : aiMsg.promptTokens,
              completionTokens: completionTokens > 0 ? completionTokens : aiMsg.completionTokens,
              toolCalls: _mergeToolCalls(aiMsg.toolCalls, chunk.toolCalls),
            );
            final newMessages = List<Message>.from(state.messages);
            if (newMessages.isNotEmpty && newMessages.last.id == aiMsg.id) {
              newMessages.removeLast();
            }
            newMessages.add(aiMsg);
            if (mounted) state = state.copyWith(messages: newMessages);
          }
          if (!mounted) return aiMsg.id;
          if (aiMsg.reasoningDurationSeconds == null &&
              reasoningStartTime != null) {
            final duration =
                DateTime.now().difference(reasoningStartTime).inMilliseconds /
                    1000.0;
            aiMsg = aiMsg.copyWith(reasoningDurationSeconds: duration);
            final newMessages = List<Message>.from(state.messages);
            if (newMessages.isNotEmpty && newMessages.last.id == aiMsg.id) {
              newMessages.removeLast();
            }
            newMessages.add(aiMsg);
            if (mounted) state = state.copyWith(messages: newMessages);
          }
          // Check for text-based search pattern: <search>query</search>
          final searchPattern = RegExp(r'<search>(.*?)</search>', dotAll: true);
          final searchMatch = searchPattern.firstMatch(aiMsg.content);
          if (searchMatch != null) {
            final searchQuery = searchMatch.group(1)?.trim() ?? '';
            if (searchQuery.isNotEmpty) {
              continueGeneration = true;
              // Remove the <search> tag from displayed content
              if (!mounted) break;
              final cleanedContent = aiMsg.content.replaceAll(searchPattern, '').trim();
              aiMsg = aiMsg.copyWith(content: cleanedContent);
              final newMessages = List<Message>.from(state.messages);
              if (newMessages.isNotEmpty && newMessages.last.id == aiMsg.id) {
                newMessages.removeLast();
              }
              newMessages.add(aiMsg);
              state = state.copyWith(messages: newMessages);
              
              // Execute search
              String searchResult;
              try {
                searchResult = await toolManager.executeTool('SearchWeb', {'query': searchQuery},
                    preferredEngine: settings.searchEngine, skills: activeSkills);
              } catch (e) {
                searchResult = jsonEncode({'error': e.toString()});
              }
              
              // Create a tool call ID for display purposes
              final toolCallId = 'search_${const Uuid().v4().substring(0, 8)}';
              
              if (!mounted) break;
              // Display search results to user as tool message
              final toolMsg = Message.tool(searchResult, toolCallId: toolCallId);
              state = state.copyWith(messages: [...state.messages, toolMsg]);
              
              // Add assistant message and search result to API messages
              messagesForApi.add(aiMsg.copyWith(content: '<search>$searchQuery</search>'));
              messagesForApi.add(Message(
                id: const Uuid().v4(),
                role: 'user',
                content: '## Search Results for "$searchQuery"\n$searchResult\n\nPlease synthesize the above search results and provide a comprehensive answer. Cite sources using [index](link) format.',
                timestamp: DateTime.now(),
                isUser: false,
              ));
              
              if (!mounted) break;
              // Create new AI message for final response
              aiMsg = Message.ai('', model: currentModel, provider: currentProvider);
              state = state.copyWith(messages: [...state.messages, aiMsg]);
            }
          }
          // Legacy JSON-based tool calls (fallback)
          else if (aiMsg.toolCalls != null && aiMsg.toolCalls!.isNotEmpty) {
            continueGeneration = true;
            messagesForApi.add(aiMsg);
            for (final tc in aiMsg.toolCalls!) {
              String toolResult;
              try {
                if (tc.name == 'call_skill') {
                  final activeSkills = _ref.read(skillProvider).skills;
                   Map<String, dynamic> args;
                   if (tc.arguments.startsWith('{')) {
                      args = jsonDecode(tc.arguments);
                   } else {
                      // Handle hallucinated nested json strings or malformed args
                      try {
                        args = jsonDecode(tc.arguments);
                      } catch (e) {
                         args = {'query': tc.arguments, 'skill_name': 'unknown'};
                      }
                   }
                   
                   var skillName = args['skill_name'];
                   // Fallback if skill_name is missing but might be inferred? 
                   // No, we need skill_name. 
                   if (skillName == null) {
                      // Try to fix hallucination where everything is in 'skill_args'
                      if (args.containsKey('skill_args')) {
                        final nested = args['skill_args'];
                        if (nested is Map) {
                           skillName = nested['skill_name'];
                        } else if (nested is String) {
                           try {
                             final nMap = jsonDecode(nested);
                             skillName = nMap['skill_name'];
                           } catch (_) {}
                        }
                      }
                   }

                   var query = args['query'] ?? args['request'] ?? args['task'] ?? args['content'];
                   if (query == null) {
                      // If query is missing, dump arguments as query (excluding skill_name)
                      final copy = Map<String, dynamic>.from(args);
                      copy.remove('skill_name');
                      query = jsonEncode(copy);
                   }
                   
                   final skill = activeSkills.firstWhere(
                      (s) => s.name == skillName, 
                      orElse: () {
                        // If skill not found, maybe just pick the most likely one based on description? 
                        // Too risky. Throw specific error.
                        throw Exception('Skill "$skillName" not found. Available: ${activeSkills.map((s) => s.name).join(", ")}');
                      }
                   );
                   
                    final workerService = WorkerService(llmService);
                    final executionModel = settings.executionModel;
                    final executionProviderId = settings.executionProviderId;
                    toolResult = await workerService.executeSkillTask(skill, query.toString(), model: executionModel, providerId: executionProviderId);
                } else {
                  final args = jsonDecode(tc.arguments);
                  toolResult = await toolManager.executeTool(tc.name, args,
                      preferredEngine: settings.searchEngine, skills: _ref.read(skillProvider).skills);
                }
              } catch (e) {
                toolResult = jsonEncode({'error': e.toString()});
              }
              if (!mounted) break;
              final toolMsg = Message.tool(toolResult, toolCallId: tc.id);
              messagesForApi.add(toolMsg);
              state = state.copyWith(messages: [...state.messages, toolMsg]);
            }
            aiMsg =
                Message.ai('', model: currentModel, provider: currentProvider);
            state = state.copyWith(messages: [...state.messages, aiMsg]);
          }
        } else {
          final response = await llmService.getResponse(
            messagesForApi,
            tools: tools,
            cancelToken: _currentCancelToken,
          );
          if (response.promptTokens != null) promptTokens = response.promptTokens!;
          if (response.completionTokens != null) completionTokens = response.completionTokens!;
          if (_currentGenerationId == myGenerationId && mounted) {
            aiMsg = Message(
                id: aiMsg.id,
                content: response.content ?? '',
                reasoningContent: response.reasoning,
                isUser: false,
                timestamp: aiMsg.timestamp,
                attachments: aiMsg.attachments,
                images: response.images,
                model: aiMsg.model,
                provider: aiMsg.provider,
                tokenCount: response.usage,
                promptTokens: response.promptTokens,
                completionTokens: response.completionTokens,
                toolCalls: response.toolCalls
                    ?.map((tc) => ToolCall(
                        id: tc.id ?? '',
                        type: tc.type ?? 'function',
                        name: tc.name ?? '',
                        arguments: tc.arguments ?? ''))
                    .toList());
            final newMessages = List<Message>.from(state.messages);
            if (newMessages.isNotEmpty && newMessages.last.id == aiMsg.id) {
              newMessages.removeLast();
            }
            newMessages.add(aiMsg);
            state = state.copyWith(messages: newMessages);
            // Check for text-based search pattern in non-streaming mode
            final searchPattern = RegExp(r'<search>(.*?)</search>', dotAll: true);
            final searchMatch = searchPattern.firstMatch(aiMsg.content);
            if (searchMatch != null) {
              final searchQuery = searchMatch.group(1)?.trim() ?? '';
              if (searchQuery.isNotEmpty) {
                continueGeneration = true;
                final cleanedContent = aiMsg.content.replaceAll(searchPattern, '').trim();
                aiMsg = aiMsg.copyWith(content: cleanedContent);
                
                String searchResult;
                try {
                  searchResult = await toolManager.executeTool('SearchWeb', {'query': searchQuery},
                      preferredEngine: settings.searchEngine, skills: activeSkills);
                } catch (e) {
                  searchResult = jsonEncode({'error': e.toString()});
                }
                
                // Create a tool call ID for display purposes
                final toolCallId = 'search_${const Uuid().v4().substring(0, 8)}';
                
                // Display search results to user as tool message
                final toolMsg = Message.tool(searchResult, toolCallId: toolCallId);
                state = state.copyWith(messages: [...state.messages, toolMsg]);
                
                messagesForApi.add(aiMsg.copyWith(content: '<search>$searchQuery</search>'));
                messagesForApi.add(Message(
                  id: const Uuid().v4(),
                  role: 'user',
                  content: '## Search Results for "$searchQuery"\n$searchResult\n\nPlease synthesize the above search results and provide a comprehensive answer. Cite sources using [index](link) format.',
                  timestamp: DateTime.now(),
                  isUser: false,
                ));
                
                aiMsg = Message.ai('', model: currentModel, provider: currentProvider);
                state = state.copyWith(messages: [...state.messages, aiMsg]);
              }
            }
            // Legacy JSON-based tool calls (fallback for non-streaming)
            else if (aiMsg.toolCalls != null && aiMsg.toolCalls!.isNotEmpty) {
              continueGeneration = true;
              messagesForApi.add(aiMsg);
              for (final tc in aiMsg.toolCalls!) {
                String toolResult;
                try {
                  final args = jsonDecode(tc.arguments);
                  toolResult = await toolManager.executeTool(tc.name, args,
                      preferredEngine: settings.searchEngine, skills: activeSkills);
                } catch (e) {
                  toolResult = jsonEncode({'error': e.toString()});
                }
                final toolMsg = Message.tool(toolResult, toolCallId: tc.id);
                messagesForApi.add(toolMsg);
                state = state.copyWith(messages: [...state.messages, toolMsg]);
              }
              aiMsg = Message.ai('',
                  model: currentModel, provider: currentProvider);
              state = state.copyWith(messages: [...state.messages, aiMsg]);
            }
          }
        }
      }
      // If we hit the turn limit and AI message is empty or still has search tag, force a final response
      if (_currentGenerationId == myGenerationId && 
          mounted && 
          turns >= 3 && 
          (aiMsg.content.isEmpty || aiMsg.content.contains('<search>'))) {
        // Remove search tag from content if present
        final cleanedContent = aiMsg.content.replaceAll(RegExp(r'<search>.*?</search>', dotAll: true), '').trim();
        aiMsg = aiMsg.copyWith(content: cleanedContent);
        
        // Add instruction to synthesize without further search
        messagesForApi.add(Message(
          id: const Uuid().v4(),
          role: 'user',
          content: '请根据已有的搜索结果直接给出答案，不要再进行搜索。如果搜索结果不足，请如实说明。',
          timestamp: DateTime.now(),
          isUser: false,
        ));
        
        // Make one final request without search capability
        aiMsg = Message.ai('', model: currentModel, provider: currentProvider);
        final newMessages = List<Message>.from(state.messages);
        // Remove empty messages at the end
        while (newMessages.isNotEmpty && !newMessages.last.isUser && newMessages.last.content.isEmpty) {
          newMessages.removeLast();
        }
        newMessages.add(aiMsg);
        state = state.copyWith(messages: newMessages);
        
        // Final generation without tools
        final finalStream = llmService.streamResponse(
          messagesForApi,
          tools: null, // No tools for final response
          cancelToken: _currentCancelToken,
        );
        await for (final chunk in finalStream) {
          if (_currentGenerationId != myGenerationId || !mounted) break;
          aiMsg = Message(
            id: aiMsg.id,
            content: aiMsg.content + (chunk.content ?? ''),
            reasoningContent: (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
            isUser: false,
            timestamp: aiMsg.timestamp,
            model: aiMsg.model,
            provider: aiMsg.provider,
            tokenCount: chunk.usage ?? aiMsg.tokenCount,
            promptTokens: promptTokens > 0 ? promptTokens : aiMsg.promptTokens,
            completionTokens: completionTokens > 0 ? completionTokens : aiMsg.completionTokens,
          );
          final updateMessages = List<Message>.from(state.messages);
          if (updateMessages.isNotEmpty && updateMessages.last.id == aiMsg.id) {
            updateMessages.removeLast();
          }
          updateMessages.add(aiMsg);
          if (mounted) state = state.copyWith(messages: updateMessages);
        }
      }
      if (_currentGenerationId == myGenerationId) {
        final messages = state.messages;
        // Calculate timing metrics before saving
        final durationMs = DateTime.now().difference(startTime).inMilliseconds;
        final firstTokenMs = firstContentTime != null
            ? firstContentTime.difference(startTime).inMilliseconds
            : null;
        if (messages.length > startSaveIndex) {
          final unsaved = messages.sublist(startSaveIndex);
          final updatedMessages = List<Message>.from(state.messages);
          for (int i = 0; i < unsaved.length; i++) {
            if (_currentGenerationId != myGenerationId) {
              break;
            }
            var m = unsaved[i];
            // Add timing metrics to the last non-tool AI message
            if (!m.isUser && m.role != 'tool' && i == unsaved.length - 1) {
              m = m.copyWith(
                firstTokenMs: firstTokenMs,
                durationMs: durationMs,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
              );
            }
            final dbId = await _storage.saveMessage(m, _sessionId);
            if (!mounted) break;
            final stateIndex = startSaveIndex + i;
            if (stateIndex < updatedMessages.length) {
              updatedMessages[stateIndex] = m.copyWith(id: dbId);
            }
          }
          if (mounted && _currentGenerationId == myGenerationId) {
            state = state.copyWith(
                messages: updatedMessages,
                isLoading: false,
                hasUnreadResponse: true);
            _ref.read(sessionsProvider.notifier).loadSessions();
          }
        } else {
          if (mounted)
            state = state.copyWith(isLoading: false, hasUnreadResponse: true);
        }
        if (currentModel != null && currentModel.isNotEmpty) {
          final tokenCount = aiMsg.tokenCount ?? 0;
          _ref.read(usageStatsProvider.notifier).incrementUsage(currentModel,
              success: true,
              durationMs: durationMs,
              firstTokenMs: firstTokenMs ?? 0,
              tokenCount: tokenCount,
              promptTokens: promptTokens,
              completionTokens: completionTokens);
        }
        
        // Auto-rotate API key after successful request if enabled
        final activeProvider = settings.activeProvider;
        if (activeProvider.autoRotateKeys && activeProvider.apiKeys.length > 1) {
          _ref.read(settingsProvider.notifier).rotateApiKey(activeProvider.id);
        }
      }
    } catch (e, stack) {
      if (_currentGenerationId == myGenerationId && mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        if (!mounted) return _sessionId;
        final messages = List<Message>.from(state.messages);
        if (messages.isNotEmpty && !messages.last.isUser) {
          final lastMsg = messages.last;
          messages[messages.length - 1] = Message(
            id: lastMsg.id,
            content: '⚠️ **请求失败**\n\n$errorMessage',
            isUser: false,
            timestamp: lastMsg.timestamp,
            model: lastMsg.model,
            provider: lastMsg.provider,
          );
        }
        if (mounted) {
          state = state.copyWith(
              messages: messages, isLoading: false, error: errorMessage);
        }
        final currentModel =
            _ref.read(settingsProvider).activeProvider?.selectedModel;
        if (currentModel != null && currentModel.isNotEmpty) {
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          
          AppErrorType errorType = AppErrorType.unknown;
          if (e is AppException) {
            errorType = e.type;
          }

          _ref.read(usageStatsProvider.notifier).incrementUsage(currentModel,
              success: false, durationMs: duration, errorType: errorType);
          
          // Rotate API key on auth/rate-limit errors if multiple keys available
          if (e is AppException) {
            final shouldRotate = errorType == AppErrorType.unauthorized ||
                errorType == AppErrorType.rateLimit;
            if (shouldRotate) {
              final provider = _ref.read(settingsProvider).activeProvider;
              if (provider.apiKeys.length > 1) {
                _ref.read(settingsProvider.notifier).rotateApiKey(provider.id);
              }
            }
          }
        }
      }
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
    return _sessionId;
  }

  List<ToolCall>? _mergeToolCalls(
      List<ToolCall>? existing, List<ToolCallChunk>? chunks) {
    if (chunks == null || chunks.isEmpty) return existing;
    final merged =
        existing != null ? List<ToolCall>.from(existing) : <ToolCall>[];
    for (final chunk in chunks) {
      final index = chunk.index ?? 0;
      if (index >= merged.length) {
        merged.add(ToolCall(
            id: chunk.id ?? '',
            type: chunk.type ?? 'function',
            name: chunk.name ?? '',
            arguments: chunk.arguments ?? ''));
      } else {
        final prev = merged[index];
        merged[index] = ToolCall(
            id: (prev.id == '' ? (chunk.id ?? '') : prev.id),
            type: (prev.type == 'function'
                ? (chunk.type ?? 'function')
                : prev.type),
            name: prev.name + (chunk.name ?? ''),
            arguments: prev.arguments + (chunk.arguments ?? ''));
      }
    }
    return merged;
  }

  Future<void> deleteMessage(String id) async {
    final newMessages = state.messages.where((m) => m.id != id).toList();
    state = state.copyWith(messages: newMessages);
    await _storage.deleteMessage(id, sessionId: _sessionId);
  }

  Future<void> editMessage(String id, String newContent,
      {List<String>? newAttachments}) async {
    final index = state.messages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final oldMsg = state.messages[index];
    final updatedAttachments = newAttachments ?? oldMsg.attachments;
    final newMsg = Message(
      id: oldMsg.id,
      content: newContent,
      isUser: oldMsg.isUser,
      timestamp: oldMsg.timestamp,
      reasoningContent: oldMsg.reasoningContent,
      attachments: updatedAttachments,
      images: newAttachments != null ? const [] : oldMsg.images,
    );
    final newMessages = List<Message>.from(state.messages);
    newMessages[index] = newMsg;
    state = state.copyWith(messages: newMessages);
    await _storage.updateMessage(newMsg);
  }

  Future<void> regenerateResponse(String rootMessageId) async {
    final index = state.messages.indexWhere((m) => m.id == rootMessageId);
    if (index == -1) return;
    abortGeneration();
    await Future.delayed(const Duration(milliseconds: 100));
    final rootMsg = state.messages[index];
    List<Message> historyToKeep;
    
    // Determine the user message to update
    Message? userMsgToUpdate;

    if (rootMsg.isUser) {
      historyToKeep = state.messages.sublist(0, index + 1);
      userMsgToUpdate = rootMsg;
    } else {
      if (index == 0) return;
      historyToKeep = state.messages.sublist(0, index);
      // The last message in historyToKeep (which is index - 1 in original list) is the user message
      userMsgToUpdate = historyToKeep.last;
    }

    if (userMsgToUpdate != null && userMsgToUpdate.isUser) {
      final updatedUserMsg = userMsgToUpdate.copyWith(timestamp: DateTime.now());
      await _storage.updateMessage(updatedUserMsg);
      historyToKeep[historyToKeep.length - 1] = updatedUserMsg;
    }

    final oldMessages = state.messages;
    state = state.copyWith(
        messages: historyToKeep,
        isLoading: true,
        error: null,
        isAutoScrollEnabled: true);
    final idsToDelete =
        oldMessages.skip(historyToKeep.length).map((m) => m.id).toList();
    for (final mid in idsToDelete) {
      await _storage.deleteMessage(mid, sessionId: _sessionId);
    }
    await sendMessage(null);
  }

  Future<void> clearContext() async {
    if (_sessionId == 'new_chat' || _sessionId == 'translation') {
      state = state.copyWith(messages: [], isLoading: false, error: null);
      return;
    }
    await _storage.clearSessionMessages(_sessionId);
    state = state.copyWith(messages: []);
  }

  void toggleSearch() {
    _ref.read(settingsProvider.notifier).toggleSearchEnabled();
  }

  Future<void> updateSystemPrompt(String template, [String? presetName]) async {
    final settingsState = _ref.read(settingsProvider);
    final user = settingsState.userName;
    final system = Platform.operatingSystem;
    final lang = settingsState.language;
    String deviceName = Platform.localHostname;
    String clipboardContent = '';
    if (template.contains('{clipboard}')) {
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        clipboardContent = data?.text ?? '';
      } catch (e) {
        debugPrint('Failed to get clipboard data: $e');
      }
    }
    String prompt = template
        .replaceAll('{time}', DateTime.now().toString())
        .replaceAll('{user_name}', user)
        .replaceAll('{system}', system)
        .replaceAll('{device}', deviceName)
        .replaceAll('{language}', lang)
        .replaceAll('{clipboard}', clipboardContent);
    final messages = List<Message>.from(state.messages);
    final index = messages.indexWhere((m) => m.role == 'system');
    if (index != -1) {
      final oldMsg = messages[index];
      final newMsg = oldMsg.copyWith(content: prompt);
      messages[index] = newMsg;
      await _storage.updateMessage(newMsg);
    } else {
      final newMsg = Message(
        id: const Uuid().v4(),
        role: 'system',
        content: prompt,
        timestamp: DateTime.now(),
        isUser: false,
      );
      messages.insert(0, newMsg);
      await _storage.saveMessage(newMsg, _sessionId);
    }
    state = state.copyWith(
      messages: messages,
      activePresetName: presetName,
    );
    debugPrint(
        '[PresetSave] updateSystemPrompt called with presetName: $presetName, sessionId: $_sessionId');
    if (presetName != null) {
      final presets = settingsState.presets;
      final match = presets.where((p) => p.name == presetName);
      if (match.isNotEmpty) {
        final newPresetId = match.first.id;
        // await _ref.read(settingsProvider.notifier).setLastPresetId(newPresetId);
        if (_sessionId != 'chat' && _sessionId != 'new_chat') {
          await _storage.updateSessionPreset(_sessionId, newPresetId);
        }
      }
    } else {
      // await _ref.read(settingsProvider.notifier).setLastPresetId(null);
      if (_sessionId != 'chat' && _sessionId != 'new_chat') {
        await _storage.updateSessionPreset(_sessionId, '');
      }
    }
  }

  void setSearchEngine(SearchEngine engine) {
    _ref.read(settingsProvider.notifier).setSearchEngine(engine.name);
  }

  Future<String> _generateTopic(String text) async {
    final settings = _ref.read(settingsProvider);
    if (!settings.enableSmartTopic || settings.topicGenerationModel == null) {
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final parts = settings.topicGenerationModel!.split('@');
    if (parts.length != 2) {
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final providerId = parts[0];
    final modelId = parts[1];
    final imageModelRegex = RegExp(
      r'(dall-e|gpt-image|midjourney|mj-|flux|stable-diffusion|sd-|sdxl|imagen|cogview|qwen-image)',
      caseSensitive: false,
    );
    if (imageModelRegex.hasMatch(modelId)) {
      debugPrint(
          'Skipping smart topic generation: Image model detected ($modelId)');
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final providerIndex =
        settings.providers.indexWhere((p) => p.id == providerId);
    if (providerIndex == -1) {
      return text.length > 15 ? '${text.substring(0, 15)}...' : text;
    }
    final tempProviders = List<ProviderConfig>.from(settings.providers);
    tempProviders[providerIndex] =
        tempProviders[providerIndex].copyWith(selectedModel: modelId);
    final tempSettings = settings.copyWith(
      activeProviderId: providerId,
      providers: tempProviders,
    );
    final tempLLMService = OpenAILLMService(tempSettings);
    try {
      final inputContent = text.length > 3000 ? text.substring(0, 3000) : text;
      final prompt =
          '''Analyze the conversation in <content> and generate a concise title.
Rules:
1. Language: Use the same language as the conversation.
2. Length: Max 10 characters or 5 words.
3. Style: Concise, no punctuation, no special symbols.
4. Output: The title text only.
<content>
$inputContent
</content>''';
      final response = await tempLLMService.getResponse([Message.user(prompt)]);
      final generatedTitle = response.content?.trim() ?? '';
      if (generatedTitle.isNotEmpty) {
        var cleanTitle = generatedTitle.replaceAll('"', '').replaceAll("'", "");
        if (cleanTitle.length > 20) {
          cleanTitle = cleanTitle.substring(0, 20);
        }
        return cleanTitle;
      }
    } catch (e) {
      debugPrint('Error generating topic: $e');
    }
    return text.length > 15 ? '${text.substring(0, 15)}...' : text;
  }
}

final chatStorageProvider = Provider<ChatStorage>((ref) {
  final settingsStorage = ref.watch(settingsStorageProvider);
  return ChatStorage(settingsStorage);
});
final translationProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return ChatNotifier(ref: ref, storage: storage, sessionId: 'translation');
});

class SessionsState {
  final List<SessionEntity> sessions;
  final bool isLoading;
  SessionsState({this.sessions = const [], this.isLoading = false});
}

class SessionsNotifier extends StateNotifier<SessionsState> {
  final ChatStorage _storage;
  final Ref _ref;
  SessionsNotifier(this._ref, this._storage) : super(SessionsState()) {
    _init();
  }
  Future<void> _init() async {
    await _storage.cleanupEmptySessions();
    await loadSessions();
    _storage.preloadAllSessions();
    final settings = await _ref.read(settingsStorageProvider).loadAppSettings();
    final lastId = settings?.lastSessionId;
    final lastTopicId = settings?.lastTopicId;
    debugPrint('Restoring session. lastId: $lastId, lastTopicId: $lastTopicId');
    if (lastTopicId != null) {
      final topicId = int.tryParse(lastTopicId);
      _ref.read(selectedTopicIdProvider.notifier).state = topicId;
      debugPrint('Restored topic id: $topicId');
    }
    if (lastId != null && state.sessions.any((s) => s.sessionId == lastId)) {
      _ref.read(selectedHistorySessionIdProvider.notifier).state = lastId;
    } else {
      // Start with virtual new chat if no last session or it was deleted
      _ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
    }
  }

  Future<void> loadSessions() async {
    state = SessionsState(sessions: state.sessions, isLoading: true);
    final sessions = await _storage.loadSessions();
    final order = await _storage.loadSessionOrder();
    if (order.isNotEmpty) {
      final orderMap = {for (var i = 0; i < order.length; i++) order[i]: i};
      sessions.sort((a, b) {
        final idxA = orderMap[a.sessionId];
        final idxB = orderMap[b.sessionId];
        if (idxA != null && idxB != null) return idxA.compareTo(idxB);
        if (idxA != null) return 1;
        if (idxB != null) return -1;
        return b.lastMessageTime.compareTo(a.lastMessageTime);
      });
    }
    state = SessionsState(sessions: sessions, isLoading: false);
  }

  Future<void> reorderSession(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<SessionEntity>.from(state.sessions);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = SessionsState(sessions: items, isLoading: false);
    final newOrder = items.map((s) => s.sessionId).toList();
    await _storage.saveSessionOrder(newOrder);
  }

  Future<String> createNewSession(String title) async {
    final id = await _storage.createSession(title: title);
    await loadSessions();
    return id;
  }

  Future<void> startNewSession() async {
    // Deep reset: clear draft and reset virtual ID
    _ref.read(chatSessionManagerProvider).resetSession('new_chat');
    _ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
  }

  Future<void> cleanupSessionIfEmpty(String? sessionId) async {
    if (sessionId == null || sessionId == 'new_chat') return;
    final deleted = await _storage.deleteSessionIfEmpty(sessionId);
    if (deleted) {
      await loadSessions();
    }
  }

  Future<void> renameSession(String id, String newTitle) async {
    await _storage.updateSessionTitle(id, newTitle);
    await loadSessions();
  }

  Future<void> deleteSession(String id) async {
    final selectedId = _ref.read(selectedHistorySessionIdProvider);
    await _storage.deleteSession(id);
    // Explicitly reset the session in manager to clear memory and cache
    _ref.read(chatSessionManagerProvider).resetSession(id);
    
    await loadSessions();
    
    // If we deleted the currently active session, move to the next best one
    if (selectedId == id || selectedId == null) {
      if (state.sessions.isNotEmpty) {
        _ref.read(selectedHistorySessionIdProvider.notifier).state =
            state.sessions.first.sessionId;
      } else {
        _ref.read(chatSessionManagerProvider).resetSession('new_chat');
        _ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
      }
    }
  }

  /// Creates a new session with messages copied up to and including the specified message.
  /// Returns the new session ID if successful, null otherwise.
  Future<String?> createBranchSession({
    required String originalSessionId,
    required String originalTitle,
    required String upToMessageId,
    required String branchSuffix,
  }) async {
    // Load original session messages
    final messages = await _storage.loadHistory(originalSessionId);
    if (messages.isEmpty) return null;

    // Find the index of the target message
    final targetIndex = messages.indexWhere((m) => m.id == upToMessageId);
    if (targetIndex == -1) return null;

    // Get the session to copy the topicId
    final originalSession = await _storage.getSession(originalSessionId);
    final topicId = originalSession?.topicId;

    // Create a copy of messages up to and including the target
    final messagesToCopy = messages.sublist(0, targetIndex + 1);

    // Create new session with branch name
    final newTitle = '$originalTitle$branchSuffix';
    final newSessionId = await _storage.createSession(title: newTitle, topicId: topicId);

    // Save copied messages to new session
    await _storage.saveHistory(messagesToCopy, newSessionId);

    // Reload sessions
    await loadSessions();

    return newSessionId;
  }
}


final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return SessionsNotifier(ref, storage);
});
final selectedHistorySessionIdProvider = StateProvider<String?>((ref) => null);
final isHistorySidebarVisibleProvider = StateProvider<bool>((ref) => true);
final sessionSearchQueryProvider = StateProvider<String>((ref) => '');

class ChatSessionManager {
  final Map<String, ChatNotifier> _cache = {};
  final ChatStorage _storage;
  final Ref _ref;
  final StateController<int> _updateTrigger;
  ChatSessionManager(this._ref, this._storage, this._updateTrigger);
  ChatNotifier getOrCreate(String sessionId) {
    if (!_cache.containsKey(sessionId)) {
      _cache[sessionId] = ChatNotifier(
        ref: _ref,
        storage: _storage,
        sessionId: sessionId,
        onSessionCreated: (newId) {
          if (_cache.containsKey(sessionId)) {
            _cache[newId] = _cache.remove(sessionId)!;
          }
          // Restore missing navigation and session list refresh
          _ref.read(sessionsProvider.notifier).loadSessions();
          _ref.read(selectedHistorySessionIdProvider.notifier).state = newId;
        },
        onStateChanged: () {
          _updateTrigger.state++;
        },
      );
    }
    return _cache[sessionId]!;
  }

  void resetSession(String sessionId) {
    _cache.remove(sessionId)?.dispose();
    _updateTrigger.state++;
  }

  void disposeSession(String sessionId) {
    resetSession(sessionId);
  }

  void disposeAll() {
    for (final notifier in _cache.values) {
      notifier.dispose();
    }
    _cache.clear();
  }

  ChatState? getState(String sessionId) {
    return _cache[sessionId]?.currentState;
  }
}

final chatStateUpdateTriggerProvider = StateProvider<int>((ref) => 0);
final isSidebarExpandedProvider = StateProvider<bool>((ref) => false);
final desktopActiveTabProvider = StateProvider<int>((ref) => 0);
final chatSessionManagerProvider = Provider<ChatSessionManager>((ref) {
  final storage = ref.watch(chatStorageProvider);
  final updateTrigger = ref.watch(chatStateUpdateTriggerProvider.notifier);
  final manager = ChatSessionManager(ref, storage, updateTrigger);
  ref.onDispose(() => manager.disposeAll());
  return manager;
});
final historyChatProvider = Provider<ChatNotifier>((ref) {
  final manager = ref.watch(chatSessionManagerProvider);
  final sessionId = ref.watch(selectedHistorySessionIdProvider);
  ref.watch(chatStateUpdateTriggerProvider);
  if (sessionId == null) {
    return manager.getOrCreate('temp_empty');
  }
  return manager.getOrCreate(sessionId);
});
final historyChatStateProvider = Provider<ChatState>((ref) {
  final notifier = ref.watch(historyChatProvider);
  ref.watch(chatStateUpdateTriggerProvider);
  return notifier.currentState;
});
final chatSessionNotifierProvider = Provider.family<ChatNotifier, String>((ref, sessionId) {
  final manager = ref.watch(chatSessionManagerProvider);
  ref.watch(chatStateUpdateTriggerProvider);
  return manager.getOrCreate(sessionId);
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return ChatNotifier(ref: ref, storage: storage, sessionId: 'chat');
});
