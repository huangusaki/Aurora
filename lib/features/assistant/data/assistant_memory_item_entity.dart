import 'package:isar/isar.dart';

part 'assistant_memory_item_entity.g.dart';

@collection
class AssistantMemoryItemEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String memoryId;

  @Index()
  late String assistantId;

  @Index()
  late String key;

  late String valueJson;

  double confidence = 0.0;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? lastSeenAt;
  List<int> evidenceMessageIds = [];
  bool isActive = true;
}
