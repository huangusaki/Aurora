part of 'chat_provider.dart';

class SessionsState {
  final List<SessionEntity> sessions;
  final bool isLoading;
  SessionsState({this.sessions = const [], this.isLoading = false});
}

class SessionsNotifier extends StateNotifier<SessionsState> {
  static const Duration _maintenanceInterval = Duration(hours: 24);
  static const int _desktopPreloadLimit = 24;

  final ChatStorage _storage;
  final Ref _ref;
  SessionsNotifier(this._ref, this._storage) : super(SessionsState()) {
    _init();
  }

  void _cleanupCollapsedSessionIds(List<SessionEntity> sessions) {
    final collapsed = _ref.read(collapsedHistorySessionIdsProvider);
    if (collapsed.isEmpty) return;
    final validIds = sessions.map((s) => s.sessionId).toSet();
    final nextCollapsed = collapsed.where(validIds.contains).toSet();
    if (nextCollapsed.length != collapsed.length) {
      _ref.read(collapsedHistorySessionIdsProvider.notifier).state =
          nextCollapsed;
    }
  }

  void ensureSessionVisible(String sessionId) {
    if (state.sessions.isEmpty) return;
    final sessionMap = {for (final s in state.sessions) s.sessionId: s};
    final collapsed =
        Set<String>.from(_ref.read(collapsedHistorySessionIdsProvider));
    var changed = false;

    SessionEntity? current = sessionMap[sessionId];
    while (current != null) {
      final parentId = current.parentSessionId;
      if (parentId == null || parentId.isEmpty) break;
      if (collapsed.remove(parentId)) {
        changed = true;
      }
      current = sessionMap[parentId];
    }

    if (changed) {
      _ref.read(collapsedHistorySessionIdsProvider.notifier).state = collapsed;
    }
  }

