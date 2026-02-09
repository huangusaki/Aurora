import 'package:isar/isar.dart';

part 'assistant_memory_state_entity.g.dart';

@collection
class AssistantMemoryStateEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String assistantId;

  int consolidatedUntilMessageId = 0;
  DateTime? lastSuccessfulRunAt;
  DateTime? lastObservedMessageAt;
  int runsToday = 0;
  String? runsDayKey;
}
