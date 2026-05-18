import 'package:aurora/shared/riverpod_legacy.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

import '../data/mcp_bindings_storage.dart';
import '../domain/mcp_server_config.dart';

class McpBindingsState {
  final Map<String, List<String>> assistantOverrides;
  final Map<String, List<String>> sessionOverrides;
  final bool isLoading;
  final String? error;

  const McpBindingsState({
    this.assistantOverrides = const {},
    this.sessionOverrides = const {},
    this.isLoading = false,
    this.error,
  });

  McpBindingsState copyWith({
    Map<String, List<String>>? assistantOverrides,
    Map<String, List<String>>? sessionOverrides,
    bool? isLoading,
    String? error,
  }) {
    return McpBindingsState(
      assistantOverrides: assistantOverrides ?? this.assistantOverrides,
      sessionOverrides: sessionOverrides ?? this.sessionOverrides,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class McpBindingsNotifier extends StateNotifier<McpBindingsState> {
  final McpBindingsStorage _storage = McpBindingsStorage();
  bool _hasLoaded = false;

  McpBindingsNotifier() : super(const McpBindingsState());

  Future<void> load() async {
    if (_hasLoaded) return;
    _hasLoaded = true;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _storage.load();
      state = state.copyWith(
        assistantOverrides: data.assistant,
        sessionOverrides: data.session,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<String>? assistantOverride(String assistantId) {
    return state.assistantOverrides[assistantId];
  }

  List<String>? sessionOverride(String sessionId) {
    return state.sessionOverrides[sessionId];
  }

  Future<void> setAssistantOverride(String assistantId, List<String> serverIds) async {
    final next = Map<String, List<String>>.from(state.assistantOverrides);
    next[assistantId] = List<String>.from(serverIds);
    state = state.copyWith(assistantOverrides: next, error: null);
    await _storage.save(McpBindingsData(
      assistant: next,
      session: state.sessionOverrides,
    ));
  }

  Future<void> clearAssistantOverride(String assistantId) async {
    final next = Map<String, List<String>>.from(state.assistantOverrides);
    next.remove(assistantId);
    state = state.copyWith(assistantOverrides: next, error: null);
    await _storage.save(McpBindingsData(
      assistant: next,
      session: state.sessionOverrides,
    ));
  }

  Future<void> setSessionOverride(String sessionId, List<String> serverIds) async {
    final next = Map<String, List<String>>.from(state.sessionOverrides);
    next[sessionId] = List<String>.from(serverIds);
    state = state.copyWith(sessionOverrides: next, error: null);
    await _storage.save(McpBindingsData(
      assistant: state.assistantOverrides,
      session: next,
    ));
  }

  Future<void> clearSessionOverride(String sessionId) async {
    final next = Map<String, List<String>>.from(state.sessionOverrides);
    next.remove(sessionId);
    state = state.copyWith(sessionOverrides: next, error: null);
    await _storage.save(McpBindingsData(
      assistant: state.assistantOverrides,
      session: next,
    ));
  }

  Future<void> migrateSessionOverride({
    required String fromSessionId,
    required String toSessionId,
  }) async {
    final from = state.sessionOverrides[fromSessionId];
    if (from == null) return;

    final next = Map<String, List<String>>.from(state.sessionOverrides);
    if (!next.containsKey(toSessionId)) {
      next[toSessionId] = List<String>.from(from);
    }
    next.remove(fromSessionId);

    state = state.copyWith(sessionOverrides: next, error: null);
    await _storage.save(McpBindingsData(
      assistant: state.assistantOverrides,
      session: next,
    ));
  }

  List<McpServerConfig> resolveEffectiveServers({
    required List<McpServerConfig> configuredServers,
    required String sessionId,
    String? assistantId,
  }) {
    final enabled = configuredServers.where((s) => s.enabled).toList(growable: false);

    final sessionIds = state.sessionOverrides[sessionId];
    List<String>? selectedIds;
    if (sessionIds != null) {
      selectedIds = sessionIds;
    } else if (assistantId != null) {
      selectedIds = state.assistantOverrides[assistantId];
    }

    Iterable<McpServerConfig> effective = enabled;
    if (selectedIds != null) {
      final idSet = selectedIds.toSet();
      effective = enabled.where((s) => idSet.contains(s.id));
    }

    if (PlatformUtils.isMobile) {
      effective =
          effective.where((s) => s.transport != McpServerTransport.stdio);
    }

    return effective.toList(growable: false);
  }
}

final mcpBindingsProvider =
    StateNotifierProvider<McpBindingsNotifier, McpBindingsState>((ref) {
  return McpBindingsNotifier();
});


