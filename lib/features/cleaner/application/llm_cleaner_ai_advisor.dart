import 'dart:convert';

import '../../chat/domain/message.dart';
import '../../../shared/services/llm_service.dart';
import '../domain/cleaner_ai_advisor.dart';
import '../domain/cleaner_models.dart';
import 'heuristic_cleaner_ai_advisor.dart';

class LlmCleanerAiAdvisor implements CleanerAiAdvisor {
  final LLMService llmService;
  final CleanerAiAdvisor fallbackAdvisor;
  final int minBatchSize;
  final int maxBatchSize;
  final int targetPromptChars;

  LlmCleanerAiAdvisor({
    required this.llmService,
    CleanerAiAdvisor? fallbackAdvisor,
    this.minBatchSize = 24,
    this.maxBatchSize = 250,
    this.targetPromptChars = 60000,
  }) : fallbackAdvisor = fallbackAdvisor ?? const HeuristicCleanerAiAdvisor();

  @override
  Future<List<CleanerAiSuggestion>> suggest({
    required List<CleanerCandidate> candidates,
    required CleanerAiContext context,
    CleanerAiProgressCallback? onProgress,
    bool Function()? shouldStop,
  }) async {
    if (candidates.isEmpty) return const [];

    final batches = _buildAdaptiveBatches(candidates, context: context);
    final results = <CleanerAiSuggestion>[];
    final totalBatches = batches.length;
    var processedBatches = 0;

    for (final batch in batches) {
      if (shouldStop?.call() ?? false) {
        break;
      }
      final batchResults = await _suggestBatch(batch, context: context);
      results.addAll(batchResults);
      processedBatches++;
      onProgress?.call(
        List<CleanerAiSuggestion>.unmodifiable(results),
        CleanerAiProgress(
          processedBatches: processedBatches,
          totalBatches: totalBatches,
          processedCandidates: results.length,
          totalCandidates: candidates.length,
        ),
      );
    }
    return results;
  }

  List<List<CleanerCandidate>> _buildAdaptiveBatches(
    List<CleanerCandidate> candidates, {
    required CleanerAiContext context,
  }) {
    final safeMin = minBatchSize < 1 ? 1 : minBatchSize;
    final safeMax = maxBatchSize < safeMin ? safeMin : maxBatchSize;
    final safeTarget = targetPromptChars < 4000 ? 4000 : targetPromptChars;

    final batches = <List<CleanerCandidate>>[];
    var current = <CleanerCandidate>[];
    // Reserve space for system prompt and JSON wrapper.
    var currentChars = 1500;

    for (final candidate in candidates) {
      final candidateChars = _estimateCandidateChars(
        candidate,
        redactPath: context.redactPaths,
      );
      final exceedsTarget = currentChars + candidateChars > safeTarget;
      final reachedMax = current.length >= safeMax;
      final shouldSplit = current.isNotEmpty &&
          (reachedMax || (exceedsTarget && current.length >= safeMin));

      if (shouldSplit) {
        batches.add(current);
        current = <CleanerCandidate>[];
        currentChars = 1500;
      }

      current.add(candidate);
      currentChars += candidateChars;
    }

    if (current.isNotEmpty) {
      batches.add(current);
    }

    return batches;
  }

  int _estimateCandidateChars(
    CleanerCandidate candidate, {
    required bool redactPath,
  }) {
    final encoded = jsonEncode(candidate.toAiInput(redactPath: redactPath));
    return encoded.length + 48;
  }

  Future<List<CleanerAiSuggestion>> _suggestBatch(
    List<CleanerCandidate> batch, {
    required CleanerAiContext context,
  }) async {
    try {
      final response = await llmService.getResponse(
        _buildMessages(batch, context: context),
        model: context.model,
        providerId: context.providerId,
      );
      final raw = (response.content ?? '').trim();
      if (raw.isEmpty) {
        return _fallbackBatch(batch, context: context);
      }

      final parsedById = _parseSuggestions(raw);
      if (parsedById == null || parsedById.isEmpty) {
        return _fallbackBatch(batch, context: context);
      }
      return _materializeBatch(
        batch: batch,
        parsedById: parsedById,
        context: context,
      );
    } catch (_) {
      return _fallbackBatch(batch, context: context);
    }
  }

  Future<List<CleanerAiSuggestion>> _materializeBatch({
    required List<CleanerCandidate> batch,
    required Map<String, CleanerAiSuggestion> parsedById,
    required CleanerAiContext context,
  }) async {
    final fallback = await _fallbackBatch(batch, context: context);
    final fallbackById = {
      for (final suggestion in fallback) suggestion.candidateId: suggestion,
    };

    final output = <CleanerAiSuggestion>[];
    for (final candidate in batch) {
      final parsed = parsedById[candidate.id];
      if (parsed != null) {
        output.add(parsed);
        continue;
      }
      final fb = fallbackById[candidate.id];
      if (fb != null) {
        output.add(fb.copyWith(
          reasonCodes: [...fb.reasonCodes, 'missing_from_llm_output'],
        ));
      }
    }
    return output;
  }

