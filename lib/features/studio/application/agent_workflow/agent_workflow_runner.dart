import 'dart:collection';

import 'package:dio/dio.dart';

import '../../domain/agent_workflow/agent_workflow_models.dart';
import '../../domain/agent_workflow/agent_workflow_validator.dart';

enum AgentWorkflowNodeRunStatus {
  idle,
  running,
  success,
  error,
  stopped,
}

class AgentWorkflowNodeRunUpdate {
  final String nodeId;
  final AgentWorkflowNodeRunStatus status;
  final Map<String, String> inputsByName;
  final String renderedBody;
  final String? output;
  final String? error;
  final int? durationMs;

  const AgentWorkflowNodeRunUpdate({
    required this.nodeId,
    required this.status,
    this.inputsByName = const {},
    this.renderedBody = '',
    this.output,
    this.error,
    this.durationMs,
  });
}

class AgentWorkflowNodeExecutionRequest {
  final Map<String, String> inputsByName;
  final Map<String, String> inputsByPortId;
  final String renderedBody;
  final CancelToken? cancelToken;

  const AgentWorkflowNodeExecutionRequest({
    required this.inputsByName,
    required this.inputsByPortId,
    required this.renderedBody,
    this.cancelToken,
  });
}

typedef AgentWorkflowExecutor = Future<String> Function(
  AgentWorkflowNode node,
  AgentWorkflowNodeExecutionRequest request,
);

class AgentWorkflowRunResult {
  final bool success;
  final bool stopped;
  final String? finalOutput;
  final String? error;

  const AgentWorkflowRunResult({
    required this.success,
    required this.stopped,
    this.finalOutput,
    this.error,
  });

  factory AgentWorkflowRunResult.stopped() =>
      const AgentWorkflowRunResult(success: false, stopped: true);
}

class AgentWorkflowTemplateEngine {
  static final RegExp _token = RegExp(r'\{\{(.*?)\}\}');

  static String applyTemplate(
    String template,
    Map<String, String> vars,
  ) {
    if (template.isEmpty) return template;
    if (vars.isEmpty) return template;
    return template.replaceAllMapped(_token, (match) {
      final rawKey = match.group(1) ?? '';
      final key = rawKey.trim();
      if (key.isEmpty) return match.group(0) ?? '';
      if (!vars.containsKey(key)) return match.group(0) ?? '';
      return vars[key] ?? '';
    });
  }
}

class AgentWorkflowRunner {
  final AgentWorkflowValidator _validator;
  final AgentWorkflowExecutor _executor;

  const AgentWorkflowRunner({
    required AgentWorkflowValidator validator,
    required AgentWorkflowExecutor executor,
  })  : _validator = validator,
        _executor = executor;

