import 'package:aurora/shared/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AppLogger.resetForTest();
  });

  test(
      'listeners receive structured entries even when console min level is higher',
      () {
    final received = <AppLogEntry>[];
    final removeListener = AppLogger.addListener(received.add);
    addTearDown(removeListener);

    AppLogger.install(
      useColor: false,
      minLevel: AppLogLevel.error,
    );

    AppLogger.debug('TEST', 'debug message');
    AppLogger.error('TEST', 'error message');

    expect(received, hasLength(2));
    expect(received.first.level, AppLogLevel.debug);
    expect(received.first.channel, 'TEST');
    expect(received.first.message, 'debug message');
    expect(received.last.level, AppLogLevel.error);
    expect(received.last.message, 'error message');
    expect(AppLogger.bufferedEntriesSnapshot(), hasLength(2));
  });
}
