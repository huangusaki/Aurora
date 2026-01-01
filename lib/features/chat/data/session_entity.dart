import 'package:isar/isar.dart';

part 'session_entity.g.dart';

@collection
class SessionEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String sessionId;

  late String title;
  late DateTime lastMessageTime;
  
  // Preview of the last message
  String? snippet; 
}
