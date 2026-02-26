import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/agent_workflow/agent_workflow_models.dart';

class AgentWorkflowStorage {
  static const String fileName = 'agent_workflows.json';

  Future<File> _getFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, fileName));
  }

  Future<AgentWorkflowDocument> load() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return AgentWorkflowDocument(version: 1, templates: [
        AgentWorkflowTemplate.create(name: 'Default Workflow'),
      ]);
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Root is not an object');
      }
      final map = decoded.map((k, v) => MapEntry('$k', v));
      final doc = AgentWorkflowDocument.fromJson(map);
      final fixed = _fixupDocument(doc);
      return fixed.templates.isEmpty
          ? AgentWorkflowDocument(version: 1, templates: [
              AgentWorkflowTemplate.create(name: 'Default Workflow'),
            ])
          : fixed;
    } catch (_) {
      return AgentWorkflowDocument(version: 1, templates: [
        AgentWorkflowTemplate.create(name: 'Default Workflow'),
      ]);
    }
  }

  Future<void> save(AgentWorkflowDocument document) async {
    final file = await _getFile();
    final fixed = _fixupDocument(document);
    await file.writeAsString(jsonEncode(fixed.toJson()));
  }

  AgentWorkflowDocument _fixupDocument(AgentWorkflowDocument document) {
    final fixedTemplates = <AgentWorkflowTemplate>[];
    final idSet = <String>{};

    for (final template in document.templates) {
      final trimmedId = template.id.trim();
      final id = trimmedId.isEmpty ? const Uuid().v4() : trimmedId;
      if (!idSet.add(id)) {
        continue;
      }
      fixedTemplates.add(_fixupTemplate(template.copyWith(id: id)));
    }

    return document.copyWith(templates: fixedTemplates);
  }

  AgentWorkflowTemplate _fixupTemplate(AgentWorkflowTemplate template) {
    var name = template.name.trim();
    if (name.isEmpty) {
      name = 'Workflow';
    }

    final nodes = template.nodes.toList(growable: true);
    final edges = template.edges.toList(growable: true);

    AgentWorkflowNode? start =
        nodes.where((n) => n.type == AgentWorkflowNodeType.start).firstOrNull;
    AgentWorkflowNode? end =
        nodes.where((n) => n.type == AgentWorkflowNodeType.end).firstOrNull;

    // Remove extra Start/End nodes if any.
    final startNodes =
        nodes.where((n) => n.type == AgentWorkflowNodeType.start).toList();
    if (startNodes.length > 1) {
      final keep = startNodes.first.id;
      nodes.removeWhere(
          (n) => n.type == AgentWorkflowNodeType.start && n.id != keep);
      edges.removeWhere((e) =>
          e.fromNodeId != keep && startNodes.any((n) => n.id == e.fromNodeId));
      start = nodes.firstWhere((n) => n.id == keep);
    }

    final endNodes =
        nodes.where((n) => n.type == AgentWorkflowNodeType.end).toList();
    if (endNodes.length > 1) {
      final keep = endNodes.first.id;
      nodes.removeWhere((n) => n.type == AgentWorkflowNodeType.end && n.id != keep);
      edges.removeWhere(
          (e) => e.toNodeId != keep && endNodes.any((n) => n.id == e.toNodeId));
      end = nodes.firstWhere((n) => n.id == keep);
    }

    start ??= AgentWorkflowNode.createStart();
    end ??= AgentWorkflowNode.createEnd();

    // Ensure Start node shape.
    final startOutputs = start.outputs.toList(growable: true);
    AgentWorkflowPort? startPort = startOutputs
        .where((p) => p.name.trim() == 'start')
        .firstOrNull;
    if (startPort == null) {
      if (startOutputs.isNotEmpty) {
        startPort = startOutputs.first.copyWith(name: 'start');
      } else {
        startPort = AgentWorkflowPort(id: const Uuid().v4(), name: 'start');
      }
    }

    final fixedStart = start.copyWith(
      title: start.title.trim().isEmpty ? 'Start' : start.title,
      inputs: const [],
      outputs: [startPort],
    );

    // Ensure End node shape.
    final endInputs = end.inputs.toList(growable: true);
    AgentWorkflowPort? endPort =
        endInputs.where((p) => p.name.trim() == 'result').firstOrNull;
    if (endPort == null) {
      if (endInputs.isNotEmpty) {
        endPort = endInputs.first.copyWith(name: 'result');
      } else {
        endPort = AgentWorkflowPort(id: const Uuid().v4(), name: 'result');
      }
    }

    final fixedEnd = end.copyWith(
      title: end.title.trim().isEmpty ? 'End' : end.title,
      inputs: [endPort],
      outputs: const [],
    );

    // Replace nodes list with fixed start/end in-place if they existed.
    nodes.removeWhere(
        (n) => n.id == fixedStart.id || n.id == fixedEnd.id);
    nodes.insert(0, fixedStart);
    nodes.add(fixedEnd);

    // Fix empty titles/port names in other nodes.
    final fixedNodes = nodes.map((n) {
      if (n.type == AgentWorkflowNodeType.start || n.type == AgentWorkflowNodeType.end) {
        return n;
      }
      final title = n.title.trim().isEmpty ? n.type.name.toUpperCase() : n.title;
      final inputs = n.inputs.asMap().entries.map((entry) {
        final idx = entry.key;
        final p = entry.value;
        final name = p.name.trim().isEmpty ? 'in${idx + 1}' : p.name;
        return p.copyWith(name: name);
      }).toList(growable: false);
      final outputs = n.outputs.asMap().entries.map((entry) {
        final idx = entry.key;
        final p = entry.value;
        final name = p.name.trim().isEmpty ? 'out${idx + 1}' : p.name;
        return p.copyWith(name: name);
      }).toList(growable: false);
      return n.copyWith(title: title, inputs: inputs, outputs: outputs);
    }).toList(growable: false);

    // Drop edges that reference missing nodes/ports.
    final nodeById = {for (final n in fixedNodes) n.id: n};
    final validEdges = edges.where((e) {
      final fromNode = nodeById[e.fromNodeId];
      final toNode = nodeById[e.toNodeId];
      if (fromNode == null || toNode == null) return false;
      if (!fromNode.outputs.any((p) => p.id == e.fromPortId)) return false;
      if (!toNode.inputs.any((p) => p.id == e.toPortId)) return false;
      if (fromNode.type == AgentWorkflowNodeType.end) return false;
      if (toNode.type == AgentWorkflowNodeType.start) return false;
      return true;
    }).toList(growable: false);

    return template.copyWith(
      name: name,
      nodes: fixedNodes,
      edges: validEdges,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

