import '../domain/cleaner_ai_advisor.dart';
import '../domain/cleaner_models.dart';

class HeuristicCleanerAiAdvisor implements CleanerAiAdvisor {
  const HeuristicCleanerAiAdvisor();

  @override
  Future<List<CleanerAiSuggestion>> suggest({
    required List<CleanerCandidate> candidates,
    required CleanerAiContext context,
    CleanerAiProgressCallback? onProgress,
    bool Function()? shouldStop,
  }) async {
    if (shouldStop?.call() ?? false) {
      return const [];
    }
    final isZh = context.language.toLowerCase().startsWith('zh');
    final suggestions = candidates.map((candidate) {
      return _suggestOne(candidate, isZh: isZh);
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

  CleanerAiSuggestion _suggestOne(
    CleanerCandidate candidate, {
    required bool isZh,
  }) {
    if (candidate.isProtected) {
      return CleanerAiSuggestion(
        candidateId: candidate.id,
        decision: CleanerDecision.keep,
        riskLevel: CleanerRiskLevel.high,
        confidence: 0.95,
        reasonCodes: const ['protected_candidate'],
        humanReason: isZh ? '命中保护规则，默认保留。' : 'Protected by safety policy.',
        source: 'heuristic',
      );
    }

    switch (candidate.kind) {
      case CleanerCandidateKind.cache:
      case CleanerCandidateKind.temporary:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.deleteRecommend,
          riskLevel: CleanerRiskLevel.low,
          confidence: 0.88,
          reasonCodes: const ['cache_like_path', 'reclaim_space'],
          humanReason: isZh
              ? '该文件位于缓存/临时目录，通常可以安全清理。'
              : 'This file is in a cache/temp area and is usually safe to clean.',
          source: 'heuristic',
        );
      case CleanerCandidateKind.duplicate:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.reviewRequired,
          riskLevel: CleanerRiskLevel.medium,
          confidence: 0.74,
          reasonCodes: const ['possible_duplicate', 'needs_user_choice'],
          humanReason: isZh
              ? '疑似重复文件，建议确认保留哪一份后再删除。'
              : 'Looks duplicated; review which copy should be kept first.',
          source: 'heuristic',
        );
      case CleanerCandidateKind.largeFile:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.reviewRequired,
          riskLevel: CleanerRiskLevel.medium,
          confidence: 0.66,
          reasonCodes: const ['large_file', 'value_unknown'],
          humanReason: isZh
              ? '文件体积较大，但价值未知，建议先人工复核。'
              : 'Large file with unknown value; manual review is safer.',
          source: 'heuristic',
        );
      case CleanerCandidateKind.staleFile:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.reviewRequired,
          riskLevel: CleanerRiskLevel.medium,
          confidence: 0.68,
          reasonCodes: const ['stale_unused', 'needs_confirmation'],
          humanReason: isZh
              ? '长期未修改，可能可清理，但建议确认后执行。'
              : 'Long-unmodified file may be removable, but confirm first.',
          source: 'heuristic',
        );
      case CleanerCandidateKind.unknown:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.keep,
          riskLevel: CleanerRiskLevel.high,
          confidence: 0.55,
          reasonCodes: const ['insufficient_signal'],
          humanReason:
              isZh ? '缺少足够依据，默认保留。' : 'Not enough evidence; keep by default.',
          source: 'heuristic',
        );
    }
  }
}
