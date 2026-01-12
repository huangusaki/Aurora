import 'package:uuid/uuid.dart';

class ChatPreset {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  const ChatPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
  });
  factory ChatPreset.create({
    required String name,
    required String description,
    required String systemPrompt,
  }) {
    return ChatPreset(
      id: const Uuid().v4(),
      name: name,
      description: description,
      systemPrompt: systemPrompt,
    );
  }
  ChatPreset copyWith({
    String? name,
    String? description,
    String? systemPrompt,
  }) {
    return ChatPreset(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }
}
