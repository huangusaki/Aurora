import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../assistant/data/assistant_entity.dart';
import '../../assistant/data/assistant_memory_item_entity.dart';
import '../../assistant/data/assistant_memory_state_entity.dart';
import '../../chat/data/message_entity.dart';
import '../../chat/data/session_entity.dart';
import '../../chat/data/topic_entity.dart';
import '../../knowledge/data/knowledge_entities.dart';
import '../../settings/data/chat_preset_entity.dart';
import '../../settings/data/daily_usage_stats_entity.dart';
import '../../settings/data/provider_config_entity.dart';
import '../../settings/data/settings_storage.dart';
import '../../settings/data/usage_stats_entity.dart';
import '../data/webdav_service.dart';
import '../domain/backup_entity.dart';
import '../domain/backup_options.dart';
import '../domain/webdav_config.dart';

class BackupService {
  static const String _prefAppSettings = 'appSettings';
  static const String _prefSessionOrder = 'sessionOrder';
  static const String _prefProviderOrder = 'providerOrder';
  static const String _prefAssistants = 'assistants';
  static const String _prefAssistantMemoryItems = 'assistantMemoryItems';
  static const String _prefAssistantMemoryStates = 'assistantMemoryStates';
  static const String _prefKnowledgeBases = 'knowledgeBases';
  static const String _prefKnowledgeDocuments = 'knowledgeDocuments';
  static const String _prefKnowledgeChunks = 'knowledgeChunks';
  static const String _prefUsageStats = 'usageStats';
  static const String _prefDailyUsageStats = 'dailyUsageStats';

  final SettingsStorage _storage;

  BackupService(this._storage);

