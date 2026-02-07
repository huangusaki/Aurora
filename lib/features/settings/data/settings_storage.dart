import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/error/app_error_type.dart';
import 'chat_preset_entity.dart';
import 'daily_usage_stats_entity.dart';
import 'provider_config_entity.dart';
import 'usage_stats_entity.dart';
import '../../chat/data/message_entity.dart';
import '../../chat/data/session_entity.dart';
import '../../chat/data/topic_entity.dart';
import '../../knowledge/data/knowledge_entities.dart';

import '../../assistant/data/assistant_entity.dart';

class SettingsStorage {
  late Isar _isar;
  Isar get isar => _isar;
  Future<void> init() async {
    final supportDir = await getApplicationSupportDirectory();
    final documentsDir = await getApplicationDocumentsDirectory();

    // Migration logic
    await _migrateFromExampleIfNeeded(supportDir);
    await _migrateIfNeeded(documentsDir, supportDir);

    _isar = await Isar.open(
      [
        ProviderConfigEntitySchema,
        AppSettingsEntitySchema,
        MessageEntitySchema,
        SessionEntitySchema,
        UsageStatsEntitySchema,
        DailyUsageStatsEntitySchema,
        TopicEntitySchema,
        ChatPresetEntitySchema,
        AssistantEntitySchema,
        KnowledgeBaseEntitySchema,
        KnowledgeDocumentEntitySchema,
        KnowledgeChunkEntitySchema,
      ],
      directory: supportDir.path,
    );

    // Fix legacy absolute paths inside the database content
    await _fixLegacyPaths(supportDir.path);
  }

