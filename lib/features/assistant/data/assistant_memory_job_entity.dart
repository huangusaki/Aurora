import 'package:isar/isar.dart';

part 'assistant_memory_job_entity.g.dart';

@collection
class AssistantMemoryJobEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String jobId;

  @Index()
  late String assistantId;

  int startMessageId = 0;
  int endMessageId = 0;
  String status = 'pending';
  int attemptCount = 0;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? nextRetryAt;
  DateTime? lockedUntil;
  String? lastError;
}
