import 'dart:convert';

class AgentWorkflowValue {
  final String text;
  final Object? json;
  final String? raw;

  const AgentWorkflowValue._({
    required this.text,
    this.json,
    this.raw,
  });

  factory AgentWorkflowValue.fromText(
    String text, {
    String? raw,
  }) {
    return AgentWorkflowValue._(text: text, raw: raw);
  }

  factory AgentWorkflowValue.fromJson(
    Object json, {
    String? raw,
  }) {
    return AgentWorkflowValue._(
      text: jsonEncode(json),
      json: json,
      raw: raw,
    );
  }

  factory AgentWorkflowValue.error(String message) {
    return AgentWorkflowValue._(text: message);
  }
}

