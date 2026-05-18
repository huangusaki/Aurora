import 'dart:async';
import 'dart:math';

import 'package:aurora/shared/riverpod_legacy.dart';
import 'package:aurora/shared/services/mcp/mcp_client_session.dart';
import 'package:aurora/shared/utils/platform_utils.dart';

import '../domain/mcp_server_config.dart';

enum McpConnectionStatus {
  disconnected,
  connecting,
  ready,
  error,
}

const Object _mcpInfoSentinel = Object();

class McpConnectionInfo {
  final McpConnectionStatus status;
  final String? lastError;
  final DateTime? lastConnectedAt;
  final DateTime? lastPingAt;
  final DateTime? lastToolListAt;
  final int? lastToolListDurationMs;
  final int? cachedToolsCount;
  final DateTime? lastCallAt;
  final int? lastCallDurationMs;
  final List<String> stderrTail;
  final bool pingSupported;
  final DateTime? lastActivityAt;

  const McpConnectionInfo({
    required this.status,
    this.lastError,
    this.lastConnectedAt,
    this.lastPingAt,
    this.lastToolListAt,
    this.lastToolListDurationMs,
    this.cachedToolsCount,
    this.lastCallAt,
    this.lastCallDurationMs,
    this.stderrTail = const [],
    this.pingSupported = true,
    this.lastActivityAt,
  });

