import 'dart:convert';

import 'package:json_schema/json_schema.dart';

class AgentWorkflowJsonSchema {
  AgentWorkflowJsonSchema._();

  static final Map<String, JsonSchema> _compiled = <String, JsonSchema>{};

  static List<String> validateInstance({
    required Map<String, dynamic> schema,
    required Object? instance,
  }) {
    final key = const JsonEncoder().convert(schema);
    final compiled = _compiled[key] ??=
        JsonSchema.create(schema, schemaVersion: SchemaVersion.draft7);

    final result = compiled.validate(instance);
    if (result.isValid) return const [];
    return result.errors.map((e) => e.toString()).toList(growable: false);
  }
}

