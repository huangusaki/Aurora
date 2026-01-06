import 'package:isar/isar.dart';
part 'usage_stats_entity.g.dart';

@collection
class UsageStatsEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String modelName;
  int successCount = 0;
  int failureCount = 0;
}
