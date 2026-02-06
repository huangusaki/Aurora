import 'package:isar/isar.dart';
part 'session_entity.g.dart';

@collection
class SessionEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String sessionId;
  late String title;
  late DateTime lastMessageTime;
  String? snippet;
  int? topicId;
  String? presetId;
  int totalTokens = 0;
}
