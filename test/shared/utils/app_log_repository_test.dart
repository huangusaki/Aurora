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
}
