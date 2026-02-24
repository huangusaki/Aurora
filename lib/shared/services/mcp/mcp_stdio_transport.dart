import 'dart:async';
import 'dart:convert';
import 'dart:io';

class McpStdioTransport {
  final String command;
  final List<String> args;
  final String? workingDirectory;
  final Map<String, String>? environment;
  final bool runInShell;

  McpStdioTransport({
    required this.command,
    this.args = const [],
    this.workingDirectory,
    this.environment,
    this.runInShell = false,
  });

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  final StreamController<Map<String, dynamic>> _incomingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get incoming => _incomingController.stream;
  Stream<String> get stderrLines => _stderrController.stream;

  bool get isConnected => _process != null;

  Future<void> connect() async {
    if (_process != null) return;

    final process = await Process.start(
      command,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: runInShell,
    );
    _process = process;

    _stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          _incomingController.add(
              decoded.map((key, value) => MapEntry('$key', value)));
        }
      } catch (_) {
        // Ignore malformed lines.
      }
    }, onError: (_) {});

    _stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (!_stderrController.isClosed) {
        _stderrController.add(line);
      }
    }, onError: (_) {});

    unawaited(process.exitCode.then((_) async {
      await close();
    }));
  }

  Future<void> send(Map<String, dynamic> message) async {
    final p = _process;
    if (p == null) {
      throw StateError('MCP transport is not connected');
    }
    p.stdin.writeln(jsonEncode(message));
  }

  Future<void> close() async {
    final p = _process;
    _process = null;

    try {
      await _stdoutSub?.cancel();
    } catch (_) {}
    _stdoutSub = null;

    try {
      await _stderrSub?.cancel();
    } catch (_) {}
    _stderrSub = null;

    try {
      if (p != null) {
        try {
          p.stdin.close();
        } catch (_) {}
        try {
          p.kill();
        } catch (_) {}
      }
    } catch (_) {}

    try {
      await _incomingController.close();
    } catch (_) {}
    try {
      await _stderrController.close();
    } catch (_) {}
  }
}

