import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../chat/data/message_entity.dart';
import '../../chat/data/session_entity.dart';
import '../../chat/data/topic_entity.dart';
import '../../settings/data/chat_preset_entity.dart';
import '../../settings/data/provider_config_entity.dart';
import '../../settings/data/settings_storage.dart';
import '../domain/backup_entity.dart';
import '../domain/backup_options.dart';
import '../domain/webdav_config.dart';
import '../data/webdav_service.dart';

class BackupService {
  final SettingsStorage _storage;
  
  BackupService(this._storage);

  Future<void> backup(WebDavConfig config, {BackupOptions options = const BackupOptions()}) async {
    final webdav = WebDavService(config);
    if (!await webdav.checkConnection()) {
      throw Exception('Connection failed');
    }

    final backupEntity = await _exportData(options: options);
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

  Future<void> exportToLocalFile(String destinationPath, {BackupOptions options = const BackupOptions()}) async {
    final backupEntity = await _exportData(options: options);
    final tempFile = await _createBackupFile(backupEntity);
    await tempFile.copy(destinationPath);
    await tempFile.delete();
  }

  Future<void> importFromLocalFile(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('File not found: $sourcePath');
    }
    final backupEntity = await _parseBackupFile(file);
    await _mergeData(backupEntity);
  }

  Future<void> clearAllData() async {
    final isar = _storage.isar;
    await isar.writeTxn(() async {
      await isar.messageEntitys.clear();
      await isar.sessionEntitys.clear();
      await isar.topicEntitys.clear();
    });
  }

  Future<BackupEntity> _exportData({BackupOptions options = const BackupOptions()}) async {
    final isar = _storage.isar;
    
    final sessions = options.includeChatHistory ? await isar.sessionEntitys.where().findAll() : <SessionEntity>[];
    final messages = options.includeChatHistory ? await isar.messageEntitys.where().findAll() : <MessageEntity>[];
    final topics = options.includeChatHistory ? await isar.topicEntitys.where().findAll() : <TopicEntity>[];
    final chatPresets = options.includeChatPresets ? await isar.chatPresetEntitys.where().findAll() : <ChatPresetEntity>[];
    final providerConfigs = options.includeProviderConfigs ? await isar.providerConfigEntitys.where().findAll() : <ProviderConfigEntity>[];
    
    // Load studio content
    Map<String, dynamic>? studioContent;
    if (options.includeStudioContent) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final studioFile = File('${docsDir.path}/novel_writing_state.json');
        if (await studioFile.exists()) {
          final content = await studioFile.readAsString();
          studioContent = jsonDecode(content) as Map<String, dynamic>;
        }
      } catch (e) {
        print('Error exporting studio content: $e');
      }
    }
    
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

    final chatPresetBackups = chatPresets.map((p) => ChatPresetBackup(
      presetId: p.presetId,
      name: p.name,
      description: p.description,
      systemPrompt: p.systemPrompt,
    )).toList();

    final providerConfigBackups = providerConfigs.map((c) => ProviderConfigBackup(
      providerId: c.providerId,
      name: c.name,
      color: c.color,
      apiKeys: c.apiKeys,
      currentKeyIndex: c.currentKeyIndex,
      autoRotateKeys: c.autoRotateKeys,
      baseUrl: c.baseUrl,
      isCustom: c.isCustom,
      customParametersJson: c.customParametersJson,
      modelSettingsJson: c.modelSettingsJson,
      globalSettingsJson: c.globalSettingsJson,
      globalExcludeModels: c.globalExcludeModels,
      savedModels: c.savedModels,
      lastSelectedModel: c.lastSelectedModel,
      isActive: c.isActive,
      isEnabled: c.isEnabled,
    )).toList();

    return BackupEntity(
      version: 1,
      createdAt: DateTime.now(),
      sessions: sessionBackups,
      messages: messageBackups,
      topics: topicBackups,
      chatPresets: chatPresetBackups,
      providerConfigs: providerConfigBackups,
      studioContent: studioContent,
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
        
        // Re-mapping topic ID
        int? localTopicId;
        if (s.topicName != null) {
           localTopicId = topicMap[s.topicName];
        }
        
        if (existing == null) {
            // Create new session
            await isar.sessionEntitys.put(SessionEntity()
                ..sessionId = s.sessionId
                ..title = s.title
                ..lastMessageTime = s.lastMessageTime
                ..snippet = s.snippet
                ..topicId = localTopicId
                ..presetId = s.presetId
                ..totalTokens = s.totalTokens
            );
        } else {
            // Update existing session's topicId if it's missing but backup has it
            if (existing.topicId == null && localTopicId != null) {
                existing.topicId = localTopicId;
                await isar.sessionEntitys.put(existing);
            }
        }
      }

      // 3. Merge Messages
      for (final m in backup.messages) {
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

      // 4. Merge Chat Presets
      for (final p in backup.chatPresets) {
        final existing = await isar.chatPresetEntitys.filter().presetIdEqualTo(p.presetId).findFirst();
        if (existing == null) {
          await isar.chatPresetEntitys.put(ChatPresetEntity()
            ..presetId = p.presetId
            ..name = p.name
            ..description = p.description
            ..systemPrompt = p.systemPrompt
          );
        }
      }

      // 5. Merge Provider Configs
      for (final c in backup.providerConfigs) {
        final existing = await isar.providerConfigEntitys.filter().providerIdEqualTo(c.providerId).findFirst();
        if (existing == null) {
          await isar.providerConfigEntitys.put(ProviderConfigEntity()
            ..providerId = c.providerId
            ..name = c.name
            ..color = c.color
            ..apiKeys = c.apiKeys
            ..currentKeyIndex = c.currentKeyIndex
            ..autoRotateKeys = c.autoRotateKeys
            ..baseUrl = c.baseUrl
            ..isCustom = c.isCustom
            ..customParametersJson = c.customParametersJson
            ..modelSettingsJson = c.modelSettingsJson
            ..globalSettingsJson = c.globalSettingsJson
            ..globalExcludeModels = c.globalExcludeModels
            ..savedModels = c.savedModels
            ..lastSelectedModel = c.lastSelectedModel
            ..isActive = c.isActive
            ..isEnabled = c.isEnabled
          );
        } else {
          // If existing, maybe update some fields? For now, we only add missing ones or keep existing.
          // In sync, usually we might want to update if backup is newer, but Isaar doesn't have updatedAt on these.
          // We'll stick to "add if missing" for provider configs to avoid overwriting user's local keys if they differ.
        }
      }
    });

    // 6. Restore Studio Content
    if (backup.studioContent != null) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final studioFile = File('${docsDir.path}/novel_writing_state.json');
        await studioFile.writeAsString(jsonEncode(backup.studioContent));
      } catch (e) {
        print('Error restoring studio content: $e');
      }
    }
  }
}

