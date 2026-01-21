import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../chat/data/message_entity.dart';
import '../../chat/data/session_entity.dart';
import '../../chat/data/topic_entity.dart';
import '../../settings/data/settings_storage.dart';
import '../domain/backup_entity.dart';
import '../domain/webdav_config.dart';
import '../data/webdav_service.dart';

class BackupService {
  final SettingsStorage _storage;
  
  BackupService(this._storage);

  Future<void> backup(WebDavConfig config) async {
    final webdav = WebDavService(config);
    if (!await webdav.checkConnection()) {
      throw Exception('Connection failed');
    }

    final backupEntity = await _exportData();
    final file = await _createBackupFile(backupEntity);
    
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final remoteName = 'aurora_backup_$timestamp.zip';
    
    await webdav.uploadFile(file, remoteName);
    await file.delete();
  }

  Future<void> restore(WebDavConfig config, String remoteFileName) async {
    final webdav = WebDavService(config);
    final tempDir = await getTemporaryDirectory();
    final localPath = '${tempDir.path}/restore_temp.zip';
    
    await webdav.downloadFile(remoteFileName, localPath);
    final file = File(localPath);
    
    final backupEntity = await _parseBackupFile(file);
    await _mergeData(backupEntity);
    
    await file.delete();
  }

  Future<BackupEntity> _exportData() async {
    final isar = _storage.isar;
    
    final sessions = await isar.sessionEntitys.where().findAll();
    final messages = await isar.messageEntitys.where().findAll();
    final topics = await isar.topicEntitys.where().findAll();
    
    // Create topic map for ID to Name resolution
    final topicMap = {for (var t in topics) t.id: t.name};

    // Convert to Backup DTOs
    final sessionBackups = sessions.map((s) => SessionBackup(
      sessionId: s.sessionId,
      title: s.title,
      lastMessageTime: s.lastMessageTime,
      snippet: s.snippet,
      topicId: s.topicId,
      topicName: s.topicId != null ? topicMap[s.topicId] : null,
      presetId: s.presetId,
      totalTokens: s.totalTokens ?? 0,
    )).toList();

    final messageBackups = messages.map((m) => MessageBackup(
      timestamp: m.timestamp,
      isUser: m.isUser,
      content: m.content,
      reasoningContent: m.reasoningContent,
      attachments: m.attachments ?? [],
      images: m.images ?? [],
      sessionId: m.sessionId,
      model: m.model,
      provider: m.provider,
      reasoningDurationSeconds: m.reasoningDurationSeconds,
      role: m.role,
      toolCallId: m.toolCallId,
      toolCallsJson: m.toolCallsJson,
      tokenCount: m.tokenCount,
      firstTokenMs: m.firstTokenMs,
      durationMs: m.durationMs,
    )).toList();

    final topicBackups = topics.map((t) => TopicBackup(
        name: t.name,
        createdAt: t.createdAt,
    )).toList();

    return BackupEntity(
      version: 1,
      createdAt: DateTime.now(),
      sessions: sessionBackups,
      messages: messageBackups,
      topics: topicBackups,
    );
  }

  Future<File> _createBackupFile(BackupEntity data) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = File('${tempDir.path}/backup_$timestamp.zip');
    
    final archive = Archive();
    
    // Add data.json
    final jsonStr = jsonEncode(data.toJson());
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
    
    // TODO: Add images logic here if needed (skipping for now as per plan to focus on lightweight sync first)

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw Exception('Failed to encode zip');
    
    await zipFile.writeAsBytes(encoded);
    return zipFile;
  }

  Future<BackupEntity> _parseBackupFile(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    final dataFile = archive.findFile('data.json');
    if (dataFile == null) throw Exception('Invalid backup file: data.json not found');
    
    final content = utf8.decode(dataFile.content as List<int>);
    final json = jsonDecode(content);
    return BackupEntity.fromJson(json);
  }

  Future<void> _mergeData(BackupEntity backup) async {
    final isar = _storage.isar;
    
    await isar.writeTxn(() async {
      // 1. Merge Topics
      for (final t in backup.topics) {
        final existing = await isar.topicEntitys.filter().nameEqualTo(t.name).findFirst();
        if (existing == null) {
            await isar.topicEntitys.put(TopicEntity()
                ..name = t.name
                ..createdAt = t.createdAt
            );
        }
      }
      
      // Need to re-fetch topics to get their IDs map
      final allTopics = await isar.topicEntitys.where().findAll();
      final topicMap = {for (var t in allTopics) t.name: t.id};

      // 2. Merge Sessions
      for (final s in backup.sessions) {
        final existing = await isar.sessionEntitys.filter().sessionIdEqualTo(s.sessionId).findFirst();
        if (existing == null) {
            // Re-mapping topic ID
            int? localTopicId;
            if (s.topicName != null) {
               localTopicId = topicMap[s.topicName];
            } else if (s.topicId != null) {
               // Fallback logic could go here, but IDs are usually not portable.
               // Leaving specific localTopicId null if name match fails.
            }

            await isar.sessionEntitys.put(SessionEntity()
                ..sessionId = s.sessionId
                ..title = s.title
                ..lastMessageTime = s.lastMessageTime
                ..snippet = s.snippet
                ..topicId = localTopicId
                ..presetId = s.presetId
                ..totalTokens = s.totalTokens
            );
        }
      }

      // 3. Merge Messages
      for (final m in backup.messages) {
        // Compound uniqueness check: sessionId + timestamp + content
        // Or just trust UUID if MessageEntity had one? It uses auto-increment ID.
        // So we must rely on content match.
        final count = await isar.messageEntitys
            .filter()
            .sessionIdEqualTo(m.sessionId)
            .timestampEqualTo(m.timestamp)
            .count();
            
        if (count == 0) {
            await isar.messageEntitys.put(MessageEntity()
                ..timestamp = m.timestamp
                ..isUser = m.isUser
                ..content = m.content
                ..reasoningContent = m.reasoningContent
                ..attachments = m.attachments
                ..images = m.images
                ..sessionId = m.sessionId
                ..model = m.model
                ..provider = m.provider
                ..reasoningDurationSeconds = m.reasoningDurationSeconds
                ..role = m.role
                ..toolCallId = m.toolCallId
                ..toolCallsJson = m.toolCallsJson
                ..tokenCount = m.tokenCount
                ..firstTokenMs = m.firstTokenMs
                ..durationMs = m.durationMs
            );
        }
      }
    });
  }
}
