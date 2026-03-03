import 'dart:typed_data';

import 'package:aurora/shared/utils/image_format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectImageExtension', () {
    test('detects PNG', () {
      final bytes = Uint8List.fromList(
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00],
      );
      expect(detectImageExtension(bytes), 'png');
    });

    test('detects JPEG', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]);
      expect(detectImageExtension(bytes), 'jpg');
    });

    test('detects WEBP', () {
      final bytes = Uint8List.fromList(
        [0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50],
      );
      expect(detectImageExtension(bytes), 'webp');
    });

    test('detects GIF', () {
      final bytes = Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00]);
      expect(detectImageExtension(bytes), 'gif');
    });

    test('detects BMP', () {
      final bytes = Uint8List.fromList([0x42, 0x4D, 0x00, 0x00]);
      expect(detectImageExtension(bytes), 'bmp');
    });

    test('detects TIFF', () {
      final littleEndian = Uint8List.fromList([0x49, 0x49, 0x2A, 0x00, 0x00]);
      final bigEndian = Uint8List.fromList([0x4D, 0x4D, 0x00, 0x2A, 0x00]);
      expect(detectImageExtension(littleEndian), 'tiff');
      expect(detectImageExtension(bigEndian), 'tiff');
    });

    test('falls back to defaultExtension for unknown bytes', () {
      final bytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      expect(detectImageExtension(bytes, defaultExtension: 'png'), 'png');
      expect(detectImageExtension(bytes, defaultExtension: 'bin'), 'bin');
    });
  });
}

