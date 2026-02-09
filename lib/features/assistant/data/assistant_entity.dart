import 'package:isar/isar.dart';

part 'assistant_entity.g.dart';

@collection
class AssistantEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String assistantId;

  late String name;
  String? avatar;
  String? description;
  late String systemPrompt;

  String? preferredModel;
  String? providerId;
  List<String> skillIds = [];
  List<String> knowledgeBaseIds = [];
  bool enableMemory = false;
  String? memoryProviderId;
  String? memoryModel;

  @Index()
  DateTime? updatedAt;
}
