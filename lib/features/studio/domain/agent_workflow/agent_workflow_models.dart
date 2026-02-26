import 'dart:convert';

import 'package:uuid/uuid.dart';

enum AgentWorkflowNodeType {
  start,
  end,
  llm,
  skill,
  mcp;

  static AgentWorkflowNodeType? tryParse(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase();
    for (final value in AgentWorkflowNodeType.values) {
      if (value.name == normalized) return value;
    }
    return null;
  }
}

class AgentWorkflowModelRef {
  final String providerId;
  final String modelId;

  const AgentWorkflowModelRef({
    required this.providerId,
    required this.modelId,
  });

  AgentWorkflowModelRef copyWith({
    String? providerId,
    String? modelId,
  }) {
    return AgentWorkflowModelRef(
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
    );
  }

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'modelId': modelId,
      };

  factory AgentWorkflowModelRef.fromJson(Map<String, dynamic> json) {
    return AgentWorkflowModelRef(
      providerId: (json['providerId'] as String?) ?? '',
      modelId: (json['modelId'] as String?) ?? '',
    );
  }

  bool get isValid => providerId.trim().isNotEmpty && modelId.trim().isNotEmpty;
}

class AgentWorkflowPort {
  final String id;
  final String name;

  const AgentWorkflowPort({
    required this.id,
    required this.name,
  });

