import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/agent_workflow/agent_workflow_json_schema.dart';
import '../../domain/agent_workflow/agent_workflow_models.dart';
import '../../domain/agent_workflow/agent_workflow_validator.dart';
import 'agent_workflow_value.dart';

enum AgentWorkflowNodeRunStatus {
  idle,
  running,
  waiting,
  success,
  warning,
  error,
  stopped,
}

class AgentWorkflowNodeRunUpdate {
  final String nodeId;
  final AgentWorkflowNodeRunStatus status;
  final Map<String, String> inputsByName;
  final String renderedBody;
  final String? output;
  final String? rawOutput;
  final String? outputJsonPretty;
  final String? error;
  final List<String> warnings;
  final int? durationMs;

  const AgentWorkflowNodeRunUpdate({
    required this.nodeId,
    required this.status,
    this.inputsByName = const {},
    this.renderedBody = '',
    this.output,
    this.rawOutput,
    this.outputJsonPretty,
    this.error,
    this.warnings = const [],
    this.durationMs,
  });
}

class AgentWorkflowNodeExecutionRequest {
  final Map<String, String> inputsByName;
  final Map<String, String> inputsByPortId;
  final Map<String, AgentWorkflowValue?> inputsByNameValue;
  final Map<String, AgentWorkflowValue?> inputsByPortIdValue;
  final String renderedBody;
  final CancelToken? cancelToken;

  const AgentWorkflowNodeExecutionRequest({
    required this.inputsByName,
    required this.inputsByPortId,
    required this.inputsByNameValue,
    required this.inputsByPortIdValue,
    required this.renderedBody,
    this.cancelToken,
  });
}

typedef AgentWorkflowExecutor = Future<AgentWorkflowValue> Function(
  AgentWorkflowNode node,
  AgentWorkflowNodeExecutionRequest request,
);

