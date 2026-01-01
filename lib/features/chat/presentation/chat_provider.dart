import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/openai_llm_service.dart';
import '../domain/message.dart';
import 'package:aurora/shared/services/llm_service.dart';
import '../data/chat_storage.dart'; // Added Copy
import '../data/session_entity.dart';

// Service Provider
final llmServiceProvider = Provider<LLMService>((ref) {
  final settings = ref.watch(settingsProvider);
  return OpenAILLMService(settings);
});

// Chat State
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error; // Added error field

  const ChatState({this.messages = const [], this.isLoading = false, this.error});

  ChatState copyWith({List<Message>? messages, bool? isLoading, String? error}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error, 
    );
  }
}

// Chat Controller
class ChatNotifier extends StateNotifier<ChatState> {
  final LLMService _llmService;
  final SettingsState _settings;
  final ChatStorage _storage;
  String _sessionId;
  final void Function(String newId)? onSessionCreated;

  ChatNotifier({
    required LLMService llmService, 
    required SettingsState settings,
    required ChatStorage storage,
    required String sessionId,
    this.onSessionCreated,
  }) : _llmService = llmService, 
       _settings = settings,
       _storage = storage,
       _sessionId = sessionId,
       super(const ChatState()) { 
         // Only load history if it's a real session
         if (_sessionId != 'chat' && _sessionId != 'new_chat') {
            _loadHistory();
         }
       }

  Future<void> _loadHistory() async {
    final messages = await _storage.loadHistory(_sessionId);
    state = state.copyWith(messages: messages);
  }

  Future<String> sendMessage(String text, {List<String> attachments = const [], String? apiContent}) async {
    if (text.trim().isEmpty && attachments.isEmpty) return _sessionId;

    // Auto-create session if this is the default 'chat' session OR 'new_chat'
    if (_sessionId == 'chat' || _sessionId == 'new_chat') {
      final title = text.length > 20 ? '${text.substring(0, 20)}...' : text;
      
      final realId = await _storage.createSession(title: title);
      
      if (_sessionId == 'new_chat' && onSessionCreated != null) {
         onSessionCreated!(realId);
      }
      
      _sessionId = realId;
    }

    final userMessage = Message.user(text, attachments: attachments);

    // Save User Message
    await _storage.saveMessage(userMessage, _sessionId);
    
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Prepare messages for API (Use apiContent if provided)
      List<Message> messagesForApi = state.messages;
      if (apiContent != null) {
        messagesForApi = List<Message>.from(state.messages);
        messagesForApi.removeLast(); // Remove the display message
        messagesForApi.add(Message.user(apiContent, attachments: attachments)); // Add the API prompt message
      }

      final responseStream = _llmService.streamResponse(messagesForApi, attachments: attachments);
      
      final activeModel = _settings.selectedModel;
      final activeProvider = _settings.activeProvider?.name;

      var aiMsg = Message.ai('', model: activeModel, provider: activeProvider);
      state = state.copyWith(messages: [...state.messages, aiMsg]);

      await for (final chunk in responseStream) {
        aiMsg = Message(
          id: aiMsg.id, 
          content: aiMsg.content + (chunk.content ?? ''),
          reasoningContent: (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
          isUser: false, 
          timestamp: aiMsg.timestamp,
          attachments: aiMsg.attachments,
          images: [...aiMsg.images, ...chunk.images],
          model: aiMsg.model,
          provider: aiMsg.provider,
        );

        final newMessages = List<Message>.from(state.messages);
        newMessages.removeLast();
        newMessages.add(aiMsg);
        
        state = state.copyWith(messages: newMessages);
      }
      
      // Save Final AI Message
      await _storage.saveMessage(aiMsg, _sessionId);
      
    } catch (e) {
       state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }

    return _sessionId;
  }

  Future<void> deleteMessage(String id) async {
    // Optimistic update
    final newMessages = state.messages.where((m) => m.id != id).toList();
    state = state.copyWith(messages: newMessages);
    
    await _storage.deleteMessage(id);
  }

