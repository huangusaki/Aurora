import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'provider_config_entity.dart';
import 'usage_stats_entity.dart';
import '../../chat/data/message_entity.dart';
import '../../chat/data/session_entity.dart';

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
    return await _isar.providerConfigEntitys.where().findAll();
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
    String? language,
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
      ..enableSmartTopic = enableSmartTopic ?? existing?.enableSmartTopic ?? true
      ..topicGenerationModel = topicGenerationModel ?? existing?.topicGenerationModel
      ..lastSessionId = lastSessionId ?? existing?.lastSessionId
      ..language = language ?? existing?.language ?? 'zh';
    
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
      ..language = existing.language;
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
      ..language = existing.language;
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
    } catch (e) {
      // ignore error
    }
    return [];
  }

  Future<void> saveSessionOrder(List<String> order) async {
    try {
      final file = await _orderFile;
      await file.writeAsString(jsonEncode(order));
    } catch (e) {
      // ignore error
    }
  }

  // Usage Stats Methods
  Future<void> incrementUsage(String modelName, {bool success = true, int durationMs = 0}) async {
    await _isar.writeTxn(() async {
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
          ..validDurationCount = durationMs > 0 ? 1 : 0;
      } else {
        if (success) {
          existing.successCount++;
        } else {
          existing.failureCount++;
        }
        // Only accumulate duration if it's a valid positive value
        if (durationMs > 0) {
          existing.totalDurationMs += durationMs;
          existing.validDurationCount++;
        }
      }
      await _isar.usageStatsEntitys.put(existing);
    });
  }

  Future<List<UsageStatsEntity>> loadAllUsageStats() async {
    return await _isar.usageStatsEntitys.where().findAll();
  }

  Future<void> clearUsageStats() async {
    await _isar.writeTxn(() async {
      await _isar.usageStatsEntitys.clear();
    });
  }
}
