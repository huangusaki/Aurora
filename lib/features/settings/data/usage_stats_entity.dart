import 'package:isar/isar.dart';
part 'usage_stats_entity.g.dart';

@collection
class UsageStatsEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String modelName;
  int successCount = 0;
  int failureCount = 0;
  int totalDurationMs = 0;
  int validDurationCount = 0;
  int totalFirstTokenMs = 0;
  int validFirstTokenCount = 0;
  int totalTokenCount = 0;
  int promptTokenCount = 0;
  int completionTokenCount = 0;
  int reasoningTokenCount = 0;

  // Error Classification Counts
  int errorTimeoutCount = 0;
  int errorNetworkCount = 0;
  int errorBadRequestCount = 0;
  int errorUnauthorizedCount = 0;
  int errorServerCount = 0;
  int errorRateLimitCount = 0;
  int errorUnknownCount = 0;
}