  Future<List<CleanerAiSuggestion>> _fallbackBatch(
    List<CleanerCandidate> batch, {
    required CleanerAiContext context,
  }) {
    return fallbackAdvisor.suggest(candidates: batch, context: context);
  }

  List<Message> _buildMessages(
    List<CleanerCandidate> candidates, {
    required CleanerAiContext context,
  }) {
    final language =
        context.language.toLowerCase().startsWith('zh') ? 'zh-CN' : 'en-US';

    const systemPrompt = '''
You are a cautious storage-cleaning advisor.
You must evaluate each file candidate and produce strict JSON only.
Do not include markdown or extra prose.

Allowed decision values:
- delete_recommend
- review_required
- keep

Allowed risk_level values:
- low
- medium
- high

Output schema:
{
  "items": [
    {
      "candidate_id": "string",
      "decision": "delete_recommend|review_required|keep",
      "confidence": 0.0,
      "risk_level": "low|medium|high",
      "reason_codes": ["string"],
      "human_reason": "string"
    }
  ]
}
''';

    final payload = {
      'language': language,
      'items': candidates
          .map((c) => c.toAiInput(redactPath: context.redactPaths))
          .toList(),
    };

    return [
      Message(
        id: 'cleaner-ai-system',
        role: 'system',
        isUser: false,
        timestamp: DateTime.now(),
        content: systemPrompt,
      ),
      Message.user(jsonEncode(payload)),
    ];
  }

  Map<String, CleanerAiSuggestion>? _parseSuggestions(String raw) {
    final obj = _decodeJsonObject(raw);
    if (obj == null) return null;

    final itemsValue = obj['items'];
    if (itemsValue is! List) return null;

    final mapped = <String, CleanerAiSuggestion>{};
    for (final item in itemsValue) {
      if (item is! Map) continue;
      final map = <String, dynamic>{};
      item.forEach((key, value) {
        if (key is String) map[key] = value;
      });
      final suggestion = _parseSuggestionMap(map);
      if (suggestion == null) continue;
      mapped[suggestion.candidateId] = suggestion;
    }
    return mapped;
  }

  CleanerAiSuggestion? _parseSuggestionMap(Map<String, dynamic> map) {
    final candidateId =
        (map['candidate_id'] ?? map['candidateId'])?.toString().trim();
    if (candidateId == null || candidateId.isEmpty) return null;

    final decisionRaw = map['decision']?.toString() ?? 'review_required';
    final riskRaw = map['risk_level']?.toString() ?? 'medium';
    final confidenceRaw = map['confidence'];
    final reasonCodesRaw = map['reason_codes'];
    final humanReason = (map['human_reason']?.toString() ?? '').trim();

    final confidence = _clampConfidence(confidenceRaw);
    final reasonCodes = reasonCodesRaw is List
        ? reasonCodesRaw.map((e) => e.toString()).toList()
        : const <String>[];

    return CleanerAiSuggestion(
      candidateId: candidateId,
      decision: cleanerDecisionFromWire(decisionRaw),
      riskLevel: cleanerRiskLevelFromWire(riskRaw),
      confidence: confidence,
      reasonCodes: reasonCodes,
      humanReason: humanReason.isEmpty ? 'LLM suggestion' : humanReason,
      source: 'llm',
    );
  }

  Map<String, dynamic>? _decodeJsonObject(String raw) {
    final normalized = _stripCodeFences(raw.trim());
    final direct = _tryDecodeMap(normalized);
    if (direct != null) return direct;

    final first = normalized.indexOf('{');
    final last = normalized.lastIndexOf('}');
    if (first < 0 || last <= first) return null;

    final sliced = normalized.substring(first, last + 1);
    return _tryDecodeMap(sliced);
  }

  Map<String, dynamic>? _tryDecodeMap(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      final map = <String, dynamic>{};
      decoded.forEach((key, value) {
        if (key is String) map[key] = value;
      });
      return map;
    } catch (_) {
      return null;
    }
  }

  String _stripCodeFences(String value) {
    if (!value.startsWith('```')) return value;
    final lines = value.split(RegExp(r'\r?\n'));
    if (lines.length < 3 || lines.last.trim() != '```') return value;
    return lines.sublist(1, lines.length - 1).join('\n').trim();
  }

  double _clampConfidence(dynamic raw) {
    final parsed = switch (raw) {
      int v => v.toDouble(),
      double v => v,
      String v => double.tryParse(v),
      _ => null,
    };
    if (parsed == null) return 0.5;
    if (parsed < 0) return 0;
    if (parsed > 1) return 1;
    return parsed;
  }
}
