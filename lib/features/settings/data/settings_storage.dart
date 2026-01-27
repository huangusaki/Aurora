import 'dart:convert';
import 'dart:io';

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

class SettingsStorage {
  late Isar _isar;
  Isar get isar => _isar;
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
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
      ],
      directory: dir.path,
    );
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
    required String activeProviderId,
    String? selectedModel,
    List<String>? availableModels,
    String? userName,
    String? userAvatar,
    String? llmName,
    String? llmAvatar,
    String? themeMode,
    bool? isStreamEnabled,
    bool? isSearchEnabled,
    String? searchEngine,
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
  }) async {
    final existing = await loadAppSettings();
    final settings = AppSettingsEntity()
      ..activeProviderId = activeProviderId
      ..selectedModel = selectedModel ?? existing?.selectedModel
      ..availableModels = availableModels ?? existing?.availableModels ?? []
      ..userName = userName ?? existing?.userName ?? 'User'
      ..userAvatar = userAvatar ?? existing?.userAvatar
      ..llmName = llmName ?? existing?.llmName ?? 'Assistant'
      ..llmAvatar = llmAvatar ?? existing?.llmAvatar
      ..themeMode = themeMode ?? existing?.themeMode ?? 'system'
      ..isStreamEnabled = isStreamEnabled ?? existing?.isStreamEnabled ?? true
      ..isSearchEnabled = isSearchEnabled ?? existing?.isSearchEnabled ?? false
      ..searchEngine = searchEngine ?? existing?.searchEngine ?? 'duckduckgo'
      ..enableSmartTopic =
          enableSmartTopic ?? existing?.enableSmartTopic ?? true
      ..topicGenerationModel =
          topicGenerationModel ?? existing?.topicGenerationModel
      ..lastSessionId = lastSessionId ?? existing?.lastSessionId
      ..lastTopicId = lastTopicId ?? existing?.lastTopicId
      ..language = language ?? existing?.language ?? 'zh'
      ..lastPresetId = existing?.lastPresetId
      ..themeColor = themeColor ?? existing?.themeColor
      ..backgroundColor = backgroundColor ?? existing?.backgroundColor
      ..closeBehavior = closeBehavior ?? existing?.closeBehavior ?? 0
      ..executionModel = executionModel ?? existing?.executionModel
      ..executionProviderId = executionProviderId ?? existing?.executionProviderId;
    await _isar.writeTxn(() async {
      await _isar.appSettingsEntitys.clear();
      await _isar.appSettingsEntitys.put(settings);
    });
  }

  Future<void> saveLastSessionId(String sessionId) async {
    final existing = await loadAppSettings();
    if (existing == null) return;
    final settings = AppSettingsEntity()
      ..activeProviderId = existing.activeProviderId
      ..selectedModel = existing.selectedModel
      ..availableModels = existing.availableModels
      ..userName = existing.userName
      ..userAvatar = existing.userAvatar
      ..llmName = existing.llmName
      ..llmAvatar = existing.llmAvatar
      ..themeMode = existing.themeMode
      ..isStreamEnabled = existing.isStreamEnabled
      ..isSearchEnabled = existing.isSearchEnabled
      ..searchEngine = existing.searchEngine
      ..enableSmartTopic = existing.enableSmartTopic
      ..topicGenerationModel = existing.topicGenerationModel
      ..lastSessionId = sessionId
      ..lastTopicId = existing.lastTopicId
      ..language = existing.language
      ..lastPresetId = existing.lastPresetId
      ..themeColor = existing.themeColor
      ..backgroundColor = existing.backgroundColor
      ..closeBehavior = existing.closeBehavior
      ..executionModel = existing.executionModel
      ..executionProviderId = existing.executionProviderId;
    await _isar.writeTxn(() async {
      await _isar.appSettingsEntitys.clear();
      await _isar.appSettingsEntitys.put(settings);
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
    final existing = await loadAppSettings();
    if (existing == null) return;
    final settings = AppSettingsEntity()
      ..activeProviderId = existing.activeProviderId
      ..selectedModel = existing.selectedModel
      ..availableModels = existing.availableModels
      ..userName = userName ?? existing.userName
      ..userAvatar = userAvatar ?? existing.userAvatar
      ..llmName = llmName ?? existing.llmName
      ..llmAvatar = llmAvatar ?? existing.llmAvatar
      ..themeMode = existing.themeMode
      ..isStreamEnabled = existing.isStreamEnabled
      ..isSearchEnabled = existing.isSearchEnabled
      ..searchEngine = existing.searchEngine
      ..enableSmartTopic = existing.enableSmartTopic
      ..topicGenerationModel = existing.topicGenerationModel
      ..lastTopicId = existing.lastTopicId
      ..language = existing.language
      ..lastPresetId = existing.lastPresetId
      ..themeColor = existing.themeColor
      ..backgroundColor = existing.backgroundColor
      ..closeBehavior = existing.closeBehavior
      ..executionModel = existing.executionModel
      ..executionProviderId = existing.executionProviderId;
    await _isar.writeTxn(() async {
      await _isar.appSettingsEntitys.clear();
      await _isar.appSettingsEntitys.put(settings);
    });
  }

  Future<File> get _orderFile async {
    final dir = await getApplicationDocumentsDirectory();
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
    } catch (e) {}
    return [];
  }

  Future<void> saveSessionOrder(List<String> order) async {
    try {
      final file = await _orderFile;
      await file.writeAsString(jsonEncode(order));
    } catch (e) {}
  }

  Future<File> get _providerOrderFile async {
    final dir = await getApplicationDocumentsDirectory();
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
    } catch (e) {}
    return [];
  }

  Future<void> saveProviderOrder(List<String> order) async {
    try {
      final file = await _providerOrderFile;
      await file.writeAsString(jsonEncode(order));
    } catch (e) {}
  }

  Future<void> incrementUsage(String modelName,
      {bool success = true,
      int durationMs = 0,
      int firstTokenMs = 0,
      int tokenCount = 0, // Kept for backward compatibility logic, usually sum of prompt+completion
      int promptTokens = 0,
      int completionTokens = 0,
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
          ..promptTokenCount = promptTokens > 0 ? promptTokens : (tokenCount ~/ 2)
          ..completionTokenCount = completionTokens > 0 ? completionTokens : (tokenCount - tokenCount ~/ 2)
          ..totalTokenCount = (promptTokens > 0 ? promptTokens : (tokenCount ~/ 2)) + (completionTokens > 0 ? completionTokens : (tokenCount - tokenCount ~/ 2));
        
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
        
        // Always use prompt + completion for consistency
        // If only tokenCount is provided (legacy), split evenly as approximation
        final effectivePrompt = promptTokens > 0 ? promptTokens : (tokenCount ~/ 2);
        final effectiveCompletion = completionTokens > 0 ? completionTokens : (tokenCount - tokenCount ~/ 2);
        existing.promptTokenCount += effectivePrompt;
        existing.completionTokenCount += effectiveCompletion;
        existing.totalTokenCount = existing.promptTokenCount + existing.completionTokenCount;
      }
      await _isar.usageStatsEntitys.put(existing);

      // 2. Update daily stats
      var daily = await _isar.dailyUsageStatsEntitys
          .filter()
          .dateEqualTo(today)
          .findFirst();
      
      final effectiveTotalForDaily = tokenCount > 0 ? tokenCount : (promptTokens + completionTokens);

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
        final expectedTotal = stats.promptTokenCount + stats.completionTokenCount;
        if (stats.totalTokenCount != expectedTotal) {
          // If we have prompt+completion data, use that as the source of truth
          if (stats.promptTokenCount > 0 || stats.completionTokenCount > 0) {
            stats.totalTokenCount = expectedTotal;
          } else {
            // If we only have totalTokenCount, split it evenly
            stats.promptTokenCount = stats.totalTokenCount ~/ 2;
            stats.completionTokenCount = stats.totalTokenCount - stats.promptTokenCount;
          }
          await _isar.usageStatsEntitys.put(stats);
          migratedCount++;
        }
      }
    });
    
    return migratedCount;
  }

  Future<void> saveLastTopicId(String? topicId) async {
    final existing = await loadAppSettings();
    if (existing == null) return;
    final settings = AppSettingsEntity()
      ..activeProviderId = existing.activeProviderId
      ..selectedModel = existing.selectedModel
      ..availableModels = existing.availableModels
      ..userName = existing.userName
      ..userAvatar = existing.userAvatar
      ..llmName = existing.llmName
      ..llmAvatar = existing.llmAvatar
      ..themeMode = existing.themeMode
      ..isStreamEnabled = existing.isStreamEnabled
      ..isSearchEnabled = existing.isSearchEnabled
      ..searchEngine = existing.searchEngine
      ..enableSmartTopic = existing.enableSmartTopic
      ..topicGenerationModel = existing.topicGenerationModel
      ..lastTopicId = topicId
      ..language = existing.language
      ..lastPresetId = existing.lastPresetId
      ..themeColor = existing.themeColor
      ..backgroundColor = existing.backgroundColor
      ..closeBehavior = existing.closeBehavior
      ..executionModel = existing.executionModel
      ..executionProviderId = existing.executionProviderId;
    await _isar.writeTxn(() async {
      await _isar.appSettingsEntitys.clear();
      await _isar.appSettingsEntitys.put(settings);
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
    final existing = await loadAppSettings();
    if (existing == null) return;
    final settings = AppSettingsEntity()
      ..activeProviderId = existing.activeProviderId
      ..selectedModel = existing.selectedModel
      ..availableModels = existing.availableModels
      ..userName = existing.userName
      ..userAvatar = existing.userAvatar
      ..llmName = existing.llmName
      ..llmAvatar = existing.llmAvatar
      ..themeMode = existing.themeMode
      ..isStreamEnabled = existing.isStreamEnabled
      ..isSearchEnabled = existing.isSearchEnabled
      ..searchEngine = existing.searchEngine
      ..enableSmartTopic = existing.enableSmartTopic
      ..topicGenerationModel = existing.topicGenerationModel
      ..lastSessionId = existing.lastSessionId
      ..lastTopicId = existing.lastTopicId
      ..language = existing.language
      ..lastPresetId = presetId
      ..themeColor = existing.themeColor
      ..backgroundColor = existing.backgroundColor
      ..closeBehavior = existing.closeBehavior
      ..executionModel = existing.executionModel
      ..executionProviderId = existing.executionProviderId;
    await _isar.writeTxn(() async {
      await _isar.appSettingsEntitys.clear();
      await _isar.appSettingsEntitys.put(settings);
    });
  }
}
