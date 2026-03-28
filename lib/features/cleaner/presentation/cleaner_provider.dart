import 'dart:math' as math;

import 'package:aurora/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:aurora/shared/riverpod_compat.dart';

import '../../../shared/services/model_routed_llm_service.dart';
import '../../settings/presentation/settings_provider.dart';
import '../application/cleaner_orchestrator.dart';
import '../application/cleaner_policy_engine.dart';
import '../application/heuristic_cleaner_ai_advisor.dart';
import '../application/heuristic_cleaner_directory_planner.dart';
import '../application/llm_cleaner_ai_advisor.dart';
import '../application/llm_cleaner_directory_planner.dart';
import '../data/cleaner_scan_service.dart';
import '../data/soft_delete_executor.dart';
import '../domain/cleaner_ai_advisor.dart';
import '../domain/cleaner_directory_planner.dart';
import '../domain/cleaner_models.dart';
import '../domain/cleaner_services.dart';

final cleanerScannerProvider = Provider<CleanerScanner>((ref) {
  return CleanerScanService(
    directoryPlanner: ref.watch(cleanerDirectoryPlannerProvider),
  );
});

final cleanerDeleteExecutorProvider = Provider<CleanerDeleteExecutor>((ref) {
  return const CleanerSoftDeleteExecutor();
});

final cleanerPolicyEngineProvider = Provider<CleanerPolicyEngine>((ref) {
  return const CleanerPolicyEngine();
});

final cleanerFallbackAdvisorProvider = Provider<CleanerAiAdvisor>((ref) {
  return const HeuristicCleanerAiAdvisor();
});

final cleanerAiAdvisorProvider = Provider<CleanerAiAdvisor>((ref) {
  final settings = ref.watch(settingsProvider);
  final fallbackAdvisor = ref.watch(cleanerFallbackAdvisorProvider);
  final llmService = ModelRoutedLlmService(settings);
  return LlmCleanerAiAdvisor(
    llmService: llmService,
    fallbackAdvisor: fallbackAdvisor,
  );
});

final cleanerFallbackDirectoryPlannerProvider =
    Provider<CleanerDirectoryPlanner>((ref) {
  return const HeuristicCleanerDirectoryPlanner();
});

final cleanerDirectoryPlannerProvider =
    Provider<CleanerDirectoryPlanner>((ref) {
  final settings = ref.watch(settingsProvider);
  final llmService = ModelRoutedLlmService(settings);
  final fallbackPlanner = ref.watch(cleanerFallbackDirectoryPlannerProvider);
  final context = CleanerAiContext(
    language: settings.language,
    model: settings.executionModel ?? settings.selectedModel,
    providerId: settings.executionProviderId ?? settings.activeProviderId,
    redactPaths: true,
  );
  return LlmCleanerDirectoryPlanner(
    llmService: llmService,
    context: context,
    fallbackPlanner: fallbackPlanner,
  );
});

final cleanerOrchestratorProvider = Provider<CleanerOrchestrator>((ref) {
  return CleanerOrchestrator(
    scanner: ref.watch(cleanerScannerProvider),
    aiAdvisor: ref.watch(cleanerAiAdvisorProvider),
    policyEngine: ref.watch(cleanerPolicyEngineProvider),
    deleteExecutor: ref.watch(cleanerDeleteExecutorProvider),
  );
});

class CleanerState {
  final bool isAnalyzing;
  final bool isDeleting;
  final bool canContinueAnalyze;
  final bool stopRequested;
  final int processedCandidates;
  final int totalCandidates;
  final int processedBatches;
  final int totalBatches;
  final String? error;
  final CleanerRunResult? runResult;
  final CleanerDeleteBatchResult? lastDeleteResult;

  const CleanerState({
    this.isAnalyzing = false,
    this.isDeleting = false,
    this.canContinueAnalyze = false,
    this.stopRequested = false,
    this.processedCandidates = 0,
    this.totalCandidates = 0,
    this.processedBatches = 0,
    this.totalBatches = 0,
    this.error,
    this.runResult,
    this.lastDeleteResult,
  });

