import 'dart:collection';
import 'dart:io';

class FileSnapshot {
  final String path;
  final String fileName;
  final File file;
  final int size;
  final DateTime modified;

  const FileSnapshot({
    required this.path,
    required this.fileName,
    required this.file,
    required this.size,
    required this.modified,
  });
}

class FileSnapshotCache<T> {
  FileSnapshotCache({this.maxEntries = 24});

  final int maxEntries;
  final LinkedHashMap<String, _FileSnapshotCacheEntry<T>> _entries =
      LinkedHashMap<String, _FileSnapshotCacheEntry<T>>();

  Future<T?> getOrLoad(
    String path,
    Future<T?> Function(FileSnapshot snapshot) loader,
  ) async {
    final file = File(path);
    FileStat stat;
    try {
      stat = await file.stat();
    } on FileSystemException {
      _entries.remove(path);
      return null;
    }

    if (stat.type == FileSystemEntityType.notFound) {
      _entries.remove(path);
      return null;
    }

    final cached = _entries.remove(path);
    if (cached != null &&
        cached.size == stat.size &&
        cached.modified.isAtSameMomentAs(stat.modified)) {
      _entries[path] = cached;
      return cached.value;
    }

    final snapshot = FileSnapshot(
      path: path,
      fileName: path.split(Platform.pathSeparator).last,
      file: file,
      size: stat.size,
      modified: stat.modified,
    );
    final loaded = await loader(snapshot);
    if (loaded == null) {
      _entries.remove(path);
      return null;
    }

    _entries[path] = _FileSnapshotCacheEntry<T>(
      size: stat.size,
      modified: stat.modified,
      value: loaded,
    );
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return loaded;
  }

  void invalidate(String path) {
    _entries.remove(path);
  }

  void clear() {
    _entries.clear();
  }
}

class _FileSnapshotCacheEntry<T> {
  final int size;
  final DateTime modified;
  final T value;

  const _FileSnapshotCacheEntry({
    required this.size,
    required this.modified,
    required this.value,
  });
}

List<Map<String, dynamic>> cloneStructuredMapList(
  List<Map<String, dynamic>> input,
) {
  return input
      .map((item) => Map<String, dynamic>.fromEntries(
            item.entries.map(
              (entry) =>
                  MapEntry(entry.key, _cloneStructuredValue(entry.value)),
            ),
          ))
      .toList(growable: false);
}

dynamic _cloneStructuredValue(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map(
        (entry) =>
            MapEntry(entry.key.toString(), _cloneStructuredValue(entry.value)),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneStructuredValue).toList(growable: false);
  }
  return value;
}
