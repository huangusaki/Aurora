import 'package:aurora/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

import '../domain/cleaner_models.dart';

class CleanerPolicyConfig {
  final double minConfidenceForDelete;
  final int largeFileReviewThresholdBytes;
  final bool requireRecoverableForDelete;
  final bool executableRequiresReview;

  const CleanerPolicyConfig({
    this.minConfidenceForDelete = 0.65,
    this.largeFileReviewThresholdBytes = 512 * 1024 * 1024,
    this.requireRecoverableForDelete = true,
    this.executableRequiresReview = true,
  });
}

class CleanerPolicyEngine {
  final CleanerPolicyConfig config;

  const CleanerPolicyEngine({this.config = const CleanerPolicyConfig()});

  List<CleanerReviewItem> evaluateAll({
    required List<CleanerCandidate> candidates,
    required List<CleanerAiSuggestion> suggestions,
    String languageCode = 'en',
  }) {
    final byId = {
      for (final suggestion in suggestions) suggestion.candidateId: suggestion,
    };
    return candidates.map((candidate) {
      final suggestion =
          byId[candidate.id] ?? _defaultSuggestion(candidate.id, languageCode);
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

    if (candidate.isProtected) {
      finalDecision = CleanerDecision.keep;
      finalRisk = CleanerRiskLevel.high;
      policyReasons.add('candidate_marked_protected');
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

    if (finalDecision == CleanerDecision.deleteRecommend &&
        config.executableRequiresReview &&
        _isExecutablePath(candidate.path)) {
      finalDecision = CleanerDecision.reviewRequired;
      finalRisk = maxCleanerRiskLevel(finalRisk, CleanerRiskLevel.high);
      policyReasons.add('executable_requires_review');
    }

    return CleanerReviewItem(
      candidate: candidate,
      aiSuggestion: suggestion,
      finalDecision: finalDecision,
      finalRiskLevel: finalRisk,
      policyReasons: policyReasons,
    );
  }

  CleanerAiSuggestion _defaultSuggestion(
    String candidateId,
    String languageCode,
  ) {
    final l10n = _lookupCleanerLocalizations(languageCode);
    return CleanerAiSuggestion(
      candidateId: candidateId,
      decision: CleanerDecision.reviewRequired,
      riskLevel: CleanerRiskLevel.medium,
      confidence: 0.5,
      reasonCodes: const ['missing_ai_suggestion'],
      humanReason: l10n.cleanerPolicyDefaultAiUnavailable,
      source: 'policy-default',
    );
  }

  AppLocalizations _lookupCleanerLocalizations(String languageCode) {
    final normalized = languageCode.toLowerCase();
    final locale = Locale(normalized.startsWith('zh') ? 'zh' : 'en');
    return lookupAppLocalizations(locale);
  }

  bool _isExecutablePath(String rawPath) {
    final normalized = rawPath.trim().toLowerCase().replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= fileName.length - 1) {
      return false;
    }
    final extension = fileName.substring(dotIndex);
    return _executableExtensions.contains(extension);
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
