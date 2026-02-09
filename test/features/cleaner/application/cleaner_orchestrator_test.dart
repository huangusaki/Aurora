import 'package:aurora/features/cleaner/application/cleaner_orchestrator.dart';
import 'package:aurora/features/cleaner/application/cleaner_policy_engine.dart';
import 'package:aurora/features/cleaner/domain/cleaner_ai_advisor.dart';
import 'package:aurora/features/cleaner/domain/cleaner_models.dart';
import 'package:aurora/features/cleaner/domain/cleaner_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CleanerOrchestrator', () {
    test('analyze builds summary using policy decisions', () async {
      final candidates = [
        _candidate('c1', '/tmp/a.tmp', 100, CleanerCandidateKind.temporary),
        _candidate('c2', '/tmp/b.bin', 500, CleanerCandidateKind.largeFile),
        _candidate('c3', '/tmp/c.db', 50, CleanerCandidateKind.staleFile),
      ];
      final scanner = _FakeScanner(candidates);
      final advisor = _FakeAdvisor({
        'c1': _suggestion('c1', CleanerDecision.deleteRecommend, 0.95),
        'c2': _suggestion('c2', CleanerDecision.deleteRecommend, 0.95),
        'c3': _suggestion('c3', CleanerDecision.keep, 0.9),
      });
      final deleter = _FakeDeleteExecutor();
      final orchestrator = CleanerOrchestrator(
        scanner: scanner,
        aiAdvisor: advisor,
        policyEngine: const CleanerPolicyEngine(
          config: CleanerPolicyConfig(
            minConfidenceForDelete: 0.6,
            largeFileReviewThresholdBytes: 400,
          ),
        ),
        deleteExecutor: deleter,
      );

      final result = await orchestrator.analyze();

      expect(result.summary.totalCandidates, 3);
      expect(result.summary.deleteRecommendedCount, 1);
      expect(result.summary.reviewRequiredCount, 1);
      expect(result.summary.keepCount, 1);
      expect(result.summary.policyAdjustedCount, 1);
      expect(result.summary.estimatedReclaimBytes, 100);
    });

    test('deleteByDecision sends only matching candidates', () async {
      final candidates = [
        _candidate('c1', '/tmp/a.tmp', 100, CleanerCandidateKind.temporary),
        _candidate('c2', '/tmp/b.bin', 500, CleanerCandidateKind.largeFile),
      ];
      final scanner = _FakeScanner(candidates);
      final advisor = _FakeAdvisor({
        'c1': _suggestion('c1', CleanerDecision.deleteRecommend, 0.95),
        'c2': _suggestion('c2', CleanerDecision.reviewRequired, 0.7),
      });
      final deleter = _FakeDeleteExecutor();
      final orchestrator = CleanerOrchestrator(
        scanner: scanner,
        aiAdvisor: advisor,
        policyEngine: const CleanerPolicyEngine(),
        deleteExecutor: deleter,
      );

      final analyzed = await orchestrator.analyze();
      final deleted = await orchestrator.deleteByDecision(analyzed);

      expect(deleter.receivedIds, ['c1']);
      expect(deleted.results.length, 1);
      expect(deleted.totalFreedBytes, 100);
    });
  });
}

CleanerCandidate _candidate(
  String id,
  String path,
  int sizeBytes,
  CleanerCandidateKind kind,
) {
  return CleanerCandidate(
    id: id,
    path: path,
    sizeBytes: sizeBytes,
    modifiedAt: DateTime.utc(2026, 1, 1),
    kind: kind,
    recoverable: true,
    isProtected: false,
    source: 'test',
  );
}

CleanerAiSuggestion _suggestion(
  String id,
  CleanerDecision decision,
  double confidence,
) {
  return CleanerAiSuggestion(
    candidateId: id,
    decision: decision,
    riskLevel: CleanerRiskLevel.medium,
    confidence: confidence,
    reasonCodes: const ['test'],
    humanReason: 'test',
    source: 'test',
  );
}

class _FakeScanner implements CleanerScanner {
  final List<CleanerCandidate> _candidates;

  const _FakeScanner(this._candidates);

  @override
  Future<List<CleanerCandidate>> scan(
    CleanerScanOptions options, {
    bool Function()? shouldStop,
  }) async {
    return _candidates;
  }
}

class _FakeAdvisor implements CleanerAiAdvisor {
  final Map<String, CleanerAiSuggestion> byId;

  const _FakeAdvisor(this.byId);

  @override
  Future<List<CleanerAiSuggestion>> suggest({
    required List<CleanerCandidate> candidates,
    required CleanerAiContext context,
    CleanerAiProgressCallback? onProgress,
    bool Function()? shouldStop,
  }) async {
    final suggestions = candidates.map((c) {
      return byId[c.id] ??
          CleanerAiSuggestion(
            candidateId: c.id,
            decision: CleanerDecision.reviewRequired,
            riskLevel: CleanerRiskLevel.medium,
            confidence: 0.5,
            reasonCodes: const ['default'],
            humanReason: 'default',
            source: 'fake',
          );
    }).toList();
    if (onProgress != null && suggestions.isNotEmpty) {
      onProgress(
        suggestions,
        CleanerAiProgress(
          processedBatches: 1,
          totalBatches: 1,
          processedCandidates: suggestions.length,
          totalCandidates: suggestions.length,
        ),
      );
    }
    return suggestions;
  }
}

class _FakeDeleteExecutor implements CleanerDeleteExecutor {
  List<String> receivedIds = const [];

  @override
  Future<CleanerDeleteBatchResult> softDelete(
      List<CleanerCandidate> candidates) async {
    receivedIds = candidates.map((e) => e.id).toList();
    final results = candidates.map((c) {
      return CleanerDeleteItemResult(
        candidateId: c.id,
        sourcePath: c.path,
        trashPath: '/trash/${c.id}',
        success: true,
        freedBytes: c.sizeBytes,
      );
    }).toList();
    return CleanerDeleteBatchResult(
      deletedAt: DateTime.now().toUtc(),
      results: results,
      totalFreedBytes: candidates.fold<int>(
        0,
        (sum, c) => sum + c.sizeBytes,
      ),
    );
  }
}
