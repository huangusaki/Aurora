import 'package:isar/isar.dart';
part 'provider_config_entity.g.dart';

@collection
class ProviderConfigEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String providerId;
  late String name;
  String? color;
  @Deprecated('Use apiKeys instead. Kept for migration.')
  String apiKey = '';
  List<String> apiKeys = [];
  int currentKeyIndex = 0;
  bool autoRotateKeys = false;
  late String baseUrl;
  bool isCustom = false;
  String? customParametersJson;
  String? modelSettingsJson;
  String? globalSettingsJson;
  List<String> globalExcludeModels = [];
  List<String> savedModels = [];
  String? lastSelectedModel;
  bool isActive = false;
  bool isEnabled = true;
}

@collection
class AppSettingsEntity {
  Id id = Isar.autoIncrement;
  late String activeProviderId;
  String? selectedModel;
  List<String> availableModels = [];
  String userName = 'User';
  String? userAvatar;
  String llmName = 'Assistant';
  String? llmAvatar;
  String themeMode = 'system';
  bool isStreamEnabled = true;
  bool isSearchEnabled = false;
  String searchEngine = 'duckduckgo';
  bool enableSmartTopic = true;
  String? topicGenerationModel;
  String? lastSessionId;
  String? lastTopicId;
  String language = 'zh';
  String? lastPresetId;
  String? themeColor;
  String? backgroundColor;
  @Index()
  int closeBehavior = 0; // 0: ask, 1: minimize, 2: exit
  String? executionModel;
}
