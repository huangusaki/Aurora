import 'dart:io';

import 'package:aurora/shared/utils/file_snapshot_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileSnapshotCache', () {
    test('reuses cached value while file snapshot is unchanged', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('aurora-cache-test-');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = File('${tempDir.path}${Platform.pathSeparator}sample.txt');
      await file.writeAsString('hello');

      final cache = FileSnapshotCache<String>(maxEntries: 4);
      var loadCount = 0;

      Future<String?> load(FileSnapshot snapshot) async {
        loadCount++;
        return snapshot.file.readAsString();
      }

      final first = await cache.getOrLoad(file.path, load);
      final second = await cache.getOrLoad(file.path, load);

      expect(first, 'hello');
      expect(second, 'hello');
      expect(loadCount, 1);
    });

    test('reloads value after file size changes', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('aurora-cache-test-');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = File('${tempDir.path}${Platform.pathSeparator}sample.txt');
      await file.writeAsString('one');

      final cache = FileSnapshotCache<String>(maxEntries: 4);
      var loadCount = 0;

      Future<String?> load(FileSnapshot snapshot) async {
        loadCount++;
        return snapshot.file.readAsString();
      }

      final first = await cache.getOrLoad(file.path, load);
      await file.writeAsString('two two');
      final second = await cache.getOrLoad(file.path, load);

      expect(first, 'one');
      expect(second, 'two two');
      expect(loadCount, 2);
    });
  });
}