  Future<void> _migrateIfNeeded(Directory oldDir, Directory newDir) async {
    // If the new directory doesn't have the database, but the old one does, migrate.
    final oldIsarFile = File('${oldDir.path}/default.isar');
    final newIsarFile = File('${newDir.path}/default.isar');

    if (await oldIsarFile.exists() && !await newIsarFile.exists()) {
      debugPrint('Migrating Aurora data from ${oldDir.path} to ${newDir.path}');

      // Ensure new directory exists
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }

      // 1. Migrate Isar database files
      final filesToMigrate = [
        'default.isar',
        'default.isar.lock',
      ];

      for (final fileName in filesToMigrate) {
        final oldFile = File('${oldDir.path}/$fileName');
        if (await oldFile.exists()) {
          await oldFile.copy('${newDir.path}/$fileName');
          await oldFile.delete();
        }
      }

      // 2. Migrate JSON config files
      final jsonFiles = [
        'session_order.json',
        'provider_order.json',
        'novel_writing_state.json',
      ];

      for (final fileName in jsonFiles) {
        final oldFile = File('${oldDir.path}/$fileName');
        if (await oldFile.exists()) {
          await oldFile.copy('${newDir.path}/$fileName');
          await oldFile.delete();
        }
      }

      // 3. Migrate background images
      try {
        final backgroundDir = Directory('${newDir.path}/backgrounds');
        if (!await backgroundDir.exists()) {
          await backgroundDir.create(recursive: true);
        }

        final files = oldDir.listSync();
        for (var file in files) {
          if (file is File) {
            final fileName = file.uri.pathSegments.last;
            if (fileName.startsWith('custom_background')) {
              await file.copy('${backgroundDir.path}/$fileName');
              await file.delete();
            }
          }
        }
      } catch (e) {
        debugPrint('Error migrating background images: $e');
      }

      // 4. Migrate Aurora attachments folder
      try {
        final oldAuroraDir = Directory('${oldDir.path}/Aurora');
        if (await oldAuroraDir.exists()) {
          // We can just move the whole directory if it's on the same partition,
          // but copy/delete is safer across partitions if that were ever the case.
          // For simplicity and consistency with other steps, let's copy recursive.
          await _copyDirectory(oldAuroraDir, Directory(newDir.path));
          await oldAuroraDir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('Error migrating Aurora attachments: $e');
      }

      debugPrint('Migration completed successfully.');
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }
    await for (var entity in source.list(recursive: false)) {
      final fileName = entity.path.split(Platform.pathSeparator).last;
      final newPath = '${destination.path}${Platform.pathSeparator}$fileName';
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  Future<void> saveProvider(ProviderConfigEntity provider) async {
    await _isar.writeTxn(() async {
      await _isar.providerConfigEntitys.put(provider);
    });
  }

  Future<void> deleteProvider(String providerId) async {
    await _isar.writeTxn(() async {
      await _isar.providerConfigEntitys
          .filter()
          .providerIdEqualTo(providerId)
          .deleteAll();
    });
  }

  Future<List<ProviderConfigEntity>> loadProviders() async {
    final providers = await _isar.providerConfigEntitys.where().findAll();
    final order = await loadProviderOrder();
    if (order.isEmpty) return providers;

    // Sort providers based on order list
    final Map<String, int> orderMap = {
      for (var i = 0; i < order.length; i++) order[i]: i
    };

    providers.sort((a, b) {
      final indexA = orderMap[a.providerId] ?? 9999;
      final indexB = orderMap[b.providerId] ?? 9999;
      return indexA.compareTo(indexB);
    });

    return providers;
  }

  Future<void> saveAppSettings({
    String? activeProviderId,
    String? selectedModel,
    List<String>? availableModels,
    String? userName,
    String? userAvatar,
    String? llmName,
    String? llmAvatar,
    String? themeMode,
    bool? isStreamEnabled,
    bool? isSearchEnabled,
    bool? isKnowledgeEnabled,
    String? searchEngine,
    String? searchRegion,
    String? searchSafeSearch,
    int? searchMaxResults,
    int? searchTimeoutSeconds,
    int? knowledgeTopK,
    bool? knowledgeUseEmbedding,
    String? knowledgeLlmEnhanceMode,
    String? knowledgeEmbeddingModel,
    String? knowledgeEmbeddingProviderId,
    List<String>? activeKnowledgeBaseIds,
    bool? enableSmartTopic,
    String? topicGenerationModel,
    String? lastSessionId,
    String? lastTopicId,
    String? language,
    String? themeColor,
    String? backgroundColor,
    int? closeBehavior,
    String? executionModel,
    String? executionProviderId,
    double? fontSize,
    String? backgroundImagePath,
    double? backgroundBrightness,
    double? backgroundBlur,
    bool? useCustomTheme,
    bool clearBackgroundImage = false,
  }) async {
    final existing = await loadAppSettings();
    final settings = AppSettingsEntity()
      ..activeProviderId = activeProviderId ?? existing?.activeProviderId ?? ''
      ..selectedModel = selectedModel ?? existing?.selectedModel
      ..availableModels = availableModels ?? existing?.availableModels ?? []
      ..userName = userName ?? existing?.userName ?? 'User'
      ..userAvatar = userAvatar ?? existing?.userAvatar
      ..llmName = llmName ?? existing?.llmName ?? 'Assistant'
      ..llmAvatar = llmAvatar ?? existing?.llmAvatar
      ..themeMode = themeMode ?? existing?.themeMode ?? 'system'
      ..isStreamEnabled = isStreamEnabled ?? existing?.isStreamEnabled ?? true
      ..isSearchEnabled = isSearchEnabled ?? existing?.isSearchEnabled ?? false
      ..isKnowledgeEnabled =
          isKnowledgeEnabled ?? existing?.isKnowledgeEnabled ?? false
      ..searchEngine = searchEngine ?? existing?.searchEngine ?? 'duckduckgo'
      ..searchRegion = searchRegion ?? existing?.searchRegion ?? 'us-en'
      ..searchSafeSearch =
          searchSafeSearch ?? existing?.searchSafeSearch ?? 'moderate'
      ..searchMaxResults = searchMaxResults ?? existing?.searchMaxResults ?? 5
      ..searchTimeoutSeconds =
          searchTimeoutSeconds ?? existing?.searchTimeoutSeconds ?? 15
      ..knowledgeTopK = knowledgeTopK ?? existing?.knowledgeTopK ?? 5
      ..knowledgeUseEmbedding =
          knowledgeUseEmbedding ?? existing?.knowledgeUseEmbedding ?? false
      ..knowledgeLlmEnhanceMode =
          knowledgeLlmEnhanceMode ?? existing?.knowledgeLlmEnhanceMode ?? 'off'
      ..knowledgeEmbeddingModel =
          knowledgeEmbeddingModel ?? existing?.knowledgeEmbeddingModel
      ..knowledgeEmbeddingProviderId =
          knowledgeEmbeddingProviderId ?? existing?.knowledgeEmbeddingProviderId
      ..activeKnowledgeBaseIds =
          activeKnowledgeBaseIds ?? existing?.activeKnowledgeBaseIds ?? []
      ..enableSmartTopic =
          enableSmartTopic ?? existing?.enableSmartTopic ?? true
      ..topicGenerationModel =
          topicGenerationModel ?? existing?.topicGenerationModel
      ..lastSessionId = lastSessionId ?? existing?.lastSessionId
      ..lastTopicId = lastTopicId ?? existing?.lastTopicId
      ..language = language ?? existing?.language ?? 'zh'
      ..lastPresetId = existing?.lastPresetId
      ..lastAssistantId = existing?.lastAssistantId
      ..themeColor = themeColor ?? existing?.themeColor
      ..backgroundColor = backgroundColor ?? existing?.backgroundColor
      ..closeBehavior = closeBehavior ?? existing?.closeBehavior ?? 0
      ..executionModel = executionModel ?? existing?.executionModel
      ..executionProviderId =
          executionProviderId ?? existing?.executionProviderId
      ..fontSize = fontSize ?? existing?.fontSize ?? 14.0
      ..backgroundImagePath = clearBackgroundImage
          ? null
          : (backgroundImagePath ?? existing?.backgroundImagePath)
      ..backgroundBrightness =
          backgroundBrightness ?? existing?.backgroundBrightness ?? 0.5
      ..backgroundBlur = backgroundBlur ?? existing?.backgroundBlur ?? 0.0
      ..useCustomTheme = useCustomTheme ?? existing?.useCustomTheme ?? false;
    await _saveSingleAppSettings(settings);
  }

  Future<void> saveLastSessionId(String sessionId) async {
    await _updateExistingAppSettings((settings) {
      settings.lastSessionId = sessionId;
    });
  }

  Future<AppSettingsEntity?> loadAppSettings() async {
    return await _isar.appSettingsEntitys.where().findFirst();
  }

  Future<void> saveChatDisplaySettings({
    String? userName,
    String? userAvatar,
    String? llmName,
    String? llmAvatar,
  }) async {
    await _updateExistingAppSettings((settings) {
      settings.userName = userName ?? settings.userName;
      settings.userAvatar = userAvatar ?? settings.userAvatar;
      settings.llmName = llmName ?? settings.llmName;
      settings.llmAvatar = llmAvatar ?? settings.llmAvatar;
    });
  }

  Future<File> get _orderFile async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/session_order.json');
  }

  Future<List<String>> loadSessionOrder() async {
    try {
      final file = await _orderFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> json = jsonDecode(content);
        return json.cast<String>();
      }
    } catch (e, st) {
      debugPrint('Failed to load session order: $e\n$st');
    }
    return [];
  }

