import 'dart:convert';
import 'dart:io';
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
      if (message.tokenCount != null || message.promptTokens != null) {
        final session = await _isar.sessionEntitys.getBySessionId(sessionId);
        if (session != null) {
          // Calculate total tokens for this message
          int msgTotal = message.tokenCount ?? 0;
          if (message.promptTokens != null || message.completionTokens != null) {
             // Enforce P + C + R logic
             final p = message.promptTokens ?? 0;
             final c = message.completionTokens ?? 0;
             final r = message.reasoningTokens ?? 0;
             msgTotal = p + c + r;
          }
          
          session.totalTokens += msgTotal;
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
          print('Error parsing toolCallsJson: $e');
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
      if (entity.attachments.isNotEmpty) {
        await _deleteAttachmentFiles(entity.attachments);
      }
      final targetSessionId = sessionId ?? entity.sessionId;
      if (_messagesCache.containsKey(targetSessionId)) {
        _messagesCache[targetSessionId]!.removeWhere((m) => m.id == id);
      }
    }
    await _isar.writeTxn(() async {
      if (entity != null &&
          entity.tokenCount != null &&
          entity.tokenCount! > 0) {
        final session = await _isar.sessionEntitys
            .filter()
            .sessionIdEqualTo(entity.sessionId!)
            .findFirst();
        if (session != null) {
          session.totalTokens =
              (session.totalTokens - entity.tokenCount!).clamp(0, 999999999);
          await _isar.sessionEntitys.put(session);
        }
      }
      await _isar.messageEntitys.delete(intId);
    });
  }

  Future<void> updateMessage(Message message) async {
    final intId = int.tryParse(message.id);
    if (intId == null) return;
    await _isar.writeTxn(() async {
      final existing = await _isar.messageEntitys.get(intId);
      if (existing != null) {
        existing.content = message.content;
        existing.reasoningContent = message.reasoningContent;
        existing.images = message.images;
        existing.attachments = message.attachments;
        existing.model = message.model;
        existing.provider = message.provider;
        existing.reasoningDurationSeconds = message.reasoningDurationSeconds;
        existing.role = message.role;
        existing.toolCallId = message.toolCallId;
        if (message.toolCalls != null) {
          existing.toolCallsJson =
              jsonEncode(message.toolCalls!.map((tc) => tc.toJson()).toList());
        } else {
          existing.toolCallsJson = null;
        }
        if (message.tokenCount != null &&
            message.tokenCount != existing.tokenCount) {
          final diff = (message.tokenCount ?? 0) - (existing.tokenCount ?? 0);
          if (diff != 0) {
            final session = await _isar.sessionEntitys
                .filter()
                .sessionIdEqualTo(existing.sessionId!)
                .findFirst();
            if (session != null) {
              session.totalTokens =
                  (session.totalTokens + diff).clamp(0, 999999999);
              await _isar.sessionEntitys.put(session);
            }
          }
          existing.tokenCount = message.tokenCount;
        }
        if (_messagesCache.containsKey(existing.sessionId!)) {
          final cachedList = _messagesCache[existing.sessionId!]!;
          final cacheIndex = cachedList.indexWhere((m) => m.id == message.id);
          if (cacheIndex != -1) {
            cachedList[cacheIndex] = message;
          }
        }
        await _isar.messageEntitys.put(existing);
      }
    });
  }

  Future<void> clearSessionMessages(String sessionId) async {
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
  }

  Future<String> createSession(
      {required String title,
      String? uuid,
      int? topicId,
      String? presetId}) async {
    final session = SessionEntity()
      ..sessionId = uuid ?? DateTime.now().millisecondsSinceEpoch.toString()
      ..title = title
      ..lastMessageTime = DateTime.now()
      ..topicId = topicId
      ..presetId = presetId;
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

  Future<void> deleteSession(String sessionId) async {
    final messages = await _isar.messageEntitys
        .filter()
        .sessionIdEqualTo(sessionId)
        .findAll();
    final allAttachments = <String>[];
    for (final msg in messages) {
      allAttachments.addAll(msg.attachments);
    }
    if (allAttachments.isNotEmpty) {
      await _deleteAttachmentFiles(allAttachments);
    }
    await _isar.writeTxn(() async {
      await _isar.messageEntitys
          .filter()
          .sessionIdEqualTo(sessionId)
          .deleteAll();
      await _isar.sessionEntitys
          .filter()
          .sessionIdEqualTo(sessionId)
          .deleteAll();
    });
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
      for (final session in sessions) {
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

  Future<bool> deleteSessionIfEmpty(String sessionId) async {
    final count =
        await _isar.messageEntitys.filter().sessionIdEqualTo(sessionId).count();
    if (count == 0) {
      await deleteSession(sessionId);
      invalidateCache(sessionId);
      return true;
    }
    return false;
  }

  Future<List<String>> loadSessionOrder() =>
      _settingsStorage.loadSessionOrder();
  Future<void> saveSessionOrder(List<String> order) =>
      _settingsStorage.saveSessionOrder(order);
}