  Future<AgentWorkflowRunResult> run({
    required AgentWorkflowTemplate template,
    required String startInput,
    required void Function(AgentWorkflowNodeRunUpdate update) onUpdate,
    required bool Function() shouldStop,
    CancelToken? cancelToken,
  }) async {
    final validation = _validator.validate(template);
    if (!validation.isValid) {
      return AgentWorkflowRunResult(
        success: false,
        stopped: false,
        error: validation.toMultilineString(),
      );
    }

    final start = template.startNode!;
    final end = template.endNode!;

    final nodesById = {for (final n in template.nodes) n.id: n};
    final nodeIndex = <String, int>{
      for (var i = 0; i < template.nodes.length; i += 1)
        template.nodes[i].id: i
    };

    final adjacency = <String, List<String>>{};
    final reverseAdjacency = <String, List<String>>{};
    for (final n in template.nodes) {
      adjacency[n.id] = <String>[];
      reverseAdjacency[n.id] = <String>[];
    }
    for (final e in template.edges) {
      adjacency[e.fromNodeId]?.add(e.toNodeId);
      reverseAdjacency[e.toNodeId]?.add(e.fromNodeId);
    }

    final forward = _reachable(start.id, adjacency);
    final reverse = _reachable(end.id, reverseAdjacency);
    final included = forward.intersection(reverse);

    final includedEdges = template.edges
        .where((e) => included.contains(e.fromNodeId) && included.contains(e.toNodeId))
        .toList(growable: false);

    final incomingByToPortKey = <String, AgentWorkflowEdge>{};
    for (final e in includedEdges) {
      incomingByToPortKey['${e.toNodeId}:${e.toPortId}'] = e;
    }

    final indegree = <String, int>{
      for (final id in included) id: 0,
    };
    for (final e in includedEdges) {
      indegree[e.toNodeId] = (indegree[e.toNodeId] ?? 0) + 1;
    }

    final ready = <String>[
      for (final entry in indegree.entries)
        if (entry.value == 0) entry.key
    ]..sort((a, b) => (nodeIndex[a] ?? 0).compareTo(nodeIndex[b] ?? 0));

    final outputsByNodeId = <String, String>{};
    String? finalOutput;

    void emit(AgentWorkflowNodeRunUpdate update) {
      onUpdate(update);
    }

    Future<void> setNodeRunning(
      String nodeId, {
      required Map<String, String> inputsByName,
      required String body,
    }) async {
      emit(AgentWorkflowNodeRunUpdate(
        nodeId: nodeId,
        status: AgentWorkflowNodeRunStatus.running,
        inputsByName: inputsByName,
        renderedBody: body,
      ));
    }

    Future<void> setNodeSuccess(
      String nodeId, {
      required Map<String, String> inputsByName,
      required String body,
      required String output,
      required int durationMs,
    }) async {
      emit(AgentWorkflowNodeRunUpdate(
        nodeId: nodeId,
        status: AgentWorkflowNodeRunStatus.success,
        inputsByName: inputsByName,
        renderedBody: body,
        output: output,
        durationMs: durationMs,
      ));
    }

    Future<void> setNodeError(
      String nodeId, {
      required Map<String, String> inputsByName,
      required String body,
      required String error,
      required int durationMs,
    }) async {
      emit(AgentWorkflowNodeRunUpdate(
        nodeId: nodeId,
        status: AgentWorkflowNodeRunStatus.error,
        inputsByName: inputsByName,
        renderedBody: body,
        error: error,
        durationMs: durationMs,
      ));
    }

    Future<void> setNodeStopped(
      String nodeId, {
      required Map<String, String> inputsByName,
      required String body,
    }) async {
      emit(AgentWorkflowNodeRunUpdate(
        nodeId: nodeId,
        status: AgentWorkflowNodeRunStatus.stopped,
        inputsByName: inputsByName,
        renderedBody: body,
      ));
    }

    while (ready.isNotEmpty) {
      if (shouldStop()) {
        return AgentWorkflowRunResult.stopped();
      }

      final currentId = ready.removeAt(0);
      if (!included.contains(currentId)) continue;
      final node = nodesById[currentId];
      if (node == null) continue;

      final inputsByName = <String, String>{};
      final inputsByPortId = <String, String>{};

      for (final port in node.inputs) {
        final edge = incomingByToPortKey['${node.id}:${port.id}'];
        final upstream = edge == null ? null : outputsByNodeId[edge.fromNodeId];
        final value = upstream ?? '';
        inputsByPortId[port.id] = value;
        inputsByName[port.name] = value;
      }

      if (node.type == AgentWorkflowNodeType.start) {
        final output = startInput;
        outputsByNodeId[node.id] = output;
        await setNodeSuccess(
          node.id,
          inputsByName: inputsByName,
          body: '',
          output: output,
          durationMs: 0,
        );
      } else if (node.type == AgentWorkflowNodeType.end) {
        final resultValue = node.inputs.isEmpty ? '' : inputsByPortId[node.inputs.first.id] ?? '';
        finalOutput = resultValue;
        await setNodeSuccess(
          node.id,
          inputsByName: inputsByName,
          body: '',
          output: resultValue,
          durationMs: 0,
        );
      } else {
        final body = AgentWorkflowTemplateEngine.applyTemplate(
          node.bodyTemplate,
          inputsByName,
        );

        await setNodeRunning(node.id, inputsByName: inputsByName, body: body);

        final startTime = DateTime.now();
        try {
          final output = await _executor(
            node,
            AgentWorkflowNodeExecutionRequest(
              inputsByName: Map<String, String>.unmodifiable(inputsByName),
              inputsByPortId: Map<String, String>.unmodifiable(inputsByPortId),
              renderedBody: body,
              cancelToken: cancelToken,
            ),
          );

          if (shouldStop()) {
            await setNodeStopped(node.id, inputsByName: inputsByName, body: body);
            return AgentWorkflowRunResult.stopped();
          }

          final durationMs =
              DateTime.now().difference(startTime).inMilliseconds;
          outputsByNodeId[node.id] = output;
          await setNodeSuccess(
            node.id,
            inputsByName: inputsByName,
            body: body,
            output: output,
            durationMs: durationMs,
          );
        } on DioException catch (e) {
          final durationMs =
              DateTime.now().difference(startTime).inMilliseconds;
          if (e.type == DioExceptionType.cancel) {
            await setNodeStopped(
              node.id,
              inputsByName: inputsByName,
              body: body,
            );
            return AgentWorkflowRunResult.stopped();
          }
          await setNodeError(
            node.id,
            inputsByName: inputsByName,
            body: body,
            error: e.toString(),
            durationMs: durationMs,
          );
          return AgentWorkflowRunResult(
            success: false,
            stopped: false,
            error: e.toString(),
          );
        } catch (e) {
          final durationMs =
              DateTime.now().difference(startTime).inMilliseconds;
          await setNodeError(
            node.id,
            inputsByName: inputsByName,
            body: body,
            error: e.toString(),
            durationMs: durationMs,
          );
          return AgentWorkflowRunResult(
            success: false,
            stopped: false,
            error: e.toString(),
          );
        }
      }

      // Decrement indegree.
      for (final edge in includedEdges.where((e) => e.fromNodeId == node.id)) {
        if (!indegree.containsKey(edge.toNodeId)) continue;
        final next = (indegree[edge.toNodeId] ?? 0) - 1;
        indegree[edge.toNodeId] = next;
        if (next == 0) {
          ready.add(edge.toNodeId);
        }
      }
      ready.sort((a, b) => (nodeIndex[a] ?? 0).compareTo(nodeIndex[b] ?? 0));
    }

    return AgentWorkflowRunResult(
      success: true,
      stopped: false,
      finalOutput: finalOutput,
    );
  }

  Set<String> _reachable(
    String startId,
    Map<String, List<String>> adjacency,
  ) {
    final visited = <String>{};
    final queue = Queue<String>()..add(startId);
    visited.add(startId);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final next in adjacency[current] ?? const <String>[]) {
        if (visited.add(next)) {
          queue.add(next);
        }
      }
    }
    return visited;
  }
}