typedef AgentWorkflowUserInputHandler = Future<String?> Function(
  AgentWorkflowNode node,
  String prompt,
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
    Map<String, AgentWorkflowValue?> vars,
  ) {
    if (template.isEmpty) return template;
    if (vars.isEmpty) return template;

    return template.replaceAllMapped(_token, (match) {
      final rawKey = match.group(1) ?? '';
      final key = rawKey.trim();
      if (key.isEmpty) return match.group(0) ?? '';

      final parts = key.split('.');
      if (parts.isEmpty) return match.group(0) ?? '';
      final baseKey = parts.first.trim();
      if (baseKey.isEmpty) return match.group(0) ?? '';

      final value = vars[baseKey];
      if (value == null) return match.group(0) ?? '';
      if (parts.length == 1) return value.text;

      return _resolveValuePath(
            value,
            parts.sublist(1),
          ) ??
          (match.group(0) ?? '');
    });
  }

  static String? _resolveValuePath(
    AgentWorkflowValue value,
    List<String> segments,
  ) {
    if (segments.isEmpty) return value.text;

    final first = segments.first.trim();
    if (first == r'$raw') {
      if (segments.length == 1) return value.raw ?? value.text;
      return null;
    }

    Object? jsonValue = value.json;
    if (jsonValue == null) {
      final trimmed = value.text.trim();
      if (trimmed.startsWith('{') ||
          trimmed.startsWith('[') ||
          trimmed == 'null' ||
          trimmed == 'true' ||
          trimmed == 'false' ||
          RegExp(r'^-?\d+(\.\d+)?([eE][+-]?\d+)?$').hasMatch(trimmed)) {
        try {
          jsonValue = jsonDecode(trimmed);
        } catch (_) {
          jsonValue = null;
        }
      }
    }

    var current = jsonValue;
    var startIndex = 0;
    if (first == r'$json') {
      startIndex = 1;
      if (startIndex >= segments.length) {
        return current == null ? null : jsonEncode(current);
      }
    }

    for (var i = startIndex; i < segments.length; i += 1) {
      final seg = segments[i].trim();
      if (seg.isEmpty) return null;
      if (current is Map) {
        if (!current.containsKey(seg)) return null;
        current = current[seg];
        continue;
      }
      if (current is List) {
        final idx = int.tryParse(seg);
        if (idx == null || idx < 0 || idx >= current.length) return null;
        current = current[idx];
        continue;
      }
      return null;
    }

    if (current == null) return 'null';
    if (current is String) return current;
    if (current is num || current is bool) return current.toString();
    try {
      return jsonEncode(current);
    } catch (_) {
      return current.toString();
    }
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
    required AgentWorkflowUserInputHandler onRequestUserInput,
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

    final incomingEdgeByToPortKey = <String, AgentWorkflowEdge>{};
    final outgoingEdgesByFromPortKey = <String, List<AgentWorkflowEdge>>{};
    for (final e in includedEdges) {
      incomingEdgeByToPortKey['${e.toNodeId}:${e.toPortId}'] = e;
      (outgoingEdgesByFromPortKey['${e.fromNodeId}:${e.fromPortId}'] ??=
              <AgentWorkflowEdge>[])
          .add(e);
    }

    final requiredInputsByNodeId = <String, int>{
      for (final id in included) id: 0,
    };
    for (final e in includedEdges) {
      requiredInputsByNodeId[e.toNodeId] = (requiredInputsByNodeId[e.toNodeId] ?? 0) + 1;
    }

    final receivedInputsByNodeId = <String, int>{
      for (final id in included) id: 0,
    };
    final receivedValueByToPortKey = <String, AgentWorkflowValue>{};

    final ready = <String>[
      for (final entry in requiredInputsByNodeId.entries)
        if (entry.value == 0) entry.key
    ]..sort((a, b) => (nodeIndex[a] ?? 0).compareTo(nodeIndex[b] ?? 0));

    String? finalOutput;

    void emit(AgentWorkflowNodeRunUpdate update) {
      onUpdate(update);
    }

    AgentWorkflowPort? findErrorOutputPort(AgentWorkflowNode node) {
      return node.outputs.where((p) => p.name.trim() == 'error').firstOrNull;
    }

    List<AgentWorkflowPort> nonErrorOutputPorts(AgentWorkflowNode node) {
      return node.outputs
          .where((p) => p.name.trim() != 'error')
          .toList(growable: false);
    }

    void satisfyInput(AgentWorkflowEdge edge, AgentWorkflowValue value) {
      final toKey = '${edge.toNodeId}:${edge.toPortId}';
      if (receivedValueByToPortKey.containsKey(toKey)) return;
      receivedValueByToPortKey[toKey] = value;
      receivedInputsByNodeId[edge.toNodeId] =
          (receivedInputsByNodeId[edge.toNodeId] ?? 0) + 1;
      if (receivedInputsByNodeId[edge.toNodeId] ==
          (requiredInputsByNodeId[edge.toNodeId] ?? 0)) {
        ready.add(edge.toNodeId);
      }
    }

    void propagateFromPort({
      required String fromNodeId,
      required String fromPortId,
      required AgentWorkflowValue value,
    }) {
      final edges = outgoingEdgesByFromPortKey['$fromNodeId:$fromPortId'];
      if (edges == null || edges.isEmpty) return;
      for (final edge in edges) {
        satisfyInput(edge, value);
      }
    }

    List<String> validatePortValue({
      required AgentWorkflowPort port,
      required AgentWorkflowValue value,
    }) {
      final errors = <String>[];

      Object? instance;
      if (port.valueType == AgentWorkflowPortValueType.json) {
        instance = value.json;
        if (instance == null) {
          try {
            instance = jsonDecode(value.text);
          } catch (_) {
            errors.add('Port "${port.name}" expects JSON but received non-JSON text.');
            return errors;
          }
        }
      } else {
        instance = value.text;
      }

      final schema = port.schema;
      if (schema != null) {
        try {
          errors.addAll(AgentWorkflowJsonSchema.validateInstance(
            schema: schema,
            instance: instance,
          ));
        } catch (e) {
          errors.add('Invalid JSON Schema on port "${port.name}": $e');
        }
      }

      return errors;
    }

    AgentWorkflowValidationMode validationModeForPhase({
      required AgentWorkflowNode node,
      required bool isInput,
    }) {
      return isInput ? node.inputValidation : node.outputValidation;
    }

    bool applyValidation({
      required AgentWorkflowNode node,
      required bool isInput,
      required List<AgentWorkflowPort> ports,
      required AgentWorkflowValue Function(AgentWorkflowPort port) valueForPort,
      required List<String> outWarnings,
      required void Function(String error) onStrictError,
    }) {
      final mode = validationModeForPhase(node: node, isInput: isInput);
      if (mode == AgentWorkflowValidationMode.off) return true;

      final issues = <String>[];
      for (final port in ports) {
        final hasSchema = port.schema != null;
        final expectsJson = port.valueType == AgentWorkflowPortValueType.json;
        if (!hasSchema && !expectsJson) continue;
        issues.addAll(validatePortValue(port: port, value: valueForPort(port)));
      }

      if (issues.isEmpty) return true;
      if (mode == AgentWorkflowValidationMode.warn) {
        outWarnings.addAll(issues.map((e) => '[${isInput ? 'input' : 'output'}] $e'));
        return true;
      }

      onStrictError(issues.join('\n'));
      return false;
    }

    AgentWorkflowValue? valueForInputPort({
      required AgentWorkflowNode node,
      required AgentWorkflowPort port,
    }) {
      return receivedValueByToPortKey['${node.id}:${port.id}'];
    }

    Map<String, AgentWorkflowValue?> buildInputsByNameValue(
      AgentWorkflowNode node,
    ) {
      final map = <String, AgentWorkflowValue?>{};
      for (final port in node.inputs) {
        map[port.name] = valueForInputPort(node: node, port: port);
      }
      return map;
    }

    String safePrettyJson(Object value) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }

    while (ready.isNotEmpty) {
      ready.sort((a, b) => (nodeIndex[a] ?? 0).compareTo(nodeIndex[b] ?? 0));
      if (shouldStop()) {
        return AgentWorkflowRunResult.stopped();
      }

      final currentId = ready.removeAt(0);
      if (!included.contains(currentId)) continue;
      final node = nodesById[currentId];
      if (node == null) continue;

      final inputsByNameValue = buildInputsByNameValue(node);
      final inputsByPortIdValue = <String, AgentWorkflowValue?>{
        for (final port in node.inputs)
          port.id: valueForInputPort(node: node, port: port),
      };

      final inputsByName = <String, String>{
        for (final entry in inputsByNameValue.entries)
          entry.key: entry.value?.text ?? '',
      };
      final inputsByPortId = <String, String>{
        for (final entry in inputsByPortIdValue.entries)
          entry.key: entry.value?.text ?? '',
      };

      final warnings = <String>[];

      final renderedBody = node.type == AgentWorkflowNodeType.start ||
              node.type == AgentWorkflowNodeType.end
          ? ''
          : AgentWorkflowTemplateEngine.applyTemplate(
              node.bodyTemplate,
              inputsByNameValue,
            );

      String? strictInputError;
      final okInput = applyValidation(
        node: node,
        isInput: true,
        ports: node.inputs
            .where((p) => inputsByNameValue[p.name] != null)
            .toList(growable: false),
        valueForPort: (p) => inputsByNameValue[p.name]!,
        outWarnings: warnings,
        onStrictError: (err) => strictInputError = err,
      );

      if (!okInput) {
        final errorMsg = 'Input validation failed on node "${node.title}":\n$strictInputError';
        emit(AgentWorkflowNodeRunUpdate(
          nodeId: node.id,
          status: AgentWorkflowNodeRunStatus.error,
          inputsByName: inputsByName,
          renderedBody: renderedBody,
          error: errorMsg,
          warnings: warnings,
          durationMs: 0,
        ));

        final errorPort = findErrorOutputPort(node);
        final errorEdges = errorPort == null
            ? const <AgentWorkflowEdge>[]
            : (outgoingEdgesByFromPortKey['${node.id}:${errorPort.id}'] ??
                const <AgentWorkflowEdge>[]);
        if (errorEdges.isEmpty) {
          return AgentWorkflowRunResult(
            success: false,
            stopped: false,
            error: errorMsg,
          );
        }
        for (final edge in errorEdges) {
          satisfyInput(edge, AgentWorkflowValue.error(errorMsg));
        }
        continue;
      }

      if (node.type == AgentWorkflowNodeType.start) {
        final output = AgentWorkflowValue.fromText(startInput);
        String? strictOutputError;
        final okOutput = applyValidation(
          node: node,
          isInput: false,
          ports: nonErrorOutputPorts(node),
          valueForPort: (_) => output,
          outWarnings: warnings,
          onStrictError: (err) => strictOutputError = err,
        );
        if (!okOutput) {
          final errorMsg =
              'Output validation failed on Start node:\n$strictOutputError';
          emit(AgentWorkflowNodeRunUpdate(
            nodeId: node.id,
            status: AgentWorkflowNodeRunStatus.error,
            inputsByName: inputsByName,
            renderedBody: '',
            error: errorMsg,
            warnings: warnings,
            durationMs: 0,
          ));
          return AgentWorkflowRunResult(
            success: false,
            stopped: false,
            error: errorMsg,
          );
        }

        final status =
            warnings.isEmpty ? AgentWorkflowNodeRunStatus.success : AgentWorkflowNodeRunStatus.warning;
        emit(AgentWorkflowNodeRunUpdate(
          nodeId: node.id,
          status: status,
          inputsByName: inputsByName,
          renderedBody: '',
          output: output.text,
          warnings: warnings,
          durationMs: 0,
        ));

        for (final outPort in nonErrorOutputPorts(node)) {
          propagateFromPort(
            fromNodeId: node.id,
            fromPortId: outPort.id,
            value: output,
          );
        }
        continue;
      }

      if (node.type == AgentWorkflowNodeType.end) {
        final inputPort = node.inputs.firstOrNull;
        final inValue = inputPort == null ? null : inputsByPortIdValue[inputPort.id];
        final resultValue = inValue?.text ?? '';
        finalOutput = resultValue;

        final status =
            warnings.isEmpty ? AgentWorkflowNodeRunStatus.success : AgentWorkflowNodeRunStatus.warning;
        emit(AgentWorkflowNodeRunUpdate(
          nodeId: node.id,
          status: status,
          inputsByName: inputsByName,
          renderedBody: '',
          output: resultValue,
          warnings: warnings,
          durationMs: 0,
        ));
        return AgentWorkflowRunResult(
          success: true,
          stopped: false,
          finalOutput: finalOutput,
        );
      }

      if (node.type == AgentWorkflowNodeType.userInput) {
        emit(AgentWorkflowNodeRunUpdate(
          nodeId: node.id,
          status: AgentWorkflowNodeRunStatus.waiting,
          inputsByName: inputsByName,
          renderedBody: renderedBody,
          warnings: warnings,
        ));

        final input = await onRequestUserInput(node, renderedBody);
        if (shouldStop()) {
          emit(AgentWorkflowNodeRunUpdate(
            nodeId: node.id,
            status: AgentWorkflowNodeRunStatus.stopped,
            inputsByName: inputsByName,
            renderedBody: renderedBody,
            warnings: warnings,
          ));
          return AgentWorkflowRunResult.stopped();
        }

        if (input == null) {
          final errorMsg = 'User input cancelled.';
          final errorPort = findErrorOutputPort(node);
          final errorEdges = errorPort == null
              ? const <AgentWorkflowEdge>[]
              : (outgoingEdgesByFromPortKey['${node.id}:${errorPort.id}'] ??
                  const <AgentWorkflowEdge>[]);
          if (errorEdges.isEmpty) {
            emit(AgentWorkflowNodeRunUpdate(
              nodeId: node.id,
              status: AgentWorkflowNodeRunStatus.stopped,
              inputsByName: inputsByName,
              renderedBody: renderedBody,
              warnings: warnings,
              durationMs: 0,
            ));
            return AgentWorkflowRunResult.stopped();
          }

          emit(AgentWorkflowNodeRunUpdate(
            nodeId: node.id,
            status: AgentWorkflowNodeRunStatus.error,
            inputsByName: inputsByName,
            renderedBody: renderedBody,
            error: errorMsg,
            warnings: warnings,
            durationMs: 0,
          ));
          for (final edge in errorEdges) {
            satisfyInput(edge, AgentWorkflowValue.error(errorMsg));
          }
          continue;
        }

        final output = AgentWorkflowValue.fromText(input);
        String? strictOutputError;
        final okOutput = applyValidation(
          node: node,
          isInput: false,
          ports: nonErrorOutputPorts(node),
          valueForPort: (_) => output,
          outWarnings: warnings,
          onStrictError: (err) => strictOutputError = err,
        );

        if (!okOutput) {
          final errorMsg =
              'Output validation failed on node "${node.title}":\n$strictOutputError';
          emit(AgentWorkflowNodeRunUpdate(
            nodeId: node.id,
            status: AgentWorkflowNodeRunStatus.error,
            inputsByName: inputsByName,
            renderedBody: renderedBody,
            error: errorMsg,
            warnings: warnings,
            durationMs: 0,
          ));

          final errorPort = findErrorOutputPort(node);
          final errorEdges = errorPort == null
              ? const <AgentWorkflowEdge>[]
              : (outgoingEdgesByFromPortKey['${node.id}:${errorPort.id}'] ??
                  const <AgentWorkflowEdge>[]);
          if (errorEdges.isEmpty) {
            return AgentWorkflowRunResult(
              success: false,
              stopped: false,
              error: errorMsg,
            );
          }
          for (final edge in errorEdges) {
            satisfyInput(edge, AgentWorkflowValue.error(errorMsg));
          }
          continue;
        }

        final status =
            warnings.isEmpty ? AgentWorkflowNodeRunStatus.success : AgentWorkflowNodeRunStatus.warning;
        emit(AgentWorkflowNodeRunUpdate(
          nodeId: node.id,
          status: status,
          inputsByName: inputsByName,
          renderedBody: renderedBody,
          output: output.text,
          warnings: warnings,
          durationMs: 0,
        ));
        for (final outPort in nonErrorOutputPorts(node)) {
          propagateFromPort(
            fromNodeId: node.id,
            fromPortId: outPort.id,
            value: output,
          );
        }
        continue;
      }

      emit(AgentWorkflowNodeRunUpdate(
        nodeId: node.id,
        status: AgentWorkflowNodeRunStatus.running,
        inputsByName: inputsByName,
        renderedBody: renderedBody,
        warnings: warnings,
      ));

      final startTime = DateTime.now();
      try {
        final output = await _executor(
          node,
          AgentWorkflowNodeExecutionRequest(
            inputsByName: Map<String, String>.unmodifiable(inputsByName),
            inputsByPortId: Map<String, String>.unmodifiable(inputsByPortId),
            inputsByNameValue:
                Map<String, AgentWorkflowValue?>.unmodifiable(inputsByNameValue),
            inputsByPortIdValue: Map<String, AgentWorkflowValue?>.unmodifiable(
                inputsByPortIdValue),
            renderedBody: renderedBody,
            cancelToken: cancelToken,
          ),
        );

        if (shouldStop()) {
          emit(AgentWorkflowNodeRunUpdate(
            nodeId: node.id,
            status: AgentWorkflowNodeRunStatus.stopped,
            inputsByName: inputsByName,
            renderedBody: renderedBody,
            warnings: warnings,
          ));
          return AgentWorkflowRunResult.stopped();
        }

        String? strictOutputError;
        final okOutput = applyValidation(
          node: node,
          isInput: false,
          ports: nonErrorOutputPorts(node),
          valueForPort: (_) => output,
          outWarnings: warnings,
          onStrictError: (err) => strictOutputError = err,
        );

        final durationMs =
            DateTime.now().difference(startTime).inMilliseconds;
        if (!okOutput) {
          final errorMsg =
              'Output validation failed on node "${node.title}":\n$strictOutputError';
          emit(AgentWorkflowNodeRunUpdate(
            nodeId: node.id,
            status: AgentWorkflowNodeRunStatus.error,
            inputsByName: inputsByName,
            renderedBody: renderedBody,
            error: errorMsg,
            warnings: warnings,
            durationMs: durationMs,
          ));

          final errorPort = findErrorOutputPort(node);
          final errorEdges = errorPort == null
              ? const <AgentWorkflowEdge>[]
              : (outgoingEdgesByFromPortKey['${node.id}:${errorPort.id}'] ??
                  const <AgentWorkflowEdge>[]);
          if (errorEdges.isEmpty) {
            return AgentWorkflowRunResult(
              success: false,
              stopped: false,
              error: errorMsg,
            );
          }
          for (final edge in errorEdges) {
            satisfyInput(edge, AgentWorkflowValue.error(errorMsg));
          }
          continue;
        }

        String? outputPretty;
        if (output.json != null) {
          try {
            outputPretty = safePrettyJson(output.json!);
          } catch (_) {}
        }

        final status =
            warnings.isEmpty ? AgentWorkflowNodeRunStatus.success : AgentWorkflowNodeRunStatus.warning;
        emit(AgentWorkflowNodeRunUpdate(
          nodeId: node.id,
          status: status,
          inputsByName: inputsByName,
          renderedBody: renderedBody,
          output: output.text,
          rawOutput: output.raw,
          outputJsonPretty: outputPretty,
          warnings: warnings,
          durationMs: durationMs,
        ));

        for (final outPort in nonErrorOutputPorts(node)) {
          propagateFromPort(
            fromNodeId: node.id,
            fromPortId: outPort.id,
            value: output,
          );
        }
      } on DioException catch (e) {
        final durationMs = DateTime.now().difference(startTime).inMilliseconds;
        if (e.type == DioExceptionType.cancel) {
          emit(AgentWorkflowNodeRunUpdate(
            nodeId: node.id,
            status: AgentWorkflowNodeRunStatus.stopped,
            inputsByName: inputsByName,
            renderedBody: renderedBody,
            warnings: warnings,
            durationMs: durationMs,
          ));
          return AgentWorkflowRunResult.stopped();
        }

        final errorMsg = e.toString();
        emit(AgentWorkflowNodeRunUpdate(
          nodeId: node.id,
          status: AgentWorkflowNodeRunStatus.error,
          inputsByName: inputsByName,
          renderedBody: renderedBody,
          error: errorMsg,
          warnings: warnings,
          durationMs: durationMs,
        ));

        final errorPort = findErrorOutputPort(node);
        final errorEdges = errorPort == null
            ? const <AgentWorkflowEdge>[]
            : (outgoingEdgesByFromPortKey['${node.id}:${errorPort.id}'] ??
                const <AgentWorkflowEdge>[]);
        if (errorEdges.isEmpty) {
          return AgentWorkflowRunResult(
            success: false,
            stopped: false,
            error: errorMsg,
          );
        }
        for (final edge in errorEdges) {
          satisfyInput(edge, AgentWorkflowValue.error(errorMsg));
        }
      } catch (e) {
        final durationMs = DateTime.now().difference(startTime).inMilliseconds;
        final errorMsg = e.toString();
        emit(AgentWorkflowNodeRunUpdate(
          nodeId: node.id,
          status: AgentWorkflowNodeRunStatus.error,
          inputsByName: inputsByName,
          renderedBody: renderedBody,
          error: errorMsg,
          warnings: warnings,
          durationMs: durationMs,
        ));

        final errorPort = findErrorOutputPort(node);
        final errorEdges = errorPort == null
            ? const <AgentWorkflowEdge>[]
            : (outgoingEdgesByFromPortKey['${node.id}:${errorPort.id}'] ??
                const <AgentWorkflowEdge>[]);
        if (errorEdges.isEmpty) {
          return AgentWorkflowRunResult(
            success: false,
            stopped: false,
            error: errorMsg,
          );
        }
        for (final edge in errorEdges) {
          satisfyInput(edge, AgentWorkflowValue.error(errorMsg));
        }
      }
    }

    return AgentWorkflowRunResult(
      success: false,
      stopped: false,
      error: 'End node was not reached.',
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