  CleanerState copyWith({
    bool? isAnalyzing,
    bool? isDeleting,
    bool? canContinueAnalyze,
    bool? stopRequested,
    int? processedCandidates,
    int? totalCandidates,
    int? processedBatches,
    int? totalBatches,
    Object? error = _cleanerSentinel,
    Object? runResult = _cleanerSentinel,
    Object? lastDeleteResult = _cleanerSentinel,
  }) {
    return CleanerState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isDeleting: isDeleting ?? this.isDeleting,
      canContinueAnalyze: canContinueAnalyze ?? this.canContinueAnalyze,
      stopRequested: stopRequested ?? this.stopRequested,
      processedCandidates: processedCandidates ?? this.processedCandidates,
      totalCandidates: totalCandidates ?? this.totalCandidates,
      processedBatches: processedBatches ?? this.processedBatches,
      totalBatches: totalBatches ?? this.totalBatches,
      error: error == _cleanerSentinel ? this.error : error as String?,
      runResult: runResult == _cleanerSentinel
          ? this.runResult
          : runResult as CleanerRunResult?,
      lastDeleteResult: lastDeleteResult == _cleanerSentinel
          ? this.lastDeleteResult
          : lastDeleteResult as CleanerDeleteBatchResult?,
    );
  }
}

const Object _cleanerSentinel = Object();

class CleanerNotifier extends StateNotifier<CleanerState> {
  final Ref _ref;

  bool _stopRequested = false;
  CleanerScanOptions? _lastOptions;
  CleanerAiContext? _lastContext;
  List<CleanerCandidate>? _sessionCandidates;
  bool _resumeRequiresRescan = false;
  final Map<String, CleanerAiSuggestion> _sessionSuggestionsById =
      <String, CleanerAiSuggestion>{};

  CleanerNotifier(this._ref) : super(const CleanerState());

  Future<void> analyze({
    CleanerScanOptions options = const CleanerScanOptions(),
  }) async {
    if (state.isAnalyzing) return;

    final orchestrator = _ref.read(cleanerOrchestratorProvider);
    _lastOptions = options;
    _lastContext = _buildAiContext();
    _sessionCandidates = null;
    _resumeRequiresRescan = false;
    _sessionSuggestionsById.clear();
    _stopRequested = false;

    state = state.copyWith(
      isAnalyzing: true,
      canContinueAnalyze: false,
      stopRequested: false,
      processedCandidates: 0,
      totalCandidates: 0,
      processedBatches: 0,
      totalBatches: 0,
      error: null,
      runResult: null,
    );

    try {
      final candidates = await orchestrator.scan(
        options,
        shouldStop: _isStopRequested,
      );
      _sessionCandidates = candidates;

      if (_stopRequested) {
        _stopRequested = false;
        _resumeRequiresRescan = true;
        _sessionCandidates = null;
        _sessionSuggestionsById.clear();
        state = state.copyWith(
          isAnalyzing: false,
          canContinueAnalyze: candidates.isNotEmpty,
          stopRequested: false,
          processedCandidates: 0,
          totalCandidates: candidates.length,
          processedBatches: 0,
          totalBatches: 0,
          runResult: orchestrator.reviewCandidates(
            candidates: candidates,
            suggestions: const <CleanerAiSuggestion>[],
            languageCode: _effectiveLanguageCode,
          ),
        );
        return;
      }

      if (candidates.isEmpty) {
        _stopRequested = false;
        state = state.copyWith(
          isAnalyzing: false,
          canContinueAnalyze: false,
          stopRequested: false,
          runResult: CleanerRunResult.empty(),
        );
        return;
      }

      state = state.copyWith(
        totalCandidates: candidates.length,
      );

      await orchestrator.analyzeCandidates(
        candidates: candidates,
        context: _lastContext!,
        shouldStop: _isStopRequested,
        onProgress: (partialSuggestions, progress) {
          for (final suggestion in partialSuggestions) {
            _sessionSuggestionsById[suggestion.candidateId] = suggestion;
          }
          final partialResult = orchestrator.reviewCandidates(
            candidates: candidates,
            suggestions: _sessionSuggestionsById.values,
            languageCode: _effectiveLanguageCode,
          );
          state = state.copyWith(
            runResult: partialResult,
            processedCandidates: _sessionSuggestionsById.length,
            totalCandidates: candidates.length,
            processedBatches: progress.processedBatches,
            totalBatches: progress.totalBatches,
          );
        },
      );

      final processedCandidates = _sessionSuggestionsById.length;
      final hasPending = processedCandidates < candidates.length;
      final finalResult = orchestrator.reviewCandidates(
        candidates: candidates,
        suggestions: _sessionSuggestionsById.values,
        languageCode: _effectiveLanguageCode,
      );

      _stopRequested = false;
      state = state.copyWith(
        isAnalyzing: false,
        stopRequested: false,
        canContinueAnalyze: hasPending,
        runResult: finalResult,
        processedCandidates: processedCandidates,
        totalCandidates: candidates.length,
        processedBatches: state.processedBatches == 0 && processedCandidates > 0
            ? 1
            : state.processedBatches,
        totalBatches: state.totalBatches == 0 && processedCandidates > 0
            ? 1
            : state.totalBatches,
      );

      _clearSessionIfComplete();
    } catch (e) {
      _stopRequested = false;
      final l10n = _localizations();
      state = state.copyWith(
        isAnalyzing: false,
        stopRequested: false,
        canContinueAnalyze: false,
        error: l10n.cleanerErrorAnalyzeFailed('$e'),
      );
    }
  }

