import '../domain/cleaner_models.dart';

class CleanerPolicyConfig {
  final double minConfidenceForDelete;
  final int largeFileReviewThresholdBytes;
  final bool requireRecoverableForDelete;
  final List<String> protectedPathKeywords;

  const CleanerPolicyConfig({
    this.minConfidenceForDelete = 0.65,
    this.largeFileReviewThresholdBytes = 512 * 1024 * 1024,
    this.requireRecoverableForDelete = true,
    this.protectedPathKeywords = const [
      '/windows/system32/',
      '/system/',
      '/usr/',
      '/bin/',
      '/sbin/',
      '/android/data/',
      '/android/obb/',
    ],
  });
}

class CleanerPolicyEngine {
  final CleanerPolicyConfig config;

  const CleanerPolicyEngine({this.config = const CleanerPolicyConfig()});

  List<CleanerReviewItem> evaluateAll({
    required List<CleanerCandidate> candidates,
    required List<CleanerAiSuggestion> suggestions,
  }) {
    final byId = {
      for (final suggestion in suggestions) suggestion.candidateId: suggestion,
    };
    return candidates.map((candidate) {
      final suggestion = byId[candidate.id] ?? _defaultSuggestion(candidate.id);
      return evaluate(candidate: candidate, suggestion: suggestion);
    }).toList();
  }

  CleanerReviewItem evaluate({
    required CleanerCandidate candidate,
    required CleanerAiSuggestion suggestion,
  }) {
    var finalDecision = suggestion.decision;
    var finalRisk = suggestion.riskLevel;
    final policyReasons = <String>[];

    final protectedByPath = _matchesProtectedPath(candidate.path);
    if (candidate.isProtected || protectedByPath) {
      finalDecision = CleanerDecision.keep;
      finalRisk = CleanerRiskLevel.high;
      policyReasons.add(candidate.isProtected
          ? 'candidate_marked_protected'
          : 'path_protected');
    }

    if (finalDecision == CleanerDecision.deleteRecommend &&
        config.requireRecoverableForDelete &&
        !candidate.recoverable) {
      finalDecision = CleanerDecision.reviewRequired;
      finalRisk = maxCleanerRiskLevel(finalRisk, CleanerRiskLevel.high);
      policyReasons.add('non_recoverable_requires_review');
    }

    if (finalDecision == CleanerDecision.deleteRecommend &&
        suggestion.confidence < config.minConfidenceForDelete) {
      finalDecision = CleanerDecision.reviewRequired;
      finalRisk = maxCleanerRiskLevel(finalRisk, CleanerRiskLevel.medium);
      policyReasons.add('low_confidence_requires_review');
    }

    if (finalDecision == CleanerDecision.deleteRecommend &&
        candidate.sizeBytes >= config.largeFileReviewThresholdBytes) {
      finalDecision = CleanerDecision.reviewRequired;
      finalRisk = maxCleanerRiskLevel(finalRisk, CleanerRiskLevel.high);
      policyReasons.add('large_file_requires_review');
    }

    return CleanerReviewItem(
      candidate: candidate,
      aiSuggestion: suggestion,
      finalDecision: finalDecision,
      finalRiskLevel: finalRisk,
      policyReasons: policyReasons,
    );
  }

  CleanerAiSuggestion _defaultSuggestion(String candidateId) {
    return CleanerAiSuggestion(
      candidateId: candidateId,
      decision: CleanerDecision.reviewRequired,
      riskLevel: CleanerRiskLevel.medium,
      confidence: 0.5,
      reasonCodes: const ['missing_ai_suggestion'],
      humanReason: 'AI suggestion unavailable.',
      source: 'policy-default',
    );
  }

  bool _matchesProtectedPath(String path) {
    final normalized = path.toLowerCase().replaceAll('\\', '/');
    for (final keyword in config.protectedPathKeywords) {
      final k = keyword.toLowerCase().replaceAll('\\', '/');
      if (k.isEmpty) continue;
      if (normalized.contains(k)) return true;
    }
    return false;
  }
}