  McpConnectionInfo copyWith({
    McpConnectionStatus? status,
    Object? lastError = _mcpInfoSentinel,
    DateTime? lastConnectedAt,
    DateTime? lastPingAt,
    DateTime? lastToolListAt,
    int? lastToolListDurationMs,
    int? cachedToolsCount,
    DateTime? lastCallAt,
    int? lastCallDurationMs,
    List<String>? stderrTail,
    bool? pingSupported,
    DateTime? lastActivityAt,
  }) {
    return McpConnectionInfo(
      status: status ?? this.status,
      lastError:
          lastError == _mcpInfoSentinel ? this.lastError : lastError as String?,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastPingAt: lastPingAt ?? this.lastPingAt,
      lastToolListAt: lastToolListAt ?? this.lastToolListAt,
      lastToolListDurationMs: lastToolListDurationMs ?? this.lastToolListDurationMs,
      cachedToolsCount: cachedToolsCount ?? this.cachedToolsCount,
      lastCallAt: lastCallAt ?? this.lastCallAt,
      lastCallDurationMs: lastCallDurationMs ?? this.lastCallDurationMs,
      stderrTail: stderrTail ?? this.stderrTail,
      pingSupported: pingSupported ?? this.pingSupported,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}

class McpConnectionState {
  final Map<String, McpConnectionInfo> connections;

  const McpConnectionState({
    this.connections = const {},
  });

  McpConnectionState copyWith({
    Map<String, McpConnectionInfo>? connections,
  }) {
    return McpConnectionState(connections: connections ?? this.connections);
  }
}

class McpConnectionTestResult {
  final bool success;
  final List<McpTool> tools;
  final String? error;
  final List<String> stderrTail;

  const McpConnectionTestResult({
    required this.success,
    this.tools = const [],
    this.error,
    this.stderrTail = const [],
  });
}

class _ToolCacheEntry {
  final List<McpTool> tools;
  final DateTime fetchedAt;

  const _ToolCacheEntry({required this.tools, required this.fetchedAt});
}

bool _isTransportSupported(McpServerTransport transport) {
  if (transport == McpServerTransport.stdio) {
    return PlatformUtils.isDesktop;
  }
  return true;
}

bool _stringListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _stringMapEquals(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _sameConnectionConfig(McpServerConfig a, McpServerConfig b) {
  if (a.transport != b.transport) return false;

  if (a.transport == McpServerTransport.http) {
    return a.url == b.url && _stringMapEquals(a.headers, b.headers);
  }

  return a.command == b.command &&
      _stringListEquals(a.args, b.args) &&
      a.cwd == b.cwd &&
      _stringMapEquals(a.env, b.env) &&
      a.runInShell == b.runInShell;
}

class McpConnectionNotifier extends StateNotifier<McpConnectionState> {
  static const Duration toolCacheTtl = Duration(minutes: 5);
  static const Duration idleTimeout = Duration(minutes: 10);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const int stderrTailMaxLines = 200;

  final Map<String, McpClientSession> _sessions = {};
  final Map<String, Future<McpClientSession>> _connecting = {};
  final Map<String, Timer> _heartbeats = {};
  final Map<String, Timer> _reconnectTimers = {};
  final Map<String, int> _backoffAttempts = {};
  final Map<String, int> _pingFailures = {};
  final Map<String, bool> _pingInFlight = {};
  final Map<String, StreamSubscription<String>> _stderrSubs = {};
  final Map<String, _ToolCacheEntry> _toolCache = {};
  final Map<String, McpServerConfig> _serverConfigs = {};

  final Random _random = Random();

  McpConnectionNotifier() : super(const McpConnectionState());

  McpConnectionInfo connectionInfo(String serverId) {
    return state.connections[serverId] ??
        const McpConnectionInfo(status: McpConnectionStatus.disconnected);
  }

  void syncConfiguredServers(List<McpServerConfig> servers) {
    final configuredIds = servers.map((s) => s.id).toSet();
    final enabledIds =
        servers.where((s) => s.enabled).map((s) => s.id).toSet();

    final toDisconnect = <String>{};

    for (final id in _sessions.keys) {
      if (!enabledIds.contains(id) || !configuredIds.contains(id)) {
        toDisconnect.add(id);
      }
    }

    for (final s in servers) {
      final prev = _serverConfigs[s.id];
      if (prev != null &&
          _sessions.containsKey(s.id) &&
          !_sameConnectionConfig(prev, s)) {
        toDisconnect.add(s.id);
      }
      if (!_isTransportSupported(s.transport)) {
        toDisconnect.add(s.id);
      }
    }

    _serverConfigs.removeWhere((id, _) => !configuredIds.contains(id));
    for (final s in servers) {
      _serverConfigs[s.id] = s;
    }

    for (final id in toDisconnect) {
      unawaited(disconnect(id));
    }
  }

  Future<McpClientSession> ensureConnected(
    McpServerConfig server, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (!_isTransportSupported(server.transport)) {
      throw UnsupportedError('MCP transport ${server.transport} is not supported on this platform');
    }

    _serverConfigs[server.id] = server;

    final existing = _sessions[server.id];
    if (existing != null) {
      _touch(server.id);
      _ensureHeartbeat(server.id, server: server, session: existing);
      return existing;
    }

    final pending = _connecting[server.id];
    if (pending != null) return pending;

    _setInfo(
      server.id,
      connectionInfo(server.id).copyWith(
        status: McpConnectionStatus.connecting,
        lastError: null,
      ),
    );

    final future = _connectAndInitialize(server, timeout: timeout).then((session) {
      _sessions[server.id] = session;
      _connecting.remove(server.id);

      _backoffAttempts[server.id] = 0;
      _pingFailures[server.id] = 0;

      _setInfo(
        server.id,
        connectionInfo(server.id).copyWith(
          status: McpConnectionStatus.ready,
          lastError: null,
          lastConnectedAt: DateTime.now(),
          pingSupported: session.pingSupported,
        ),
      );

      _attachStderr(server.id, session);
      _ensureHeartbeat(server.id, server: server, session: session);
      _touch(server.id);
      return session;
    }).catchError((e, st) {
      _connecting.remove(server.id);
      _setInfo(
        server.id,
        connectionInfo(server.id).copyWith(
          status: McpConnectionStatus.error,
          lastError: e.toString(),
        ),
      );
      _scheduleReconnect(server.id);
      Error.throwWithStackTrace(e, st);
    });

    _connecting[server.id] = future;
    return future;
  }

  Future<List<McpTool>> listTools(
    McpServerConfig server, {
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final id = server.id;
    _serverConfigs[id] = server;

    final cached = _toolCache[id];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < toolCacheTtl) {
      _touch(id);
      _setInfo(
        id,
        connectionInfo(id).copyWith(
          cachedToolsCount: cached.tools.length,
        ),
      );
      return cached.tools;
    }

    final session = await ensureConnected(server, timeout: timeout);
    final start = DateTime.now();
    try {
      final tools = await session.listToolsAll(timeout: timeout);
      _toolCache[id] = _ToolCacheEntry(tools: tools, fetchedAt: DateTime.now());

      _setInfo(
        id,
        connectionInfo(id).copyWith(
          lastToolListAt: DateTime.now(),
          lastToolListDurationMs: DateTime.now().difference(start).inMilliseconds,
          cachedToolsCount: tools.length,
        ),
      );

      _touch(id);
      return tools;
    } catch (e) {
      _setInfo(
        id,
        connectionInfo(id).copyWith(
          status: McpConnectionStatus.error,
          lastError: e.toString(),
        ),
      );
      _scheduleReconnect(id);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> callTool(
    McpServerConfig server, {
    required String name,
    required Map<String, dynamic> arguments,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final id = server.id;
    _serverConfigs[id] = server;

    final session = await ensureConnected(server, timeout: timeout);
    final start = DateTime.now();
    try {
      final result = await session.callTool(name, arguments, timeout: timeout);
      _setInfo(
        id,
        connectionInfo(id).copyWith(
          lastCallAt: DateTime.now(),
          lastCallDurationMs: DateTime.now().difference(start).inMilliseconds,
        ),
      );
      _touch(id);
      return result;
    } catch (e) {
      _setInfo(
        id,
        connectionInfo(id).copyWith(
          status: McpConnectionStatus.error,
          lastError: e.toString(),
        ),
      );
      _scheduleReconnect(id);
      rethrow;
    }
  }

  Future<McpConnectionTestResult> testConnection(
    McpServerConfig server, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    try {
      final tools = await listTools(server, forceRefresh: true, timeout: timeout);
      final stderr = connectionInfo(server.id).stderrTail;
      return McpConnectionTestResult(
        success: true,
        tools: tools,
        stderrTail: stderr,
      );
    } catch (e) {
      final stderr = connectionInfo(server.id).stderrTail;
      return McpConnectionTestResult(
        success: false,
        error: e.toString(),
        stderrTail: stderr,
      );
    }
  }

  Future<void> reconnect(McpServerConfig server) async {
    await disconnect(server.id);
    await ensureConnected(server);
  }

  Future<void> disconnect(String serverId) async {
    _reconnectTimers.remove(serverId)?.cancel();
    _heartbeats.remove(serverId)?.cancel();
    _pingInFlight.remove(serverId);
    _pingFailures.remove(serverId);
    _backoffAttempts.remove(serverId);
    _toolCache.remove(serverId);

    try {
      await _stderrSubs.remove(serverId)?.cancel();
    } catch (_) {}

    final session = _sessions.remove(serverId);
    if (session != null) {
      try {
        await session.close();
      } catch (_) {}
    }

    _setInfo(
      serverId,
      connectionInfo(serverId).copyWith(
        status: McpConnectionStatus.disconnected,
        lastError: null,
      ),
    );
  }

  Future<McpClientSession> _connectAndInitialize(
    McpServerConfig server, {
    required Duration timeout,
  }) async {
    McpClientSession session;
    if (server.transport == McpServerTransport.http) {
      final uri = Uri.tryParse(server.url.trim());
      if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
        throw ArgumentError('Invalid MCP server URL: ${server.url}');
      }
      session = await McpClientSession.connectHttp(
        url: uri,
        headers: server.headers,
      );
    } else {
      session = await McpClientSession.connect(
        command: server.command,
        args: server.args,
        cwd: server.cwd,
        env: server.env.isEmpty ? null : server.env,
        runInShell: server.runInShell,
      );
    }

    await session.initialize(timeout: timeout);
    return session;
  }

  void _attachStderr(String serverId, McpClientSession session) {
    _stderrSubs.remove(serverId)?.cancel();
    final current = connectionInfo(serverId);
    final tail = List<String>.from(current.stderrTail);
    _stderrSubs[serverId] = session.stderrLines.listen((line) {
      if (line.trim().isEmpty) return;
      tail.add(line);
      if (tail.length > stderrTailMaxLines) {
        tail.removeRange(0, tail.length - stderrTailMaxLines);
      }
      _setInfo(
        serverId,
        connectionInfo(serverId).copyWith(stderrTail: List<String>.from(tail)),
      );
    }, onError: (_) {});
  }

  void _ensureHeartbeat(
    String serverId, {
    required McpServerConfig server,
    required McpClientSession session,
  }) {
    _heartbeats[serverId]?.cancel();
    _heartbeats[serverId] = Timer.periodic(heartbeatInterval, (_) async {
      final currentSession = _sessions[serverId];
      if (currentSession == null) {
        _heartbeats.remove(serverId)?.cancel();
        return;
      }

      final lastActivity = connectionInfo(serverId).lastActivityAt;
      if (lastActivity != null &&
          DateTime.now().difference(lastActivity) > idleTimeout) {
        await disconnect(serverId);
        return;
      }

      if (!currentSession.pingSupported) return;
      if (_pingInFlight[serverId] == true) return;

      _pingInFlight[serverId] = true;
      try {
        await currentSession.ping(timeout: const Duration(seconds: 5));
        _pingFailures[serverId] = 0;
        _setInfo(
          serverId,
          connectionInfo(serverId).copyWith(
            lastPingAt: DateTime.now(),
            status: McpConnectionStatus.ready,
            lastError: null,
            pingSupported: true,
          ),
        );
      } on UnsupportedError {
        _setInfo(
          serverId,
          connectionInfo(serverId).copyWith(pingSupported: false),
        );
      } catch (e) {
        final failures = (_pingFailures[serverId] ?? 0) + 1;
        _pingFailures[serverId] = failures;
        if (failures >= 3) {
          _setInfo(
            serverId,
            connectionInfo(serverId).copyWith(
              status: McpConnectionStatus.error,
              lastError: e.toString(),
            ),
          );
          _scheduleReconnect(serverId);
        }
      } finally {
        _pingInFlight[serverId] = false;
      }
    });
  }

  void _scheduleReconnect(String serverId) {
    if (_reconnectTimers.containsKey(serverId)) return;
    final cfg = _serverConfigs[serverId];
    if (cfg == null || !cfg.enabled) return;
    if (!_isTransportSupported(cfg.transport)) return;

    final attempt = (_backoffAttempts[serverId] ?? 0) + 1;
    _backoffAttempts[serverId] = attempt;

    final baseSec = min(30, 1 << (attempt - 1));
    final jitterMs = _random.nextInt(500);
    final delay = Duration(seconds: baseSec) + Duration(milliseconds: jitterMs);

    _reconnectTimers[serverId] = Timer(delay, () async {
      _reconnectTimers.remove(serverId);
      final cfgNow = _serverConfigs[serverId];
      if (cfgNow == null || !cfgNow.enabled) return;
      try {
        await reconnect(cfgNow);
      } catch (_) {
        // If reconnect fails, scheduling will be re-triggered by callers.
      }
    });
  }

  void _touch(String serverId) {
    _setInfo(
      serverId,
      connectionInfo(serverId).copyWith(lastActivityAt: DateTime.now()),
    );
  }

  void _setInfo(String serverId, McpConnectionInfo info) {
    final next = Map<String, McpConnectionInfo>.from(state.connections);
    next[serverId] = info;
    state = state.copyWith(connections: next);
  }

  @override
  void dispose() {
    for (final t in _reconnectTimers.values) {
      t.cancel();
    }
    for (final t in _heartbeats.values) {
      t.cancel();
    }
    for (final sub in _stderrSubs.values) {
      sub.cancel();
    }
    for (final session in _sessions.values) {
      unawaited(session.close());
    }
    _reconnectTimers.clear();
    _heartbeats.clear();
    _stderrSubs.clear();
    _sessions.clear();
    super.dispose();
  }
}

final mcpConnectionProvider =
    StateNotifierProvider<McpConnectionNotifier, McpConnectionState>((ref) {
  final notifier = McpConnectionNotifier();
  return notifier;
});

