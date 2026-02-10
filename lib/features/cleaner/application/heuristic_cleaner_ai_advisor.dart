import 'package:aurora/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

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
    final l10n = _lookupCleanerLocalizations(context.language);
    final suggestions = candidates.map((candidate) {
      return _suggestOne(candidate, l10n: l10n);
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
    required AppLocalizations l10n,
  }) {
    final fileName = _extractFileName(candidate.path);
    final extension = _extractExtension(fileName);
    final hasDisposableSignal = _disposableExtensions.contains(extension) ||
        _containsAny(fileName, _disposableKeywords);
    final hasValuableSignal = _valuableExtensions.contains(extension);
    final isExecutable = _executableExtensions.contains(extension);
    final extLabel =
        extension.isEmpty ? l10n.cleanerHeuristicNoExtension : extension;

    if (candidate.isProtected) {
      return CleanerAiSuggestion(
        candidateId: candidate.id,
        decision: CleanerDecision.keep,
        riskLevel: CleanerRiskLevel.high,
        confidence: 0.95,
        reasonCodes: const ['protected_candidate'],
        humanReason: l10n.cleanerHeuristicProtected,
        source: 'heuristic',
      );
    }

    if (isExecutable) {
      return CleanerAiSuggestion(
        candidateId: candidate.id,
        decision: CleanerDecision.reviewRequired,
        riskLevel: CleanerRiskLevel.high,
        confidence: 0.92,
        reasonCodes: const ['executable_or_script_requires_review'],
        humanReason: l10n.cleanerHeuristicExecutableReview(extLabel),
        source: 'heuristic',
      );
    }

    if (hasValuableSignal && candidate.kind != CleanerCandidateKind.duplicate) {
      return CleanerAiSuggestion(
        candidateId: candidate.id,
        decision: CleanerDecision.keep,
        riskLevel: CleanerRiskLevel.high,
        confidence: 0.84,
        reasonCodes: const ['valuable_file_type_keep'],
        humanReason: l10n.cleanerHeuristicValuableKeep(extLabel),
        source: 'heuristic',
      );
    }

    if (hasDisposableSignal &&
        (candidate.kind == CleanerCandidateKind.cache ||
            candidate.kind == CleanerCandidateKind.temporary ||
            candidate.kind == CleanerCandidateKind.staleFile ||
            candidate.kind == CleanerCandidateKind.unknown)) {
      return CleanerAiSuggestion(
        candidateId: candidate.id,
        decision: CleanerDecision.deleteRecommend,
        riskLevel: CleanerRiskLevel.low,
        confidence: 0.9,
        reasonCodes: const ['disposable_name_or_extension'],
        humanReason: l10n.cleanerHeuristicDisposableDelete(extLabel),
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
          humanReason: l10n.cleanerHeuristicCachePathDelete(extLabel),
          source: 'heuristic',
        );
      case CleanerCandidateKind.duplicate:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.reviewRequired,
          riskLevel: CleanerRiskLevel.medium,
          confidence: 0.74,
          reasonCodes: const ['possible_duplicate', 'needs_user_choice'],
          humanReason: l10n.cleanerHeuristicDuplicateReview(extLabel),
          source: 'heuristic',
        );
      case CleanerCandidateKind.largeFile:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.reviewRequired,
          riskLevel: CleanerRiskLevel.medium,
          confidence: 0.66,
          reasonCodes: const ['large_file', 'value_unknown'],
          humanReason: l10n.cleanerHeuristicLargeFileReview(extLabel),
          source: 'heuristic',
        );
      case CleanerCandidateKind.staleFile:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.reviewRequired,
          riskLevel: CleanerRiskLevel.medium,
          confidence: 0.68,
          reasonCodes: const ['stale_unused', 'needs_confirmation'],
          humanReason: l10n.cleanerHeuristicStaleFileReview(extLabel),
          source: 'heuristic',
        );
      case CleanerCandidateKind.unknown:
        return CleanerAiSuggestion(
          candidateId: candidate.id,
          decision: CleanerDecision.keep,
          riskLevel: CleanerRiskLevel.high,
          confidence: 0.55,
          reasonCodes: const ['insufficient_signal'],
          humanReason: l10n.cleanerHeuristicInsufficientSignal(extLabel),
          source: 'heuristic',
        );
    }
  }

  AppLocalizations _lookupCleanerLocalizations(String languageCode) {
    final normalized = languageCode.toLowerCase();
    final locale = Locale(normalized.startsWith('zh') ? 'zh' : 'en');
    return lookupAppLocalizations(locale);
  }

  String _extractFileName(String rawPath) {
    final normalized = rawPath.replaceAll('\\', '/');
    final segments = normalized.split('/');
    for (var i = segments.length - 1; i >= 0; i--) {
      final segment = segments[i].trim();
      if (segment.isNotEmpty) {
        return segment.toLowerCase();
      }
    }
    return normalized.trim().toLowerCase();
  }

  String _extractExtension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index <= 0 || index >= fileName.length - 1) {
      return '';
    }
    return fileName.substring(index).toLowerCase();
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}

const Set<String> _executableExtensions = <String>{
  '.exe',
  '.msi',
  '.bat',
  '.cmd',
  '.ps1',
  '.vbs',
  '.js',
  '.jar',
  '.com',
  '.scr',
  '.pif',
  '.lnk',
  '.sh',
  '.bash',
  '.zsh',
  '.fish',
  '.appimage',
  '.apk',
  '.ipa',
};

const Set<String> _disposableExtensions = <String>{
  '.tmp',
  '.temp',
  '.log',
  '.dmp',
  '.mdmp',
  '.etl',
  '.trace',
  '.old',
  '.bak',
  '.part',
  '.download',
  '.partial',
  '.cache',
  '.thumbcache',
};

const List<String> _disposableKeywords = <String>[
  'temp',
  'tmp',
  'cache',
  'log',
  'logs',
  'trace',
  'dump',
  'crash',
  'thumbnail',
  'thumbcache',
];

const Set<String> _valuableExtensions = <String>{
  '.doc',
  '.docx',
  '.xls',
  '.xlsx',
  '.ppt',
  '.pptx',
  '.pdf',
  '.txt',
  '.md',
  '.csv',
  '.sql',
  '.db',
  '.sqlite',
  '.sqlite3',
  '.zip',
  '.rar',
  '.7z',
  '.tar',
  '.gz',
  '.mp4',
  '.mkv',
  '.avi',
  '.mov',
  '.mp3',
  '.flac',
  '.wav',
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.gif',
};
