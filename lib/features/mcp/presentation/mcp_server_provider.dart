import 'dart:async';

import 'package:aurora/shared/riverpod_compat.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/services/mcp/mcp_client_session.dart';
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

class McpTestResult {
  final bool success;
  final List<McpTool> tools;
  final String? error;
  final List<String> stderrLines;

  const McpTestResult({
    required this.success,
    this.tools = const [],
    this.error,
    this.stderrLines = const [],
  });
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
    required String command,
    List<String> args = const [],
    String? cwd,
    Map<String, String> env = const {},
    bool enabled = true,
    bool runInShell = false,
  }) async {
    final id = const Uuid().v4();
    final server = McpServerConfig(
      id: id,
      name: name,
      enabled: enabled,
      command: command,
      args: args,
      cwd: cwd,
      env: env,
      runInShell: runInShell,
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

  Future<McpTestResult> testConnection(McpServerConfig server) async {
    McpClientSession? session;
    final stderr = <String>[];
    StreamSubscription<String>? stderrSub;
    try {
      session = await McpClientSession.connect(
        command: server.command,
        args: server.args,
        cwd: server.cwd,
        env: server.env.isEmpty ? null : server.env,
        runInShell: server.runInShell,
      );
      stderrSub = session.stderrLines.listen((line) {
        if (stderr.length < 200) stderr.add(line);
      });
      // Allow extra time for first-time starts (e.g. npx download).
      const timeout = Duration(seconds: 90);
      await session.initialize(timeout: timeout);
      final tools = await session.listToolsAll(timeout: timeout);
      return McpTestResult(success: true, tools: tools, stderrLines: stderr);
    } catch (e) {
      return McpTestResult(
        success: false,
        error: e.toString(),
        stderrLines: stderr,
      );
    } finally {
      try {
        await stderrSub?.cancel();
      } catch (_) {}
      try {
        await session?.close();
      } catch (_) {}
    }
  }
}

final mcpServerProvider =
    StateNotifierProvider<McpServerNotifier, McpServerState>((ref) {
  return McpServerNotifier();
});
