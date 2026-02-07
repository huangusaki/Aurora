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
  bool isKnowledgeEnabled = false;
  String searchEngine = 'duckduckgo';
  String searchRegion = 'us-en';
  String searchSafeSearch = 'moderate';
  int searchMaxResults = 5;
  int searchTimeoutSeconds = 15;
  int knowledgeTopK = 5;
  bool knowledgeUseEmbedding = false;
  String knowledgeLlmEnhanceMode = 'off';
  String? knowledgeEmbeddingModel;
  String? knowledgeEmbeddingProviderId;
  List<String> activeKnowledgeBaseIds = [];
  bool enableSmartTopic = true;
  String? topicGenerationModel;
  String? lastSessionId;
  String? lastTopicId;
  String language = 'zh';
  String? lastPresetId;
  String? lastAssistantId;
  String? themeColor;
  String? backgroundColor;
  @Index()
  int closeBehavior = 0; // 0: ask, 1: minimize, 2: exit
  String? executionModel;
  String? executionProviderId;
  double fontSize = 14.0;
  String? backgroundImagePath;
  double backgroundBrightness = 0.5;
  double backgroundBlur = 0.0;
  bool useCustomTheme = false;
}
