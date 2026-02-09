import 'dart:convert';
import 'dart:io';
import 'package:aurora/shared/utils/translation_prompt_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../settings/data/settings_storage.dart';
import 'message_entity.dart';
import 'session_entity.dart';
import 'topic_entity.dart';
import '../domain/message.dart';

Future<void> _deleteAttachmentFiles(List<String> paths) async {
  for (final path in paths) {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete attachment: $path, error: $e');
    }
  }
}

class ChatStorage {
  final Isar _isar;
  final SettingsStorage _settingsStorage;
  final Map<String, List<Message>> _messagesCache = {};
  ChatStorage(this._settingsStorage) : _isar = _settingsStorage.isar;

  int _effectiveTokenTotalFromMessage(Message message) {
    final splitProvided = message.promptTokens != null ||
        message.completionTokens != null ||
        message.reasoningTokens != null;
    final splitTotal = (message.promptTokens ?? 0) +
        (message.completionTokens ?? 0) +
        (message.reasoningTokens ?? 0);
    final legacyTotal = message.tokenCount ?? 0;

    if (splitProvided && splitTotal > 0) return splitTotal;
    if (legacyTotal > 0) return legacyTotal;
    return splitTotal;
  }

  int _effectiveTokenTotalFromEntity(MessageEntity entity) {
    final splitProvided = entity.promptTokens != null ||
        entity.completionTokens != null ||
        entity.reasoningTokens != null;
    final splitTotal = (entity.promptTokens ?? 0) +
        (entity.completionTokens ?? 0) +
        (entity.reasoningTokens ?? 0);
    final legacyTotal = entity.tokenCount ?? 0;

    if (splitProvided && splitTotal > 0) return splitTotal;
    if (legacyTotal > 0) return legacyTotal;
    return splitTotal;
  }

  Future<List<String>> _findUnreferencedAttachments(
    Iterable<String> candidatePaths, {
    Set<int> excludedMessageIds = const {},
    Set<String> excludedSessionIds = const {},
  }) async {
    final targets = candidatePaths
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toSet();
    if (targets.isEmpty) return const [];

    final referenced = <String>{};
    final messages = await _isar.messageEntitys.where().findAll();
    for (final msg in messages) {
      if (excludedMessageIds.contains(msg.id)) continue;
      final sid = msg.sessionId;
      if (sid != null && excludedSessionIds.contains(sid)) continue;
      if (msg.attachments.isEmpty) continue;
      for (final path in msg.attachments) {
        if (!targets.contains(path)) continue;
        referenced.add(path);
        if (referenced.length == targets.length) {
          return const [];
        }
      }
    }

    return targets.where((path) => !referenced.contains(path)).toList();
  }

  Future<void> preloadAllSessions() async {
    final sw = Stopwatch()..start();
    final sessions = await loadSessions();
    for (final session in sessions) {
      if (!_messagesCache.containsKey(session.sessionId)) {
        _messagesCache[session.sessionId] =
            await _loadHistoryFromDb(session.sessionId);
      }
    }
    debugPrint(
        'ChatStorage: preloadAllSessions completed in ${sw.elapsedMilliseconds}ms for ${sessions.length} sessions');
  }

  Future<String> saveMessage(Message message, String sessionId) async {
    final entity = MessageEntity()
      ..timestamp = message.timestamp
      ..isUser = message.isUser
      ..content = message.content
      ..reasoningContent = message.reasoningContent
      ..attachments = message.attachments
      ..images = message.images
      ..model = message.model
      ..provider = message.provider
      ..reasoningDurationSeconds = message.reasoningDurationSeconds
      ..sessionId = sessionId
      ..assistantId = message.assistantId
      ..requestId = message.requestId
      ..role = message.role
      ..toolCallId = message.toolCallId
      ..tokenCount = message.tokenCount
      ..firstTokenMs = message.firstTokenMs
      ..durationMs = message.durationMs
      ..promptTokens = message.promptTokens
      ..reasoningTokens = message.reasoningTokens
      ..completionTokens = message.completionTokens;
    if (message.toolCalls != null) {
      entity.toolCallsJson =
          jsonEncode(message.toolCalls!.map((tc) => tc.toJson()).toList());
    }
    await _isar.writeTxn(() async {
      await _isar.messageEntitys.put(entity);
      final session = await _isar.sessionEntitys.getBySessionId(sessionId);
      if (session != null) {
        var shouldPersistSession = false;
        if (message.isUser) {
          session.lastMessageTime = message.timestamp;
          shouldPersistSession = true;
        }
        final msgTotal = _effectiveTokenTotalFromMessage(message);
        if (msgTotal > 0) {
          session.totalTokens += msgTotal;
          shouldPersistSession = true;
        }
        if (shouldPersistSession) {
          await _isar.sessionEntitys.put(session);
        }
      }
    });
    if (_messagesCache.containsKey(sessionId)) {
      final cachedMessage = message.copyWith(id: entity.id.toString());
      _messagesCache[sessionId]!.add(cachedMessage);
    }
    return entity.id.toString();
  }