  Future<void> backup(WebDavConfig config,
      {BackupOptions options = const BackupOptions()}) async {
    final webdav = WebDavService(config);
    if (!await webdav.checkConnection()) {
      throw Exception('Connection failed');
    }

    final backupEntity = await _exportData(options: options);
    final file = await _createBackupFile(backupEntity);

    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
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

  Future<void> exportToLocalFile(String destinationPath,
      {BackupOptions options = const BackupOptions()}) async {
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

  Future<BackupEntity> _exportData(
      {BackupOptions options = const BackupOptions()}) async {
    final isar = _storage.isar;

    final sessions = options.includeChatHistory
        ? await isar.sessionEntitys.where().findAll()
        : <SessionEntity>[];
    final messages = options.includeChatHistory
        ? await isar.messageEntitys.where().findAll()
        : <MessageEntity>[];
    final topics = options.includeChatHistory
        ? await isar.topicEntitys.where().findAll()
        : <TopicEntity>[];
    final chatPresets = options.includeChatPresets
        ? await isar.chatPresetEntitys.where().findAll()
        : <ChatPresetEntity>[];
    final providerConfigs = options.includeProviderConfigs
        ? await isar.providerConfigEntitys.where().findAll()
        : <ProviderConfigEntity>[];
    final appSettings = options.includeAppSettings
        ? await isar.appSettingsEntitys.where().findFirst()
        : null;
    final sessionOrder = options.includeAppSettings
        ? await _storage.loadSessionOrder()
        : const <String>[];
    final providerOrder = options.includeAppSettings
        ? await _storage.loadProviderOrder()
        : const <String>[];
    final assistants = options.includeAssistants
        ? await isar.assistantEntitys.where().findAll()
        : <AssistantEntity>[];
    final assistantMemoryItems = options.includeAssistants
        ? await isar.assistantMemoryItemEntitys.where().findAll()
        : <AssistantMemoryItemEntity>[];
    final assistantMemoryStates = options.includeAssistants
        ? await isar.assistantMemoryStateEntitys.where().findAll()
        : <AssistantMemoryStateEntity>[];
    final knowledgeBases = options.includeKnowledgeBases
        ? await isar.knowledgeBaseEntitys.where().findAll()
        : <KnowledgeBaseEntity>[];
    final knowledgeDocuments = options.includeKnowledgeBases
        ? await isar.knowledgeDocumentEntitys.where().findAll()
        : <KnowledgeDocumentEntity>[];
    final knowledgeChunks = options.includeKnowledgeBases
        ? await isar.knowledgeChunkEntitys.where().findAll()
        : <KnowledgeChunkEntity>[];
    final usageStats = options.includeUsageStats
        ? await isar.usageStatsEntitys.where().findAll()
        : <UsageStatsEntity>[];
    final dailyUsageStats = options.includeUsageStats
        ? await isar.dailyUsageStatsEntitys.where().findAll()
        : <DailyUsageStatsEntity>[];

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
        debugPrint('Error exporting studio content: $e');
      }
    }

    // Create topic map for ID to Name resolution
    final topicMap = {for (var t in topics) t.id: t.name};

    // Convert to Backup DTOs
    final sessionBackups = sessions
        .map((s) => SessionBackup(
              sessionId: s.sessionId,
              title: s.title,
              lastMessageTime: s.lastMessageTime,
              snippet: s.snippet,
              topicId: s.topicId,
              topicName: s.topicId != null ? topicMap[s.topicId] : null,
              presetId: s.presetId,
              totalTokens: s.totalTokens,
            ))
        .toList();

    final messageBackups = messages
        .map((m) => MessageBackup(
              timestamp: m.timestamp,
              isUser: m.isUser,
              content: m.content,
              reasoningContent: m.reasoningContent,
              attachments: m.attachments,
              images: m.images,
              sessionId: m.sessionId,
              assistantId: m.assistantId,
              requestId: m.requestId,
              model: m.model,
              provider: m.provider,
              reasoningDurationSeconds: m.reasoningDurationSeconds,
              role: m.role,
              toolCallId: m.toolCallId,
              toolCallsJson: m.toolCallsJson,
              tokenCount: m.tokenCount,
              promptTokens: m.promptTokens,
              completionTokens: m.completionTokens,
              reasoningTokens: m.reasoningTokens,
              firstTokenMs: m.firstTokenMs,
              durationMs: m.durationMs,
            ))
        .toList();

    final topicBackups = topics
        .map((t) => TopicBackup(
              name: t.name,
              createdAt: t.createdAt,
            ))
        .toList();

    final chatPresetBackups = chatPresets
        .map((p) => ChatPresetBackup(
              presetId: p.presetId,
              name: p.name,
              description: p.description,
              systemPrompt: p.systemPrompt,
            ))
        .toList();

    final providerConfigBackups = providerConfigs
        .map((c) => ProviderConfigBackup(
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
            ))
        .toList();

    final preferences = <String, dynamic>{};

    if (options.includeAppSettings) {
      if (appSettings != null) {
        preferences[_prefAppSettings] = _appSettingsToJson(appSettings);
      }
      preferences[_prefSessionOrder] = sessionOrder;
      preferences[_prefProviderOrder] = providerOrder;
    }

    if (options.includeAssistants) {
      preferences[_prefAssistants] =
          assistants.map(_assistantToJson).toList(growable: false);
      preferences[_prefAssistantMemoryItems] = assistantMemoryItems
          .map(_assistantMemoryItemToJson)
          .toList(growable: false);
      preferences[_prefAssistantMemoryStates] = assistantMemoryStates
          .map(_assistantMemoryStateToJson)
          .toList(growable: false);
    }

    if (options.includeKnowledgeBases) {
      preferences[_prefKnowledgeBases] =
          knowledgeBases.map(_knowledgeBaseToJson).toList(growable: false);
      preferences[_prefKnowledgeDocuments] = knowledgeDocuments
          .map(_knowledgeDocumentToJson)
          .toList(growable: false);
      preferences[_prefKnowledgeChunks] =
          knowledgeChunks.map(_knowledgeChunkToJson).toList(growable: false);
    }

    if (options.includeUsageStats) {
      preferences[_prefUsageStats] =
          usageStats.map(_usageStatsToJson).toList(growable: false);
      preferences[_prefDailyUsageStats] =
          dailyUsageStats.map(_dailyUsageStatsToJson).toList(growable: false);
    }

    return BackupEntity(
      version: 2,
      createdAt: DateTime.now(),
      sessions: sessionBackups,
      messages: messageBackups,
      topics: topicBackups,
      chatPresets: chatPresetBackups,
      providerConfigs: providerConfigBackups,
      studioContent: studioContent,
      preferences: preferences,
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

    await zipFile.writeAsBytes(encoded);
    return zipFile;
  }

  Future<BackupEntity> _parseBackupFile(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dataFile = archive.findFile('data.json');
    if (dataFile == null) {
      throw Exception('Invalid backup file: data.json not found');
    }

    final content = utf8.decode(dataFile.content as List<int>);
    final json = jsonDecode(content);
    return BackupEntity.fromJson(json);
  }

  Future<void> _mergeData(BackupEntity backup) async {
    final isar = _storage.isar;
    final preferences = backup.preferences;

    await isar.writeTxn(() async {
      // 1. Merge Topics
      for (final t in backup.topics) {
        final existing =
            await isar.topicEntitys.filter().nameEqualTo(t.name).findFirst();
        if (existing == null) {
          await isar.topicEntitys.put(TopicEntity()
            ..name = t.name
            ..createdAt = t.createdAt);
        }
      }

      // Need to re-fetch topics to get their IDs map
      final allTopics = await isar.topicEntitys.where().findAll();
      final topicMap = {for (var t in allTopics) t.name: t.id};

      // 2. Merge Sessions
      for (final s in backup.sessions) {
        final existing = await isar.sessionEntitys
            .filter()
            .sessionIdEqualTo(s.sessionId)
            .findFirst();

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
            ..totalTokens = s.totalTokens);
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
            ..assistantId = m.assistantId
            ..requestId = m.requestId
            ..model = m.model
            ..provider = m.provider
            ..reasoningDurationSeconds = m.reasoningDurationSeconds
            ..role = m.role
            ..toolCallId = m.toolCallId
            ..toolCallsJson = m.toolCallsJson
            ..tokenCount = m.tokenCount
            ..promptTokens = m.promptTokens
            ..completionTokens = m.completionTokens
            ..reasoningTokens = m.reasoningTokens
            ..firstTokenMs = m.firstTokenMs
            ..durationMs = m.durationMs);
        }
      }

      // 4. Merge Chat Presets
      for (final p in backup.chatPresets) {
        final existing = await isar.chatPresetEntitys
            .filter()
            .presetIdEqualTo(p.presetId)
            .findFirst();
        if (existing == null) {
          await isar.chatPresetEntitys.put(ChatPresetEntity()
            ..presetId = p.presetId
            ..name = p.name
            ..description = p.description
            ..systemPrompt = p.systemPrompt);
        }
      }

      // 5. Merge Provider Configs
      for (final c in backup.providerConfigs) {
        final existing = await isar.providerConfigEntitys
            .filter()
            .providerIdEqualTo(c.providerId)
            .findFirst();
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
            ..isEnabled = c.isEnabled);
        } else {
          // If existing, maybe update some fields? For now, we only add missing ones or keep existing.
          // In sync, usually we might want to update if backup is newer, but Isaar doesn't have updatedAt on these.
          // We'll stick to "add if missing" for provider configs to avoid overwriting user's local keys if they differ.
        }
      }

      // 6. Restore additional selectable content
      await _mergeExtendedPreferences(isar, preferences);
    });

    // 7. Restore Studio Content
    if (backup.studioContent != null) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final studioFile = File('${docsDir.path}/novel_writing_state.json');
        await studioFile.writeAsString(jsonEncode(backup.studioContent));
      } catch (e) {
        debugPrint('Error restoring studio content: $e');
      }
    }

    // 8. Restore ordering preferences from local files
    await _restoreOrderPreferences(preferences);
  }

  Future<void> _mergeExtendedPreferences(
      Isar isar, Map<String, dynamic> preferences) async {
    if (preferences.isEmpty) return;

    // App settings
    if (preferences.containsKey(_prefAppSettings)) {
      final appSettingsJson = _asMap(preferences[_prefAppSettings]);
      final appSettings = _appSettingsFromJson(appSettingsJson);
      if (appSettings != null) {
        await isar.appSettingsEntitys.clear();
        await isar.appSettingsEntitys.put(appSettings);
      }
    }

    // Assistants and memory
    if (preferences.containsKey(_prefAssistants)) {
      final assistants = _decodeEntityList<AssistantEntity>(
        preferences[_prefAssistants],
        _assistantFromJson,
      );
      if (assistants.isNotEmpty) {
        await isar.assistantEntitys.putAll(assistants);
      }
    }
    if (preferences.containsKey(_prefAssistantMemoryItems)) {
      final memoryItems = _decodeEntityList<AssistantMemoryItemEntity>(
        preferences[_prefAssistantMemoryItems],
        _assistantMemoryItemFromJson,
      );
      if (memoryItems.isNotEmpty) {
        await isar.assistantMemoryItemEntitys.putAll(memoryItems);
      }
    }
    if (preferences.containsKey(_prefAssistantMemoryStates)) {
      final memoryStates = _decodeEntityList<AssistantMemoryStateEntity>(
        preferences[_prefAssistantMemoryStates],
        _assistantMemoryStateFromJson,
      );
      if (memoryStates.isNotEmpty) {
        await isar.assistantMemoryStateEntitys.putAll(memoryStates);
      }
    }

    // Knowledge base data
    if (preferences.containsKey(_prefKnowledgeBases)) {
      final bases = _decodeEntityList<KnowledgeBaseEntity>(
        preferences[_prefKnowledgeBases],
        _knowledgeBaseFromJson,
      );
      if (bases.isNotEmpty) {
        await isar.knowledgeBaseEntitys.putAll(bases);
      }
    }
    if (preferences.containsKey(_prefKnowledgeDocuments)) {
      final docs = _decodeEntityList<KnowledgeDocumentEntity>(
        preferences[_prefKnowledgeDocuments],
        _knowledgeDocumentFromJson,
      );
      if (docs.isNotEmpty) {
        await isar.knowledgeDocumentEntitys.putAll(docs);
      }
    }
    if (preferences.containsKey(_prefKnowledgeChunks)) {
      final chunks = _decodeEntityList<KnowledgeChunkEntity>(
        preferences[_prefKnowledgeChunks],
        _knowledgeChunkFromJson,
      );
      if (chunks.isNotEmpty) {
        await isar.knowledgeChunkEntitys.putAll(chunks);
      }
    }

    // Usage statistics
    if (preferences.containsKey(_prefUsageStats)) {
      final usageStats = _decodeEntityList<UsageStatsEntity>(
        preferences[_prefUsageStats],
        _usageStatsFromJson,
      );
      if (usageStats.isNotEmpty) {
        await isar.usageStatsEntitys.putAll(usageStats);
      }
    }
    if (preferences.containsKey(_prefDailyUsageStats)) {
      final dailyUsageStats = _decodeEntityList<DailyUsageStatsEntity>(
        preferences[_prefDailyUsageStats],
        _dailyUsageStatsFromJson,
      );
      if (dailyUsageStats.isNotEmpty) {
        await isar.dailyUsageStatsEntitys.putAll(dailyUsageStats);
      }
    }
  }

  Future<void> _restoreOrderPreferences(
      Map<String, dynamic> preferences) async {
    if (preferences.isEmpty) return;
    try {
      if (preferences.containsKey(_prefSessionOrder)) {
        final sessionOrder = _asStringList(preferences[_prefSessionOrder]);
        await _storage.saveSessionOrder(sessionOrder);
      }
      if (preferences.containsKey(_prefProviderOrder)) {
        final providerOrder = _asStringList(preferences[_prefProviderOrder]);
        await _storage.saveProviderOrder(providerOrder);
      }
    } catch (e) {
      debugPrint('Error restoring order preferences: $e');
    }
  }

  Map<String, dynamic> _appSettingsToJson(AppSettingsEntity s) => {
        'activeProviderId': s.activeProviderId,
        'selectedModel': s.selectedModel,
        'availableModels': s.availableModels,
        'userName': s.userName,
        'userAvatar': s.userAvatar,
        'llmName': s.llmName,
        'llmAvatar': s.llmAvatar,
        'themeMode': s.themeMode,
        'isStreamEnabled': s.isStreamEnabled,
        'isSearchEnabled': s.isSearchEnabled,
        'isKnowledgeEnabled': s.isKnowledgeEnabled,
        'searchEngine': s.searchEngine,
        'searchRegion': s.searchRegion,
        'searchSafeSearch': s.searchSafeSearch,
        'searchMaxResults': s.searchMaxResults,
        'searchTimeoutSeconds': s.searchTimeoutSeconds,
        'knowledgeTopK': s.knowledgeTopK,
        'knowledgeUseEmbedding': s.knowledgeUseEmbedding,
        'knowledgeLlmEnhanceMode': s.knowledgeLlmEnhanceMode,
        'knowledgeEmbeddingModel': s.knowledgeEmbeddingModel,
        'knowledgeEmbeddingProviderId': s.knowledgeEmbeddingProviderId,
        'activeKnowledgeBaseIds': s.activeKnowledgeBaseIds,
        'enableSmartTopic': s.enableSmartTopic,
        'topicGenerationModel': s.topicGenerationModel,
        'lastSessionId': s.lastSessionId,
        'lastTopicId': s.lastTopicId,
        'language': s.language,
        'lastPresetId': s.lastPresetId,
        'lastAssistantId': s.lastAssistantId,
        'themeColor': s.themeColor,
        'backgroundColor': s.backgroundColor,
        'closeBehavior': s.closeBehavior,
        'executionModel': s.executionModel,
        'executionProviderId': s.executionProviderId,
        'memoryMinNewUserMessages': s.memoryMinNewUserMessages,
        'memoryIdleSeconds': s.memoryIdleSeconds,
        'memoryMaxBufferedMessages': s.memoryMaxBufferedMessages,
        'memoryMaxRunsPerDay': s.memoryMaxRunsPerDay,
        'memoryContextWindowSize': s.memoryContextWindowSize,
        'fontSize': s.fontSize,
        'backgroundImagePath': s.backgroundImagePath,
        'backgroundBrightness': s.backgroundBrightness,
        'backgroundBlur': s.backgroundBlur,
        'useCustomTheme': s.useCustomTheme,
      };

  AppSettingsEntity? _appSettingsFromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return null;
    return AppSettingsEntity()
      ..activeProviderId =
          _asString(json['activeProviderId'], fallback: 'custom')
      ..selectedModel = _asNullableString(json['selectedModel'])
      ..availableModels = _asStringList(json['availableModels'])
      ..userName = _asString(json['userName'], fallback: 'User')
      ..userAvatar = _asNullableString(json['userAvatar'])
      ..llmName = _asString(json['llmName'], fallback: 'Assistant')
      ..llmAvatar = _asNullableString(json['llmAvatar'])
      ..themeMode = _asString(json['themeMode'], fallback: 'system')
      ..isStreamEnabled = _asBool(json['isStreamEnabled'], fallback: true)
      ..isSearchEnabled = _asBool(json['isSearchEnabled'], fallback: false)
      ..isKnowledgeEnabled =
          _asBool(json['isKnowledgeEnabled'], fallback: false)
      ..searchEngine = _asString(json['searchEngine'], fallback: 'duckduckgo')
      ..searchRegion = _asString(json['searchRegion'], fallback: 'us-en')
      ..searchSafeSearch =
          _asString(json['searchSafeSearch'], fallback: 'moderate')
      ..searchMaxResults = _asInt(json['searchMaxResults'], fallback: 5)
      ..searchTimeoutSeconds =
          _asInt(json['searchTimeoutSeconds'], fallback: 15)
      ..knowledgeTopK = _asInt(json['knowledgeTopK'], fallback: 5)
      ..knowledgeUseEmbedding =
          _asBool(json['knowledgeUseEmbedding'], fallback: false)
      ..knowledgeLlmEnhanceMode =
          _asString(json['knowledgeLlmEnhanceMode'], fallback: 'off')
      ..knowledgeEmbeddingModel =
          _asNullableString(json['knowledgeEmbeddingModel'])
      ..knowledgeEmbeddingProviderId =
          _asNullableString(json['knowledgeEmbeddingProviderId'])
      ..activeKnowledgeBaseIds = _asStringList(json['activeKnowledgeBaseIds'])
      ..enableSmartTopic = _asBool(json['enableSmartTopic'], fallback: true)
      ..topicGenerationModel = _asNullableString(json['topicGenerationModel'])
      ..lastSessionId = _asNullableString(json['lastSessionId'])
      ..lastTopicId = _asNullableString(json['lastTopicId'])
      ..language = _asString(json['language'], fallback: 'zh')
      ..lastPresetId = _asNullableString(json['lastPresetId'])
      ..lastAssistantId = _asNullableString(json['lastAssistantId'])
      ..themeColor = _asNullableString(json['themeColor'])
      ..backgroundColor = _asNullableString(json['backgroundColor'])
      ..closeBehavior = _asInt(json['closeBehavior'], fallback: 0)
      ..executionModel = _asNullableString(json['executionModel'])
      ..executionProviderId = _asNullableString(json['executionProviderId'])
      ..memoryMinNewUserMessages =
          _asInt(json['memoryMinNewUserMessages'], fallback: 20)
      ..memoryIdleSeconds = _asInt(json['memoryIdleSeconds'], fallback: 600)
      ..memoryMaxBufferedMessages =
          _asInt(json['memoryMaxBufferedMessages'], fallback: 120)
      ..memoryMaxRunsPerDay = _asInt(json['memoryMaxRunsPerDay'], fallback: 2)
      ..memoryContextWindowSize =
          _asInt(json['memoryContextWindowSize'], fallback: 80)
      ..fontSize = _asDouble(json['fontSize'], fallback: 14.0)
      ..backgroundImagePath = _asNullableString(json['backgroundImagePath'])
      ..backgroundBrightness =
          _asDouble(json['backgroundBrightness'], fallback: 0.5)
      ..backgroundBlur = _asDouble(json['backgroundBlur'], fallback: 0.0)
      ..useCustomTheme = _asBool(json['useCustomTheme'], fallback: false);
  }

  Map<String, dynamic> _assistantToJson(AssistantEntity assistant) => {
        'assistantId': assistant.assistantId,
        'name': assistant.name,
        'avatar': assistant.avatar,
        'description': assistant.description,
        'systemPrompt': assistant.systemPrompt,
        'preferredModel': assistant.preferredModel,
        'providerId': assistant.providerId,
        'skillIds': assistant.skillIds,
        'knowledgeBaseIds': assistant.knowledgeBaseIds,
        'enableMemory': assistant.enableMemory,
        'memoryProviderId': assistant.memoryProviderId,
        'memoryModel': assistant.memoryModel,
        'updatedAt': assistant.updatedAt?.toIso8601String(),
      };

  AssistantEntity? _assistantFromJson(Map<String, dynamic> json) {
    final assistantId = _asNullableString(json['assistantId']);
    final name = _asNullableString(json['name']);
    final systemPrompt = _asNullableString(json['systemPrompt']);
    if (assistantId == null ||
        assistantId.isEmpty ||
        name == null ||
        name.isEmpty ||
        systemPrompt == null) {
      return null;
    }

    return AssistantEntity()
      ..assistantId = assistantId
      ..name = name
      ..avatar = _asNullableString(json['avatar'])
      ..description = _asNullableString(json['description'])
      ..systemPrompt = systemPrompt
      ..preferredModel = _asNullableString(json['preferredModel'])
      ..providerId = _asNullableString(json['providerId'])
      ..skillIds = _asStringList(json['skillIds'])
      ..knowledgeBaseIds = _asStringList(json['knowledgeBaseIds'])
      ..enableMemory = _asBool(json['enableMemory'], fallback: false)
      ..memoryProviderId = _asNullableString(json['memoryProviderId'])
      ..memoryModel = _asNullableString(json['memoryModel'])
      ..updatedAt = _asDateTime(json['updatedAt']);
  }

  Map<String, dynamic> _assistantMemoryItemToJson(
          AssistantMemoryItemEntity item) =>
      {
        'memoryId': item.memoryId,
        'assistantId': item.assistantId,
        'key': item.key,
        'valueJson': item.valueJson,
        'confidence': item.confidence,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
        'lastSeenAt': item.lastSeenAt?.toIso8601String(),
        'evidenceMessageIds': item.evidenceMessageIds,
        'isActive': item.isActive,
      };

  AssistantMemoryItemEntity? _assistantMemoryItemFromJson(
      Map<String, dynamic> json) {
    final memoryId = _asNullableString(json['memoryId']);
    final assistantId = _asNullableString(json['assistantId']);
    final key = _asNullableString(json['key']);
    final valueJson = _asNullableString(json['valueJson']);
    if (memoryId == null ||
        memoryId.isEmpty ||
        assistantId == null ||
        assistantId.isEmpty ||
        key == null ||
        key.isEmpty ||
        valueJson == null) {
      return null;
    }

    return AssistantMemoryItemEntity()
      ..memoryId = memoryId
      ..assistantId = assistantId
      ..key = key
      ..valueJson = valueJson
      ..confidence = _asDouble(json['confidence'], fallback: 0.0)
      ..createdAt = _asDateTime(json['createdAt']) ?? DateTime.now()
      ..updatedAt = _asDateTime(json['updatedAt']) ?? DateTime.now()
      ..lastSeenAt = _asDateTime(json['lastSeenAt'])
      ..evidenceMessageIds = _asIntList(json['evidenceMessageIds'])
      ..isActive = _asBool(json['isActive'], fallback: true);
  }

  Map<String, dynamic> _assistantMemoryStateToJson(
          AssistantMemoryStateEntity state) =>
      {
        'assistantId': state.assistantId,
        'consolidatedUntilMessageId': state.consolidatedUntilMessageId,
        'lastSuccessfulRunAt': state.lastSuccessfulRunAt?.toIso8601String(),
        'lastObservedMessageAt': state.lastObservedMessageAt?.toIso8601String(),
        'runsToday': state.runsToday,
        'runsDayKey': state.runsDayKey,
      };

  AssistantMemoryStateEntity? _assistantMemoryStateFromJson(
      Map<String, dynamic> json) {
    final assistantId = _asNullableString(json['assistantId']);
    if (assistantId == null || assistantId.isEmpty) return null;

    return AssistantMemoryStateEntity()
      ..assistantId = assistantId
      ..consolidatedUntilMessageId =
          _asInt(json['consolidatedUntilMessageId'], fallback: 0)
      ..lastSuccessfulRunAt = _asDateTime(json['lastSuccessfulRunAt'])
      ..lastObservedMessageAt = _asDateTime(json['lastObservedMessageAt'])
      ..runsToday = _asInt(json['runsToday'], fallback: 0)
      ..runsDayKey = _asNullableString(json['runsDayKey']);
  }

  Map<String, dynamic> _knowledgeBaseToJson(KnowledgeBaseEntity base) => {
        'baseId': base.baseId,
        'scope': base.scope,
        'ownerProjectId': base.ownerProjectId,
        'name': base.name,
        'description': base.description,
        'isEnabled': base.isEnabled,
        'createdAt': base.createdAt.toIso8601String(),
        'updatedAt': base.updatedAt.toIso8601String(),
      };

  KnowledgeBaseEntity? _knowledgeBaseFromJson(Map<String, dynamic> json) {
    final baseId = _asNullableString(json['baseId']);
    final name = _asNullableString(json['name']);
    if (baseId == null || baseId.isEmpty || name == null || name.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    return KnowledgeBaseEntity()
      ..baseId = baseId
      ..scope = _asString(json['scope'], fallback: 'chat')
      ..ownerProjectId = _asNullableString(json['ownerProjectId'])
      ..name = name
      ..description = _asString(json['description'], fallback: '')
      ..isEnabled = _asBool(json['isEnabled'], fallback: true)
      ..createdAt = _asDateTime(json['createdAt']) ?? now
      ..updatedAt = _asDateTime(json['updatedAt']) ?? now;
  }

  Map<String, dynamic> _knowledgeDocumentToJson(KnowledgeDocumentEntity doc) =>
      {
        'documentId': doc.documentId,
        'baseId': doc.baseId,
        'fileName': doc.fileName,
        'sourcePath': doc.sourcePath,
        'status': doc.status,
        'error': doc.error,
        'chunkCount': doc.chunkCount,
        'createdAt': doc.createdAt.toIso8601String(),
        'updatedAt': doc.updatedAt.toIso8601String(),
      };

  KnowledgeDocumentEntity? _knowledgeDocumentFromJson(
      Map<String, dynamic> json) {
    final documentId = _asNullableString(json['documentId']);
    final baseId = _asNullableString(json['baseId']);
    final fileName = _asNullableString(json['fileName']);
    if (documentId == null ||
        documentId.isEmpty ||
        baseId == null ||
        baseId.isEmpty ||
        fileName == null ||
        fileName.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    return KnowledgeDocumentEntity()
      ..documentId = documentId
      ..baseId = baseId
      ..fileName = fileName
      ..sourcePath = _asNullableString(json['sourcePath'])
      ..status = _asString(json['status'], fallback: 'ready')
      ..error = _asNullableString(json['error'])
      ..chunkCount = _asInt(json['chunkCount'], fallback: 0)
      ..createdAt = _asDateTime(json['createdAt']) ?? now
      ..updatedAt = _asDateTime(json['updatedAt']) ?? now;
  }

  Map<String, dynamic> _knowledgeChunkToJson(KnowledgeChunkEntity chunk) => {
        'chunkId': chunk.chunkId,
        'baseId': chunk.baseId,
        'documentId': chunk.documentId,
        'chunkIndex': chunk.chunkIndex,
        'text': chunk.text,
        'tokens': chunk.tokens,
        'tokenCount': chunk.tokenCount,
        'sourceLabel': chunk.sourceLabel,
        'embeddingJson': chunk.embeddingJson,
        'createdAt': chunk.createdAt.toIso8601String(),
      };

  KnowledgeChunkEntity? _knowledgeChunkFromJson(Map<String, dynamic> json) {
    final chunkId = _asNullableString(json['chunkId']);
    final baseId = _asNullableString(json['baseId']);
    final documentId = _asNullableString(json['documentId']);
    final text = _asNullableString(json['text']);
    final tokens = _asNullableString(json['tokens']);
    final sourceLabel = _asNullableString(json['sourceLabel']);
    if (chunkId == null ||
        chunkId.isEmpty ||
        baseId == null ||
        baseId.isEmpty ||
        documentId == null ||
        documentId.isEmpty ||
        text == null ||
        tokens == null ||
        sourceLabel == null) {
      return null;
    }

    return KnowledgeChunkEntity()
      ..chunkId = chunkId
      ..baseId = baseId
      ..documentId = documentId
      ..chunkIndex = _asInt(json['chunkIndex'], fallback: 0)
      ..text = text
      ..tokens = tokens
      ..tokenCount = _asInt(json['tokenCount'], fallback: 0)
      ..sourceLabel = sourceLabel
      ..embeddingJson = _asNullableString(json['embeddingJson'])
      ..createdAt = _asDateTime(json['createdAt']) ?? DateTime.now();
  }

  Map<String, dynamic> _usageStatsToJson(UsageStatsEntity stats) => {
        'modelName': stats.modelName,
        'successCount': stats.successCount,
        'failureCount': stats.failureCount,
        'totalDurationMs': stats.totalDurationMs,
        'validDurationCount': stats.validDurationCount,
        'totalFirstTokenMs': stats.totalFirstTokenMs,
        'validFirstTokenCount': stats.validFirstTokenCount,
        'totalTokenCount': stats.totalTokenCount,
        'promptTokenCount': stats.promptTokenCount,
        'completionTokenCount': stats.completionTokenCount,
        'reasoningTokenCount': stats.reasoningTokenCount,
        'errorTimeoutCount': stats.errorTimeoutCount,
        'errorNetworkCount': stats.errorNetworkCount,
        'errorBadRequestCount': stats.errorBadRequestCount,
        'errorUnauthorizedCount': stats.errorUnauthorizedCount,
        'errorServerCount': stats.errorServerCount,
        'errorRateLimitCount': stats.errorRateLimitCount,
        'errorUnknownCount': stats.errorUnknownCount,
      };

  UsageStatsEntity? _usageStatsFromJson(Map<String, dynamic> json) {
    final modelName = _asNullableString(json['modelName']);
    if (modelName == null || modelName.isEmpty) return null;

    return UsageStatsEntity()
      ..modelName = modelName
      ..successCount = _asInt(json['successCount'], fallback: 0)
      ..failureCount = _asInt(json['failureCount'], fallback: 0)
      ..totalDurationMs = _asInt(json['totalDurationMs'], fallback: 0)
      ..validDurationCount = _asInt(json['validDurationCount'], fallback: 0)
      ..totalFirstTokenMs = _asInt(json['totalFirstTokenMs'], fallback: 0)
      ..validFirstTokenCount = _asInt(json['validFirstTokenCount'], fallback: 0)
      ..totalTokenCount = _asInt(json['totalTokenCount'], fallback: 0)
      ..promptTokenCount = _asInt(json['promptTokenCount'], fallback: 0)
      ..completionTokenCount = _asInt(json['completionTokenCount'], fallback: 0)
      ..reasoningTokenCount = _asInt(json['reasoningTokenCount'], fallback: 0)
      ..errorTimeoutCount = _asInt(json['errorTimeoutCount'], fallback: 0)
      ..errorNetworkCount = _asInt(json['errorNetworkCount'], fallback: 0)
      ..errorBadRequestCount = _asInt(json['errorBadRequestCount'], fallback: 0)
      ..errorUnauthorizedCount =
          _asInt(json['errorUnauthorizedCount'], fallback: 0)
      ..errorServerCount = _asInt(json['errorServerCount'], fallback: 0)
      ..errorRateLimitCount = _asInt(json['errorRateLimitCount'], fallback: 0)
      ..errorUnknownCount = _asInt(json['errorUnknownCount'], fallback: 0);
  }

  Map<String, dynamic> _dailyUsageStatsToJson(DailyUsageStatsEntity stats) => {
        'date': stats.date.toIso8601String(),
        'totalCalls': stats.totalCalls,
        'successCount': stats.successCount,
        'failureCount': stats.failureCount,
        'tokenCount': stats.tokenCount,
      };

  DailyUsageStatsEntity? _dailyUsageStatsFromJson(Map<String, dynamic> json) {
    final date = _asDateTime(json['date']);
    if (date == null) return null;

    return DailyUsageStatsEntity()
      ..date = DateTime(date.year, date.month, date.day)
      ..totalCalls = _asInt(json['totalCalls'], fallback: 0)
      ..successCount = _asInt(json['successCount'], fallback: 0)
      ..failureCount = _asInt(json['failureCount'], fallback: 0)
      ..tokenCount = _asInt(json['tokenCount'], fallback: 0);
  }

  List<T> _decodeEntityList<T>(
      dynamic raw, T? Function(Map<String, dynamic>) decoder) {
    if (raw is! List) return const [];

    final results = <T>[];
    for (final item in raw) {
      final map = _asMap(item);
      if (map.isEmpty) continue;
      final entity = decoder(map);
      if (entity != null) {
        results.add(entity);
      }
    }
    return results;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  String _asString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  String? _asNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final converted = value.toString().trim();
    return converted.isEmpty ? null : converted;
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  double _asDouble(dynamic value, {required double fallback}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  List<int> _asIntList(dynamic value) {
    if (value is! List) return const [];
    final result = <int>[];
    for (final item in value) {
      if (item is int) {
        result.add(item);
        continue;
      }
      if (item is num) {
        result.add(item.toInt());
        continue;
      }
      final parsed = int.tryParse(item.toString());
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }
}
