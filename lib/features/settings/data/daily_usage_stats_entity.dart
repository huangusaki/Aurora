import 'package:isar/isar.dart';

part 'daily_usage_stats_entity.g.dart';

@collection
class DailyUsageStatsEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date; // Store as 00:00:00 of the day

  int totalCalls = 0;
  int successCount = 0;
  int failureCount = 0;
  int tokenCount = 0;
}
