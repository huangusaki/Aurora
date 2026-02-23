import 'dart:io';

import '../domain/cleaner_models.dart';
import '../domain/cleaner_services.dart';

class CleanerHardDeleteExecutor implements CleanerDeleteExecutor {
  const CleanerHardDeleteExecutor();

  @override
  Future<CleanerDeleteBatchResult> softDelete(
      List<CleanerCandidate> candidates) async {
    if (candidates.isEmpty) {
      return CleanerDeleteBatchResult.empty();
    }

    final deletedAt = DateTime.now().toUtc();
    final results = <CleanerDeleteItemResult>[];
    var totalFreedBytes = 0;

    for (final candidate in candidates) {
      final source = File(candidate.path);
      if (!await source.exists()) {
        results.add(
          CleanerDeleteItemResult(
            candidateId: candidate.id,
            sourcePath: candidate.path,
            trashPath: null,
            success: false,
            freedBytes: 0,
            error: 'File does not exist',
          ),
        );
        continue;
      }

      try {
        final bytesFreed = candidate.sizeBytes > 0
            ? candidate.sizeBytes
            : await _safeFileLength(source);
        await source.delete();

        results.add(
          CleanerDeleteItemResult(
            candidateId: candidate.id,
            sourcePath: candidate.path,
            trashPath: null,
            success: true,
            freedBytes: bytesFreed,
          ),
        );
        totalFreedBytes += bytesFreed;
      } catch (e) {
        results.add(
          CleanerDeleteItemResult(
            candidateId: candidate.id,
            sourcePath: candidate.path,
            trashPath: null,
            success: false,
            freedBytes: 0,
            error: e.toString(),
          ),
        );
      }
    }

    return CleanerDeleteBatchResult(
      deletedAt: deletedAt,
      results: results,
      totalFreedBytes: totalFreedBytes,
    );
  }

  Future<int> _safeFileLength(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return 0;
    }
  }
}
