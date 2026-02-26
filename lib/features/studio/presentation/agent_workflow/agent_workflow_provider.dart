import 'dart:async';

import 'package:aurora/features/mcp/presentation/mcp_connection_provider.dart';
import 'package:aurora/features/mcp/presentation/mcp_server_provider.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/skills/presentation/skill_provider.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/services/model_routed_llm_service.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../application/agent_workflow/agent_workflow_executor.dart';
import '../../application/agent_workflow/agent_workflow_runner.dart';
import '../../data/agent_workflow/agent_workflow_storage.dart';
import '../../domain/agent_workflow/agent_workflow_models.dart';
import '../../domain/agent_workflow/agent_workflow_validator.dart';

class AgentWorkflowNodeRunState {
  final AgentWorkflowNodeRunStatus status;
  final Map<String, String> inputsByName;
  final String renderedBody;
  final String? output;
  final String? error;
  final int? durationMs;

  const AgentWorkflowNodeRunState({
    this.status = AgentWorkflowNodeRunStatus.idle,
    this.inputsByName = const {},
    this.renderedBody = '',
    this.output,
    this.error,
    this.durationMs,
  });

  AgentWorkflowNodeRunState copyWith({
    AgentWorkflowNodeRunStatus? status,
    Map<String, String>? inputsByName,
    String? renderedBody,
    Object? output = _sentinel,
    Object? error = _sentinel,
    Object? durationMs = _sentinel,
  }) {
    return AgentWorkflowNodeRunState(
      status: status ?? this.status,
      inputsByName: inputsByName ?? this.inputsByName,
      renderedBody: renderedBody ?? this.renderedBody,
      output: output == _sentinel ? this.output : output as String?,
      error: error == _sentinel ? this.error : error as String?,
      durationMs: durationMs == _sentinel ? this.durationMs : durationMs as int?,
    );
  }
}

class AgentWorkflowState {
  final bool isLoading;
  final String? error;
  final AgentWorkflowDocument document;
  final String? selectedTemplateId;
  final String? selectedNodeId;
  final String startInput;
  final bool isRunning;
  final bool isStopping;
  final String? finalOutput;
  final Map<String, AgentWorkflowNodeRunState> runStates;

  const AgentWorkflowState({
    this.isLoading = false,
    this.error,
    this.document = const AgentWorkflowDocument(version: 1, templates: []),
    this.selectedTemplateId,
    this.selectedNodeId,
    this.startInput = '',
    this.isRunning = false,
    this.isStopping = false,
    this.finalOutput,
    this.runStates = const {},
  });

  AgentWorkflowTemplate? get selectedTemplate {
    final id = selectedTemplateId;
    if (id == null || id.isEmpty) return null;
    return document.templates.where((t) => t.id == id).firstOrNull;
  }

  AgentWorkflowState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    AgentWorkflowDocument? document,
    Object? selectedTemplateId = _sentinel,
    Object? selectedNodeId = _sentinel,
    String? startInput,
    bool? isRunning,
    bool? isStopping,
    Object? finalOutput = _sentinel,
    Map<String, AgentWorkflowNodeRunState>? runStates,
  }) {
    return AgentWorkflowState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      document: document ?? this.document,
      selectedTemplateId: selectedTemplateId == _sentinel
          ? this.selectedTemplateId
          : selectedTemplateId as String?,
      selectedNodeId: selectedNodeId == _sentinel
          ? this.selectedNodeId
          : selectedNodeId as String?,
      startInput: startInput ?? this.startInput,
      isRunning: isRunning ?? this.isRunning,
      isStopping: isStopping ?? this.isStopping,
      finalOutput:
          finalOutput == _sentinel ? this.finalOutput : finalOutput as String?,
      runStates: runStates ?? this.runStates,
    );
  }
}

class AgentWorkflowNotifier extends StateNotifier<AgentWorkflowState> {
  final Ref _ref;
  final AgentWorkflowStorage _storage = AgentWorkflowStorage();
  final AgentWorkflowValidator _validator = const AgentWorkflowValidator();
  bool _hasLoaded = false;
  Timer? _saveDebounce;
  CancelToken? _cancelToken;

  AgentWorkflowNotifier(this._ref) : super(const AgentWorkflowState());

