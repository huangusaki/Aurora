import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/openai_llm_service.dart';
import '../domain/message.dart';
import 'package:aurora/shared/services/llm_service.dart';
import '../data/chat_storage.dart';
import '../data/session_entity.dart';
import 'package:aurora/shared/services/tool_manager.dart'; // Import ToolManager
import 'package:fluent_ui/fluent_ui.dart';
import 'package:uuid/uuid.dart';

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
  final String? currentStreamReasoning; // New: Stream reasoning
  final double? currentReasoningTimer; // New: Timer for live reasoning
  final bool isStreamEnabled; // New: Stream toggle state
  final bool isLoadingHistory; // New: Flag for initial history load

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
    this.isStreamEnabled = true, // Default to true
    this.isLoadingHistory = false,
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
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasUnreadResponse: hasUnreadResponse ?? this.hasUnreadResponse,
      isAutoScrollEnabled: isAutoScrollEnabled ?? this.isAutoScrollEnabled,
      isStreaming: isStreaming ?? this.isStreaming,
      currentStreamContent: currentStreamContent ?? this.currentStreamContent,
      currentStreamReasoning: currentStreamReasoning ?? this.currentStreamReasoning,
      currentReasoningTimer: currentReasoningTimer ?? this.currentReasoningTimer,
      isStreamEnabled: isStreamEnabled ?? this.isStreamEnabled,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final ChatStorage _storage;
  String _sessionId;
  final void Function(String newId)? onSessionCreated;
  final void Function()? onStateChanged;
  bool _isAborted = false;
  double? _savedScrollOffset;
  
  // Per-session listeners for targeted rebuilds
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
  
  /// Add a listener that will be called when this session's state changes.
  void addLocalListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  /// Remove a previously added listener.
  void removeLocalListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  void _notifyLocalListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  @override
  set state(ChatState value) {
    super.state = value;
    onStateChanged?.call();
    _notifyLocalListeners(); // Notify local listeners too
  }
  
  /// Public getter for current state (avoids protected member access)
  ChatState get currentState => state;

  /// Public getter for saved scroll offset
  double? get savedScrollOffset => _savedScrollOffset;
  
  void setAutoScrollEnabled(bool enabled) {
    if (state.isAutoScrollEnabled != enabled) {
      state = state.copyWith(isAutoScrollEnabled: enabled);
    }
  }


  
  void saveScrollOffset(double offset) {
    _savedScrollOffset = offset;
    // No state update to prevent rebuilds
  }
  
  void abortGeneration() {
    _isAborted = true;
    state = state.copyWith(isLoading: false);
  }
  
  void markAsRead() {
    if (state.hasUnreadResponse) {
      state = state.copyWith(hasUnreadResponse: false);
    }
  }
  
  Future<void> _loadHistory() async {
    // Defer state modification to avoid Riverpod "provider modifying another provider during initialization" error.
    // This happens because _loadHistory is called from constructor, and state= triggers onStateChanged.
    await Future.microtask(() {});
    if (!mounted) return;
    
    state = state.copyWith(isLoadingHistory: true);
    final messages = await _storage.loadHistory(_sessionId);
    if (!mounted) return;
    // When loading history, we assume it's read unless told otherwise (could persist unread state in DB later)
    state = state.copyWith(messages: messages, isLoadingHistory: false);
  }

  Future<String> sendMessage(String? text,
      {List<String> attachments = const [], String? apiContent}) async {
    print('DEBUG: sendMessage called - text: $text');
    
    // If new text provided, validate it
    if (text != null && text.trim().isEmpty && attachments.isEmpty) return _sessionId;
    
    _isAborted = false; // Reset abort flag
    
    // Session handling
    if (text != null && (_sessionId == 'chat' || _sessionId == 'new_chat')) {
      final title = text.length > 20 ? '${text.substring(0, 20)}...' : text;
      final realId = await _storage.createSession(title: title);
      debugPrint('Created new session: $realId with title: $title');
      if (_sessionId == 'new_chat' && onSessionCreated != null) {
        onSessionCreated!(realId);
      }
      _sessionId = realId;
      // Load empty history or initialize? Usually createSession makes empty DB.
      // We don't need to reload, just update ID.
    }

    if (text != null) {
      final content = apiContent ?? text;
      final userMessage = Message.user(content, attachments: attachments);
      
      // Save user message
      await _storage.saveMessage(userMessage, _sessionId);
      
      // Force UI update to show user message immediately
      state = state.copyWith(
        messages: [...state.messages, userMessage],
      );
    }
    
    state = state.copyWith(isLoading: true, error: null, hasUnreadResponse: false);
    
    // Track index of first new AI/Tool message to save later
    final startSaveIndex = state.messages.length;

    try {
      // Use current state messages for API context
      // If we didn't add a user message (regeneration), we rely on existing history.
      final messagesForApi = List<Message>.from(state.messages);
      final settings = _ref.read(settingsProvider);
      final llmService = _ref.read(llmServiceProvider);
      // Instantiate ToolManager
      final toolManager = ToolManager();
      
      final currentModel = settings.activeProvider?.selectedModel;
      final currentProvider = settings.activeProvider?.name;
      
      var aiMsg = Message.ai('', model: currentModel, provider: currentProvider);
      state = state.copyWith(messages: [...state.messages, aiMsg]);
      
      
      // Determine if tools should be used
      List<Map<String, dynamic>>? tools;
      if (settings.isSearchEnabled) {
        tools = toolManager.getTools();
        print('DEBUG: sendMessage - Tools enabled. Count: ${tools.length}');
      } else {
        print('DEBUG: sendMessage - Tools disabled globally.');
      }

      // Loop for tool execution (Max 3 turns to prevent infinite loops)
      bool continueGeneration = true;
      int turns = 0;
      
      while (continueGeneration && turns < 3 && !_isAborted && mounted) {
        turns++;
        print('DEBUG: sendMessage - Turn $turns/5 started');
        continueGeneration = false; // Assume done unless tool call occurs
        
        // ... (lines 198-375 match existing structure, omitted in replace logic, need to only target changed lines? No, replace tool works on chunks)
        // I need to target specific blocks. I can't skip the middle.
        // I will do TWO replacements. 
        // 1. Loop definition.
        // 2. Cleanup logic.

        // Check stream mode (from global settings) BEFORE making API call
        if (settings.isStreamEnabled) {
          print('DEBUG: sendMessage - Stream Enabled: true');
          // Streaming mode - call streamResponse
          final responseStream = llmService.streamResponse(
            messagesForApi,
            attachments: attachments,
            tools: tools,
          );
          
          DateTime? reasoningStartTime;
          
          await for (final chunk in responseStream) {
            if (_isAborted || !mounted) break; // Check abort flag and mounted state
            
            // Track reasoning start
            if (chunk.reasoning != null && chunk.reasoning!.isNotEmpty) {
              reasoningStartTime ??= DateTime.now();
            }
            
            // Calculate duration if reasoning finished (content started)
            double? duration = aiMsg.reasoningDurationSeconds;
            if (duration == null && 
                reasoningStartTime != null && 
                chunk.content != null && 
                chunk.content!.isNotEmpty) {
              duration = DateTime.now().difference(reasoningStartTime).inMilliseconds / 1000.0;
            }

            // Update AI Message accumulator
            // If toolCalls are present, we need to accumulate them too
            // Note: ToolCalls in streams are usually built up across chunks. 
            // For simplicity, we'll assume the LLMService parses them correctly or we'd need complex merging logic here.
            // Our LLMService yields chunks with partial tool calls. We need to merge them.
            // TODO: simplified merging for now.

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
              // Merge tool calls
              toolCalls: _mergeToolCalls(aiMsg.toolCalls, chunk.toolCalls),
            );
            
            // Update UI
            final newMessages = List<Message>.from(state.messages);
            if (newMessages.isNotEmpty && newMessages.last.id == aiMsg.id) {
               newMessages.removeLast();
            }
            newMessages.add(aiMsg);
            if (mounted) state = state.copyWith(messages: newMessages);
          }
           
           if (!mounted) return aiMsg.id;

          // If reasoning finished but duration wasn't set (e.g. stream ended without content or pure reasoning)
          if (aiMsg.reasoningDurationSeconds == null && reasoningStartTime != null) {
             final duration = DateTime.now().difference(reasoningStartTime).inMilliseconds / 1000.0;
             aiMsg = aiMsg.copyWith(reasoningDurationSeconds: duration);
             // Verify UI update one last time
             final newMessages = List<Message>.from(state.messages);
             if (newMessages.isNotEmpty && newMessages.last.id == aiMsg.id) {
                 newMessages.removeLast();
             }
             newMessages.add(aiMsg);
             if (mounted) state = state.copyWith(messages: newMessages);
          }

          // Check if the final message has tool calls
          if (aiMsg.toolCalls != null && aiMsg.toolCalls!.isNotEmpty) {
             // Execute tools
             continueGeneration = true; // Loop again
             
             // 1. Add Assistant message (already in state, but ensure it's in `messagesForApi`)
             // Note: `messagesForApi` is a local disconnected list in this loop implementation?
             // Actually, we must update `messagesForApi` to include the AI response + Tool Outputs
             
             // Update history for next API call
             messagesForApi.add(aiMsg);

             // 2. Execute each tool
             for (final tc in aiMsg.toolCalls!) {
                String toolResult;
                try {
                  final args = jsonDecode(tc.arguments);  
                  toolResult = await toolManager.executeTool(tc.name, args, preferredEngine: settings.searchEngine);
                } catch (e) {
                  toolResult = jsonEncode({'error': e.toString()});
                }
                
                final toolMsg = Message.tool(toolResult, toolCallId: tc.id);
                messagesForApi.add(toolMsg);
                // Also update UI state to show the tool usage invisibly or visibly?
                // Usually tool outputs are hidden or shown as expandable.
                // For now, let's add them to state so `messagesForApi` logic stays consistent with state.
                state = state.copyWith(messages: [...state.messages, toolMsg]);
             }
             
             // Prepare for next Turn (Assistant Answer)
             aiMsg = Message.ai('', model: currentModel, provider: currentProvider);
             // Add placeholder for the *next* assistant response
             state = state.copyWith(messages: [...state.messages, aiMsg]);
          }

        } else {
          print('DEBUG: sendMessage - Stream Enabled: false');
          // Non-streaming mode
          final response = await llmService.getResponse(
            messagesForApi, 
            attachments: attachments,
            tools: tools
          );
          
          if (!_isAborted && mounted) {
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
              toolCalls: response.toolCalls?.map((tc) => ToolCall(id: tc.id ?? '', type: tc.type ?? 'function', name: tc.name ?? '', arguments: tc.arguments ?? '')).toList()
            );
            
            // Update UI
            final newMessages = List<Message>.from(state.messages);
            if (newMessages.isNotEmpty && newMessages.last.id == aiMsg.id) {
                newMessages.removeLast();
            }
            newMessages.add(aiMsg);
            state = state.copyWith(messages: newMessages);
            
            if (aiMsg.toolCalls != null && aiMsg.toolCalls!.isNotEmpty) {
               continueGeneration = true;
               messagesForApi.add(aiMsg);
               
               for (final tc in aiMsg.toolCalls!) {
                  String toolResult;
                  try {
                    final args = jsonDecode(tc.arguments);
                    toolResult = await toolManager.executeTool(tc.name, args, preferredEngine: settings.searchEngine);
                  } catch (e) {
                    toolResult = jsonEncode({'error': e.toString()});
                  }
                  final toolMsg = Message.tool(toolResult, toolCallId: tc.id);
                  messagesForApi.add(toolMsg);
                  state = state.copyWith(messages: [...state.messages, toolMsg]);
               }
               
               aiMsg = Message.ai('', model: currentModel, provider: currentProvider);
               state = state.copyWith(messages: [...state.messages, aiMsg]);
            }
          }
        }
      } // End while loop

      if (!_isAborted) {
        // Save the *final* conversation state 
        // (Note: Intermediate tool calls constitute valid history, so we should save all new messages)
        // We iterate and save messages that aren't saved yet? 
        // Or just save the *last* one? 
        // Correct way: Save all messages generated in this session turn.
        // For simplicity: We save the *final* AI message. Tool messages should also be saved if we want history context to work.
        // Current architecture: `saveMessage` writes one by one.
        // We need to ensure all tool messages + final AI answer are saved.
        
        // Find all unsaved messages (newly generated ones)
        final messages = state.messages;
        if (messages.length > startSaveIndex) {
          final unsaved = messages.sublist(startSaveIndex);
          for (final m in unsaved) {
             await _storage.saveMessage(m, _sessionId);
          }
        }
        
        // Generation complete, mark as unread
        if (mounted) state = state.copyWith(isLoading: false, hasUnreadResponse: true);
      }
    } catch (e, stack) {
      print('DEBUG: sendMessage - Error: $e\n$stack');
      if (!_isAborted && mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
    return _sessionId;
  }
  
  List<ToolCall>? _mergeToolCalls(List<ToolCall>? existing, List<ToolCallChunk>? chunks) {
    if (chunks == null || chunks.isEmpty) return existing;
    final merged = existing != null ? List<ToolCall>.from(existing) : <ToolCall>[];
    
    for (final chunk in chunks) {
       final index = chunk.index ?? 0;
       if (index >= merged.length) {
         // New tool call
         merged.add(ToolCall(
           id: chunk.id ?? '', 
           type: chunk.type ?? 'function', 
           name: chunk.name ?? '', 
           arguments: chunk.arguments ?? ''
         ));
       } else {
         // Append to existing
         final prev = merged[index];
         merged[index] = ToolCall(
           id: (prev.id == '' ? (chunk.id ?? '') : prev.id),
           type: (prev.type == 'function' ? (chunk.type ?? 'function') : prev.type),
           name: prev.name + (chunk.name ?? ''),
           arguments: prev.arguments + (chunk.arguments ?? '')
         );
       }
    }
    return merged;
  }

  Future<void> deleteMessage(String id) async {
    final newMessages = state.messages.where((m) => m.id != id).toList();
    state = state.copyWith(messages: newMessages);
    await _storage.deleteMessage(id);
  }

  Future<void> editMessage(String id, String newContent,
      {List<String>? newAttachments}) async {
    final index = state.messages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final oldMsg = state.messages[index];
    final updatedAttachments = newAttachments ?? oldMsg.attachments;
    List<String> updatedImages = oldMsg.images;
    if (newAttachments != null) {
      final imageExts = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
      updatedImages = newAttachments.where((path) {
        final ext = path.split('.').last.toLowerCase();
        return imageExts.contains(ext);
      }).toList();
    }
    final newMsg = Message(
      id: oldMsg.id,
      content: newContent,
      isUser: oldMsg.isUser,
      timestamp: oldMsg.timestamp,
      reasoningContent: oldMsg.reasoningContent,
      attachments: updatedAttachments,
      images: updatedImages,
    );
    final newMessages = List<Message>.from(state.messages);
    newMessages[index] = newMsg;
    state = state.copyWith(messages: newMessages);
    await _storage.updateMessage(newMsg);
  }

  Future<void> regenerateResponse(String rootMessageId) async {
    final index = state.messages.indexWhere((m) => m.id == rootMessageId);
    if (index == -1) return;
    _isAborted = false; // Reset abort flag
    final rootMsg = state.messages[index];
    List<Message> historyToKeep;
    
    // Determine history to keep
    if (rootMsg.isUser) {
      // If user message selected: Keep up to this User message (inclusive)
      // Then generate new assistant response.
      historyToKeep = state.messages.sublist(0, index + 1);
    } else {
      // If assistant message selected: Keep up to the PREVIOUS message (User usually)
      if (index == 0) return;
      historyToKeep = state.messages.sublist(0, index);
    }

    final oldMessages = state.messages;
    // Update state to show pruned history immediately and loading
    state = state.copyWith(messages: historyToKeep, isLoading: true, error: null);
    
    // Delete valid pruned messages from database
    final idsToDelete =
        oldMessages.skip(historyToKeep.length).map((m) => m.id).toList();
    for (final mid in idsToDelete) {
      await _storage.deleteMessage(mid);
    }
    
    // Trigger generation using existing history
    await sendMessage(null);
  }

  Future<void> clearContext() async {
    if (_sessionId == 'new_chat' || _sessionId == 'translation') {
      state = state.copyWith(messages: [], isLoading: false, error: null); // Keep other settings
      return;
    }
    await _storage.clearSessionMessages(_sessionId);
    state = state.copyWith(messages: []);
  }

  void toggleSearch() {
    _ref.read(settingsProvider.notifier).toggleSearchEnabled();
  }

  void setSearchEngine(SearchEngine engine) {
    _ref.read(settingsProvider.notifier).setSearchEngine(engine.name);
  }
}