  Future<void> saveHistory(List<Message> messages, String sessionId) async {
    await _isar.writeTxn(() async {
      await _isar.messageEntitys
          .filter()
          .sessionIdEqualTo(sessionId)
          .deleteAll();
      final entities = messages.map((m) {
        final e = MessageEntity()
          ..timestamp = m.timestamp
          ..isUser = m.isUser
          ..content = m.content
          ..reasoningContent = m.reasoningContent
          ..attachments = m.attachments
          ..images = m.images
          ..model = m.model
          ..provider = m.provider
          ..reasoningDurationSeconds = m.reasoningDurationSeconds
          ..sessionId = sessionId
          ..assistantId = m.assistantId
          ..requestId = m.requestId
          ..role = m.role
          ..toolCallId = m.toolCallId
          ..tokenCount = m.tokenCount
          ..firstTokenMs = m.firstTokenMs
          ..durationMs = m.durationMs
          ..promptTokens = m.promptTokens
          ..completionTokens = m.completionTokens
          ..reasoningTokens = m.reasoningTokens;
        if (m.toolCalls != null) {
          e.toolCallsJson =
              jsonEncode(m.toolCalls!.map((tc) => tc.toJson()).toList());
        }
        return e;
      }).toList();
      await _isar.messageEntitys.putAll(entities);

      DateTime? lastUserMessageTime;
      for (int i = messages.length - 1; i >= 0; i--) {
        if (messages[i].isUser) {
          lastUserMessageTime = messages[i].timestamp;
          break;
        }
      }
      if (lastUserMessageTime != null) {
        final session = await _isar.sessionEntitys.getBySessionId(sessionId);
        if (session != null) {
          session.lastMessageTime = lastUserMessageTime;
          await _isar.sessionEntitys.put(session);
        }
      }
    });
    _messagesCache[sessionId] = List.of(messages);
  }

  Future<List<Message>> loadHistory(String sessionId) async {
    if (_messagesCache.containsKey(sessionId)) {
      debugPrint('ChatStorage: loadHistory cache HIT for $sessionId');
      return List.from(_messagesCache[sessionId]!);
    }
    debugPrint(
        'ChatStorage: loadHistory cache MISS for $sessionId, loading from DB');
    final messages = await _loadHistoryFromDb(sessionId);
    _messagesCache[sessionId] = messages;
    return List.from(messages);
  }

