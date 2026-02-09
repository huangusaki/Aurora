import 'package:aurora/features/cleaner/application/cleaner_policy_engine.dart';
import 'package:aurora/features/cleaner/domain/cleaner_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CleanerPolicyEngine', () {
    test('forces keep when candidate is protected', () {
      final engine = CleanerPolicyEngine(
        config: const CleanerPolicyConfig(
          largeFileReviewThresholdBytes: 100,
        ),
      );
      final candidate = _candidate(
        isProtected: true,
      );
      final suggestion = _suggestion(
        decision: CleanerDecision.deleteRecommend,
        confidence: 0.99,
      );

      final result =
          engine.evaluate(candidate: candidate, suggestion: suggestion);

      expect(result.finalDecision, CleanerDecision.keep);
      expect(result.finalRiskLevel, CleanerRiskLevel.high);
      expect(result.policyReasons, contains('candidate_marked_protected'));
    });

    test('forces review when confidence is too low for delete', () {
      final engine = CleanerPolicyEngine(
        config: const CleanerPolicyConfig(
          minConfidenceForDelete: 0.8,
          largeFileReviewThresholdBytes: 1024 * 1024 * 1024,
        ),
      );
      final candidate = _candidate(sizeBytes: 64);
      final suggestion = _suggestion(
        decision: CleanerDecision.deleteRecommend,
        confidence: 0.61,
      );

      final result =
          engine.evaluate(candidate: candidate, suggestion: suggestion);

      expect(result.finalDecision, CleanerDecision.reviewRequired);
      expect(result.policyReasons, contains('low_confidence_requires_review'));
    });

    test('forces review for large files even with high confidence', () {
      final engine = CleanerPolicyEngine(
        config: const CleanerPolicyConfig(
          minConfidenceForDelete: 0.5,
          largeFileReviewThresholdBytes: 200,
        ),
      );
      final candidate = _candidate(sizeBytes: 500);
      final suggestion = _suggestion(
        decision: CleanerDecision.deleteRecommend,
        confidence: 0.95,
        riskLevel: CleanerRiskLevel.low,
      );

      final result =
          engine.evaluate(candidate: candidate, suggestion: suggestion);

      expect(result.finalDecision, CleanerDecision.reviewRequired);
      expect(result.finalRiskLevel, CleanerRiskLevel.high);
      expect(result.policyReasons, contains('large_file_requires_review'));
    });

    test('forces review for non-recoverable delete', () {
      final engine = CleanerPolicyEngine(
        config: const CleanerPolicyConfig(
          minConfidenceForDelete: 0.5,
          largeFileReviewThresholdBytes: 1024 * 1024 * 1024,
          requireRecoverableForDelete: true,
        ),
      );
      final candidate = _candidate(
        recoverable: false,
      );
      final suggestion = _suggestion(
        decision: CleanerDecision.deleteRecommend,
        confidence: 0.9,
      );

      final result =
          engine.evaluate(candidate: candidate, suggestion: suggestion);

      expect(result.finalDecision, CleanerDecision.reviewRequired);
      expect(result.policyReasons, contains('non_recoverable_requires_review'));
    });

    test('keeps keep decision unchanged when no policy is triggered', () {
      final engine = CleanerPolicyEngine(
        config: const CleanerPolicyConfig(
          minConfidenceForDelete: 0.5,
          largeFileReviewThresholdBytes: 1024 * 1024 * 1024,
        ),
      );
      final candidate = _candidate(sizeBytes: 120);
      final suggestion = _suggestion(
        decision: CleanerDecision.keep,
        confidence: 0.9,
        riskLevel: CleanerRiskLevel.medium,
      );

      final result =
          engine.evaluate(candidate: candidate, suggestion: suggestion);

      expect(result.finalDecision, CleanerDecision.keep);
      expect(result.finalRiskLevel, CleanerRiskLevel.medium);
      expect(result.policyReasons, isEmpty);
    });
  });
}

CleanerCandidate _candidate({
  bool isProtected = false,
  bool recoverable = true,
  int sizeBytes = 10,
}) {
  return CleanerCandidate(
    id: 'c1',
    path: '/tmp/cache.bin',
    sizeBytes: sizeBytes,
    modifiedAt: DateTime.utc(2026, 1, 1),
    kind: CleanerCandidateKind.cache,
    recoverable: recoverable,
    isProtected: isProtected,
    source: 'temporary',
  );
}

CleanerAiSuggestion _suggestion({
  CleanerDecision decision = CleanerDecision.reviewRequired,
  CleanerRiskLevel riskLevel = CleanerRiskLevel.medium,
  double confidence = 0.5,
}) {
  return CleanerAiSuggestion(
    candidateId: 'c1',
    decision: decision,
    riskLevel: riskLevel,
    confidence: confidence,
    reasonCodes: const ['test'],
    humanReason: 'test',
    source: 'test',
  );
}
