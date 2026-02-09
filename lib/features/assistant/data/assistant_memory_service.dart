import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../chat/data/message_entity.dart';
import '../../chat/domain/message.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../assistant/domain/assistant.dart';
import '../../../shared/services/llm_service.dart';
import 'assistant_memory_item_entity.dart';
import 'assistant_memory_job_entity.dart';
import 'assistant_memory_state_entity.dart';

class AssistantMemoryService {
  AssistantMemoryService({
    required Isar isar,
    required LLMService llmService,
  })  : _isar = isar,
        _llmService = llmService;

  final Isar _isar;
  final LLMService _llmService;
  final Map<String, Timer> _idleTimers = {};

  static const Set<String> _allowedKeys = {
    'language',
    'verbosity',
    'answer_first',
    'format',
    'emoji',
    'unit_system',
    'timezone',
    'code_style',
    'tone',
    'structure',
  };

  void dispose() {
    for (final timer in _idleTimers.values) {
      timer.cancel();
    }
    _idleTimers.clear();
  }

  Future<String> buildMemorySystemPrompt(String assistantId) async {
    if (assistantId.isEmpty) return '';
    final items = await _isar.assistantMemoryItemEntitys
        .filter()
        .assistantIdEqualTo(assistantId)
        .isActiveEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();
    if (items.isEmpty) return '';

    final lines = items.take(12).map((item) {
      final rendered = _renderValue(item.valueJson);
      return '- ${item.key}: $rendered';
    }).join('\n');

    return '''
# Assistant Memory (Profile Preferences)
Use these preferences when relevant.
If the current user message conflicts with these preferences, follow the current user message.
$lines
''';
  }

  Future<void> onRequestCompleted({
    required Assistant assistant,
    required SettingsState settings,
    required String requestId,
  }) async {
    if (!assistant.enableMemory || assistant.id.isEmpty || requestId.isEmpty) {
      return;
    }

    final assistantId = assistant.id;
    final requestSucceeded =
        await _hasSuccessfulAssistantResponse(assistantId, requestId);
    if (!requestSucceeded) return;

    await _touchLastObservedMessageAt(assistantId);
    await _runDueJobs(assistant: assistant, settings: settings);

    final shouldQueue = await _shouldQueueConsolidation(
      assistantId: assistantId,
      settings: settings,
      forceIdleCheck: false,
    );
    if (shouldQueue) {
      await _enqueueConsolidationJob(assistantId: assistantId);
      await _runDueJobs(assistant: assistant, settings: settings);
    }

    _scheduleIdleCheck(assistant: assistant, settings: settings);
  }

  void _scheduleIdleCheck({
    required Assistant assistant,
    required SettingsState settings,
  }) {
    final assistantId = assistant.id;
    if (assistantId.isEmpty || !assistant.enableMemory) return;
    final idleSeconds = settings.memoryIdleSeconds;
    if (idleSeconds <= 0) return;

    _idleTimers[assistantId]?.cancel();
    _idleTimers[assistantId] = Timer(
      Duration(seconds: idleSeconds),
      () async {
        final shouldQueue = await _shouldQueueConsolidation(
          assistantId: assistantId,
          settings: settings,
          forceIdleCheck: true,
        );
        if (!shouldQueue) return;
        await _enqueueConsolidationJob(assistantId: assistantId);
        await _runDueJobs(assistant: assistant, settings: settings);
      },
    );
  }

  Future<void> _runDueJobs({
    required Assistant assistant,
    required SettingsState settings,
  }) async {
    if (!assistant.enableMemory || assistant.id.isEmpty) return;
    final now = DateTime.now();
    final jobs = await _isar.assistantMemoryJobEntitys
        .filter()
        .assistantIdEqualTo(assistant.id)
        .sortByCreatedAt()
        .findAll();

    AssistantMemoryJobEntity? candidate;
    for (final job in jobs) {
      if (job.status == 'succeeded') continue;
      final lockExpired =
          job.lockedUntil == null || job.lockedUntil!.isBefore(now);
      final retryDue =
          job.nextRetryAt == null || !job.nextRetryAt!.isAfter(now);
      if (lockExpired && retryDue) {
        candidate = job;
        break;
      }
    }
    if (candidate == null) return;

    await _runSingleJob(
      assistant: assistant,
      settings: settings,
      jobId: candidate.jobId,
    );
  }