  Future<void> saveSessionOrder(List<String> order) async {
    try {
      final file = await _orderFile;
      await file.writeAsString(jsonEncode(order));
    } catch (e, st) {
      debugPrint('Failed to save session order: $e\n$st');
    }
  }

  Future<File> get _providerOrderFile async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/provider_order.json');
  }

  Future<List<String>> loadProviderOrder() async {
    try {
      final file = await _providerOrderFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> json = jsonDecode(content);
        return json.cast<String>();
      }
    } catch (e, st) {
      debugPrint('Failed to load provider order: $e\n$st');
    }
    return [];
  }

  Future<void> saveProviderOrder(List<String> order) async {
    try {
      final file = await _providerOrderFile;
      await file.writeAsString(jsonEncode(order));
    } catch (e, st) {
      debugPrint('Failed to save provider order: $e\n$st');
    }
  }

  Future<void> incrementUsage(String modelName,
      {bool success = true,
      int durationMs = 0,
      int firstTokenMs = 0,
      int tokenCount =
          0, // Kept for backward compatibility logic, usually sum of prompt+completion
      int promptTokens = 0,
      int completionTokens = 0,
      int reasoningTokens = 0,
      AppErrorType? errorType}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _isar.writeTxn(() async {
      // 1. Update per-model stats
      var existing = await _isar.usageStatsEntitys
          .filter()
          .modelNameEqualTo(modelName)
          .findFirst();
      if (existing == null) {
        existing = UsageStatsEntity()
          ..modelName = modelName
          ..successCount = success ? 1 : 0
          ..failureCount = success ? 0 : 1
          ..totalDurationMs = durationMs > 0 ? durationMs : 0
          ..validDurationCount = durationMs > 0 ? 1 : 0
          ..totalFirstTokenMs = firstTokenMs > 0 ? firstTokenMs : 0
          ..validFirstTokenCount = firstTokenMs > 0 ? 1 : 0
          ..promptTokenCount =
              promptTokens > 0 ? promptTokens : (tokenCount ~/ 2)
          ..completionTokenCount = completionTokens > 0
              ? completionTokens
              : (tokenCount - tokenCount ~/ 2)
          ..reasoningTokenCount = reasoningTokens > 0 ? reasoningTokens : 0
          ..totalTokenCount =
              (promptTokens > 0 ? promptTokens : (tokenCount ~/ 2)) +
                  (completionTokens > 0
                      ? completionTokens
                      : (tokenCount - tokenCount ~/ 2)) +
                  (reasoningTokens > 0 ? reasoningTokens : 0);

        if (errorType != null) {
          _updateErrorCount(existing, errorType);
        }
      } else {
        if (success) {
          existing.successCount++;
        } else {
          existing.failureCount++;
          if (errorType != null) {
            _updateErrorCount(existing, errorType);
          }
        }
        if (durationMs > 0) {
          existing.totalDurationMs += durationMs;
          existing.validDurationCount++;
        }
        if (firstTokenMs > 0) {
          existing.totalFirstTokenMs += firstTokenMs;
          existing.validFirstTokenCount++;
        }

        // Always use prompt + completion + reasoning for consistency
        // If only tokenCount is provided (legacy), split evenly as approximation
        final effectivePrompt =
            promptTokens > 0 ? promptTokens : (tokenCount ~/ 2);
        final effectiveCompletion = completionTokens > 0
            ? completionTokens
            : (tokenCount - tokenCount ~/ 2);
        final effectiveReasoning = reasoningTokens > 0 ? reasoningTokens : 0;

        existing.promptTokenCount += effectivePrompt;
        existing.completionTokenCount += effectiveCompletion;
        existing.reasoningTokenCount += effectiveReasoning;
        existing.totalTokenCount = existing.promptTokenCount +
            existing.completionTokenCount +
            existing.reasoningTokenCount;
      }
      await _isar.usageStatsEntitys.put(existing);

      // 2. Update daily stats
      var daily = await _isar.dailyUsageStatsEntitys
          .filter()
          .dateEqualTo(today)
          .findFirst();

      final effectiveTotalForDaily = tokenCount > 0
          ? tokenCount
          : (promptTokens + completionTokens + reasoningTokens);

      if (daily == null) {
        daily = DailyUsageStatsEntity()
          ..date = today
          ..totalCalls = 1
          ..successCount = success ? 1 : 0
          ..failureCount = success ? 0 : 1
          ..tokenCount = effectiveTotalForDaily;
      } else {
        daily.totalCalls++;
        if (success) {
          daily.successCount++;
        } else {
          daily.failureCount++;
        }
        daily.tokenCount += effectiveTotalForDaily;
      }
      await _isar.dailyUsageStatsEntitys.put(daily);
    });
  }

  void _updateErrorCount(UsageStatsEntity entity, AppErrorType errorType) {
    switch (errorType) {
      case AppErrorType.timeout:
        entity.errorTimeoutCount++;
        break;
      case AppErrorType.network:
        entity.errorNetworkCount++;
        break;
      case AppErrorType.badRequest:
        entity.errorBadRequestCount++;
        break;
      case AppErrorType.unauthorized:
        entity.errorUnauthorizedCount++;
        break;
      case AppErrorType.serverError:
        entity.errorServerCount++;
        break;
      case AppErrorType.rateLimit:
        entity.errorRateLimitCount++;
        break;
      case AppErrorType.unknown:
        entity.errorUnknownCount++;
        break;
    }
  }

  Future<List<UsageStatsEntity>> loadAllUsageStats() async {
    return await _isar.usageStatsEntitys.where().findAll();
  }

  Future<List<DailyUsageStatsEntity>> loadDailyStats(int limit) async {
    return await _isar.dailyUsageStatsEntitys
        .where()
        .sortByDate() // Assuming you want oldest to newest? Or newest to oldest? Chart needs sorted by date.
        // Wait, Isar's sortByDate sorts ascending by default.
        // To get "last 30 days", we probably want to simpler just fetch all or filter > date.
        // For simplicity let's fetch all and filter in memory or Use filter.
        .findAll();
  }

  Future<void> clearUsageStats() async {
    await _isar.writeTxn(() async {
      await _isar.usageStatsEntitys.clear();
      await _isar.dailyUsageStatsEntitys.clear();
    });
  }

  /// Migrate existing usage stats to fix totalTokenCount inconsistency.
  /// This ensures totalTokenCount = promptTokenCount + completionTokenCount.
  Future<int> migrateTokenCounts() async {
    int migratedCount = 0;
    final allStats = await _isar.usageStatsEntitys.where().findAll();

    await _isar.writeTxn(() async {
      for (final stats in allStats) {
        final expectedTotal =
            stats.promptTokenCount + stats.completionTokenCount;
        if (stats.totalTokenCount != expectedTotal) {
          // If we have prompt+completion data, use that as the source of truth
          if (stats.promptTokenCount > 0 || stats.completionTokenCount > 0) {
            stats.totalTokenCount = expectedTotal;
          } else {
            // If we only have totalTokenCount, split it evenly
            stats.promptTokenCount = stats.totalTokenCount ~/ 2;
            stats.completionTokenCount =
                stats.totalTokenCount - stats.promptTokenCount;
          }
          await _isar.usageStatsEntitys.put(stats);
          migratedCount++;
        }
      }
    });

    return migratedCount;
  }

  Future<void> saveLastTopicId(String? topicId) async {
    await _updateExistingAppSettings((settings) {
      settings.lastTopicId = topicId;
    });
  }

  Future<void> saveChatPreset(ChatPresetEntity preset) async {
    await _isar.writeTxn(() async {
      await _isar.chatPresetEntitys.put(preset);
    });
  }

  Future<void> deleteChatPreset(String presetId) async {
    await _isar.writeTxn(() async {
      await _isar.chatPresetEntitys
          .filter()
          .presetIdEqualTo(presetId)
          .deleteAll();
    });
  }

  Future<List<ChatPresetEntity>> loadChatPresets() async {
    return await _isar.chatPresetEntitys.where().findAll();
  }

  Future<void> saveLastPresetId(String? presetId) async {
    await _updateExistingAppSettings((settings) {
      settings.lastPresetId = presetId;
    });
  }

  Future<void> saveAssistant(AssistantEntity assistant) async {
    await _isar.writeTxn(() async {
      await _isar.assistantEntitys.put(assistant);
    });
  }

  Future<void> deleteAssistant(String assistantId) async {
    await _isar.writeTxn(() async {
      await _isar.assistantEntitys
          .filter()
          .assistantIdEqualTo(assistantId)
          .deleteAll();
    });
  }

  Future<List<AssistantEntity>> loadAssistants() async {
    return await _isar.assistantEntitys.where().sortByUpdatedAtDesc().findAll();
  }

  Future<void> saveLastAssistantId(String? assistantId) async {
    await _updateExistingAppSettings((settings) {
      settings.lastAssistantId = assistantId;
    });
  }

  Future<void> _saveSingleAppSettings(AppSettingsEntity settings) async {
    await _isar.writeTxn(() async {
      await _isar.appSettingsEntitys.clear();
      await _isar.appSettingsEntitys.put(settings);
    });
  }

  AppSettingsEntity _copyAppSettingsEntity(AppSettingsEntity source) {
    return AppSettingsEntity()
      ..activeProviderId = source.activeProviderId
      ..selectedModel = source.selectedModel
      ..availableModels = List<String>.from(source.availableModels)
      ..userName = source.userName
      ..userAvatar = source.userAvatar
      ..llmName = source.llmName
      ..llmAvatar = source.llmAvatar
      ..themeMode = source.themeMode
      ..isStreamEnabled = source.isStreamEnabled
      ..isSearchEnabled = source.isSearchEnabled
      ..isKnowledgeEnabled = source.isKnowledgeEnabled
      ..searchEngine = source.searchEngine
      ..searchRegion = source.searchRegion
      ..searchSafeSearch = source.searchSafeSearch
      ..searchMaxResults = source.searchMaxResults
      ..searchTimeoutSeconds = source.searchTimeoutSeconds
      ..knowledgeTopK = source.knowledgeTopK
      ..knowledgeUseEmbedding = source.knowledgeUseEmbedding
      ..knowledgeLlmEnhanceMode = source.knowledgeLlmEnhanceMode
      ..knowledgeEmbeddingModel = source.knowledgeEmbeddingModel
      ..knowledgeEmbeddingProviderId = source.knowledgeEmbeddingProviderId
      ..activeKnowledgeBaseIds =
          List<String>.from(source.activeKnowledgeBaseIds)
      ..enableSmartTopic = source.enableSmartTopic
      ..topicGenerationModel = source.topicGenerationModel
      ..lastSessionId = source.lastSessionId
      ..lastTopicId = source.lastTopicId
      ..language = source.language
      ..lastPresetId = source.lastPresetId
      ..lastAssistantId = source.lastAssistantId
      ..themeColor = source.themeColor
      ..backgroundColor = source.backgroundColor
      ..closeBehavior = source.closeBehavior
      ..executionModel = source.executionModel
      ..executionProviderId = source.executionProviderId
      ..fontSize = source.fontSize
      ..backgroundImagePath = source.backgroundImagePath
      ..backgroundBrightness = source.backgroundBrightness
      ..backgroundBlur = source.backgroundBlur
      ..useCustomTheme = source.useCustomTheme;
  }

  Future<void> _updateExistingAppSettings(
      void Function(AppSettingsEntity settings) applyUpdate) async {
    final existing = await loadAppSettings();
    if (existing == null) return;
    final settings = _copyAppSettingsEntity(existing);
    applyUpdate(settings);
    await _saveSingleAppSettings(settings);
  }

  Future<void> _migrateFromExampleIfNeeded(Directory newDir) async {
    try {
      final List<Directory> potentialOldDirs = [];

      if (Platform.isWindows) {
        // Gen 1: com.example\Aurora
        // Gen 2: Aurora\Aurora
        final roamingDir = newDir.parent;
        potentialOldDirs.add(Directory(
            '${roamingDir.path}${Platform.pathSeparator}com.example${Platform.pathSeparator}Aurora'));
        potentialOldDirs
            .add(Directory('${newDir.path}${Platform.pathSeparator}Aurora'));
      } else if (Platform.isMacOS) {
        final supportDir = newDir.parent;
        potentialOldDirs.add(Directory(
            '${supportDir.path}${Platform.pathSeparator}com.aurora.aurora'));
      } else if (Platform.isLinux) {
        final shareDir = newDir.parent;
        potentialOldDirs.add(Directory(
            '${shareDir.path}${Platform.pathSeparator}com.aurora.aurora'));
      }

      for (var oldDir in potentialOldDirs) {
        if (!await oldDir.exists() || oldDir.path == newDir.path) continue;

        final oldIsar =
            File('${oldDir.path}${Platform.pathSeparator}default.isar');
        final newIsar =
            File('${newDir.path}${Platform.pathSeparator}default.isar');

        bool oldHasData = await oldIsar.exists() ||
            await File(
                    '${oldDir.path}${Platform.pathSeparator}session_order.json')
                .exists();
        bool newIsEmpty =
            !await newIsar.exists() || (await newIsar.length() <= 1048576);

        if (oldHasData && newIsEmpty) {
          debugPrint(
              'Aggressive Migration Triggered: Data found in ${oldDir.path}');

          if (!await newDir.exists()) {
            await newDir.create(recursive: true);
          }

          if (await newIsar.exists()) {
            await newIsar.rename('${newIsar.path}.bak');
          }

          await for (var entity in oldDir.list()) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            if (fileName == 'Aurora') continue;

            final newPath = '${newDir.path}${Platform.pathSeparator}$fileName';

            try {
              if (entity is File) {
                await entity.copy(newPath);
                await entity.delete();
              } else if (entity is Directory) {
                await _copyDirectory(entity, Directory(newPath));
                await entity.delete(recursive: true);
              }
            } catch (e) {
              debugPrint('Warning: Migration failed for $fileName: $e');
            }
          }
          debugPrint('Successfully migrated from ${oldDir.path}');
          break;
        }
      }
    } catch (e) {
      debugPrint('Critical error during aggressive migration: $e');
    }
  }

  Future<void> _fixLegacyPaths(String currentSupportPath) async {
    try {
      final existing = await loadAppSettings();
      if (existing == null) return;

      bool needsUpdate = false;
      String? path = existing.backgroundImagePath;

      if (path != null) {
        final bool isLegacyExample = path.contains('com.example');
        final bool isLegacyDoubleAurora = path.contains(
            '${Platform.pathSeparator}Aurora${Platform.pathSeparator}Aurora');

        if (isLegacyExample || isLegacyDoubleAurora) {
          if (path.contains('backgrounds')) {
            final fileName = path.split(Platform.pathSeparator).last;
            final newPath =
                '$currentSupportPath${Platform.pathSeparator}backgrounds${Platform.pathSeparator}$fileName';
            if (newPath != path) {
              path = newPath;
              needsUpdate = true;
            }
          }
        }
      }

      if (needsUpdate) {
        debugPrint('Repairing legacy path in DB: $path');
        await saveAppSettings(backgroundImagePath: path);
      }
    } catch (e) {
      debugPrint('Error fixing legacy paths: $e');
    }
  }
}