  void requestStopAnalyze() {
    if (!state.isAnalyzing) return;
    _stopRequested = true;
    state = state.copyWith(stopRequested: true);
  }

  Future<void> continueAnalyze() async {
    if (state.isAnalyzing || !state.canContinueAnalyze) return;

    if (_resumeRequiresRescan) {
      final options = _lastOptions;
      _resumeRequiresRescan = false;
      if (options != null) {
        await analyze(options: options);
      }
      return;
    }

    final candidates = _sessionCandidates;
    if (candidates == null || candidates.isEmpty || _lastContext == null) {
      final options = _lastOptions;
      if (options != null) {
        await analyze(options: options);
      }
      return;
    }

    final orchestrator = _ref.read(cleanerOrchestratorProvider);
    final analyzedIds = _sessionSuggestionsById.keys.toSet();
    final remaining = candidates
        .where((candidate) => !analyzedIds.contains(candidate.id))
        .toList(growable: false);

    if (remaining.isEmpty) {
      final runResult = orchestrator.reviewCandidates(
        candidates: candidates,
        suggestions: _sessionSuggestionsById.values,
        languageCode: _effectiveLanguageCode,
      );
      state = state.copyWith(
        isAnalyzing: false,
        stopRequested: false,
        canContinueAnalyze: false,
        runResult: runResult,
        processedCandidates: _sessionSuggestionsById.length,
        totalCandidates: candidates.length,
      );
      _clearSessionIfComplete();
      return;
    }

    final baseBatches = state.processedBatches;
    var lastProcessedBatches = 0;
    var lastTotalBatches = 0;

    _stopRequested = false;
    state = state.copyWith(
      isAnalyzing: true,
      canContinueAnalyze: false,
      stopRequested: false,
      error: null,
      totalCandidates: candidates.length,
    );

    try {
      await orchestrator.analyzeCandidates(
        candidates: remaining,
        context: _lastContext!,
        shouldStop: _isStopRequested,
        onProgress: (partialSuggestions, progress) {
          for (final suggestion in partialSuggestions) {
            _sessionSuggestionsById[suggestion.candidateId] = suggestion;
          }
          lastProcessedBatches = progress.processedBatches;
          lastTotalBatches = progress.totalBatches;
          final partialResult = orchestrator.reviewCandidates(
            candidates: candidates,
            suggestions: _sessionSuggestionsById.values,
            languageCode: _effectiveLanguageCode,
          );
          state = state.copyWith(
            runResult: partialResult,
            processedCandidates: _sessionSuggestionsById.length,
            totalCandidates: candidates.length,
            processedBatches: baseBatches + progress.processedBatches,
            totalBatches: math.max(
              state.totalBatches,
              baseBatches + progress.totalBatches,
            ),
          );
        },
      );

      final processedCandidates = _sessionSuggestionsById.length;
      final hasPending = processedCandidates < candidates.length;
      final runResult = orchestrator.reviewCandidates(
        candidates: candidates,
        suggestions: _sessionSuggestionsById.values,
        languageCode: _effectiveLanguageCode,
      );

      _stopRequested = false;
      state = state.copyWith(
        isAnalyzing: false,
        stopRequested: false,
        canContinueAnalyze: hasPending,
        runResult: runResult,
        processedCandidates: processedCandidates,
        totalCandidates: candidates.length,
        processedBatches: baseBatches + lastProcessedBatches,
        totalBatches: math.max(
          state.totalBatches,
          baseBatches + lastTotalBatches,
        ),
      );

      _clearSessionIfComplete();
    } catch (e) {
      _stopRequested = false;
      final l10n = _localizations();
      state = state.copyWith(
        isAnalyzing: false,
        stopRequested: false,
        canContinueAnalyze: true,
        error: l10n.cleanerErrorContinueFailed('$e'),
      );
    }
  }