  Future<List<Message>> _loadHistoryFromDb(String sessionId) async {
    final entities = await _isar.messageEntitys
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestamp()
        .findAll();
    return entities.map((e) {
      List<ToolCall>? toolCalls;
      if (e.toolCallsJson != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(e.toolCallsJson!);
          toolCalls = jsonList.map((json) {
            return ToolCall(
              id: json['id'] as String,
              type: json['type'] as String,
              name: json['function']['name'] as String,
              arguments: json['function']['arguments'] as String,
            );
          }).toList();
        } catch (e) {
          debugPrint('Error parsing toolCallsJson: $e');
        }
      }
      return Message(
        id: e.id.toString(),
        content: e.content,
        isUser: e.isUser,
        timestamp: e.timestamp,
        reasoningContent: e.reasoningContent,
        attachments: e.attachments,
        images: e.images,
        model: e.model,
        provider: e.provider,
        reasoningDurationSeconds: e.reasoningDurationSeconds,
        role: e.role,
        assistantId: e.assistantId,
        requestId: e.requestId,
        toolCallId: e.toolCallId,
        toolCalls: toolCalls,
        tokenCount: e.tokenCount,
        firstTokenMs: e.firstTokenMs,
        durationMs: e.durationMs,
        promptTokens: e.promptTokens,
        completionTokens: e.completionTokens,
        reasoningTokens: e.reasoningTokens,
      );
    }).toList();
  }

  void invalidateCache(String sessionId) {
    _messagesCache.remove(sessionId);
  }

  Future<void> deleteMessage(String id, {String? sessionId}) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    final entity = await _isar.messageEntitys.get(intId);
    if (entity != null) {
      final targetSessionId = sessionId ?? entity.sessionId;
      if (targetSessionId != null &&
          _messagesCache.containsKey(targetSessionId)) {
        _messagesCache[targetSessionId]!.removeWhere((m) => m.id == id);
      }
    }
    await _isar.writeTxn(() async {
      await _isar.messageEntitys.delete(intId);

      final entitySessionId = entity?.sessionId;
      if (entity == null || entitySessionId == null) return;

      final session = await _isar.sessionEntitys
          .filter()
          .sessionIdEqualTo(entitySessionId)
          .findFirst();
      if (session == null) return;

      var shouldPersistSession = false;
      final entityTotal = _effectiveTokenTotalFromEntity(entity);
      if (entityTotal > 0) {
        session.totalTokens =
            (session.totalTokens - entityTotal).clamp(0, 999999999);
        shouldPersistSession = true;
      }

      if (entity.isUser) {
        final lastUserMessage = await _isar.messageEntitys
            .filter()
            .sessionIdEqualTo(entitySessionId)
            .isUserEqualTo(true)
            .sortByTimestampDesc()
            .findFirst();
        if (lastUserMessage != null) {
          session.lastMessageTime = lastUserMessage.timestamp;
          shouldPersistSession = true;
        }
      }

      if (shouldPersistSession) {
        await _isar.sessionEntitys.put(session);
      }
    });

    if (entity != null && entity.attachments.isNotEmpty) {
      final deletable = await _findUnreferencedAttachments(
        entity.attachments,
        excludedMessageIds: {entity.id},
      );
      if (deletable.isNotEmpty) {
        await _deleteAttachmentFiles(deletable);
      }
    }
  }

  Future<void> updateMessage(Message message) async {
    final intId = int.tryParse(message.id);
    if (intId == null) return;

    var removedAttachments = <String>[];
    // Get existing message to compare attachments before transaction
    final existing = await _isar.messageEntitys.get(intId);
    if (existing != null) {
      final oldAttachments = existing.attachments;
      final newAttachments = message.attachments;
      removedAttachments = oldAttachments
          .where((path) => !newAttachments.contains(path))
          .toList();
    }

    await _isar.writeTxn(() async {
      final existing = await _isar.messageEntitys.get(intId);
      if (existing != null) {
        final entitySessionId = existing.sessionId;
        final wasUser = existing.isUser;
        final oldTokenTotal = _effectiveTokenTotalFromEntity(existing);
        final newTokenTotal = _effectiveTokenTotalFromMessage(message);
        existing.content = message.content;
        existing.timestamp = message.timestamp;
        existing.isUser = message.isUser;
        existing.reasoningContent = message.reasoningContent;
        existing.images = message.images;
        existing.attachments = message.attachments;
        existing.model = message.model;
        existing.provider = message.provider;
        existing.reasoningDurationSeconds = message.reasoningDurationSeconds;
        existing.assistantId = message.assistantId;
        existing.requestId = message.requestId;
        existing.role = message.role;
        existing.toolCallId = message.toolCallId;
        existing.tokenCount = message.tokenCount;
        existing.promptTokens = message.promptTokens;
        existing.completionTokens = message.completionTokens;
        existing.reasoningTokens = message.reasoningTokens;
        existing.firstTokenMs = message.firstTokenMs;
        existing.durationMs = message.durationMs;
        if (message.toolCalls != null) {
          existing.toolCallsJson =
              jsonEncode(message.toolCalls!.map((tc) => tc.toJson()).toList());
        } else {
          existing.toolCallsJson = null;
        }
        SessionEntity? session;
        var shouldPersistSession = false;
        final diff = newTokenTotal - oldTokenTotal;
        if (diff != 0) {
          if (entitySessionId != null) {
            session = await _isar.sessionEntitys
                .filter()
                .sessionIdEqualTo(entitySessionId)
                .findFirst();
          }
          if (session != null) {
            session.totalTokens =
                (session.totalTokens + diff).clamp(0, 999999999);
            shouldPersistSession = true;
          }
        }
        final shouldUpdateLastMessageTime = wasUser || message.isUser;
        await _isar.messageEntitys.put(existing);

        if (entitySessionId != null && shouldUpdateLastMessageTime) {
          session ??= await _isar.sessionEntitys
              .filter()
              .sessionIdEqualTo(entitySessionId)
              .findFirst();
          if (session != null) {
            final lastUserMessage = await _isar.messageEntitys
                .filter()
                .sessionIdEqualTo(entitySessionId)
                .isUserEqualTo(true)
                .sortByTimestampDesc()
                .findFirst();
            if (lastUserMessage != null) {
              session.lastMessageTime = lastUserMessage.timestamp;
              shouldPersistSession = true;
            }
          }
        }

        if (shouldPersistSession && session != null) {
          await _isar.sessionEntitys.put(session);
        }

        if (entitySessionId != null &&
            _messagesCache.containsKey(entitySessionId)) {
          final cachedList = _messagesCache[entitySessionId]!;
          final cacheIndex = cachedList.indexWhere((m) => m.id == message.id);
          if (cacheIndex != -1) {
            cachedList[cacheIndex] = message;
          }
        }
      }
    });

    if (removedAttachments.isNotEmpty) {
      final deletable = await _findUnreferencedAttachments(
        removedAttachments,
        excludedMessageIds: {intId},
      );
      if (deletable.isNotEmpty) {
        await _deleteAttachmentFiles(deletable);
      }
    }
  }

  Future<void> clearSessionMessages(String sessionId) async {
    final messages = await _isar.messageEntitys
        .filter()
        .sessionIdEqualTo(sessionId)
        .findAll();
    final candidateAttachments = <String>[];
    for (final message in messages) {
      candidateAttachments.addAll(message.attachments);
    }

    await _isar.writeTxn(() async {
      await _isar.messageEntitys
          .filter()
          .sessionIdEqualTo(sessionId)
          .deleteAll();
      final session = await _isar.sessionEntitys
          .filter()
          .sessionIdEqualTo(sessionId)
          .findFirst();
      if (session != null) {
        session.totalTokens = 0;
        await _isar.sessionEntitys.put(session);
      }
    });
    invalidateCache(sessionId);

    if (candidateAttachments.isNotEmpty) {
      final deletable =
          await _findUnreferencedAttachments(candidateAttachments);
      if (deletable.isNotEmpty) {
        await _deleteAttachmentFiles(deletable);
      }
    }
  }

  Future<String> createSession({
    String title = 'New Chat',
    String? uuid,
    int? topicId,
    String? presetId,
    String? parentSessionId,
  }) async {
    final session = SessionEntity()
      ..sessionId = uuid ?? DateTime.now().millisecondsSinceEpoch.toString()
      ..title = title
      ..lastMessageTime = DateTime.now()
      ..topicId = topicId
      ..presetId = presetId
      ..parentSessionId = parentSessionId;
    await _isar.writeTxn(() async {
      await _isar.sessionEntitys.put(session);
    });
    return session.sessionId;
  }

  Future<void> createTopic(String name) async {
    final topic = TopicEntity()
      ..name = name
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.topicEntitys.put(topic);
    });
  }

  Future<void> updateTopic(int id, String name) async {
    await _isar.writeTxn(() async {
      final topic = await _isar.topicEntitys.get(id);
      if (topic != null) {
        topic.name = name;
        await _isar.topicEntitys.put(topic);
      }
    });
  }

  Future<void> deleteTopic(int id) async {
    await _isar.writeTxn(() async {
      final sessions =
          await _isar.sessionEntitys.filter().topicIdEqualTo(id).findAll();
      for (final session in sessions) {
        session.topicId = null;
        await _isar.sessionEntitys.put(session);
      }
      await _isar.topicEntitys.delete(id);
    });
  }

  Future<List<TopicEntity>> getAllTopics() async {
    return await _isar.topicEntitys.where().sortByCreatedAt().findAll();
  }

  Future<List<SessionEntity>> loadSessions() async {
    return await _isar.sessionEntitys
        .where()
        .sortByLastMessageTimeDesc()
        .findAll();
  }

  Future<SessionEntity?> getSession(String sessionId) async {
    return await _isar.sessionEntitys
        .filter()
        .sessionIdEqualTo(sessionId)
        .findFirst();
  }

  Future<List<String>> _collectSessionTreeIds(String sessionId) async {
    final sessions = await _isar.sessionEntitys.where().findAll();
    if (sessions.isEmpty) return const [];

    final childrenMap = <String, List<String>>{};
    final idSet = <String>{};
    for (final session in sessions) {
      idSet.add(session.sessionId);
      final parentId = session.parentSessionId;
      if (parentId == null || parentId.isEmpty) continue;
      childrenMap
          .putIfAbsent(parentId, () => <String>[])
          .add(session.sessionId);
    }
    if (!idSet.contains(sessionId)) return const [];

    final collected = <String>[];
    final pending = <String>[sessionId];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      collected.add(current);
      final children = childrenMap[current];
      if (children != null && children.isNotEmpty) {
        pending.addAll(children);
      }
    }
    return collected;
  }

  Future<List<String>> deleteSessionTree(String sessionId) async {
    final sessionIds = await _collectSessionTreeIds(sessionId);
    if (sessionIds.isEmpty) return const [];

    final allAttachments = <String>[];
    for (final id in sessionIds) {
      final messages =
          await _isar.messageEntitys.filter().sessionIdEqualTo(id).findAll();
      for (final msg in messages) {
        allAttachments.addAll(msg.attachments);
      }
    }

    await _isar.writeTxn(() async {
      for (final id in sessionIds) {
        await _isar.messageEntitys.filter().sessionIdEqualTo(id).deleteAll();
        await _isar.sessionEntitys.filter().sessionIdEqualTo(id).deleteAll();
      }
    });

    for (final id in sessionIds) {
      invalidateCache(id);
    }

    if (allAttachments.isNotEmpty) {
      final deletable = await _findUnreferencedAttachments(allAttachments);
      if (deletable.isNotEmpty) {
        await _deleteAttachmentFiles(deletable);
      }
    }

    return sessionIds;
  }

  Future<void> deleteSession(String sessionId) async {
    await deleteSessionTree(sessionId);
  }

  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    await _isar.writeTxn(() async {
      final session = await _isar.sessionEntitys
          .filter()
          .sessionIdEqualTo(sessionId)
          .findFirst();
      if (session != null) {
        session.title = newTitle;
        await _isar.sessionEntitys.put(session);
      }
    });
  }

  Future<void> updateSessionPreset(String sessionId, String? presetId) async {
    await _isar.writeTxn(() async {
      final session = await _isar.sessionEntitys
          .filter()
          .sessionIdEqualTo(sessionId)
          .findFirst();
      if (session != null) {
        session.presetId = presetId;
        await _isar.sessionEntitys.put(session);
      }
    });
  }

  Future<void> cleanupEmptySessions() async {
    await _isar.writeTxn(() async {
      final sessions = await _isar.sessionEntitys.where().findAll();
      final parentIds =
          sessions.map((s) => s.parentSessionId).whereType<String>().toSet();
      for (final session in sessions) {
        if (parentIds.contains(session.sessionId)) {
          continue;
        }
        final count = await _isar.messageEntitys
            .filter()
            .sessionIdEqualTo(session.sessionId)
            .count();
        if (count == 0) {
          await _isar.sessionEntitys.delete(session.id);
        }
      }
    });
  }

  Future<void> backfillSessionLastUserMessageTimes() async {
    final sessions = await _isar.sessionEntitys.where().findAll();
    if (sessions.isEmpty) return;

    final sessionsToUpdate = <SessionEntity>[];
    for (final session in sessions) {
      final lastUserMessage = await _isar.messageEntitys
          .filter()
          .sessionIdEqualTo(session.sessionId)
          .isUserEqualTo(true)
          .sortByTimestampDesc()
          .findFirst();
      if (lastUserMessage == null) continue;

      if (session.lastMessageTime != lastUserMessage.timestamp) {
        session.lastMessageTime = lastUserMessage.timestamp;
        sessionsToUpdate.add(session);
      }
    }

    if (sessionsToUpdate.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.sessionEntitys.putAll(sessionsToUpdate);
    });
  }

  Future<bool> deleteSessionIfEmpty(String sessionId) async {
    final count =
        await _isar.messageEntitys.filter().sessionIdEqualTo(sessionId).count();
    if (count == 0) {
      final sessions = await _isar.sessionEntitys.where().findAll();
      final hasChildren = sessions.any((s) => s.parentSessionId == sessionId);
      if (hasChildren) {
        return false;
      }
      await deleteSession(sessionId);
      invalidateCache(sessionId);
      return true;
    }
    return false;
  }

  Future<void> sanitizeTranslationUserMessages() async {
    const translationSessionId = 'translation';
    final entities = await _isar.messageEntitys
        .filter()
        .sessionIdEqualTo(translationSessionId)
        .isUserEqualTo(true)
        .findAll();
    if (entities.isEmpty) return;

    final toUpdate = <MessageEntity>[];
    for (final e in entities) {
      final extracted = TranslationPromptUtils.extractSourceText(e.content);
      if (extracted != e.content) {
        e.content = extracted;
        toUpdate.add(e);
      }
    }

    if (toUpdate.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.messageEntitys.putAll(toUpdate);
    });
    invalidateCache(translationSessionId);
  }

  Future<List<String>> loadSessionOrder() =>
      _settingsStorage.loadSessionOrder();
  Future<void> saveSessionOrder(List<String> order) =>
      _settingsStorage.saveSessionOrder(order);
}
