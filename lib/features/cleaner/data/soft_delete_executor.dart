import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/cleaner_models.dart';
import '../domain/cleaner_services.dart';

class CleanerSoftDeleteExecutor implements CleanerDeleteExecutor {
  const CleanerSoftDeleteExecutor();

  @override
  Future<CleanerDeleteBatchResult> softDelete(
      List<CleanerCandidate> candidates) async {
    if (candidates.isEmpty) {
      return CleanerDeleteBatchResult.empty();
    }

    final deletedAt = DateTime.now().toUtc();
    final trashRoot = await _ensureTrashRoot();
    final bucketName = _dateBucket(deletedAt);
    final bucketDir = Directory(p.join(trashRoot.path, bucketName));
    await bucketDir.create(recursive: true);
    final manifestFile = File(p.join(trashRoot.path, 'manifest.jsonl'));

    final results = <CleanerDeleteItemResult>[];
    var totalFreedBytes = 0;

    for (final candidate in candidates) {
      final result = await _deleteSingle(
        candidate: candidate,
        bucketDir: bucketDir,
        manifestFile: manifestFile,
        deletedAt: deletedAt,
      );
      results.add(result);
      totalFreedBytes += result.freedBytes;
    }

    return CleanerDeleteBatchResult(
      deletedAt: deletedAt,
      results: results,
      totalFreedBytes: totalFreedBytes,
    );
  }

  Future<String> getTrashPath() async {
    final root = await _ensureTrashRoot();
    return root.path;
  }

  Future<CleanerDeleteItemResult> _deleteSingle({
    required CleanerCandidate candidate,
    required Directory bucketDir,
    required File manifestFile,
    required DateTime deletedAt,
  }) async {
    final source = File(candidate.path);
    if (!await source.exists()) {
      return CleanerDeleteItemResult(
        candidateId: candidate.id,
        sourcePath: candidate.path,
        trashPath: null,
        success: false,
        freedBytes: 0,
        error: 'File does not exist',
      );
    }

    final basename = _sanitizeFileName(p.basename(candidate.path));
    final targetPath = p.join(
      bucketDir.path,
      '${DateTime.now().microsecondsSinceEpoch}_${candidate.id}_$basename',
    );
    final target = File(targetPath);

    try {
      await _moveFile(source, target);
      final bytesFreed = candidate.sizeBytes > 0
          ? candidate.sizeBytes
          : await _safeFileLength(target);

      await _appendManifest(
        manifestFile: manifestFile,
        entry: {
          'candidate_id': candidate.id,
          'source_path': candidate.path,
          'trash_path': target.path,
          'deleted_at': deletedAt.toIso8601String(),
          'size_bytes': bytesFreed,
          'source': candidate.source,
          'kind': candidate.kind.name,
          'tags': candidate.tags,
        },
      );

      return CleanerDeleteItemResult(
        candidateId: candidate.id,
        sourcePath: candidate.path,
        trashPath: target.path,
        success: true,
        freedBytes: bytesFreed,
      );
    } catch (e) {
      return CleanerDeleteItemResult(
        candidateId: candidate.id,
        sourcePath: candidate.path,
        trashPath: null,
        success: false,
        freedBytes: 0,
        error: e.toString(),
      );
    }
  }

  Future<void> _moveFile(File source, File target) async {
    try {
      await source.rename(target.path);
      return;
    } catch (_) {
      // Rename can fail across mounts; fallback to copy + delete.
    }
    await source.copy(target.path);
    await source.delete();
  }

  Future<int> _safeFileLength(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  Future<Directory> _ensureTrashRoot() async {
    final supportDir = await getApplicationSupportDirectory();
    final trashRoot = Directory(p.join(supportDir.path, 'cleaner_trash'));
    await trashRoot.create(recursive: true);
    return trashRoot;
  }

  Future<void> _appendManifest({
    required File manifestFile,
    required Map<String, dynamic> entry,
  }) async {
    await manifestFile.writeAsString(
      '${jsonEncode(entry)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  String _sanitizeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (cleaned.isEmpty) {
      return 'unnamed_file';
    }
    return cleaned;
  }

  String _dateBucket(DateTime time) {
    final utc = time.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
