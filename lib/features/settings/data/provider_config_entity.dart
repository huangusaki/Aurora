import 'package:isar/isar.dart';
part 'provider_config_entity.g.dart';

@collection
class ProviderConfigEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String providerId;
  late String name;
  late String apiKey;
  late String baseUrl;
  bool isCustom = false;
  String? customParametersJson;
  String? modelSettingsJson;
  List<String> savedModels = [];
  String? lastSelectedModel;
  bool isActive = false;
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
}
