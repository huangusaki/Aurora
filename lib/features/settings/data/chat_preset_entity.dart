import 'package:isar/isar.dart';
part 'chat_preset_entity.g.dart';

@collection
class ChatPresetEntity {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  late String presetId;
  late String name;
  String? description;
  late String systemPrompt;
}
