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

  test('collapses long base64 data URLs in log payloads', () {
    AppLogger.install(useColor: false);

    final base64Payload = 'A' * 320;
    AppLogger.info(
      'TEST',
      'image payload',
      data: {
        'url': 'data:image/png;base64,$base64Payload',
      },
    );

    final entry = AppLogger.bufferedEntriesSnapshot().single;
    expect(entry.details, contains('[DATA_URL_OMITTED]'));
    expect(entry.details, isNot(contains('data:image/png;base64,')));
    expect(entry.details, isNot(contains(base64Payload)));
  });

  test('collapses long raw base64 only for known base64 fields', () {
    AppLogger.install(useColor: false);

    final base64Payload = 'A' * 400;
    final ordinaryLongText = 'x' * 400;
    AppLogger.info(
      'TEST',
      'structured payload',
      data: {
        'inlineData': {
          'mimeType': 'image/png',
          'data': base64Payload,
        },
        'note': ordinaryLongText,
      },
    );

    final entry = AppLogger.bufferedEntriesSnapshot().single;
    expect(entry.details, contains('[BASE64_OMITTED]'));
    expect(entry.details, isNot(contains(base64Payload)));
    expect(entry.details, contains(ordinaryLongText));
  });

  test('sanitizes base64 image payloads in response logs', () {
    AppLogger.install(useColor: false);

    final base64Payload = 'A' * 400;
    AppLogger.llmResponse(payload: {
      'choices': [
        {
          'message': {
            'inline_data': {
              'mime_type': 'image/png',
              'data': base64Payload,
            },
          },
        },
      ],
      'data': [
        {
          'b64_json': base64Payload,
        },
      ],
    });

    final entry = AppLogger.bufferedEntriesSnapshot().single;
    expect(entry.channel, 'LLM');
    expect(entry.category, 'RESPONSE');
    expect(entry.details, contains('[BASE64_OMITTED]'));
    expect(entry.details, isNot(contains(base64Payload)));
  });
}