  AgentWorkflowPort copyWith({
    String? id,
    String? name,
  }) {
    return AgentWorkflowPort(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory AgentWorkflowPort.fromJson(Map<String, dynamic> json) {
    return AgentWorkflowPort(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      name: (json['name'] as String?) ?? '',
    );
  }
}

class AgentWorkflowNode {
  final String id;
  final AgentWorkflowNodeType type;
  final String title;
  final double x;
  final double y;
  final List<AgentWorkflowPort> inputs;
  final List<AgentWorkflowPort> outputs;

  /// Optional per-node model override. When null, the app's current model route is used.
  final AgentWorkflowModelRef? model;

  /// Optional system prompt for LLM nodes.
  final String systemPrompt;

  /// Node body template:
  /// - LLM: prompt template
  /// - Skill: skill query template
  /// - MCP: args JSON template
  final String bodyTemplate;

  /// Skill node config.
  final String? skillId;

  /// MCP node config.
  final String? mcpServerId;
  final String? mcpToolName;

  const AgentWorkflowNode({
    required this.id,
    required this.type,
    required this.title,
    required this.x,
    required this.y,
    this.inputs = const [],
    this.outputs = const [],
    this.model,
    this.systemPrompt = '',
    this.bodyTemplate = '',
    this.skillId,
    this.mcpServerId,
    this.mcpToolName,
  });

  bool get isFixed =>
      type == AgentWorkflowNodeType.start || type == AgentWorkflowNodeType.end;

  AgentWorkflowNode copyWith({
    String? id,
    AgentWorkflowNodeType? type,
    String? title,
    double? x,
    double? y,
    List<AgentWorkflowPort>? inputs,
    List<AgentWorkflowPort>? outputs,
    Object? model = _sentinel,
    String? systemPrompt,
    String? bodyTemplate,
    Object? skillId = _sentinel,
    Object? mcpServerId = _sentinel,
    Object? mcpToolName = _sentinel,
  }) {
    return AgentWorkflowNode(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      x: x ?? this.x,
      y: y ?? this.y,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      model: model == _sentinel ? this.model : model as AgentWorkflowModelRef?,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      skillId: skillId == _sentinel ? this.skillId : skillId as String?,
      mcpServerId:
          mcpServerId == _sentinel ? this.mcpServerId : mcpServerId as String?,
      mcpToolName:
          mcpToolName == _sentinel ? this.mcpToolName : mcpToolName as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'x': x,
        'y': y,
        'inputs': inputs.map((p) => p.toJson()).toList(growable: false),
        'outputs': outputs.map((p) => p.toJson()).toList(growable: false),
        'model': model?.toJson(),
        'systemPrompt': systemPrompt,
        'bodyTemplate': bodyTemplate,
        'skillId': skillId,
        'mcpServerId': mcpServerId,
        'mcpToolName': mcpToolName,
      };

  factory AgentWorkflowNode.fromJson(Map<String, dynamic> json) {
    final type = AgentWorkflowNodeType.tryParse(json['type']?.toString()) ??
        AgentWorkflowNodeType.llm;
    final modelRaw = json['model'];
    AgentWorkflowModelRef? model;
    if (modelRaw is Map) {
      model = AgentWorkflowModelRef.fromJson(
        modelRaw.map((k, v) => MapEntry('$k', v)),
      );
      if (!model.isValid) {
        model = null;
      }
    }

    final inputsRaw = json['inputs'];
    final outputsRaw = json['outputs'];
    return AgentWorkflowNode(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      type: type,
      title: (json['title'] as String?) ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      inputs: (inputsRaw is List)
          ? inputsRaw
              .whereType<Map>()
              .map((e) => AgentWorkflowPort.fromJson(
                  e.map((k, v) => MapEntry('$k', v))))
              .toList(growable: false)
          : const [],
      outputs: (outputsRaw is List)
          ? outputsRaw
              .whereType<Map>()
              .map((e) => AgentWorkflowPort.fromJson(
                  e.map((k, v) => MapEntry('$k', v))))
              .toList(growable: false)
          : const [],
      model: model,
      systemPrompt: (json['systemPrompt'] as String?) ?? '',
      bodyTemplate: (json['bodyTemplate'] as String?) ?? '',
      skillId: json['skillId'] as String?,
      mcpServerId: json['mcpServerId'] as String?,
      mcpToolName: json['mcpToolName'] as String?,
    );
  }

  static AgentWorkflowNode createStart({
    String? id,
    double x = 80,
    double y = 120,
  }) {
    return AgentWorkflowNode(
      id: id ?? const Uuid().v4(),
      type: AgentWorkflowNodeType.start,
      title: 'Start',
      x: x,
      y: y,
      inputs: const [],
      outputs: [
        AgentWorkflowPort(id: const Uuid().v4(), name: 'start'),
      ],
    );
  }

  static AgentWorkflowNode createEnd({
    String? id,
    double x = 720,
    double y = 120,
  }) {
    return AgentWorkflowNode(
      id: id ?? const Uuid().v4(),
      type: AgentWorkflowNodeType.end,
      title: 'End',
      x: x,
      y: y,
      inputs: [
        AgentWorkflowPort(id: const Uuid().v4(), name: 'result'),
      ],
      outputs: const [],
    );
  }

  static AgentWorkflowNode createLlm({
    String? id,
    String title = 'LLM',
    double x = 320,
    double y = 220,
  }) {
    return AgentWorkflowNode(
      id: id ?? const Uuid().v4(),
      type: AgentWorkflowNodeType.llm,
      title: title,
      x: x,
      y: y,
      inputs: [
        AgentWorkflowPort(id: const Uuid().v4(), name: 'input'),
      ],
      outputs: [
        AgentWorkflowPort(id: const Uuid().v4(), name: 'result'),
      ],
      systemPrompt: '',
      bodyTemplate: '{{$defaultInputName}}',
    );
  }

  static AgentWorkflowNode createSkill({
    String? id,
    String title = 'Skill',
    double x = 320,
    double y = 220,
  }) {
    return AgentWorkflowNode(
      id: id ?? const Uuid().v4(),
      type: AgentWorkflowNodeType.skill,
      title: title,
      x: x,
      y: y,
      inputs: [
        AgentWorkflowPort(id: const Uuid().v4(), name: 'input'),
      ],
      outputs: [
        AgentWorkflowPort(id: const Uuid().v4(), name: 'result'),
      ],
      bodyTemplate: '{{$defaultInputName}}',
      skillId: null,
    );
  }

  static AgentWorkflowNode createMcp({
    String? id,
    String title = 'MCP',
    double x = 320,
    double y = 220,
  }) {
    return AgentWorkflowNode(
      id: id ?? const Uuid().v4(),
      type: AgentWorkflowNodeType.mcp,
      title: title,
      x: x,
      y: y,
      inputs: [
        AgentWorkflowPort(id: const Uuid().v4(), name: 'input'),
      ],
      outputs: [
        AgentWorkflowPort(id: const Uuid().v4(), name: 'result'),
      ],
      bodyTemplate: '{"input":"{{$defaultInputName}}"}',
      mcpServerId: null,
      mcpToolName: null,
    );
  }

  static const String defaultInputName = 'input';
}

class AgentWorkflowEdge {
  final String id;
  final String fromNodeId;
  final String fromPortId;
  final String toNodeId;
  final String toPortId;

  const AgentWorkflowEdge({
    required this.id,
    required this.fromNodeId,
    required this.fromPortId,
    required this.toNodeId,
    required this.toPortId,
  });

  AgentWorkflowEdge copyWith({
    String? id,
    String? fromNodeId,
    String? fromPortId,
    String? toNodeId,
    String? toPortId,
  }) {
    return AgentWorkflowEdge(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      fromPortId: fromPortId ?? this.fromPortId,
      toNodeId: toNodeId ?? this.toNodeId,
      toPortId: toPortId ?? this.toPortId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromNodeId': fromNodeId,
        'fromPortId': fromPortId,
        'toNodeId': toNodeId,
        'toPortId': toPortId,
      };

  factory AgentWorkflowEdge.fromJson(Map<String, dynamic> json) {
    return AgentWorkflowEdge(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      fromNodeId: (json['fromNodeId'] as String?) ?? '',
      fromPortId: (json['fromPortId'] as String?) ?? '',
      toNodeId: (json['toNodeId'] as String?) ?? '',
      toPortId: (json['toPortId'] as String?) ?? '',
    );
  }
}

class AgentWorkflowTemplate {
  final String id;
  final String name;
  final List<AgentWorkflowNode> nodes;
  final List<AgentWorkflowEdge> edges;

  const AgentWorkflowTemplate({
    required this.id,
    required this.name,
    this.nodes = const [],
    this.edges = const [],
  });

  AgentWorkflowTemplate copyWith({
    String? id,
    String? name,
    List<AgentWorkflowNode>? nodes,
    List<AgentWorkflowEdge>? edges,
  }) {
    return AgentWorkflowTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  AgentWorkflowNode? get startNode =>
      nodes.where((n) => n.type == AgentWorkflowNodeType.start).firstOrNull;

  AgentWorkflowNode? get endNode =>
      nodes.where((n) => n.type == AgentWorkflowNodeType.end).firstOrNull;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nodes': nodes.map((n) => n.toJson()).toList(growable: false),
        'edges': edges.map((e) => e.toJson()).toList(growable: false),
      };

  factory AgentWorkflowTemplate.fromJson(Map<String, dynamic> json) {
    final nodesRaw = json['nodes'];
    final edgesRaw = json['edges'];
    return AgentWorkflowTemplate(
      id: (json['id'] as String?) ?? const Uuid().v4(),
      name: (json['name'] as String?) ?? '',
      nodes: (nodesRaw is List)
          ? nodesRaw
              .whereType<Map>()
              .map((e) => AgentWorkflowNode.fromJson(
                  e.map((k, v) => MapEntry('$k', v))))
              .toList(growable: false)
          : const [],
      edges: (edgesRaw is List)
          ? edgesRaw
              .whereType<Map>()
              .map((e) => AgentWorkflowEdge.fromJson(
                  e.map((k, v) => MapEntry('$k', v))))
              .toList(growable: false)
          : const [],
    );
  }

  static AgentWorkflowTemplate create({
    required String name,
  }) {
    final templateId = const Uuid().v4();
    final start = AgentWorkflowNode.createStart(x: 80, y: 160);
    final end = AgentWorkflowNode.createEnd(x: 720, y: 160);
    return AgentWorkflowTemplate(
      id: templateId,
      name: name,
      nodes: [start, end],
      edges: const [],
    );
  }
}

class AgentWorkflowDocument {
  final int version;
  final List<AgentWorkflowTemplate> templates;

  const AgentWorkflowDocument({
    required this.version,
    this.templates = const [],
  });

  AgentWorkflowDocument copyWith({
    int? version,
    List<AgentWorkflowTemplate>? templates,
  }) {
    return AgentWorkflowDocument(
      version: version ?? this.version,
      templates: templates ?? this.templates,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'templates': templates.map((t) => t.toJson()).toList(growable: false),
      };

  factory AgentWorkflowDocument.fromJson(Map<String, dynamic> json) {
    final templatesRaw = json['templates'];
    return AgentWorkflowDocument(
      version: (json['version'] as int?) ?? 1,
      templates: (templatesRaw is List)
          ? templatesRaw
              .whereType<Map>()
              .map((e) => AgentWorkflowTemplate.fromJson(
                  e.map((k, v) => MapEntry('$k', v))))
              .toList(growable: false)
          : const [],
    );
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

const Object _sentinel = Object();
