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
  
  String? customParametersJson; // JSON string for generic parameters
  String? modelSettingsJson; // JSON string for per-model parameters
  
  List<String> savedModels = [];
  String? lastSelectedModel;

  bool isActive = false; // To track which one is active if we store it here, or store separate settings.
}

@collection
class AppSettingsEntity {
  Id id = Isar.autoIncrement;
  
  late String activeProviderId;
  String? selectedModel;
  List<String> availableModels = [];
  
  // Chat display settings
  String userName = 'User';
  String? userAvatar;
  String llmName = 'Assistant';
  String? llmAvatar;
  
  String themeMode = 'system'; // system, light, dark
}
