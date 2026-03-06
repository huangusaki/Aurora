import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aurora/shared/riverpod_compat.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_logger.dart';

class AppLogState {
  final List<AppLogEntry> entries;
  final bool isLoading;

  const AppLogState({
    this.entries = const <AppLogEntry>[],
    this.isLoading = true,
  });

  AppLogState copyWith({
    List<AppLogEntry>? entries,
    bool? isLoading,
  }) {
    return AppLogState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppLogRepository extends StateNotifier<AppLogState> {
  AppLogRepository({
    Future<Directory> Function()? supportDirectoryProvider,
    Duration persistDebounce = const Duration(milliseconds: 250),
    int maxEntries = AppLogger.maxBufferedEntries,
    bool autoInit = true,
  })  : _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory,
        _persistDebounce = persistDebounce,
        _maxEntries = maxEntries,
        super(const AppLogState()) {
    if (autoInit) {
      unawaited(init());
    }
  }

  static const String logFileName = 'aurora_logs.jsonl';

  final Future<Directory> Function() _supportDirectoryProvider;
  final Duration _persistDebounce;
  final int _maxEntries;

  File? _logFile;
  Timer? _persistTimer;
  VoidCallback? _removeLoggerListener;
  Future<void>? _initFuture;
  bool _isInitialized = false;
  bool _isDisposed = false;
  List<AppLogEntry> _runtimeEntries = <AppLogEntry>[];

  List<AppLogEntry> get entries => state.entries;

  Future<void> init() {
    return _initFuture ??= _initInternal();
  }

  Future<void> flushNow() async {
    final file = _logFile;
    if (file == null || _isDisposed) return;

    final content =
        _runtimeEntries.map((entry) => jsonEncode(entry.toJson())).join('\n');

    try {
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await file.writeAsString(
        content.isEmpty ? '' : '$content\n',
        flush: true,
      );
    } catch (_) {
      // Logging persistence must never recursively log into itself.
    }
  }

  Future<void> _initInternal() async {
    _attachLoggerListener();

    try {
      final supportDir = await _supportDirectoryProvider();
      _logFile = File(p.join(supportDir.path, logFileName));
      final persistedEntries = await _readPersistedEntries(_logFile!);
      _runtimeEntries = _trimEntries([
        ...persistedEntries,
        ..._runtimeEntries,
      ]);
      _isInitialized = true;
      _publishState();
      await flushNow();
    } catch (_) {
      _isInitialized = true;
      _publishState();
    }
  }

  Future<List<AppLogEntry>> _readPersistedEntries(File file) async {
    try {
      if (!await file.exists()) {
        return const <AppLogEntry>[];
      }
      final lines = await file.readAsLines();
      final entries = <AppLogEntry>[];
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        try {
          final decoded = jsonDecode(line);
          if (decoded is Map<String, dynamic>) {
            entries.add(AppLogEntry.fromJson(decoded));
          } else if (decoded is Map) {
            entries.add(AppLogEntry.fromJson(
              decoded.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ));
          }
        } catch (_) {
          // Ignore malformed historical lines instead of breaking startup.
        }
      }
      return _trimEntries(entries);
    } catch (_) {
      return const <AppLogEntry>[];
    }
  }

  void _attachLoggerListener() {
    if (_removeLoggerListener != null) return;

    _removeLoggerListener = AppLogger.addListener(
      _handleLogEntry,
      replayBuffered: true,
    );
  }

  void _handleLogEntry(AppLogEntry entry) {
    if (_isDisposed) return;
    _runtimeEntries = _trimEntries([..._runtimeEntries, entry]);
    _publishState();
    if (_isInitialized) {
      _schedulePersist();
    }
  }

  void _publishState() {
    if (_isDisposed) return;
    state = state.copyWith(
      entries: List<AppLogEntry>.unmodifiable(_runtimeEntries),
      isLoading: !_isInitialized,
    );
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, () {
      unawaited(flushNow());
    });
  }

  List<AppLogEntry> _trimEntries(List<AppLogEntry> entries) {
    if (entries.length <= _maxEntries) {
      return List<AppLogEntry>.from(entries);
    }
    return List<AppLogEntry>.from(
      entries.sublist(entries.length - _maxEntries),
    );
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    final shouldFlush = _isInitialized;
    _removeLoggerListener?.call();
    if (shouldFlush) {
      unawaited(flushNow());
    }
    _isDisposed = true;
    super.dispose();
  }
}
