import 'cleaner_models.dart';

abstract class CleanerScanner {
  Future<List<CleanerCandidate>> scan(
    CleanerScanOptions options, {
    bool Function()? shouldStop,
  });
}

abstract class CleanerDeleteExecutor {
  Future<CleanerDeleteBatchResult> softDelete(
      List<CleanerCandidate> candidates);
}
