enum CleanerCandidateKind {
  cache,
  temporary,
  duplicate,
  largeFile,
  staleFile,
  unknown,
}

enum CleanerDecision {
  deleteRecommend,
  reviewRequired,
  keep,
}

enum CleanerRiskLevel {
  low,
  medium,
  high,
}

extension CleanerDecisionWire on CleanerDecision {
  String get wireValue {
    switch (this) {
      case CleanerDecision.deleteRecommend:
        return 'delete_recommend';
      case CleanerDecision.reviewRequired:
        return 'review_required';
      case CleanerDecision.keep:
        return 'keep';
    }
  }
}

extension CleanerRiskLevelWire on CleanerRiskLevel {
  String get wireValue {
    switch (this) {
      case CleanerRiskLevel.low:
        return 'low';
      case CleanerRiskLevel.medium:
        return 'medium';
      case CleanerRiskLevel.high:
        return 'high';
    }
  }
}

CleanerDecision cleanerDecisionFromWire(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'delete_recommend':
      return CleanerDecision.deleteRecommend;
    case 'review_required':
      return CleanerDecision.reviewRequired;
    case 'keep':
      return CleanerDecision.keep;
    default:
      return CleanerDecision.reviewRequired;
  }
}

CleanerRiskLevel cleanerRiskLevelFromWire(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'low':
      return CleanerRiskLevel.low;
    case 'medium':
      return CleanerRiskLevel.medium;
    case 'high':
      return CleanerRiskLevel.high;
    default:
      return CleanerRiskLevel.medium;
  }
}

class CleanerAiContext {
  final String language;
  final String? model;
  final String? providerId;
  final bool redactPaths;

  const CleanerAiContext({
    this.language = 'en',
    this.model,
    this.providerId,
    this.redactPaths = true,
  });
}

class CleanerAiProgress {
  final int processedBatches;
  final int totalBatches;
  final int processedCandidates;
  final int totalCandidates;

  const CleanerAiProgress({
    required this.processedBatches,
    required this.totalBatches,
    required this.processedCandidates,
    required this.totalCandidates,
  });
}

class CleanerScanOptions {
  final bool includeAppCache;
  final bool includeTemporary;
  final bool includeCommonUserRoots;
  final bool includeUserSelectedRoots;
  final bool includeUnknownInUserSelectedRoots;
  final bool includeWindowsRuleRoots;
  final bool enableTwoPhaseDirectoryScan;
  final bool enableLlmDirectoryPlanning;
  final int llmDirectoryPlanningMaxInputDirectories;
  final int profileMaxDepth;
  final int profileMaxDirectories;
  final int profileSuspiciousDirCount;
  final int profileSuspiciousMinBytes;
  final int profileLargeDirectoryThresholdBytes;
  final int maxDirectoryDepth;
  final int maxEntriesPerDirectory;
  final bool skipShallowDirectories;
  final List<String> shallowDirectoryNames;
  final bool useDefaultPathPolicy;
  final List<String> excludedPathPrefixes;
  final List<String> allowedPathPrefixes;
  final List<String> additionalRootPaths;
  final int largeFileThresholdBytes;
  final Duration staleThreshold;
  final bool detectDuplicates;
  final int maxScannedFiles;
  final int maxCandidates;
  final List<String> protectedPathPrefixes;

  const CleanerScanOptions({
    this.includeAppCache = true,
    this.includeTemporary = true,
    this.includeCommonUserRoots = true,
    this.includeUserSelectedRoots = true,
    this.includeUnknownInUserSelectedRoots = false,
    this.includeWindowsRuleRoots = true,
    this.enableTwoPhaseDirectoryScan = true,
    this.enableLlmDirectoryPlanning = true,
    this.llmDirectoryPlanningMaxInputDirectories = 240,
    this.profileMaxDepth = 3,
    this.profileMaxDirectories = 1200,
    this.profileSuspiciousDirCount = 24,
    this.profileSuspiciousMinBytes = 64 * 1024 * 1024,
    this.profileLargeDirectoryThresholdBytes = 512 * 1024 * 1024,
    this.maxDirectoryDepth = 12,
    this.maxEntriesPerDirectory = 1000,
    this.skipShallowDirectories = true,
    this.shallowDirectoryNames = const [
      'node_modules',
      '.git',
      '.github',
      '.venv',
      'venv',
      '__pycache__',
      'target',
      'vendor',
      '.npm',
      '.yarn',
      '.pnpm',
      'bower_components',
      'jspm_packages',
    ],
    this.useDefaultPathPolicy = true,
    this.excludedPathPrefixes = const [],
    this.allowedPathPrefixes = const [],
    this.additionalRootPaths = const [],
    this.largeFileThresholdBytes = 120 * 1024 * 1024,
    this.staleThreshold = const Duration(days: 90),
    this.detectDuplicates = true,
    this.maxScannedFiles = 8000,
    this.maxCandidates = 8000,
    this.protectedPathPrefixes = const [],
  });
}

class CleanerCandidate {
  final String id;
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;
  final DateTime? accessedAt;
  final CleanerCandidateKind kind;
  final bool recoverable;
  final bool isProtected;
  final String source;
  final List<String> tags;

  const CleanerCandidate({
    required this.id,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
    this.accessedAt,
    required this.kind,
    required this.recoverable,
    required this.isProtected,
    required this.source,
    this.tags = const [],
  });

