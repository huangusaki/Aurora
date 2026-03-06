import 'dart:convert';
import 'dart:io';

import 'package:aurora/shared/utils/app_log_repository.dart';
import 'package:aurora/shared/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  setUp(() {
    AppLogger.resetForTest();
  });

  test('init merges persisted and buffered entries and trims to 2000 entries',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('aurora_log_repository_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final file = File(p.join(tempDir.path, AppLogRepository.logFileName));
    final persistedEntries = List<AppLogEntry>.generate(
      1998,
      (index) => AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, index % 60),
        level: AppLogLevel.info,
        channel: 'PERSISTED',
        message: 'persisted-$index',
      ),
    );
    await file.writeAsString(
      persistedEntries.map((entry) => jsonEncode(entry.toJson())).join('\n'),
    );

    for (var index = 0; index < 5; index++) {
      AppLogger.info('BUFFERED', 'buffered-$index');
    }

    final repository = AppLogRepository(
      supportDirectoryProvider: () async => tempDir,
      autoInit: false,
    );
    addTearDown(() async {
      repository.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await repository.init();

    expect(repository.state.isLoading, isFalse);
    expect(repository.state.entries, hasLength(2000));
    expect(repository.state.entries.first.message, 'persisted-3');
    expect(repository.state.entries.last.message, 'buffered-4');

    final persistedLines = await file.readAsLines();
    expect(persistedLines, hasLength(2000));
  });

  test('clear removes in-memory and persisted log entries', () async {
    final tempDir =
        await Directory.systemTemp.createTemp('aurora_log_repository_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final file = File(p.join(tempDir.path, AppLogRepository.logFileName));
    await file.writeAsString(
      jsonEncode(
        AppLogEntry(
          timestamp: DateTime(2026, 3, 6, 10, 0, 0),
          level: AppLogLevel.info,
          channel: 'PERSISTED',
          message: 'persisted',
        ).toJson(),
      ),
    );
    AppLogger.info('BUFFERED', 'buffered');

    final repository = AppLogRepository(
      supportDirectoryProvider: () async => tempDir,
      autoInit: false,
    );
    addTearDown(() async {
      repository.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await repository.init();
    expect(repository.state.entries, isNotEmpty);

    await repository.clear();

    expect(repository.state.entries, isEmpty);
    expect(AppLogger.bufferedEntriesSnapshot(), isEmpty);
    expect(await file.readAsString(), isEmpty);
  });

  test(
      'filters startup boot info and Isar inspector info from repository state',
      () async {
    final tempDir =
        await Directory.systemTemp.createTemp('aurora_log_repository_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final file = File(p.join(tempDir.path, AppLogRepository.logFileName));
    final persistedEntries = [
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, 0),
        level: AppLogLevel.info,
        channel: 'BOOT',
        message: 'main start',
      ),
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, 1),
        level: AppLogLevel.info,
        channel: 'APP',
        message: 'IsarCore using libmdbx: v0.13.8',
      ),
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, 2),
        level: AppLogLevel.info,
        channel: 'CHAT',
        message: 'keep me',
      ),
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, 3),
        level: AppLogLevel.info,
        channel: 'SETTINGS',
        message:
            'SettingsNotifier initialized with backgroundImagePath: foo.png',
      ),
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, 4),
        level: AppLogLevel.info,
        channel: 'CHAT_STORAGE',
        message: 'loadHistory cache MISS for translation, loading from DB',
      ),
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, 5),
        level: AppLogLevel.info,
        channel: 'SESSION',
        message:
            'Restoring session (enabled=true). lastId: foo, lastTopicId: 2',
      ),
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, 6),
        level: AppLogLevel.info,
        channel: 'APP',
        message: '[STARTUP] SessionsNotifier.loadSessions 123ms (10 sessions)',
      ),
    ];
    await file.writeAsString(
      persistedEntries.map((entry) => jsonEncode(entry.toJson())).join('\n'),
    );

    final repository = AppLogRepository(
      supportDirectoryProvider: () async => tempDir,
      autoInit: false,
    );
    addTearDown(() async {
      repository.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await repository.init();
    AppLogger.info('BOOT', 'binding initialized');
    AppLogger.info(
        'APP', 'https://inspect.isar-community.dev/3.3.0/#/58645/PqJubU_YcEU');
    AppLogger.info('APP', '╔══════════════════════════════════════════════╗');
    AppLogger.info('APP', '╟──────────────────────────────────────────────╢');
    AppLogger.info('APP',
        '║             Open the link to connect to the Isar             ║');
    AppLogger.info('SETTINGS',
        'SettingsNotifier initialized with backgroundImagePath: bar.png');
    AppLogger.info('CHAT_STORAGE',
        'loadHistory cache MISS for 1772798966042, loading from DB');
    AppLogger.info('SESSION', 'Restored topic id: 2');
    AppLogger.info('APP', '[STARTUP] SessionsNotifier.deferred total 1701ms');
    AppLogger.error('BOOT', 'startup failed');

    expect(
      repository.state.entries
          .map((entry) => '${entry.channel}:${entry.message}'),
      containsAll([
        'CHAT:keep me',
        'BOOT:startup failed',
      ]),
    );
    expect(
      repository.state.entries.any(
          (entry) => entry.channel == 'BOOT' && entry.message == 'main start'),
      isFalse,
    );
    expect(
      repository.state.entries.any((entry) =>
          entry.channel == 'BOOT' && entry.message == 'binding initialized'),
      isFalse,
    );
    expect(
      repository.state.entries.any((entry) =>
          entry.channel == 'APP' &&
          entry.message.contains('inspect.isar-community.dev')),
      isFalse,
    );
    expect(
      repository.state.entries.any((entry) =>
          entry.channel == 'APP' &&
          entry.message.contains('Open the link to connect to the Isar')),
      isFalse,
    );
    expect(
      repository.state.entries.any(
          (entry) => entry.channel == 'APP' && entry.message.contains('──')),
      isFalse,
    );
    expect(
      repository.state.entries.any((entry) =>
          entry.channel == 'APP' && entry.message.startsWith('[STARTUP]')),
      isFalse,
    );
    expect(
      repository.state.entries.any((entry) =>
          entry.channel == 'SETTINGS' &&
          entry.message.startsWith('SettingsNotifier initialized')),
      isFalse,
    );
    expect(
      repository.state.entries.any((entry) =>
          entry.channel == 'CHAT_STORAGE' &&
          entry.message.startsWith('loadHistory cache MISS')),
      isFalse,
    );
    expect(
      repository.state.entries.any((entry) =>
          entry.channel == 'SESSION' &&
          entry.message.startsWith('Restoring session')),
      isFalse,
    );
    expect(
      repository.state.entries.any((entry) =>
          entry.channel == 'SESSION' &&
          entry.message.startsWith('Restored topic')),
      isFalse,
    );
  });
}
