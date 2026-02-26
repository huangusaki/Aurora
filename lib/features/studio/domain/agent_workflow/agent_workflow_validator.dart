import 'agent_workflow_models.dart';

class AgentWorkflowValidationError {
  final String message;

  const AgentWorkflowValidationError(this.message);

  @override
  String toString() => message;
}

class AgentWorkflowValidationResult {
  final List<AgentWorkflowValidationError> errors;

  const AgentWorkflowValidationResult(this.errors);

  bool get isValid => errors.isEmpty;

  String toMultilineString() => errors.map((e) => '- ${e.message}').join('\n');
}

class AgentWorkflowValidator {
  const AgentWorkflowValidator();

  AgentWorkflowValidationResult validate(AgentWorkflowTemplate template) {
    final errors = <AgentWorkflowValidationError>[];

    final startNodes =
        template.nodes.where((n) => n.type == AgentWorkflowNodeType.start).toList();
    final endNodes =
        template.nodes.where((n) => n.type == AgentWorkflowNodeType.end).toList();

    if (startNodes.length != 1) {
      errors.add(AgentWorkflowValidationError(
          'Workflow must contain exactly 1 Start node (found ${startNodes.length}).'));
    }
    if (endNodes.length != 1) {
      errors.add(AgentWorkflowValidationError(
          'Workflow must contain exactly 1 End node (found ${endNodes.length}).'));
    }

    final nodeIdSet = <String>{};
    final nodeById = <String, AgentWorkflowNode>{};
    for (final node in template.nodes) {
      final id = node.id.trim();
      if (id.isEmpty) {
        errors.add(const AgentWorkflowValidationError('Node id cannot be empty.'));
        continue;
      }
      if (!nodeIdSet.add(id)) {
        errors.add(AgentWorkflowValidationError('Duplicate node id: "$id".'));
        continue;
      }
      nodeById[id] = node;

      errors.addAll(_validateNodePorts(node));
      errors.addAll(_validateFixedNodeShape(node));
    }

    final edgeIdSet = <String>{};
    final toPortInDegree = <String, int>{}; // key: nodeId:portId
    for (final edge in template.edges) {
      if (!edgeIdSet.add(edge.id)) {
        errors.add(AgentWorkflowValidationError('Duplicate edge id: "${edge.id}".'));
      }

      final fromNode = nodeById[edge.fromNodeId];
      final toNode = nodeById[edge.toNodeId];
      if (fromNode == null) {
        errors.add(AgentWorkflowValidationError(
            'Edge "${edge.id}" references missing fromNodeId "${edge.fromNodeId}".'));
        continue;
      }
      if (toNode == null) {
        errors.add(AgentWorkflowValidationError(
            'Edge "${edge.id}" references missing toNodeId "${edge.toNodeId}".'));
        continue;
      }

      if (fromNode.type == AgentWorkflowNodeType.end) {
        errors.add(AgentWorkflowValidationError(
            'Edge "${edge.id}" cannot originate from End node.'));
      }
      if (toNode.type == AgentWorkflowNodeType.start) {
        errors.add(AgentWorkflowValidationError(
            'Edge "${edge.id}" cannot target Start node.'));
      }

      final fromPortOk =
          fromNode.outputs.any((p) => p.id == edge.fromPortId);
      if (!fromPortOk) {
        errors.add(AgentWorkflowValidationError(
            'Edge "${edge.id}" references missing fromPortId "${edge.fromPortId}" on node "${fromNode.title}".'));
      }

      final toPortOk = toNode.inputs.any((p) => p.id == edge.toPortId);
      if (!toPortOk) {
        errors.add(AgentWorkflowValidationError(
            'Edge "${edge.id}" references missing toPortId "${edge.toPortId}" on node "${toNode.title}".'));
      }

      final toKey = '${edge.toNodeId}:${edge.toPortId}';
      toPortInDegree[toKey] = (toPortInDegree[toKey] ?? 0) + 1;
    }

    for (final entry in toPortInDegree.entries) {
      if (entry.value <= 1) continue;
      errors.add(AgentWorkflowValidationError(
          'Input port "${entry.key}" has ${entry.value} incoming edges (max 1).'));
    }

    final start = startNodes.length == 1 ? startNodes.first : null;
    final end = endNodes.length == 1 ? endNodes.first : null;

    if (start != null && end != null) {
      // Enforce End.result has exactly 1 inbound edge.
      final endInput = end.inputs.firstWhere(
        (p) => p.name.trim() == 'result',
        orElse: () => end.inputs.isNotEmpty
            ? end.inputs.first
            : const AgentWorkflowPort(id: '', name: ''),
      );
      if (endInput.id.isNotEmpty) {
        final endKey = '${end.id}:${endInput.id}';
        final indegree = toPortInDegree[endKey] ?? 0;
        if (indegree != 1) {
          errors.add(AgentWorkflowValidationError(
              'End.result must have exactly 1 incoming edge (found $indegree).'));
        }
      }

      final adjacency = _buildAdjacency(template.edges);
      final reachableFromStart = _reachableNodes(
        startId: start.id,
        adjacency: adjacency,
      );

      if (!reachableFromStart.contains(end.id)) {
        errors.add(const AgentWorkflowValidationError(
            'End node must be reachable from Start node.'));
      } else {
        // Cycle detection on the Start->End relevant subgraph.
        final reverseAdjacency = _buildReverseAdjacency(template.edges);
        final canReachEnd = _reachableNodes(
          startId: end.id,
          adjacency: reverseAdjacency,
        );

        final included = reachableFromStart.intersection(canReachEnd);
        final hasCycle = _hasCycle(
          nodeIds: included,
          adjacency: adjacency,
        );
        if (hasCycle) {
          errors.add(const AgentWorkflowValidationError(
              'Workflow contains a cycle in the Start→End path.'));
        }
      }
    }

    return AgentWorkflowValidationResult(errors);
  }

