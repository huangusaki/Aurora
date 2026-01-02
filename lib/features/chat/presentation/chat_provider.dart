import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/openai_llm_service.dart';
import '../domain/message.dart';
import 'package:aurora/shared/services/llm_service.dart';
import '../data/chat_storage.dart';
import '../data/session_entity.dart';

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
  final double? scrollOffset;
  const ChatState(
      {this.messages = const [],
      this.isLoading = false,
      this.error,
      this.hasUnreadResponse = false,
      this.isAutoScrollEnabled = true,
      this.scrollOffset});
  ChatState copyWith(
      {List<Message>? messages,
      bool? isLoading,
      String? error,
      bool? hasUnreadResponse,
      bool? isAutoScrollEnabled,
      double? scrollOffset}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasUnreadResponse: hasUnreadResponse ?? this.hasUnreadResponse,
      isAutoScrollEnabled: isAutoScrollEnabled ?? this.isAutoScrollEnabled,
      scrollOffset: scrollOffset ?? this.scrollOffset,
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
  
  @override
  set state(ChatState value) {
    super.state = value;
    onStateChanged?.call();
  }
  
  /// Public getter for current state (avoids protected member access)
  ChatState get currentState => state;
  
  void setAutoScrollEnabled(bool enabled) {
    if (state.isAutoScrollEnabled != enabled) {
      state = state.copyWith(isAutoScrollEnabled: enabled);
    }
  }
  
  void updateScrollOffset(double offset) {
    state = state.copyWith(scrollOffset: offset);
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
    final messages = await _storage.loadHistory(_sessionId);
    if (!mounted) return;
    // When loading history, we assume it's read unless told otherwise (could persist unread state in DB later)
    state = state.copyWith(messages: messages);
  }

  Future<String> sendMessage(String text,
      {List<String> attachments = const [], String? apiContent}) async {
    if (text.trim().isEmpty && attachments.isEmpty) return _sessionId;
    _isAborted = false; // Reset abort flag
    if (_sessionId == 'chat' || _sessionId == 'new_chat') {
      final title = text.length > 20 ? '${text.substring(0, 20)}...' : text;
      final realId = await _storage.createSession(title: title);
      debugPrint('Created new session: $realId with title: $title');
      if (_sessionId == 'new_chat' && onSessionCreated != null) {
        onSessionCreated!(realId);
      }
      _sessionId = realId;
    }
    final userMessage = Message.user(text, attachments: attachments);
    await _storage.saveMessage(userMessage, _sessionId);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
      hasUnreadResponse: false, // Reset unread state when sending new message
    );
    try {
      List<Message> messagesForApi = state.messages;
      if (apiContent != null) {
        messagesForApi = List<Message>.from(state.messages);
        messagesForApi.removeLast();
        messagesForApi.add(Message.user(apiContent, attachments: attachments));
      }
      final settings = _ref.read(settingsProvider);
      final llmService = _ref.read(llmServiceProvider);
      
      final currentModel = settings.activeProvider?.selectedModel;
      final currentProvider = settings.activeProvider?.name;
      
      final responseStream = llmService.streamResponse(
        messagesForApi,
        attachments: attachments,
      );
      var aiMsg = Message.ai('', model: currentModel, provider: currentProvider);
      state = state.copyWith(messages: [...state.messages, aiMsg]);
      
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
        );
        final newMessages = List<Message>.from(state.messages);
        newMessages.removeLast();
        newMessages.add(aiMsg);
        if (mounted) state = state.copyWith(messages: newMessages);
      }
      
      if (!mounted) return aiMsg.id;

      // If reasoning finished ...
      
      // If reasoning finished but duration wasn't set (e.g. stream ended without content or pure reasoning)
      if (aiMsg.reasoningDurationSeconds == null && reasoningStartTime != null) {
         final duration = DateTime.now().difference(reasoningStartTime).inMilliseconds / 1000.0;
         aiMsg = Message(
          id: aiMsg.id,
          content: aiMsg.content,
          reasoningContent: aiMsg.reasoningContent,
          isUser: false,
          timestamp: aiMsg.timestamp,
          attachments: aiMsg.attachments,
          images: aiMsg.images,
          model: aiMsg.model,
          provider: aiMsg.provider,
          reasoningDurationSeconds: duration,
        );
        final newMessages = List<Message>.from(state.messages);
        newMessages.removeLast();
        newMessages.add(aiMsg);
        if (mounted) state = state.copyWith(messages: newMessages);
      }

      if (!_isAborted) {
        await _storage.saveMessage(aiMsg, _sessionId);
        // Generation complete, mark as unread (will be cleared if user is viewing)
        if (mounted) state = state.copyWith(isLoading: false, hasUnreadResponse: true);
      }
    } catch (e) {
      if (!_isAborted && mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
    return _sessionId;
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
    List<String> lastAttachments = [];
    String? lastApiContent;
    if (rootMsg.isUser) {
      historyToKeep = state.messages.sublist(0, index + 1);
      lastAttachments = rootMsg.attachments;
    } else {
      if (index == 0) return;
      historyToKeep = state.messages.sublist(0, index);
      final lastUserMsg = historyToKeep.last;
      lastAttachments = lastUserMsg.attachments;
    }
    final oldMessages = state.messages;
    state =
        state.copyWith(messages: historyToKeep, isLoading: true, error: null);
    final idsToDelete =
        oldMessages.skip(historyToKeep.length).map((m) => m.id).toList();
    for (final mid in idsToDelete) {
      await _storage.deleteMessage(mid);
    }
    try {
      final messagesForApi = List<Message>.from(historyToKeep);
      final llmService = _ref.read(llmServiceProvider);
      final responseStream = llmService.streamResponse(messagesForApi,
          attachments: lastAttachments);
      var aiMsg = Message.ai('');
      state = state.copyWith(messages: [...state.messages, aiMsg]);
      await for (final chunk in responseStream) {
        if (_isAborted) break; // Check abort flag
        aiMsg = Message(
          id: aiMsg.id,
          content: aiMsg.content + (chunk.content ?? ''),
          reasoningContent:
              (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
          isUser: false,
          timestamp: aiMsg.timestamp,
          attachments: aiMsg.attachments,
          images: [...aiMsg.images, ...chunk.images],
        );
        final newMessages = List<Message>.from(state.messages);
        newMessages.removeLast();
        newMessages.add(aiMsg);
        state = state.copyWith(messages: newMessages);
      }
      if (!_isAborted) {
        await _storage.saveMessage(aiMsg, _sessionId);
      }
    } catch (e) {
      if (!_isAborted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> clearContext() async {
    if (_sessionId == 'new_chat' || _sessionId == 'translation') {
      state = const ChatState();
      return;
    }
    await _storage.clearSessionMessages(_sessionId);
    state = const ChatState();
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
  SessionsNotifier(this._storage) : super(SessionsState()) {
    loadSessions();
  }
  Future<void> loadSessions() async {
    state = SessionsState(sessions: state.sessions, isLoading: true);
    final sessions = await _storage.loadSessions();
    state = SessionsState(sessions: sessions, isLoading: false);
  }

  Future<String> createNewSession(String title) async {
    final id = await _storage.createSession(title: title);
    await loadSessions();
    return id;
  }

  Future<void> deleteSession(String id) async {
    await _storage.deleteSession(id);
    await loadSessions();
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return SessionsNotifier(storage);
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