  CleanerCandidate copyWith({
    String? id,
    String? path,
    int? sizeBytes,
    DateTime? modifiedAt,
    DateTime? accessedAt,
    CleanerCandidateKind? kind,
    bool? recoverable,
    bool? isProtected,
    String? source,
    List<String>? tags,
  }) {
    return CleanerCandidate(
      id: id ?? this.id,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      accessedAt: accessedAt ?? this.accessedAt,
      kind: kind ?? this.kind,
      recoverable: recoverable ?? this.recoverable,
      isProtected: isProtected ?? this.isProtected,
      source: source ?? this.source,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toAiInput({required bool redactPath}) {
    final fileName = _fileName(path);
    final extension = _extension(fileName);
    return {
      'candidate_id': id,
      'path': redactPath ? _redactPath(path) : path,
      'file_name': fileName,
      'extension': extension,
      'size_bytes': sizeBytes,
      'modified_at': modifiedAt.toUtc().toIso8601String(),
      'accessed_at': accessedAt?.toUtc().toIso8601String(),
      'kind': kind.name,
      'recoverable': recoverable,
      'is_protected': isProtected,
      'source': source,
      'tags': tags,
    };
  }

  static String _redactPath(String raw) {
    final normalized = raw.replaceAll('\\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '[REDACTED]';
    if (segments.length == 1) return '[REDACTED]/${segments[0]}';
    final last = segments[segments.length - 1];
    final parent = segments[segments.length - 2];
    return '[REDACTED]/$parent/$last';
  }

  static String _fileName(String rawPath) {
    final normalized = rawPath.replaceAll('\\', '/');
    final segments = normalized.split('/');
    for (var i = segments.length - 1; i >= 0; i--) {
      final value = segments[i].trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return rawPath.trim();
  }

  static String _extension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index <= 0 || index >= fileName.length - 1) {
      return '';
    }
    return fileName.substring(index).toLowerCase();
  }
}

class CleanerAiSuggestion {
  final String candidateId;
  final CleanerDecision decision;
  final CleanerRiskLevel riskLevel;
  final double confidence;
  final List<String> reasonCodes;
  final String humanReason;
  final String source;

  const CleanerAiSuggestion({
    required this.candidateId,
    required this.decision,
    required this.riskLevel,
    required this.confidence,
    required this.reasonCodes,
    required this.humanReason,
    required this.source,
  });

  CleanerAiSuggestion copyWith({
    String? candidateId,
    CleanerDecision? decision,
    CleanerRiskLevel? riskLevel,
    double? confidence,
    List<String>? reasonCodes,
    String? humanReason,
    String? source,
  }) {
    return CleanerAiSuggestion(
      candidateId: candidateId ?? this.candidateId,
      decision: decision ?? this.decision,
      riskLevel: riskLevel ?? this.riskLevel,
      confidence: confidence ?? this.confidence,
      reasonCodes: reasonCodes ?? this.reasonCodes,
      humanReason: humanReason ?? this.humanReason,
      source: source ?? this.source,
    );
  }
}

class CleanerReviewItem {
  final CleanerCandidate candidate;
  final CleanerAiSuggestion aiSuggestion;
  final CleanerDecision finalDecision;
  final CleanerRiskLevel finalRiskLevel;
  final List<String> policyReasons;

  const CleanerReviewItem({
    required this.candidate,
    required this.aiSuggestion,
    required this.finalDecision,
    required this.finalRiskLevel,
    required this.policyReasons,
  });

  bool get policyAdjusted =>
      finalDecision != aiSuggestion.decision ||
      finalRiskLevel != aiSuggestion.riskLevel ||
      policyReasons.isNotEmpty;
}

class CleanerRunSummary {
  final int totalCandidates;
  final int deleteRecommendedCount;
  final int reviewRequiredCount;
  final int keepCount;
  final int policyAdjustedCount;
  final int estimatedReclaimBytes;

  const CleanerRunSummary({
    required this.totalCandidates,
    required this.deleteRecommendedCount,
    required this.reviewRequiredCount,
    required this.keepCount,
    required this.policyAdjustedCount,
    required this.estimatedReclaimBytes,
  });
}

class CleanerRunResult {
  final DateTime analyzedAt;
  final List<CleanerReviewItem> items;
  final CleanerRunSummary summary;

  const CleanerRunResult({
    required this.analyzedAt,
    required this.items,
    required this.summary,
  });

  factory CleanerRunResult.empty() {
    return CleanerRunResult(
      analyzedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      items: const [],
      summary: const CleanerRunSummary(
        totalCandidates: 0,
        deleteRecommendedCount: 0,
        reviewRequiredCount: 0,
        keepCount: 0,
        policyAdjustedCount: 0,
        estimatedReclaimBytes: 0,
      ),
    );
  }
}

class CleanerDeleteItemResult {
  final String candidateId;
  final String sourcePath;
  final String? trashPath;
  final bool success;
  final int freedBytes;
  final String? error;

  const CleanerDeleteItemResult({
    required this.candidateId,
    required this.sourcePath,
    required this.trashPath,
    required this.success,
    required this.freedBytes,
    this.error,
  });
}

class CleanerDeleteBatchResult {
  final DateTime deletedAt;
  final List<CleanerDeleteItemResult> results;
  final int totalFreedBytes;

  const CleanerDeleteBatchResult({
    required this.deletedAt,
    required this.results,
    required this.totalFreedBytes,
  });

  factory CleanerDeleteBatchResult.empty() {
    return CleanerDeleteBatchResult(
      deletedAt: DateTime.now().toUtc(),
      results: const [],
      totalFreedBytes: 0,
    );
  }
}

CleanerRiskLevel maxCleanerRiskLevel(CleanerRiskLevel a, CleanerRiskLevel b) {
  final scoreA = _riskScore(a);
  final scoreB = _riskScore(b);
  return scoreA >= scoreB ? a : b;
}

int _riskScore(CleanerRiskLevel level) {
  switch (level) {
    case CleanerRiskLevel.low:
      return 1;
    case CleanerRiskLevel.medium:
      return 2;
    case CleanerRiskLevel.high:
      return 3;
  }
}
