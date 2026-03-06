import 'dart:io';

import 'package:aurora/shared/utils/app_logger.dart';
import 'package:aurora/shared/utils/crash_log_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory primaryDir;
  late Directory fallbackDir;

  setUp(() async {
    primaryDir = await Directory.systemTemp.createTemp('aurora_crash_primary_');
    fallbackDir =
        await Directory.systemTemp.createTemp('aurora_crash_fallback_');
  });

  tearDown(() async {
    if (await primaryDir.exists()) {
      await primaryDir.delete(recursive: true);
    }
    if (await fallbackDir.exists()) {
      await fallbackDir.delete(recursive: true);
    }
  });

  test('writes crash snapshot to current directory when writable', () async {
    final writer = CrashLogWriter(
      currentDirectoryProvider: () => primaryDir,
      supportDirectoryProvider: () async => fallbackDir,
      logEntriesProvider: () => [
        AppLogEntry(
          timestamp: DateTime(2026, 3, 6, 12, 0, 0),
          level: AppLogLevel.info,
          channel: 'BOOT',
          message: 'startup complete',
        ),
      ],
      nowProvider: () => DateTime(2026, 3, 6, 12, 30, 0),
    );

    final file = await writer.writeCrashSnapshot(
      source: 'uncaught_zone',
      error: StateError('boom'),
      stackTrace: StackTrace.fromString('stack line'),
    );

    expect(file, isNotNull);
    expect(file!.path.startsWith(primaryDir.path), isTrue);
    final content = await file.readAsString();
    expect(content, contains('Source: uncaught_zone'));
    expect(content, contains('Bad state: boom'));
    expect(content, contains('startup complete'));
  });

  test('falls back to support directory when current directory is not writable',
      () async {
    final blockingFile =
        File('${primaryDir.path}${Platform.pathSeparator}block');
    await blockingFile.writeAsString('not a directory');

    final writer = CrashLogWriter(
      currentDirectoryProvider: () => Directory(blockingFile.path),
      supportDirectoryProvider: () async => fallbackDir,
      logEntriesProvider: () => [
        AppLogEntry(
          timestamp: DateTime(2026, 3, 6, 12, 0, 0),
          level: AppLogLevel.error,
          channel: 'CHAT',
          message: 'request failed',
        ),
      ],
      nowProvider: () => DateTime(2026, 3, 6, 12, 45, 0),
    );

    final file = await writer.writeCrashSnapshot(
      source: 'flutter_error',
      error: ArgumentError('bad value'),
      stackTrace: StackTrace.fromString('stack line'),
    );

    expect(file, isNotNull);
    expect(file!.path.startsWith(fallbackDir.path), isTrue);
    final content = await file.readAsString();
    expect(content, contains('Source: flutter_error'));
    expect(content, contains('request failed'));
  });
}
