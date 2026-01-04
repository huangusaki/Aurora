import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../settings/data/settings_storage.dart';
import 'message_entity.dart';
import 'session_entity.dart';
import '../domain/message.dart';

class ChatStorage {
  final Isar _isar;
  final SettingsStorage _settingsStorage;
  
  // In-memory cache: sessionId -> List<Message>
  final Map<String, List<Message>> _messagesCache = {};
  
  ChatStorage(this._settingsStorage) : _isar = _settingsStorage.isar;
  
  /// Preload messages for all sessions into memory cache.
  /// Call this at startup for instant session switching.
  Future<void> preloadAllSessions() async {
    final sw = Stopwatch()..start();
    final sessions = await loadSessions();
    for (final session in sessions) {
      if (!_messagesCache.containsKey(session.sessionId)) {
        _messagesCache[session.sessionId] = await _loadHistoryFromDb(session.sessionId);
      }
    }
    debugPrint('ChatStorage: preloadAllSessions completed in ${sw.elapsedMilliseconds}ms for ${sessions.length} sessions');
  }
  
  Future<void> saveMessage(Message message, String sessionId) async {
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
      ..toolCallId = message.toolCallId;
      
    if (message.toolCalls != null) {
      entity.toolCallsJson = jsonEncode(message.toolCalls!.map((tc) => tc.toJson()).toList());
    }

    await _isar.writeTxn(() async {
      await _isar.messageEntitys.put(entity);
    });
    
    // Update cache
    if (_messagesCache.containsKey(sessionId)) {
      _messagesCache[sessionId]!.add(message);
    }
  }

  Future<void> saveHistory(List<Message> messages, String sessionId) async {
    await _isar.writeTxn(() async {
      await _isar.messageEntitys
          .filter()
          .sessionIdEqualTo(sessionId)
          .deleteAll();
      final entities = messages
          .map((m) {
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
              ..toolCallId = m.toolCallId;
            if (m.toolCalls != null) {
              e.toolCallsJson = jsonEncode(m.toolCalls!.map((tc) => tc.toJson()).toList());
            }
            return e;
          })
          .toList();
      await _isar.messageEntitys.putAll(entities);
    });
    
    // Update cache
    _messagesCache[sessionId] = List.of(messages);
  }

  /// Load history, checking cache first for instant access.
  Future<List<Message>> loadHistory(String sessionId) async {
    // Check cache first
    if (_messagesCache.containsKey(sessionId)) {
      debugPrint('ChatStorage: loadHistory cache HIT for $sessionId');
      // Return a COPY to prevent shared reference issues
      return List.from(_messagesCache[sessionId]!);
    }
    
    // Cache miss - load from DB and cache
    debugPrint('ChatStorage: loadHistory cache MISS for $sessionId, loading from DB');
    final messages = await _loadHistoryFromDb(sessionId);
    _messagesCache[sessionId] = messages;
    // Return a COPY to prevent shared reference issues
    return List.from(messages);
  }
  
  /// Internal method to load from database.
  Future<List<Message>> _loadHistoryFromDb(String sessionId) async {
    final entities = await _isar.messageEntitys
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestamp()
        .findAll();
    return entities
        .map((e) {
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
            );
        })
        .toList();
  }
  
  /// Invalidate cache for a session (e.g., after delete).
  void invalidateCache(String sessionId) {
    _messagesCache.remove(sessionId);
  }

  Future<void> deleteMessage(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await _isar.writeTxn(() async {
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
            existing.toolCallsJson = jsonEncode(message.toolCalls!.map((tc) => tc.toJson()).toList());
        } else {
            existing.toolCallsJson = null;
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
    });
  }

  Future<String> createSession({required String title, String? uuid}) async {
    final session = SessionEntity()
      ..sessionId = uuid ?? DateTime.now().millisecondsSinceEpoch.toString()
      ..title = title
      ..lastMessageTime = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.sessionEntitys.put(session);
    });
    return session.sessionId;
  }

  Future<List<SessionEntity>> loadSessions() async {
    return await _isar.sessionEntitys
        .where()
        .sortByLastMessageTimeDesc()
        .findAll();
  }

  Future<void> deleteSession(String sessionId) async {
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

  /// Check if a specific session is empty (has no messages) and delete it if so.
  /// Returns true if the session was deleted.
  Future<bool> deleteSessionIfEmpty(String sessionId) async {
    final count = await _isar.messageEntitys
        .filter()
        .sessionIdEqualTo(sessionId)
        .count();
    if (count == 0) {
      await deleteSession(sessionId);
      invalidateCache(sessionId);
      return true;
    }
    return false;
  }

  Future<List<String>> loadSessionOrder() => _settingsStorage.loadSessionOrder();
  Future<void> saveSessionOrder(List<String> order) => _settingsStorage.saveSessionOrder(order);
}
