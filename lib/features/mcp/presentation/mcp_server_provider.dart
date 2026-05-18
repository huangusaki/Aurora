import 'package:aurora/shared/riverpod_legacy.dart';
import 'package:uuid/uuid.dart';

import '../data/mcp_server_storage.dart';
import '../domain/mcp_server_config.dart';

class McpServerState {
  final List<McpServerConfig> servers;
  final bool isLoading;
  final String? error;

  const McpServerState({
    this.servers = const [],
    this.isLoading = false,
    this.error,
  });

  McpServerState copyWith({
    List<McpServerConfig>? servers,
    bool? isLoading,
    String? error,
  }) {
    return McpServerState(
      servers: servers ?? this.servers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class McpServerNotifier extends StateNotifier<McpServerState> {
  final McpServerStorage _storage = McpServerStorage();
  bool _hasLoaded = false;

  McpServerNotifier() : super(const McpServerState());

  Future<void> load() async {
    if (_hasLoaded) return;
    _hasLoaded = true;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final servers = await _storage.loadServers();
      state = state.copyWith(servers: servers, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addServer({
    required String name,
    McpServerTransport transport = McpServerTransport.stdio,
    String command = '',
    List<String> args = const [],
    String? cwd,
    Map<String, String> env = const {},
    String url = '',
    Map<String, String> headers = const {},
    bool enabled = true,
    bool runInShell = false,
  }) async {
    final id = const Uuid().v4();
    final server = McpServerConfig(
      id: id,
      name: name,
      enabled: enabled,
      transport: transport,
      command: command,
      args: args,
      cwd: cwd,
      env: env,
      runInShell: runInShell,
      url: url,
      headers: headers,
    );
    final next = [...state.servers, server];
    state = state.copyWith(servers: next, error: null);
    await _storage.saveServers(next);
  }

  Future<void> updateServer(McpServerConfig server) async {
    final next = state.servers
        .map((s) => s.id == server.id ? server : s)
        .toList(growable: false);
    state = state.copyWith(servers: next, error: null);
    await _storage.saveServers(next);
  }

  Future<void> deleteServer(String id) async {
    final next =
        state.servers.where((s) => s.id != id).toList(growable: false);
    state = state.copyWith(servers: next, error: null);
    await _storage.saveServers(next);
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final next = state.servers
        .map((s) => s.id == id ? s.copyWith(enabled: enabled) : s)
        .toList(growable: false);
    state = state.copyWith(servers: next, error: null);
    await _storage.saveServers(next);
  }
}

final mcpServerProvider =
    StateNotifierProvider<McpServerNotifier, McpServerState>((ref) {
  return McpServerNotifier();
});