  Future<void> _init() async {
    final initSw = Stopwatch()..start();
    final isMobile = PlatformUtils.isMobile;
    if (isMobile) {
      _ref.read(sessionRestoreInProgressProvider.notifier).state = true;
    }

    final loadSw = Stopwatch()..start();
    await loadSessions();
    loadSw.stop();
    debugPrint(
        '[STARTUP] SessionsNotifier.loadSessions ${loadSw.elapsedMilliseconds}ms (${state.sessions.length} sessions)');

    final settings = await _ref.read(settingsStorageProvider).loadAppSettings();
    final restoreLast = settings?.restoreLastSessionOnLaunch ?? true;
    final lastId = settings?.lastSessionId;
    final lastTopicId = settings?.lastTopicId;
    debugPrint(
        'Restoring session (enabled=$restoreLast). lastId: $lastId, lastTopicId: $lastTopicId');

    var targetSessionId = 'new_chat';
    var hasRestorableLastSession = false;

    if (restoreLast) {
      if (lastTopicId != null) {
        final topicId = int.tryParse(lastTopicId);
        _ref.read(selectedTopicIdProvider.notifier).state = topicId;
        debugPrint('Restored topic id: $topicId');
      }
      if (lastId != null && state.sessions.any((s) => s.sessionId == lastId)) {
        targetSessionId = lastId;
        hasRestorableLastSession = true;
      }
    } else {
      _ref.read(selectedTopicIdProvider.notifier).state = null;
    }

    if (isMobile && hasRestorableLastSession) {
      // Show loading state first, then restore directly to the previous session.
      final deferredTarget = targetSessionId;
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _ref.read(selectedHistorySessionIdProvider.notifier).state =
            deferredTarget;
        _ref.read(sessionRestoreInProgressProvider.notifier).state = false;
        debugPrint(
            '[STARTUP] SessionsNotifier.mobile restored session: $deferredTarget');
      });
    } else {
      _ref.read(selectedHistorySessionIdProvider.notifier).state =
          targetSessionId;
      if (isMobile) {
        _ref.read(sessionRestoreInProgressProvider.notifier).state = false;
      }
    }
    initSw.stop();
    debugPrint('[STARTUP] SessionsNotifier._init total '
        '${initSw.elapsedMilliseconds}ms');

    unawaited(_runDeferredStartupMaintenance());
  }

  Future<void> _runDeferredStartupMaintenance() async {
    final totalSw = Stopwatch()..start();
    try {
      // Let first frame and early interactions complete before heavy DB work.
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final settingsStorage = _ref.read(settingsStorageProvider);
      final now = DateTime.now();
      final lastRun = await settingsStorage.loadStartupMaintenanceLastRun();
      final shouldRunMaintenance =
          lastRun == null || now.difference(lastRun) >= _maintenanceInterval;

      if (shouldRunMaintenance) {
        final maintenanceSw = Stopwatch()..start();
        await _storage.cleanupEmptySessions();
        await _storage.backfillSessionLastUserMessageTimes();
        await loadSessions();
        await settingsStorage.saveStartupMaintenanceLastRun(now);
        maintenanceSw.stop();
        debugPrint('[STARTUP] SessionsNotifier.deferredMaintenance '
            '${maintenanceSw.elapsedMilliseconds}ms');
      } else {
        debugPrint('[STARTUP] SessionsNotifier.deferredMaintenance skipped '
            '(lastRun=$lastRun)');
      }

      if (PlatformUtils.isDesktop) {
        final preloadSw = Stopwatch()..start();
        await _storage.preloadAllSessions(limit: _desktopPreloadLimit);
        preloadSw.stop();
        debugPrint('[STARTUP] SessionsNotifier.deferredPreload '
            '${preloadSw.elapsedMilliseconds}ms '
            '(limit=$_desktopPreloadLimit)');
      }
    } catch (e, st) {
      debugPrint('[STARTUP] SessionsNotifier.deferred failed: $e\n$st');
    } finally {
      totalSw.stop();
      debugPrint('[STARTUP] SessionsNotifier.deferred total '
          '${totalSw.elapsedMilliseconds}ms');
    }
  }

  Future<void> loadSessions() async {
    final sw = Stopwatch()..start();
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
    _cleanupCollapsedSessionIds(sessions);
    state = SessionsState(sessions: sessions, isLoading: false);
    sw.stop();
    debugPrint(
        '[STARTUP] SessionsNotifier.loadSessionsInternal ${sw.elapsedMilliseconds}ms (order=${order.length}, sessions=${sessions.length})');
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

  Future<void> reorderSessionById({
    required String draggedSessionId,
    String? beforeSessionId,
  }) async {
    final items = List<SessionEntity>.from(state.sessions);
    final draggedIndex =
        items.indexWhere((s) => s.sessionId == draggedSessionId);
    if (draggedIndex == -1) return;

    final dragged = items.removeAt(draggedIndex);
    int insertIndex;
    if (beforeSessionId == null) {
      insertIndex = items.length;
    } else {
      insertIndex = items.indexWhere((s) => s.sessionId == beforeSessionId);
      if (insertIndex == -1) {
        insertIndex = items.length;
      }
    }
    items.insert(insertIndex, dragged);

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
      final collapsed =
          Set<String>.from(_ref.read(collapsedHistorySessionIdsProvider));
      if (collapsed.remove(sessionId)) {
        _ref.read(collapsedHistorySessionIdsProvider.notifier).state =
            collapsed;
      }
      await loadSessions();
    }
  }

  Future<void> renameSession(String id, String newTitle) async {
    await _storage.updateSessionTitle(id, newTitle);
    await loadSessions();
  }

  Future<void> deleteSession(String id) async {
    final selectedId = _ref.read(selectedHistorySessionIdProvider);
    final deletedIds = await _storage.deleteSessionTree(id);
    if (deletedIds.isEmpty) return;

    // Explicitly reset the session in manager to clear memory and cache
    for (final deletedId in deletedIds) {
      _ref.read(chatSessionManagerProvider).resetSession(deletedId);
    }

    final collapsed =
        Set<String>.from(_ref.read(collapsedHistorySessionIdsProvider))
          ..removeWhere(deletedIds.contains);
    _ref.read(collapsedHistorySessionIdsProvider.notifier).state = collapsed;

    await loadSessions();

    // If we deleted the currently active session, move to the next best one
    if (selectedId == null || deletedIds.contains(selectedId)) {
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
    final presetId = originalSession?.presetId;

    // Create a copy of messages up to and including the target
    final messagesToCopy = messages.sublist(0, targetIndex + 1);

    // Create new session with branch name
    final newTitle = '$originalTitle$branchSuffix';
    final newSessionId = await _storage.createSession(
      title: newTitle,
      topicId: topicId,
      presetId: presetId,
      parentSessionId: originalSessionId,
    );

    // Save copied messages to new session
    await _storage.saveHistory(messagesToCopy, newSessionId);

    // Reload sessions
    await loadSessions();
    ensureSessionVisible(newSessionId);

    return newSessionId;
  }
}
