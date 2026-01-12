import 'package:isar/isar.dart';
part 'topic_entity.g.dart';

@collection
class TopicEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String name;
  late DateTime createdAt;
}