  CleanerAiContext _buildAiContext() {
    final settings = _ref.read(settingsProvider);
    return CleanerAiContext(
      language: settings.language,
      model: settings.executionModel ?? settings.selectedModel,
      providerId: settings.executionProviderId ?? settings.activeProviderId,
      redactPaths: true,
    );
  }

  void _clearSessionIfComplete() {
    if (state.canContinueAnalyze) return;
    _resumeRequiresRescan = false;
    _sessionCandidates = null;
    _sessionSuggestionsById.clear();
  }

  bool _isStopRequested() => _stopRequested;

  Future<void> deleteRecommended({
    bool includeReviewRequired = false,
  }) async {
    final runResult = state.runResult;
    if (runResult == null) return;

    state = state.copyWith(
      isDeleting: true,
      error: null,
    );

    try {
      final decisions = includeReviewRequired
          ? {
              CleanerDecision.deleteRecommend,
              CleanerDecision.reviewRequired,
            }
          : {
              CleanerDecision.deleteRecommend,
            };
      final deleteResult =
          await _ref.read(cleanerOrchestratorProvider).deleteByDecision(
                runResult,
                decisions: decisions,
              );
      state = state.copyWith(
        isDeleting: false,
        lastDeleteResult: deleteResult,
      );
    } catch (e) {
      final l10n = _localizations();
      state = state.copyWith(
        isDeleting: false,
        error: l10n.cleanerErrorDeleteFailed('$e'),
      );
    }
  }

  Future<void> deleteByIds(List<String> candidateIds) async {
    final runResult = state.runResult;
    if (runResult == null || candidateIds.isEmpty) return;

    state = state.copyWith(
      isDeleting: true,
      error: null,
    );

    try {
      final deleteResult =
          await _ref.read(cleanerOrchestratorProvider).deleteByIds(
                runResult,
                candidateIds,
              );
      state = state.copyWith(
        isDeleting: false,
        lastDeleteResult: deleteResult,
      );
    } catch (e) {
      final l10n = _localizations();
      state = state.copyWith(
        isDeleting: false,
        error: l10n.cleanerErrorDeleteFailed('$e'),
      );
    }
  }

  String get _effectiveLanguageCode {
    final contextLanguage = _lastContext?.language;
    if (contextLanguage != null && contextLanguage.trim().isNotEmpty) {
      return contextLanguage;
    }
    return _ref.read(settingsProvider).language;
  }

  AppLocalizations _localizations() {
    final lang = _effectiveLanguageCode.toLowerCase();
    final locale = Locale(lang.startsWith('zh') ? 'zh' : 'en');
    return lookupAppLocalizations(locale);
  }
}

final cleanerProvider = StateNotifierProvider<CleanerNotifier, CleanerState>(
  (ref) => CleanerNotifier(ref),
);
