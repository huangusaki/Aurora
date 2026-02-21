part of 'chat_provider.dart';

final llmServiceProvider = Provider<LLMService>((ref) {
  final settings = ref.watch(settingsProvider);
  return OpenAILLMService(settings);
});

final assistantMemoryServiceProvider = Provider<AssistantMemoryService>((ref) {
  final settingsStorage = ref.watch(settingsStorageProvider);
  final llmService = ref.watch(llmServiceProvider);
  final service = AssistantMemoryService(
      isar: settingsStorage.isar, llmService: llmService);
  ref.onDispose(service.dispose);
  return service;
});

final chatStorageProvider = Provider<ChatStorage>((ref) {
  final settingsStorage = ref.watch(settingsStorageProvider);
  return ChatStorage(settingsStorage);
});
final translationProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return ChatNotifier(ref: ref, storage: storage, sessionId: 'translation');
});

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  final storage = ref.watch(chatStorageProvider);
  return SessionsNotifier(ref, storage);
});
final selectedHistorySessionIdProvider = StateProvider<String?>((ref) => null);
final collapsedHistorySessionIdsProvider =
    StateProvider<Set<String>>((ref) => <String>{});
final isHistorySidebarVisibleProvider = StateProvider<bool>((ref) => true);
final sessionSearchQueryProvider = StateProvider<String>((ref) => '');

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
final chatSessionNotifierProvider =
    Provider.family<ChatNotifier, String>((ref, sessionId) {
  final manager = ref.watch(chatSessionManagerProvider);
  ref.watch(chatStateUpdateTriggerProvider);
  return manager.getOrCreate(sessionId);
});
