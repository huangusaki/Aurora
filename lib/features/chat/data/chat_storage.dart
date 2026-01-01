import 'package:isar/isar.dart';
import '../../settings/data/settings_storage.dart';
import 'message_entity.dart';
import 'session_entity.dart';
import '../domain/message.dart';

class ChatStorage {
  final Isar _isar;

  ChatStorage(SettingsStorage settingsStorage) : _isar = settingsStorage.isar;

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
      ..sessionId = sessionId;
      
    await _isar.writeTxn(() async {
      await _isar.messageEntitys.put(entity);
    });
  }
  
  // Save full history (simplest for small scale)
  Future<void> saveHistory(List<Message> messages, String sessionId) async {
    await _isar.writeTxn(() async {
      // Delete old messages for this session
      await _isar.messageEntitys.filter().sessionIdEqualTo(sessionId).deleteAll();
      
      final entities = messages.map((m) => MessageEntity()
        ..timestamp = m.timestamp
        ..isUser = m.isUser
        ..content = m.content
        ..reasoningContent = m.reasoningContent
        ..attachments = m.attachments
        ..images = m.images
        ..model = m.model
        ..provider = m.provider
        ..sessionId = sessionId
      ).toList();
      await _isar.messageEntitys.putAll(entities);
    });
  }

  Future<List<Message>> loadHistory(String sessionId) async {
    final entities = await _isar.messageEntitys
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByTimestamp()
        .findAll();
        
    return entities.map((e) => Message(
      id: e.id.toString(),
      content: e.content,
      isUser: e.isUser,
      timestamp: e.timestamp,
      reasoningContent: e.reasoningContent,
      attachments: e.attachments,

      images: e.images,
      model: e.model,
      provider: e.provider,
    )).toList();
  }
  
  // --- Enhanced Features ---

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
          await _isar.messageEntitys.put(existing);
       }
    });
  }
  
  Future<void> clearSessionMessages(String sessionId) async {
     await _isar.writeTxn(() async {
      await _isar.messageEntitys.filter().sessionIdEqualTo(sessionId).deleteAll();
    });
  }

  // --- Session Management ---

  Future<String> createSession({required String title, String? uuid}) async {
    final session = SessionEntity()
      ..sessionId =  uuid ?? DateTime.now().millisecondsSinceEpoch.toString()
      ..title = title
      ..lastMessageTime = DateTime.now();
      
    await _isar.writeTxn(() async {
      await _isar.sessionEntitys.put(session);
    });
    
    return session.sessionId;
  }

  Future<List<SessionEntity>> loadSessions() async {
    return await _isar.sessionEntitys.where().sortByLastMessageTimeDesc().findAll();
  }

  Future<void> deleteSession(String sessionId) async {
    await _isar.writeTxn(() async {
      // Delete messages
      await _isar.messageEntitys.filter().sessionIdEqualTo(sessionId).deleteAll();
      // Delete session
      await _isar.sessionEntitys.filter().sessionIdEqualTo(sessionId).deleteAll();
    });
  }
}