  Future<void> editMessage(String id, String newContent, {List<String>? newAttachments}) async {
    final index = state.messages.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final oldMsg = state.messages[index];
    
    // If newAttachments is provided, use it. Otherwise keep old.
    // Also, if newAttachments is provided, we might need to update 'images' if they are derived from attachments.
    // For simplicity, we assume 'attachments' stores file paths and 'images' implies strictly image assets.
    // The previous logic for sendMessage separates them. 
    // If we just support generic attachments list update:
    
    final updatedAttachments = newAttachments ?? oldMsg.attachments;
    // We should probably recalculate 'images' if attachments changed, 
    // but assuming simple mapping for now directly from attachments if they are images.
    // Let's just update both if newAttachments matches image extensions.
    
    List<String> updatedImages = oldMsg.images;
    if (newAttachments != null) {
       // Filter images from new attachments
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
     // Logic: 
     // 1. Find the message with this ID.
     // 2. If it's a User message: Delete all messages AFTER this one. Then stream response.
     // 3. If it's an AI message: Delete THIS message. Delete all messages AFTER this one (unlikely but possible). Then stream response based on history.
     
     final index = state.messages.indexWhere((m) => m.id == rootMessageId);
     if (index == -1) return;
     
     final rootMsg = state.messages[index];
     List<Message> historyToKeep;
     List<String> lastAttachments = [];
     String? lastApiContent; // Not easily recoverable unless stored, usually just use content.
     
     if (rootMsg.isUser) {
        // User clicked regenerate on their own message -> Keep this message, delete subsequent AI response
        historyToKeep = state.messages.sublist(0, index + 1);
        lastAttachments = rootMsg.attachments;
        // Last message IS the user prompt.
     } else {
        // User clicked regenerate on AI message -> Delete this AI message
        // The previous message (index-1) should be User.
        if (index == 0) return; // Cannot regenerate AI message if it's the very first one (orphaned?)
        historyToKeep = state.messages.sublist(0, index);
        // The last message in historyToKeep is the User prompt.
        final lastUserMsg = historyToKeep.last;
        lastAttachments = lastUserMsg.attachments;
     }

     // 1. Capture old messages for DB pruning
     final oldMessages = state.messages;

     // 2. Update State (Prune)
     state = state.copyWith(messages: historyToKeep, isLoading: true, error: null);
     
     // 3. Sync pruning to DB (Delete everything after the cutoff)
     final idsToDelete = oldMessages
         .skip(historyToKeep.length)
         .map((m) => m.id)
         .toList();

     for (final mid in idsToDelete) {
        await _storage.deleteMessage(mid);
     }

     // 3. Trigger Stream
     try {
        final messagesForApi = List<Message>.from(historyToKeep);
        // Stream Response
        final responseStream = _llmService.streamResponse(messagesForApi, attachments: lastAttachments);
      
        var aiMsg = Message.ai('');
        state = state.copyWith(messages: [...state.messages, aiMsg]);

        await for (final chunk in responseStream) {
          aiMsg = Message(
            id: aiMsg.id, 
            content: aiMsg.content + (chunk.content ?? ''),
            reasoningContent: (aiMsg.reasoningContent ?? '') + (chunk.reasoning ?? ''),
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
        
        await _storage.saveMessage(aiMsg, _sessionId);

     } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
     } finally {
        state = state.copyWith(isLoading: false);
     }
  }

  Future<void> clearContext() async {
    if (_sessionId == 'new_chat' || _sessionId == 'translation') {
       state = const ChatState();
       return;
    }
    
    // Clear in DB
    await _storage.clearSessionMessages(_sessionId);
    // Clear in State
    state = const ChatState();
  }
}

// Storage Provider
final chatStorageProvider = Provider<ChatStorage>((ref) {
  final settingsStorage = ref.watch(settingsStorageProvider);
  return ChatStorage(settingsStorage);
});

// Provider for Translation Tab
final translationProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final service = ref.watch(llmServiceProvider);
  final settings = ref.watch(settingsProvider);
  final storage = ref.watch(chatStorageProvider);
  return ChatNotifier(llmService: service, settings: settings, storage: storage, sessionId: 'translation');
});

// Sessions State
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

final sessionsProvider = StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return SessionsNotifier(storage);
});

// ... Keep existing ChatNotifier but add support for updating session if needed OR just use a Key to rebuild it.

// Provider for Chat Tab
// We need a way to change the session ID dynamically.
// Let's use a "SelectedSessionProvider" for the History View.

final selectedHistorySessionIdProvider = StateProvider<String?>((ref) => null);
final isHistorySidebarVisibleProvider = StateProvider<bool>((ref) => true);

// History Chat Provider - specific to the selected history session
final historyChatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final service = ref.watch(llmServiceProvider);
  final settings = ref.watch(settingsProvider);
  final storage = ref.watch(chatStorageProvider);
  final sessionId = ref.watch(selectedHistorySessionIdProvider);
  
  if (sessionId == null) {
      // Return empty/loading state if no session selected
      return ChatNotifier(llmService: service, settings: settings, storage: storage, sessionId: 'temp_empty');
  }
  
  return ChatNotifier(
    llmService: service, 
    settings: settings, 
    storage: storage, 
    sessionId: sessionId,
    onSessionCreated: (newId) {
       // When 'new_chat' becomes a real session ID:
       // 1. Refresh global sessions list so the new item appears
       ref.read(sessionsProvider.notifier).loadSessions();
       // Note: We DO NOT switch the selected ID here yet. 
       // Switching effectively destroys this Notifier instance and creates a new one.
       // We wait until the message stream is finished (in the UI) to switch.
    }
  );
});

// Main Chat Tab Provider (Default 'chat')
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final service = ref.watch(llmServiceProvider);
  final settings = ref.watch(settingsProvider);
  final storage = ref.watch(chatStorageProvider);
  return ChatNotifier(llmService: service, settings: settings, storage: storage, sessionId: 'chat');
});

