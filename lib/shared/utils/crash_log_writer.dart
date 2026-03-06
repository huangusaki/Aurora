import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_logger.dart';

class CrashLogWriter {
  CrashLogWriter({
    Future<Directory> Function()? supportDirectoryProvider,
    Directory? Function()? currentDirectoryProvider,
    List<AppLogEntry> Function()? logEntriesProvider,
    DateTime Function()? nowProvider,
    Duration dedupeWindow = const Duration(seconds: 2),
  })  : _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory,
        _currentDirectoryProvider =
            currentDirectoryProvider ?? (() => Directory.current),
        _logEntriesProvider =
            logEntriesProvider ?? AppLogger.bufferedEntriesSnapshot,
        _nowProvider = nowProvider ?? DateTime.now,
        _dedupeWindow = dedupeWindow;

  final Future<Directory> Function() _supportDirectoryProvider;
  final Directory? Function() _currentDirectoryProvider;
  final List<AppLogEntry> Function() _logEntriesProvider;
  final DateTime Function() _nowProvider;
  final Duration _dedupeWindow;

  String? _lastFingerprint;
  DateTime? _lastWriteAt;

  Future<File?> writeCrashSnapshot({
    required String source,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    final now = _nowProvider();
    final fingerprint = _buildFingerprint(error, stackTrace);
    if (_shouldSkipDuplicate(now, fingerprint)) {
      return null;
    }

    _lastFingerprint = fingerprint;
    _lastWriteAt = now;

    final fileName = 'aurora_crash_${_formatFileTimestamp(now)}.log';
    final content = _buildCrashContent(
      timestamp: now,
      source: source,
      error: error,
      stackTrace: stackTrace,
      entries: _logEntriesProvider(),
    );

    final currentDir = _safeCurrentDirectory();
    final primaryFile = await _tryWrite(
        directory: currentDir, fileName: fileName, content: content);
    if (primaryFile != null) {
      return primaryFile;
    }

    try {
      final fallbackDir = await _supportDirectoryProvider();
      final fallbackFile = await _tryWrite(
        directory: fallbackDir,
        fileName: fileName,
        content: content,
      );
      if (fallbackFile != null) {
        return fallbackFile;
      }
    } catch (writeError) {
      _reportWriteFailure(writeError);
    }

    return null;
  }

  bool _shouldSkipDuplicate(DateTime now, String fingerprint) {
    final lastWriteAt = _lastWriteAt;
    if (_lastFingerprint != fingerprint || lastWriteAt == null) {
      return false;
    }
    return now.difference(lastWriteAt) <= _dedupeWindow;
  }

  String _buildFingerprint(Object error, StackTrace stackTrace) {
    return '${error.runtimeType}|$error|$stackTrace';
  }

  Directory? _safeCurrentDirectory() {
    try {
      return _currentDirectoryProvider();
    } catch (_) {
      return null;
    }
  }

  Future<File?> _tryWrite({
    required Directory? directory,
    required String fileName,
    required String content,
  }) async {
    if (directory == null) return null;

    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(p.join(directory.path, fileName));
      await file.writeAsString(content, flush: true);
      return file;
    } catch (writeError) {
      _reportWriteFailure(writeError);
      return null;
    }
  }

  String _buildCrashContent({
    required DateTime timestamp,
    required String source,
    required Object error,
    required StackTrace stackTrace,
    required List<AppLogEntry> entries,
  }) {
    final buffer = StringBuffer()
      ..writeln('Aurora Crash Snapshot')
      ..writeln('Crash Time: ${_formatTimestamp(timestamp)}')
      ..writeln('Source: $source')
      ..writeln('Error: $error')
      ..writeln('Stack Trace:')
      ..writeln(stackTrace)
      ..writeln()
      ..writeln('Logs Before Crash:')
      ..writeln();

    if (entries.isEmpty) {
      buffer.writeln('[no buffered logs]');
      return buffer.toString();
    }

    for (final entry in entries) {
      buffer.writeln(entry.toPlainText());
    }
    return buffer.toString();
  }

  String _formatFileTimestamp(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}'
        '${local.month.toString().padLeft(2, '0')}'
        '${local.day.toString().padLeft(2, '0')}_'
        '${local.hour.toString().padLeft(2, '0')}'
        '${local.minute.toString().padLeft(2, '0')}'
        '${local.second.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }

  void _reportWriteFailure(Object error) {
    try {
      stderr.writeln('[AURORA_CRASH_LOG_WRITE_FAILED] $error');
    } catch (_) {}
  }
}