  Future<bool> _shouldQueueConsolidation({
    required String assistantId,
    required SettingsState settings,
    required bool forceIdleCheck,
  }) async {
    final state = await _getOrCreateState(assistantId);
    if (!_underDailyBudget(
      state: state,
      maxRunsPerDay: settings.memoryMaxRunsPerDay,
      now: DateTime.now(),
    )) {
      return false;
    }

    final buffered = await _loadSuccessfulBufferedMessages(
      assistantId: assistantId,
      afterMessageId: state.consolidatedUntilMessageId,
    );
    if (buffered.isEmpty) return false;

    final userCount = buffered.where((m) => m.isUser).length;
    if (userCount >= settings.memoryMinNewUserMessages) {
      return true;
    }
    if (buffered.length >= settings.memoryMaxBufferedMessages) {
      return true;
    }

    final now = DateTime.now();
    final lastAt = buffered.last.timestamp;
    final idleReached =
        now.difference(lastAt).inSeconds >= settings.memoryIdleSeconds;
    if (forceIdleCheck && idleReached) {
      return true;
    }
    return false;
  }

  Future<void> _enqueueConsolidationJob({
    required String assistantId,
  }) async {
    final state = await _getOrCreateState(assistantId);
    final buffered = await _loadSuccessfulBufferedMessages(
      assistantId: assistantId,
      afterMessageId: state.consolidatedUntilMessageId,
    );
    if (buffered.isEmpty) return;

    final endMessageId = buffered.last.id;
    final jobs = await _isar.assistantMemoryJobEntitys
        .filter()
        .assistantIdEqualTo(assistantId)
        .findAll();
    final hasActiveJob = jobs.any(
        (job) => job.status != 'succeeded' && job.endMessageId >= endMessageId);
    if (hasActiveJob) return;

    final job = AssistantMemoryJobEntity()
      ..jobId = const Uuid().v4()
      ..assistantId = assistantId
      ..startMessageId = state.consolidatedUntilMessageId + 1
      ..endMessageId = endMessageId
      ..status = 'pending'
      ..attemptCount = 0
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..nextRetryAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.assistantMemoryJobEntitys.put(job);
    });
  }

  Future<void> _runSingleJob({
    required Assistant assistant,
    required SettingsState settings,
    required String jobId,
  }) async {
    AssistantMemoryJobEntity? job = await _isar.assistantMemoryJobEntitys
        .filter()
        .jobIdEqualTo(jobId)
        .findFirst();
    if (job == null || job.status == 'succeeded') return;

    final now = DateTime.now();
    if (job.lockedUntil != null && job.lockedUntil!.isAfter(now)) return;

    await _isar.writeTxn(() async {
      final latest = await _isar.assistantMemoryJobEntitys
          .filter()
          .jobIdEqualTo(jobId)
          .findFirst();
      if (latest == null) return;
      latest.status = 'running';
      latest.attemptCount += 1;
      latest.lockedUntil = now.add(const Duration(minutes: 2));
      latest.updatedAt = now;
      await _isar.assistantMemoryJobEntitys.put(latest);
      job = latest;
    });

    final lockedJob = job;
    if (lockedJob == null) return;

    try {
      final state = await _getOrCreateState(assistant.id);
      final messages = await _loadSuccessfulBufferedMessages(
        assistantId: assistant.id,
        afterMessageId: state.consolidatedUntilMessageId,
      );
      final bounded = messages
          .where((m) => m.id <= lockedJob.endMessageId)
          .toList(growable: false);

      if (bounded.isEmpty) {
        await _markJobSuccess(
            jobId: lockedJob.jobId, endMessageId: lockedJob.endMessageId);
        return;
      }

      final windowSize = settings.memoryContextWindowSize.clamp(20, 240);
      final contextMessages = bounded.length > windowSize
          ? bounded.sublist(bounded.length - windowSize)
          : bounded;
      final existingItems = await _isar.assistantMemoryItemEntitys
          .filter()
          .assistantIdEqualTo(assistant.id)
          .isActiveEqualTo(true)
          .findAll();

      final payload = _buildConsolidationPayload(
        contextMessages: contextMessages,
        existingItems: existingItems,
      );

      final model = (assistant.memoryModel?.isNotEmpty ?? false)
          ? assistant.memoryModel
          : settings.activeProvider.selectedModel;
      final providerId = (assistant.memoryProviderId?.isNotEmpty ?? false)
          ? assistant.memoryProviderId
          : settings.activeProviderId;

      final response = await _llmService.getResponse(
        [
          Message(
            id: const Uuid().v4(),
            role: 'system',
            content: _memorySystemPrompt,
            timestamp: DateTime.now(),
            isUser: false,
          ),
          Message.user(payload),
        ],
        model: model,
        providerId: providerId,
      );

      final raw = response.content?.trim() ?? '';
      if (raw.isEmpty) {
        throw const FormatException(
            'memory consolidation returned empty content');
      }

      final decoded = _decodePayload(raw);
      final opsValue = decoded['ops'];
      if (opsValue is! List) {
        throw const FormatException('memory consolidation payload missing ops');
      }

      final existingById = {
        for (final item in existingItems) item.memoryId: item,
      };
      final upserts = <AssistantMemoryItemEntity>[];

      for (final opAny in opsValue) {
        if (opAny is! Map) continue;
        final op = opAny.map((key, value) => MapEntry(key.toString(), value));
        final action = (op['op']?.toString().toLowerCase() ?? 'upsert');
        final key = op['key']?.toString().trim() ?? '';
        if (!_allowedKeys.contains(key) || key.isEmpty) continue;

        final memoryId = '${assistant.id}::$key';
        if (action == 'delete') {
          final existing = existingById[memoryId];
          if (existing != null) {
            existing.isActive = false;
            existing.updatedAt = DateTime.now();
            upserts.add(existing);
          }
          continue;
        }

        final value = op['value'];
        if (value == null) continue;
        final confidenceRaw = op['confidence'];
        final confidence = (confidenceRaw is num)
            ? confidenceRaw.toDouble().clamp(0.0, 1.0)
            : 0.6;
        final evidenceRaw = op['evidence_message_ids'];
        final evidence = <int>[];
        if (evidenceRaw is List) {
          for (final e in evidenceRaw) {
            if (e is int) {
              evidence.add(e);
            } else {
              final parsed = int.tryParse(e.toString());
              if (parsed != null) evidence.add(parsed);
            }
          }
        }

        final target = existingById[memoryId] ?? AssistantMemoryItemEntity()
          ..memoryId = memoryId
          ..assistantId = assistant.id
          ..key = key
          ..createdAt = DateTime.now();
        target.valueJson = jsonEncode(value);
        target.confidence = confidence;
        target.updatedAt = DateTime.now();
        target.lastSeenAt = DateTime.now();
        target.evidenceMessageIds = evidence;
        target.isActive = true;
        upserts.add(target);
      }

      final memoryState = await _getOrCreateState(assistant.id);
      await _isar.writeTxn(() async {
        if (upserts.isNotEmpty) {
          await _isar.assistantMemoryItemEntitys.putAll(upserts);
        }

        final today = _dayKey(DateTime.now());
        if (memoryState.runsDayKey != today) {
          memoryState.runsToday = 0;
          memoryState.runsDayKey = today;
        }
        memoryState.runsToday += 1;
        memoryState.lastSuccessfulRunAt = DateTime.now();
        memoryState.consolidatedUntilMessageId =
            max(memoryState.consolidatedUntilMessageId, lockedJob.endMessageId);
        await _isar.assistantMemoryStateEntitys.put(memoryState);

        final latestJob = await _isar.assistantMemoryJobEntitys
            .filter()
            .jobIdEqualTo(lockedJob.jobId)
            .findFirst();
        if (latestJob != null) {
          latestJob.status = 'succeeded';
          latestJob.lockedUntil = null;
          latestJob.nextRetryAt = null;
          latestJob.updatedAt = DateTime.now();
          latestJob.lastError = null;
          await _isar.assistantMemoryJobEntitys.put(latestJob);
        }
      });
    } catch (error) {
      await _markJobFailed(jobId: lockedJob.jobId, error: error.toString());
    }
  }

  Future<void> _markJobFailed({
    required String jobId,
    required String error,
  }) async {
    await _isar.writeTxn(() async {
      final job = await _isar.assistantMemoryJobEntitys
          .filter()
          .jobIdEqualTo(jobId)
          .findFirst();
      if (job == null) return;
      final retryMinutes =
          min(60, pow(2, max(0, job.attemptCount - 1)).toInt());
      job.status = 'failed';
      job.lastError = error;
      job.lockedUntil = null;
      job.nextRetryAt = DateTime.now().add(Duration(minutes: retryMinutes));
      job.updatedAt = DateTime.now();
      await _isar.assistantMemoryJobEntitys.put(job);
    });
  }

  Future<void> _markJobSuccess({
    required String jobId,
    required int endMessageId,
  }) async {
    final job = await _isar.assistantMemoryJobEntitys
        .filter()
        .jobIdEqualTo(jobId)
        .findFirst();
    if (job == null) return;
    final state = await _getOrCreateState(job.assistantId);

    await _isar.writeTxn(() async {
      final latestJob = await _isar.assistantMemoryJobEntitys
          .filter()
          .jobIdEqualTo(jobId)
          .findFirst();
      if (latestJob == null) return;
      latestJob.status = 'succeeded';
      latestJob.lockedUntil = null;
      latestJob.nextRetryAt = null;
      latestJob.updatedAt = DateTime.now();
      latestJob.lastError = null;
      await _isar.assistantMemoryJobEntitys.put(latestJob);

      state.consolidatedUntilMessageId =
          max(state.consolidatedUntilMessageId, endMessageId);
      await _isar.assistantMemoryStateEntitys.put(state);
    });
  }

  Future<void> _touchLastObservedMessageAt(String assistantId) async {
    if (assistantId.isEmpty) return;
    final state = await _getOrCreateState(assistantId);
    state.lastObservedMessageAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.assistantMemoryStateEntitys.put(state);
    });
  }

  Future<AssistantMemoryStateEntity> _getOrCreateState(
      String assistantId) async {
    if (assistantId.isEmpty) {
      throw ArgumentError('assistantId must not be empty');
    }
    final found = await _isar.assistantMemoryStateEntitys
        .filter()
        .assistantIdEqualTo(assistantId)
        .findFirst();
    if (found != null) return found;
    final created = AssistantMemoryStateEntity()
      ..assistantId = assistantId
      ..consolidatedUntilMessageId = 0
      ..runsToday = 0
      ..runsDayKey = _dayKey(DateTime.now());
    await _isar.writeTxn(() async {
      await _isar.assistantMemoryStateEntitys.put(created);
    });
    return created;
  }

  Future<bool> _hasSuccessfulAssistantResponse(
    String assistantId,
    String requestId,
  ) async {
    final messages = await _isar.messageEntitys
        .filter()
        .assistantIdEqualTo(assistantId)
        .requestIdEqualTo(requestId)
        .findAll();
    for (final message in messages) {
      final role = message.role ?? (message.isUser ? 'user' : 'assistant');
      if (role != 'assistant') continue;
      if (message.content.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<List<MessageEntity>> _loadSuccessfulBufferedMessages({
    required String assistantId,
    required int afterMessageId,
  }) async {
    final entities = await _isar.messageEntitys
        .filter()
        .assistantIdEqualTo(assistantId)
        .idGreaterThan(afterMessageId)
        .requestIdIsNotNull()
        .sortByTimestamp()
        .findAll();
    if (entities.isEmpty) return const [];
    entities.sort((a, b) => a.id.compareTo(b.id));

    final successfulRequestIds = <String>{};
    for (final message in entities) {
      final role = message.role ?? (message.isUser ? 'user' : 'assistant');
      if (role != 'assistant') continue;
      if (message.content.trim().isEmpty) continue;
      final requestId = message.requestId;
      if (requestId == null || requestId.isEmpty) continue;
      successfulRequestIds.add(requestId);
    }
    if (successfulRequestIds.isEmpty) return const [];

    final filtered = <MessageEntity>[];
    for (final message in entities) {
      final requestId = message.requestId;
      if (requestId == null || !successfulRequestIds.contains(requestId)) {
        continue;
      }
      final role = message.role ?? (message.isUser ? 'user' : 'assistant');
      if (role == 'user' || role == 'assistant') {
        filtered.add(message);
      }
    }
    return filtered;
  }

  bool _underDailyBudget({
    required AssistantMemoryStateEntity state,
    required int maxRunsPerDay,
    required DateTime now,
  }) {
    final limit = max(1, maxRunsPerDay);
    final today = _dayKey(now);
    if (state.runsDayKey != today) return true;
    return state.runsToday < limit;
  }

  String _buildConsolidationPayload({
    required List<MessageEntity> contextMessages,
    required List<AssistantMemoryItemEntity> existingItems,
  }) {
    final transcript = contextMessages.map((m) {
      final role = m.isUser ? 'user' : (m.role ?? 'assistant');
      var content = m.content.trim();
      if (content.length > 600) {
        content = '${content.substring(0, 600)} ...';
      }
      return {
        'id': m.id,
        'role': role,
        'content': content,
      };
    }).toList();

    final existing = <Map<String, dynamic>>[];
    for (final item in existingItems) {
      existing.add({
        'key': item.key,
        'value': _decodeValue(item.valueJson),
        'confidence': item.confidence,
      });
    }

    return jsonEncode({
      'allowed_keys': _allowedKeys.toList(),
      'existing_preferences': existing,
      'transcript': transcript,
      'output_contract': {
        'ops': [
          {
            'op': 'upsert',
            'key': 'verbosity',
            'value': 'short',
            'confidence': 0.85,
            'evidence_message_ids': [123, 130]
          },
          {
            'op': 'delete',
            'key': 'emoji',
            'confidence': 0.7,
            'evidence_message_ids': [131]
          }
        ],
        'notes': 'ops can be empty, but payload must be non-empty JSON',
      },
    });
  }

  dynamic _decodeValue(String valueJson) {
    try {
      return jsonDecode(valueJson);
    } catch (_) {
      return valueJson;
    }
  }

  String _renderValue(String valueJson) {
    final decoded = _decodeValue(valueJson);
    if (decoded is String) return decoded;
    return jsonEncode(decoded);
  }

  Map<String, dynamic> _decodePayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}

    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    final match = fence.firstMatch(raw);
    if (match != null) {
      final body = match.group(1)?.trim();
      if (body != null && body.isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      }
    }
    throw const FormatException('invalid memory consolidation payload');
  }

  String _dayKey(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '${time.year}-$month-$day';
  }
}

const String _memorySystemPrompt = '''
You are a profile-preference extractor.
Read transcript messages and update assistant-scoped user preferences.
Only output JSON object, no prose.
Rules:
1) Use only allowed_keys.
2) Keep stable preferences, ignore one-off requests.
3) If no changes, output {"ops":[]}.
4) Confidence must be 0..1.
''';