  Future<void> load() async {
    if (_hasLoaded) return;
    _hasLoaded = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final doc = await _storage.load();
      final selected = doc.templates.isNotEmpty ? doc.templates.first.id : null;
      state = state.copyWith(
        isLoading: false,
        document: doc,
        selectedTemplateId: selected,
        selectedNodeId: null,
        runStates: const {},
        finalOutput: null,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _cancelToken?.cancel('disposed');
    super.dispose();
  }

  void selectTemplate(String templateId) {
    if (state.selectedTemplateId == templateId) return;
    state = state.copyWith(
      selectedTemplateId: templateId,
      selectedNodeId: null,
      runStates: const {},
      finalOutput: null,
      error: null,
      isRunning: false,
      isStopping: false,
    );
  }

  void setStartInput(String value) {
    state = state.copyWith(startInput: value);
  }

  void selectNode(String? nodeId) {
    state = state.copyWith(selectedNodeId: nodeId);
  }

  Future<void> saveNow() async {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    await _storage.save(state.document);
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 650), () {
      unawaited(_storage.save(state.document));
    });
  }

  void createTemplate(String name) {
    final trimmed = name.trim().isEmpty ? 'Workflow' : name.trim();
    final template = AgentWorkflowTemplate.create(name: trimmed);
    final doc = state.document.copyWith(
      templates: [...state.document.templates, template],
    );
    state = state.copyWith(
      document: doc,
      selectedTemplateId: template.id,
      selectedNodeId: null,
      runStates: const {},
      finalOutput: null,
      error: null,
    );
    _scheduleSave();
  }

  void renameTemplate(String templateId, String newName) {
    final name = newName.trim();
    if (name.isEmpty) return;
    final templates = state.document.templates.map((t) {
      return t.id == templateId ? t.copyWith(name: name) : t;
    }).toList(growable: false);
    state = state.copyWith(document: state.document.copyWith(templates: templates));
    _scheduleSave();
  }

  void deleteTemplate(String templateId) {
    final remaining = state.document.templates
        .where((t) => t.id != templateId)
        .toList(growable: false);
    final nextTemplates = remaining.isEmpty
        ? [AgentWorkflowTemplate.create(name: 'Default Workflow')]
        : remaining;
    final nextSelectedId = nextTemplates.first.id;
    state = state.copyWith(
      document: state.document.copyWith(templates: nextTemplates),
      selectedTemplateId: nextSelectedId,
      selectedNodeId: null,
      runStates: const {},
      finalOutput: null,
      error: null,
      isRunning: false,
      isStopping: false,
    );
    _scheduleSave();
  }

  void addNode(AgentWorkflowNodeType type) {
    final template = state.selectedTemplate;
    if (template == null) return;

    final idx = template.nodes.length;
    final x = 260.0 + (idx % 6) * 40.0;
    final y = 220.0 + (idx % 5) * 32.0;

    AgentWorkflowNode node;
    switch (type) {
      case AgentWorkflowNodeType.llm:
        node = AgentWorkflowNode.createLlm(x: x, y: y);
      case AgentWorkflowNodeType.skill:
        node = AgentWorkflowNode.createSkill(x: x, y: y);
      case AgentWorkflowNodeType.mcp:
        node = AgentWorkflowNode.createMcp(x: x, y: y);
      case AgentWorkflowNodeType.start:
      case AgentWorkflowNodeType.end:
        return;
    }

    _updateTemplate(template.copyWith(nodes: [...template.nodes, node]));
    selectNode(node.id);
  }

  void deleteNode(String nodeId) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final node = template.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null || node.isFixed) return;

    final nodes = template.nodes.where((n) => n.id != nodeId).toList(growable: false);
    final edges = template.edges
        .where((e) => e.fromNodeId != nodeId && e.toNodeId != nodeId)
        .toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes, edges: edges));

    if (state.selectedNodeId == nodeId) {
      state = state.copyWith(selectedNodeId: null);
    }
  }

  void updateNodePosition(String nodeId, double x, double y) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final safeX = x.isFinite && !x.isNaN ? x : 0.0;
    final safeY = y.isFinite && !y.isNaN ? y : 0.0;
    final nextX = safeX < 0 ? 0.0 : safeX;
    final nextY = safeY < 0 ? 0.0 : safeY;
    final nodes = template.nodes.map((n) {
      return n.id == nodeId ? n.copyWith(x: nextX, y: nextY) : n;
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes), scheduleSave: true);
  }

  void updateNodeTitle(String nodeId, String title) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final nodes = template.nodes.map((n) {
      return n.id == nodeId ? n.copyWith(title: title) : n;
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void updateNodeModel(String nodeId, AgentWorkflowModelRef? model) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final nodes = template.nodes.map((n) {
      return n.id == nodeId ? n.copyWith(model: model) : n;
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void updateNodeSystemPrompt(String nodeId, String systemPrompt) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final nodes = template.nodes.map((n) {
      return n.id == nodeId ? n.copyWith(systemPrompt: systemPrompt) : n;
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void updateNodeBodyTemplate(String nodeId, String bodyTemplate) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final nodes = template.nodes.map((n) {
      return n.id == nodeId ? n.copyWith(bodyTemplate: bodyTemplate) : n;
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void updateSkillNodeSkillId(String nodeId, String? skillId) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final normalized = (skillId ?? '').trim();
    final nodes = template.nodes.map((n) {
      return n.id == nodeId
          ? n.copyWith(skillId: normalized.isEmpty ? null : normalized)
          : n;
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void updateMcpNodeConfig(
    String nodeId, {
    String? serverId,
    String? toolName,
  }) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final normalizedServer = (serverId ?? '').trim();
    final normalizedTool = (toolName ?? '').trim();
    final nodes = template.nodes.map((n) {
      if (n.id != nodeId) return n;
      return n.copyWith(
        mcpServerId: normalizedServer.isEmpty ? null : normalizedServer,
        mcpToolName: normalizedTool.isEmpty ? null : normalizedTool,
      );
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void addInputPort(String nodeId) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final nodes = template.nodes.map((n) {
      if (n.id != nodeId || n.isFixed) return n;
      final idx = n.inputs.length + 1;
      final port = AgentWorkflowPort(id: const Uuid().v4(), name: 'in$idx');
      return n.copyWith(inputs: [...n.inputs, port]);
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void addOutputPort(String nodeId) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final nodes = template.nodes.map((n) {
      if (n.id != nodeId || n.isFixed) return n;
      final idx = n.outputs.length + 1;
      final port = AgentWorkflowPort(id: const Uuid().v4(), name: 'out$idx');
      return n.copyWith(outputs: [...n.outputs, port]);
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void renamePort({
    required String nodeId,
    required String portId,
    required bool isInput,
    required String newName,
  }) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final name = newName.trim();
    if (name.isEmpty) return;
    final nodes = template.nodes.map((n) {
      if (n.id != nodeId || n.isFixed) return n;
      if (isInput) {
        final inputs = n.inputs
            .map((p) => p.id == portId ? p.copyWith(name: name) : p)
            .toList(growable: false);
        return n.copyWith(inputs: inputs);
      } else {
        final outputs = n.outputs
            .map((p) => p.id == portId ? p.copyWith(name: name) : p)
            .toList(growable: false);
        return n.copyWith(outputs: outputs);
      }
    }).toList(growable: false);
    _updateTemplate(template.copyWith(nodes: nodes));
  }

  void deletePort({
    required String nodeId,
    required String portId,
    required bool isInput,
  }) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final node = template.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null || node.isFixed) return;

    final nodes = template.nodes.map((n) {
      if (n.id != nodeId) return n;
      if (isInput) {
        final inputs = n.inputs.where((p) => p.id != portId).toList(growable: false);
        return n.copyWith(inputs: inputs);
      } else {
        final outputs = n.outputs.where((p) => p.id != portId).toList(growable: false);
        return n.copyWith(outputs: outputs);
      }
    }).toList(growable: false);

    final edges = template.edges.where((e) {
      if (isInput) {
        return !(e.toNodeId == nodeId && e.toPortId == portId);
      }
      return !(e.fromNodeId == nodeId && e.fromPortId == portId);
    }).toList(growable: false);

    _updateTemplate(template.copyWith(nodes: nodes, edges: edges));
  }

  void connectEdge({
    required String fromNodeId,
    required String fromPortId,
    required String toNodeId,
    required String toPortId,
  }) {
    final template = state.selectedTemplate;
    if (template == null) return;
    if (fromNodeId == toNodeId && fromPortId == toPortId) return;

    final fromNode =
        template.nodes.where((n) => n.id == fromNodeId).firstOrNull;
    final toNode = template.nodes.where((n) => n.id == toNodeId).firstOrNull;
    if (fromNode == null || toNode == null) return;
    if (fromNode.type == AgentWorkflowNodeType.end) return;
    if (toNode.type == AgentWorkflowNodeType.start) return;
    if (!fromNode.outputs.any((p) => p.id == fromPortId)) return;
    if (!toNode.inputs.any((p) => p.id == toPortId)) return;

    final edges = template.edges.toList(growable: true);
    edges.removeWhere((e) => e.toNodeId == toNodeId && e.toPortId == toPortId);
    edges.add(AgentWorkflowEdge(
      id: const Uuid().v4(),
      fromNodeId: fromNodeId,
      fromPortId: fromPortId,
      toNodeId: toNodeId,
      toPortId: toPortId,
    ));
    _updateTemplate(template.copyWith(edges: edges));
  }

  void deleteEdge(String edgeId) {
    final template = state.selectedTemplate;
    if (template == null) return;
    final edges =
        template.edges.where((e) => e.id != edgeId).toList(growable: false);
    _updateTemplate(template.copyWith(edges: edges));
  }

  void _updateTemplate(AgentWorkflowTemplate updated,
      {bool scheduleSave = true}) {
    final templates = state.document.templates.map((t) {
      return t.id == updated.id ? updated : t;
    }).toList(growable: false);
    state = state.copyWith(document: state.document.copyWith(templates: templates));
    if (scheduleSave) {
      _scheduleSave();
    }
  }

  void resetRun() {
    state = state.copyWith(
      error: null,
      isRunning: false,
      isStopping: false,
      finalOutput: null,
      runStates: const {},
    );
  }

  void stopRun() {
    if (!state.isRunning) return;
    state = state.copyWith(isStopping: true);
    _cancelToken?.cancel('User requested stop');
  }

  Future<void> runSelectedTemplate() async {
    final template = state.selectedTemplate;
    if (template == null) return;
    if (state.isRunning) return;

    final validation = _validator.validate(template);
    if (!validation.isValid) {
      state = state.copyWith(error: validation.toMultilineString());
      return;
    }

    _cancelToken?.cancel('Starting new run');
    _cancelToken = CancelToken();

    final endId = template.endNode!.id;

    final initialRunStates = <String, AgentWorkflowNodeRunState>{
      for (final node in template.nodes)
        node.id: const AgentWorkflowNodeRunState(),
    };

    state = state.copyWith(
      error: null,
      isRunning: true,
      isStopping: false,
      finalOutput: null,
      runStates: initialRunStates,
    );

    final settings = _ref.read(settingsProvider);
    final llmService = ModelRoutedLlmService(settings);
    final skills = _ref.read(skillProvider).skills;
    final mcpServers = _ref.read(mcpServerProvider).servers;
    final mcpConnection = _ref.read(mcpConnectionProvider.notifier);

    final executor = AgentWorkflowDefaultExecutor(
      llmService: llmService,
      skills: skills,
      mcpConnection: mcpConnection,
      mcpServers: mcpServers,
    );
    final runner = AgentWorkflowRunner(
      validator: _validator,
      executor: executor.call,
    );

    final result = await runner.run(
      template: template,
      startInput: state.startInput,
      cancelToken: _cancelToken,
      shouldStop: () => !mounted || state.isStopping,
      onUpdate: (update) {
        final current = state.runStates[update.nodeId] ??
            const AgentWorkflowNodeRunState();
        final next = current.copyWith(
          status: update.status,
          inputsByName: update.inputsByName,
          renderedBody: update.renderedBody,
          output: update.output,
          error: update.error,
          durationMs: update.durationMs,
        );
        final updatedMap = Map<String, AgentWorkflowNodeRunState>.from(state.runStates);
        updatedMap[update.nodeId] = next;

        state = state.copyWith(
          runStates: updatedMap,
          finalOutput: update.nodeId == endId && update.output != null
              ? update.output
              : state.finalOutput,
        );
      },
    );

    if (!mounted) return;

    if (result.stopped) {
      state = state.copyWith(isRunning: false, isStopping: false);
      return;
    }

    state = state.copyWith(
      isRunning: false,
      isStopping: false,
      finalOutput: result.finalOutput ?? state.finalOutput,
      error: result.success ? null : (result.error ?? 'Run failed'),
    );
  }
}

final agentWorkflowProvider =
    StateNotifierProvider<AgentWorkflowNotifier, AgentWorkflowState>((ref) {
  return AgentWorkflowNotifier(ref);
});

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

const Object _sentinel = Object();