final chatStorageProvider = Provider<ChatStorage>((ref) {
  final settingsStorage = ref.watch(settingsStorageProvider);
  return ChatStorage(settingsStorage);
});
final translationProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return ChatNotifier(
      ref: ref,
      storage: storage,
      sessionId: 'translation');
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
    // 1. Cleanup empty sessions
    await _storage.cleanupEmptySessions();
    
    // 2. Load sessions
    await loadSessions();
    
    // 3. Preload all session messages for instant switching
    _storage.preloadAllSessions(); // Fire and forget - don't await to avoid blocking UI
    
    // 4. Restore last session
    final settings = await _ref.read(settingsStorageProvider).loadAppSettings();
    final lastId = settings?.lastSessionId;
    
    if (lastId != null && state.sessions.any((s) => s.sessionId == lastId)) {
      _ref.read(selectedHistorySessionIdProvider.notifier).state = lastId;
    } else {
      // If no valid last session, maybe create new or select first?
      // Default is null or 'new_chat' logic handled by UI.
      // If we want "Immediate New Chat" logic even on first launch:
      // await startNewSession();
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
    final id = await _storage.createSession(title: 'New Chat');
    await loadSessions();
    _ref.read(selectedHistorySessionIdProvider.notifier).state = id;
  }

  Future<void> deleteSession(String id) async {
    await _storage.deleteSession(id);
    await loadSessions();
    
    // If deleted session was selected, select another or none
    final selected = _ref.read(selectedHistorySessionIdProvider);
    if (selected == id) {
       _ref.read(selectedHistorySessionIdProvider.notifier).state = null;
    }
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

/// Manages cached ChatNotifier instances to preserve state across session switches
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
          // Migrate cache key when session is created from new_chat
          if (_cache.containsKey(sessionId)) {
            _cache[newId] = _cache.remove(sessionId)!;
          }
          _ref.read(sessionsProvider.notifier).loadSessions();
          _ref.read(selectedHistorySessionIdProvider.notifier).state = newId;
        },
        onStateChanged: () {
          // Trigger UI rebuild when state changes
          _updateTrigger.state++;
        },
      );
    }
    return _cache[sessionId]!;
  }
  
  void disposeSession(String sessionId) {
    _cache.remove(sessionId)?.dispose();
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

/// Trigger for rebuilding UI when any cached session state changes
final chatStateUpdateTriggerProvider = StateProvider<int>((ref) => 0);

/// Global provider for Desktop Sidebar state
final isSidebarExpandedProvider = StateProvider<bool>((ref) => false);

/// Global provider for Desktop Active Tab Index
final desktopActiveTabProvider = StateProvider<int>((ref) => 0);

final chatSessionManagerProvider = Provider<ChatSessionManager>((ref) {
  // Do not watch settings/service to avoid rebuilds
  final storage = ref.watch(chatStorageProvider);
  final updateTrigger = ref.watch(chatStateUpdateTriggerProvider.notifier);
  
  final manager = ChatSessionManager(ref, storage, updateTrigger);
  ref.onDispose(() => manager.disposeAll());
  return manager;
});

final historyChatProvider = Provider<ChatNotifier>((ref) {
  final manager = ref.watch(chatSessionManagerProvider);
  final sessionId = ref.watch(selectedHistorySessionIdProvider);
  // Watch the trigger to rebuild when state changes
  ref.watch(chatStateUpdateTriggerProvider);
  
  if (sessionId == null) {
    return manager.getOrCreate('temp_empty');
  }
  return manager.getOrCreate(sessionId);
});

/// Provider to watch the current chat state (for UI rebuilds)
final historyChatStateProvider = Provider<ChatState>((ref) {
  final notifier = ref.watch(historyChatProvider);
  // Watch the trigger to rebuild when state changes
  ref.watch(chatStateUpdateTriggerProvider);
  return notifier.currentState;
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return ChatNotifier(
      ref: ref,
      storage: storage,
      sessionId: 'chat');
});


