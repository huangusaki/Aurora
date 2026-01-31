import 'package:isar/isar.dart';
part 'message_entity.g.dart';

@collection
class MessageEntity {
  Id id = Isar.autoIncrement;
  @Index()
  late DateTime timestamp;
  late bool isUser;
  late String content;
  String? reasoningContent;
  List<String> attachments = [];
  List<String> images = [];
  @Index()
  String? sessionId;
  String? model;
  String? provider;
  double? reasoningDurationSeconds;
  String? role;
  String? toolCallId;
  String? toolCallsJson;
  int? tokenCount;
  int? promptTokens;
  int? completionTokens;
  int? reasoningTokens;
  int? firstTokenMs;
  int? durationMs;
}