  List<AgentWorkflowValidationError> _validateFixedNodeShape(
    AgentWorkflowNode node,
  ) {
    if (node.type == AgentWorkflowNodeType.start) {
      if (node.inputs.isNotEmpty) {
        return const [
          AgentWorkflowValidationError('Start node must not have input ports.'),
        ];
      }
      if (node.outputs.length != 1 || node.outputs.first.name.trim() != 'start') {
        return const [
          AgentWorkflowValidationError(
              'Start node must have exactly 1 output port named "start".'),
        ];
      }
    }

    if (node.type == AgentWorkflowNodeType.end) {
      if (node.outputs.isNotEmpty) {
        return const [
          AgentWorkflowValidationError('End node must not have output ports.'),
        ];
      }
      if (node.inputs.length != 1 || node.inputs.first.name.trim() != 'result') {
        return const [
          AgentWorkflowValidationError(
              'End node must have exactly 1 input port named "result".'),
        ];
      }
    }

    return const [];
  }

  List<AgentWorkflowValidationError> _validateNodePorts(AgentWorkflowNode node) {
    final errors = <AgentWorkflowValidationError>[];
    final inputIds = <String>{};
    final outputIds = <String>{};
    final inputNames = <String>{};
    final outputNames = <String>{};

    for (final p in node.inputs) {
      if (p.id.trim().isEmpty) {
        errors.add(AgentWorkflowValidationError(
            'Node "${node.title}" has an input port with empty id.'));
        continue;
      }
      if (!inputIds.add(p.id)) {
        errors.add(AgentWorkflowValidationError(
            'Node "${node.title}" has duplicate input port id "${p.id}".'));
      }
      final name = p.name.trim();
      if (name.isEmpty) {
        errors.add(AgentWorkflowValidationError(
            'Node "${node.title}" has an input port with empty name.'));
      } else if (!inputNames.add(name)) {
        errors.add(AgentWorkflowValidationError(
            'Node "${node.title}" has duplicate input port name "$name".'));
      }
    }

    for (final p in node.outputs) {
      if (p.id.trim().isEmpty) {
        errors.add(AgentWorkflowValidationError(
            'Node "${node.title}" has an output port with empty id.'));
        continue;
      }
      if (!outputIds.add(p.id)) {
        errors.add(AgentWorkflowValidationError(
            'Node "${node.title}" has duplicate output port id "${p.id}".'));
      }
      final name = p.name.trim();
      if (name.isEmpty) {
        errors.add(AgentWorkflowValidationError(
            'Node "${node.title}" has an output port with empty name.'));
      } else if (!outputNames.add(name)) {
        errors.add(AgentWorkflowValidationError(
            'Node "${node.title}" has duplicate output port name "$name".'));
      }
    }

    return errors;
  }

  Map<String, Set<String>> _buildAdjacency(List<AgentWorkflowEdge> edges) {
    final adjacency = <String, Set<String>>{};
    for (final e in edges) {
      (adjacency[e.fromNodeId] ??= <String>{}).add(e.toNodeId);
      adjacency.putIfAbsent(e.toNodeId, () => <String>{});
    }
    return adjacency;
  }

  Map<String, Set<String>> _buildReverseAdjacency(List<AgentWorkflowEdge> edges) {
    final adjacency = <String, Set<String>>{};
    for (final e in edges) {
      (adjacency[e.toNodeId] ??= <String>{}).add(e.fromNodeId);
      adjacency.putIfAbsent(e.fromNodeId, () => <String>{});
    }
    return adjacency;
  }

  Set<String> _reachableNodes({
    required String startId,
    required Map<String, Set<String>> adjacency,
  }) {
    final visited = <String>{};
    final queue = <String>[startId];
    visited.add(startId);
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final next in adjacency[current] ?? const <String>{}) {
        if (visited.add(next)) {
          queue.add(next);
        }
      }
    }
    return visited;
  }

  bool _hasCycle({
    required Set<String> nodeIds,
    required Map<String, Set<String>> adjacency,
  }) {
    if (nodeIds.isEmpty) return false;
    final indegree = <String, int>{};
    for (final id in nodeIds) {
      indegree[id] = 0;
    }
    for (final from in nodeIds) {
      for (final to in adjacency[from] ?? const <String>{}) {
        if (!nodeIds.contains(to)) continue;
        indegree[to] = (indegree[to] ?? 0) + 1;
      }
    }

    final queue = <String>[
      for (final entry in indegree.entries)
        if (entry.value == 0) entry.key
    ];

    var processed = 0;
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      processed += 1;
      for (final to in adjacency[current] ?? const <String>{}) {
        if (!nodeIds.contains(to)) continue;
        final next = (indegree[to] ?? 0) - 1;
        indegree[to] = next;
        if (next == 0) {
          queue.add(to);
        }
      }
    }

    return processed != nodeIds.length;
  }
}
