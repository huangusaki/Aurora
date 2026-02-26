import 'package:aurora/features/mcp/domain/mcp_server_config.dart';
import 'package:aurora/features/mcp/presentation/mcp_server_provider.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/skills/domain/skill_entity.dart';
import 'package:aurora/features/skills/presentation/skill_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../domain/agent_workflow/agent_workflow_models.dart';
import '../agent_workflow_provider.dart';

class WorkflowInspector extends ConsumerStatefulWidget {
  final AgentWorkflowTemplate template;
  final AgentWorkflowNode? selectedNode;
  final AgentWorkflowState workflowState;
  final bool hasBackground;

  const WorkflowInspector({
    super.key,
    required this.template,
    required this.selectedNode,
    required this.workflowState,
    this.hasBackground = false,
  });

  @override
  ConsumerState<WorkflowInspector> createState() => _WorkflowInspectorState();
}

class _WorkflowInspectorState extends ConsumerState<WorkflowInspector> {
  final _titleController = TextEditingController();
  final _systemController = TextEditingController();
  final _bodyController = TextEditingController();
  final _mcpToolController = TextEditingController();

  String? _boundNodeId;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant WorkflowInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedNode?.id != widget.selectedNode?.id ||
        oldWidget.selectedNode != widget.selectedNode) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    final node = widget.selectedNode;
    if (node == null) {
      _boundNodeId = null;
      _titleController.text = '';
      _systemController.text = '';
      _bodyController.text = '';
      _mcpToolController.text = '';
      return;
    }
    final nodeId = node.id;
    if (_boundNodeId == nodeId &&
        _titleController.text == (node.title) &&
        _systemController.text == (node.systemPrompt) &&
        _bodyController.text == (node.bodyTemplate) &&
        _mcpToolController.text == (node.mcpToolName ?? '')) {
      return;
    }

    _boundNodeId = nodeId;
    _syncing = true;
    _titleController.text = node.title;
    _systemController.text = node.systemPrompt;
    _bodyController.text = node.bodyTemplate;
    _mcpToolController.text = node.mcpToolName ?? '';
    _syncing = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _systemController.dispose();
    _bodyController.dispose();
    _mcpToolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final node = widget.selectedNode;
    final notifier = ref.read(agentWorkflowProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final skills = ref.watch(skillProvider).skills;
    final mcpServers = ref.watch(mcpServerProvider).servers;

    final isDark = theme.brightness == Brightness.dark;
    final panelBg = widget.hasBackground
        ? theme.cardColor.withValues(alpha: 0.7)
        : theme.cardColor.withValues(alpha: 0.95);

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 10),
          child: Text(text, style: theme.typography.bodyStrong),
        );

    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(k, style: theme.typography.caption),
              ),
              Expanded(
                child: Text(v, style: theme.typography.body),
              ),
            ],
          ),
        );

    Widget readonlyBlock(String label, String value) {
      return InfoLabel(
        label: label,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.resources.subtleFillColorSecondary
                .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.resources.surfaceStrokeColorDefault
                  .withValues(alpha: isDark ? 0.55 : 0.45),
            ),
          ),
          child: SelectableText(
            value,
            style: theme.typography.body,
          ),
        ),
      );
    }

    final nodeRun = node == null ? null : widget.workflowState.runStates[node.id];

    return Container(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.resources.surfaceStrokeColorDefault
                .withValues(alpha: isDark ? 0.6 : 0.5),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(l10n.inspector),
              if (node == null)
                Text(
                  l10n.selectNodeToEdit,
                  style: theme.typography.caption,
                )
              else ...[
                kv(l10n.typeLabel, node.type.name.toUpperCase()),
                InfoLabel(
                  label: l10n.titleLabel,
                  child: TextBox(
                    controller: _titleController,
                    placeholder: l10n.titleLabel,
                    onChanged: (v) {
                      if (_syncing) return;
                      notifier.updateNodeTitle(node.id, v);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (node.type == AgentWorkflowNodeType.llm ||
                    node.type == AgentWorkflowNodeType.skill ||
                    node.type == AgentWorkflowNodeType.mcp) ...[
                  _buildModelPicker(
                    context,
                    settings,
                    current: node.model,
                    onChanged: (val) => notifier.updateNodeModel(node.id, val),
                  ),
                ],
                if (node.type == AgentWorkflowNodeType.llm) ...[
                  const SizedBox(height: 10),
                  InfoLabel(
                    label: l10n.systemPrompt,
                    child: TextBox(
                      controller: _systemController,
                      maxLines: 6,
                      placeholder: l10n.systemPrompt,
                      onChanged: (v) {
                        if (_syncing) return;
                        notifier.updateNodeSystemPrompt(node.id, v);
                      },
                    ),
                  ),
                ],
                if (node.type == AgentWorkflowNodeType.skill) ...[
                  const SizedBox(height: 10),
                  _buildSkillPicker(
                    context,
                    skills,
                    currentSkillId: node.skillId,
                    onChanged: (id) =>
                        notifier.updateSkillNodeSkillId(node.id, id),
                  ),
                ],
                if (node.type == AgentWorkflowNodeType.mcp) ...[
                  const SizedBox(height: 10),
                  _buildMcpServerPicker(
                    context,
                    mcpServers,
                    current: node.mcpServerId,
                    onChanged: (id) =>
                        notifier.updateMcpNodeConfig(node.id, serverId: id),
                  ),
                  const SizedBox(height: 10),
                  InfoLabel(
                    label: l10n.toolName,
                    child: TextBox(
                      controller: _mcpToolController,
                      placeholder: l10n.toolNameHint,
                      onChanged: (v) {
                        if (_syncing) return;
                        notifier.updateMcpNodeConfig(node.id, toolName: v);
                      },
                    ),
                  ),
                ],
                if (node.type != AgentWorkflowNodeType.start &&
                    node.type != AgentWorkflowNodeType.end) ...[
                  const SizedBox(height: 10),
                  InfoLabel(
                    label: l10n.bodyTemplate,
                    child: TextBox(
                      controller: _bodyController,
                      maxLines: 8,
                      placeholder: l10n.bodyTemplateHint,
                      onChanged: (v) {
                        if (_syncing) return;
                        notifier.updateNodeBodyTemplate(node.id, v);
                      },
                    ),
                  ),
                ],
                if (!node.isFixed) ...[
                  const SizedBox(height: 8),
                  _buildPortsSection(context, node),
                  const SizedBox(height: 8),
                  _buildEdgesSection(context, node),
                ],
                if (nodeRun != null) ...[
                  const SizedBox(height: 12),
                  sectionTitle(l10n.debug),
                  kv(l10n.status, nodeRun.status.name),
                  if (nodeRun.durationMs != null)
                    kv(l10n.durationMs, '${nodeRun.durationMs}'),
                  if (nodeRun.error != null && nodeRun.error!.trim().isNotEmpty)
                    readonlyBlock(l10n.error, nodeRun.error ?? ''),
                  if (nodeRun.output != null && nodeRun.output!.trim().isNotEmpty)
                    readonlyBlock(l10n.output, nodeRun.output ?? ''),
                ],
              ],
              const SizedBox(height: 12),
              sectionTitle(l10n.finalOutput),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.resources.subtleFillColorSecondary
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.resources.surfaceStrokeColorDefault
                        .withValues(alpha: isDark ? 0.55 : 0.45),
                  ),
                ),
                child: SelectableText(
                  widget.workflowState.finalOutput?.trim().isNotEmpty == true
                      ? widget.workflowState.finalOutput!
                      : l10n.noOutputYet,
                  style: theme.typography.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelPicker(
    BuildContext context,
    SettingsState settings, {
    required AgentWorkflowModelRef? current,
    required void Function(AgentWorkflowModelRef? value) onChanged,
  }) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final options = <ComboBoxItem<AgentWorkflowModelRef?>>[];
    options.add(ComboBoxItem(
      value: null,
      child: Text(l10n.defaultModelSameAsChat,
          style: theme.typography.caption),
    ));

    for (final provider in settings.providers) {
      if (!provider.isEnabled || provider.models.isEmpty) continue;
      for (final model in provider.models) {
        if (!provider.isModelEnabled(model)) continue;
        options.add(ComboBoxItem(
          value: AgentWorkflowModelRef(providerId: provider.id, modelId: model),
          child: Text('${provider.name} - $model'),
        ));
      }
    }

    AgentWorkflowModelRef? selected;
    if (current != null && current.isValid) {
      selected = options
          .map((e) => e.value)
          .whereType<AgentWorkflowModelRef>()
          .firstWhere(
            (m) =>
                m.providerId == current.providerId && m.modelId == current.modelId,
            orElse: () => current,
          );
    }

    return InfoLabel(
      label: l10n.model,
      child: ComboBox<AgentWorkflowModelRef?>(
        isExpanded: true,
        value: selected,
        items: options,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSkillPicker(
    BuildContext context,
    List<Skill> skills, {
    required String? currentSkillId,
    required void Function(String? id) onChanged,
  }) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final options = <ComboBoxItem<String?>>[
      ComboBoxItem(
        value: null,
        child: Text(l10n.selectSkillHint, style: theme.typography.caption),
      ),
    ];

    for (final s in skills) {
      options.add(ComboBoxItem(
        value: s.id,
        child: Text(s.name),
      ));
    }

    return InfoLabel(
      label: l10n.skill,
      child: ComboBox<String?>(
        isExpanded: true,
        value: currentSkillId,
        items: options,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMcpServerPicker(
    BuildContext context,
    List<McpServerConfig> servers, {
    required String? current,
    required void Function(String? id) onChanged,
  }) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final options = <ComboBoxItem<String?>>[
      ComboBoxItem(
        value: null,
        child: Text(l10n.selectMcpServerHint, style: theme.typography.caption),
      ),
    ];

    for (final s in servers) {
      options.add(ComboBoxItem(
        value: s.id,
        child: Text('${s.enabled ? '' : '[${l10n.disabled}] '}${s.name}'),
      ));
    }

    return InfoLabel(
      label: l10n.mcpServer,
      child: ComboBox<String?>(
        isExpanded: true,
        value: current,
        items: options,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPortsSection(BuildContext context, AgentWorkflowNode node) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(agentWorkflowProvider.notifier);

    Future<void> renamePort({
      required String portId,
      required bool isInput,
      required String current,
    }) async {
      final controller = TextEditingController(text: current);
      await showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: Text(l10n.renamePort),
          content: TextBox(controller: controller, autofocus: true),
          actions: [
            Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(ctx),
            ),
            FilledButton(
              child: Text(l10n.confirm),
              onPressed: () {
                notifier.renamePort(
                  nodeId: node.id,
                  portId: portId,
                  isInput: isInput,
                  newName: controller.text,
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    }

    Widget portList(String title, List<AgentWorkflowPort> ports, bool isInput) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              children: [
                Text(title, style: theme.typography.bodyStrong),
                const Spacer(),
                IconButton(
                  icon: const Icon(AuroraIcons.add, size: 14),
                  onPressed: () {
                    if (isInput) {
                      notifier.addInputPort(node.id);
                    } else {
                      notifier.addOutputPort(node.id);
                    }
                  },
                )
              ],
            ),
          ),
          for (final p in ports)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption,
                    ),
                  ),
                  Tooltip(
                    message: l10n.renamePort,
                    child: IconButton(
                      icon: const Icon(AuroraIcons.edit, size: 14),
                      onPressed: () => renamePort(
                        portId: p.id,
                        isInput: isInput,
                        current: p.name,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: l10n.delete,
                    child: IconButton(
                      icon: const Icon(AuroraIcons.delete, size: 14),
                      onPressed: () =>
                          notifier.deletePort(nodeId: node.id, portId: p.id, isInput: isInput),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        portList(l10n.inputs, node.inputs, true),
        portList(l10n.outputs, node.outputs, false),
      ],
    );
  }

  Widget _buildEdgesSection(BuildContext context, AgentWorkflowNode node) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(agentWorkflowProvider.notifier);

    final nodeById = {for (final n in widget.template.nodes) n.id: n};
    String nodeName(String id) => nodeById[id]?.title ?? id;

    String portName(AgentWorkflowNode? n, String portId, bool isInput) {
      final ports = isInput ? (n?.inputs ?? const []) : (n?.outputs ?? const []);
      return ports.where((p) => p.id == portId).firstOrNull?.name ?? portId;
    }

    final inbound = widget.template.edges
        .where((e) => e.toNodeId == node.id)
        .toList(growable: false);
    final outbound = widget.template.edges
        .where((e) => e.fromNodeId == node.id)
        .toList(growable: false);

    Widget edgeRow({
      required String label,
      required AgentWorkflowEdge edge,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.caption,
              ),
            ),
            Tooltip(
              message: l10n.delete,
              child: IconButton(
                icon: const Icon(AuroraIcons.delete, size: 14),
                onPressed: () => notifier.deleteEdge(edge.id),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(l10n.connections, style: theme.typography.bodyStrong),
        ),
        if (inbound.isNotEmpty) ...[
          Text(l10n.inbound, style: theme.typography.caption),
          const SizedBox(height: 6),
          for (final e in inbound)
            edgeRow(
              edge: e,
              label:
                  '${nodeName(e.fromNodeId)}.${portName(nodeById[e.fromNodeId], e.fromPortId, false)} → ${node.title}.${portName(node, e.toPortId, true)}',
            ),
        ],
        if (outbound.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.outbound, style: theme.typography.caption),
          const SizedBox(height: 6),
          for (final e in outbound)
            edgeRow(
              edge: e,
              label:
                  '${node.title}.${portName(node, e.fromPortId, false)} → ${nodeName(e.toNodeId)}.${portName(nodeById[e.toNodeId], e.toPortId, true)}',
            ),
        ],
        if (inbound.isEmpty && outbound.isEmpty)
          Text(l10n.noConnectionsYet, style: theme.typography.caption),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
