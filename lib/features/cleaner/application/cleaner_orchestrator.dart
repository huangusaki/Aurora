import '../domain/cleaner_ai_advisor.dart';
import '../domain/cleaner_models.dart';
import '../domain/cleaner_services.dart';
import 'cleaner_policy_engine.dart';

typedef CleanerAnalysisProgressCallback = void Function(
  List<CleanerAiSuggestion> partialSuggestions,
  CleanerAiProgress progress,
);

class CleanerOrchestrator {
  final CleanerScanner scanner;
  final CleanerAiAdvisor aiAdvisor;
  final CleanerPolicyEngine policyEngine;
  final CleanerDeleteExecutor deleteExecutor;

  const CleanerOrchestrator({
    required this.scanner,
    required this.aiAdvisor,
    required this.policyEngine,
    required this.deleteExecutor,
  });

  Future<CleanerRunResult> analyze({
    CleanerScanOptions options = const CleanerScanOptions(),
    CleanerAiContext context = const CleanerAiContext(),
  }) async {
    final candidates = await scan(options);
    if (candidates.isEmpty) {
      return CleanerRunResult.empty();
    }

    return analyzeCandidates(
      candidates: candidates,
      context: context,
    );
  }

  Future<List<CleanerCandidate>> scan(
    CleanerScanOptions options, {
    bool Function()? shouldStop,
  }) {
    return scanner.scan(
      options,
      shouldStop: shouldStop,
    );
  }

  Future<CleanerRunResult> analyzeCandidates({
    required List<CleanerCandidate> candidates,
    required CleanerAiContext context,
    CleanerAnalysisProgressCallback? onProgress,
    bool Function()? shouldStop,
  }) async {
    if (candidates.isEmpty) {
      return CleanerRunResult.empty();
    }

    final suggestionsById = <String, CleanerAiSuggestion>{};
    final suggestions = await aiAdvisor.suggest(
      candidates: candidates,
      context: context,
      shouldStop: shouldStop,
      onProgress: (partialSuggestions, progress) {
        for (final suggestion in partialSuggestions) {
          suggestionsById[suggestion.candidateId] = suggestion;
        }
        onProgress?.call(partialSuggestions, progress);
      },
    );

    for (final suggestion in suggestions) {
      suggestionsById[suggestion.candidateId] = suggestion;
    }

    return reviewCandidates(
      candidates: candidates,
      suggestions: suggestionsById.values,
      languageCode: context.language,
    );
  }

  CleanerRunResult reviewCandidates({
    required List<CleanerCandidate> candidates,
    required Iterable<CleanerAiSuggestion> suggestions,
    String languageCode = 'en',
  }) {
    if (candidates.isEmpty) {
      return CleanerRunResult.empty();
    }

    final items = policyEngine.evaluateAll(
      candidates: candidates,
      suggestions: suggestions.toList(),
      languageCode: languageCode,
    );
    final summary = _buildSummary(items);
    return CleanerRunResult(
      analyzedAt: DateTime.now().toUtc(),
      items: items,
      summary: summary,
    );
  }

  Future<CleanerDeleteBatchResult> deleteByDecision(
    CleanerRunResult result, {
    Set<CleanerDecision> decisions = const {
      CleanerDecision.deleteRecommend,
    },
  }) {
    final selected = result.items
        .where((item) => decisions.contains(item.finalDecision))
        .map((item) => item.candidate)
        .toList();
    if (selected.isEmpty) {
      return Future.value(CleanerDeleteBatchResult.empty());
    }
    return deleteExecutor.softDelete(selected);
  }

  Future<CleanerDeleteBatchResult> deleteByIds(
    CleanerRunResult result,
    List<String> candidateIds,
  ) {
    final selectedIds = candidateIds.toSet();
    final selected = result.items
        .where((item) => selectedIds.contains(item.candidate.id))
        .map((item) => item.candidate)
        .toList();
    if (selected.isEmpty) {
      return Future.value(CleanerDeleteBatchResult.empty());
    }
    return deleteExecutor.softDelete(selected);
  }

  CleanerRunSummary _buildSummary(List<CleanerReviewItem> items) {
    var recommended = 0;
    var reviewRequired = 0;
    var keep = 0;
    var adjusted = 0;
    var reclaimBytes = 0;

    for (final item in items) {
      switch (item.finalDecision) {
        case CleanerDecision.deleteRecommend:
          recommended++;
          reclaimBytes += item.candidate.sizeBytes;
          break;
        case CleanerDecision.reviewRequired:
          reviewRequired++;
          break;
        case CleanerDecision.keep:
          keep++;
          break;
      }

      if (item.policyAdjusted) {
        adjusted++;
      }
    }

    return CleanerRunSummary(
      totalCandidates: items.length,
      deleteRecommendedCount: recommended,
      reviewRequiredCount: reviewRequired,
      keepCount: keep,
      policyAdjustedCount: adjusted,
      estimatedReclaimBytes: reclaimBytes,
    );
  }
}
