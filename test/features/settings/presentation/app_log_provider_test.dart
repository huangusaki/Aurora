import 'package:aurora/features/settings/presentation/app_log_provider.dart';
import 'package:aurora/shared/utils/app_log_repository.dart';
import 'package:aurora/shared/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppLogRepository extends AppLogRepository {
  _FakeAppLogRepository(List<AppLogEntry> entries) : super(autoInit: false) {
    state = AppLogState(entries: entries, isLoading: false);
  }

  @override
  Future<void> init() async {}
}

void main() {
  setUp(() {
    AppLogger.resetForTest();
  });

  test('filtered provider returns only selected warning-level entries', () {
    final repository = _FakeAppLogRepository([
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 0, 0),
        level: AppLogLevel.debug,
        channel: 'APP',
        message: 'debug',
      ),
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 1, 0),
        level: AppLogLevel.warn,
        channel: 'APP',
        message: 'warn',
      ),
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 10, 2, 0),
        level: AppLogLevel.error,
        channel: 'APP',
        message: 'error',
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        appLogRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);

    container.read(appLogFilterProvider.notifier).state = {AppLogLevel.warn};
    final filtered = container.read(filteredAppLogEntriesProvider);

    expect(filtered, hasLength(1));
    expect(filtered.single.level, AppLogLevel.warn);
    expect(filtered.single.message, 'warn');
  });
}
