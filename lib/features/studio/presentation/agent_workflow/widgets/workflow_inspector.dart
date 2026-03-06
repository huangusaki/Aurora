import 'dart:convert';

import 'package:aurora/features/mcp/domain/mcp_server_config.dart';
import 'package:aurora/features/mcp/presentation/mcp_connection_provider.dart';
import 'package:aurora/features/mcp/presentation/mcp_server_provider.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/skills/domain/skill_entity.dart';
import 'package:aurora/features/skills/presentation/skill_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/services/mcp/mcp_client_session.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../domain/agent_workflow/agent_workflow_json_schema.dart';
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

    final nodeRun =
        node == null ? null : widget.workflowState.runStates[node.id];

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
                  Builder(builder: (context) {
                    final serverId = node.mcpServerId;
                    final selectedServer = serverId == null
                        ? null
                        : mcpServers.where((s) => s.id == serverId).firstOrNull;
                    if (selectedServer == null) {
                      return InfoLabel(
                        label: l10n.toolName,
                        child: TextBox(
                          controller: _mcpToolController,
                          enabled: false,
                          placeholder: l10n.selectMcpServerHint,
                        ),
                      );
                    }

                    return FutureBuilder<List<McpTool>>(
                      future: ref
                          .read(mcpConnectionProvider.notifier)
                          .listTools(selectedServer),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return InfoLabel(
                            label: l10n.toolName,
                            child: const ProgressBar(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoBar(
                                title: Text(l10n.error),
                                content: Text(snapshot.error.toString()),
                                severity: InfoBarSeverity.error,
                                isLong: true,
                              ),
                              const SizedBox(height: 8),
                              InfoLabel(
                                label: l10n.toolName,
                                child: TextBox(
                                  controller: _mcpToolController,
                                  placeholder: l10n.toolNameHint,
                                  onChanged: (v) {
                                    if (_syncing) return;
                                    notifier.updateMcpNodeConfig(
                                      node.id,
                                      toolName: v,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }

                        final tools = (snapshot.data ?? const <McpTool>[])
                            .where((t) => t.name.trim().isNotEmpty)
                            .toList(growable: false)
                          ..sort((a, b) => a.name.compareTo(b.name));

                        final items = <ComboBoxItem<String?>>[
                          ComboBoxItem(
                            value: null,
                            child: Text(
                              l10n.selectMcpToolHint,
                              style: theme.typography.caption,
                            ),
                          ),
                          for (final t in tools)
                            ComboBoxItem(
                              value: t.name,
                              child: Text(t.name),
                            ),
                        ];

                        final currentName = node.mcpToolName;
                        final selectedName =
                            tools.any((t) => t.name == currentName)
                                ? currentName
                                : null;
                        final selectedTool = selectedName == null
                            ? null
                            : tools.firstWhere((t) => t.name == selectedName);
                        final schemaPretty = selectedTool != null
                            ? const JsonEncoder.withIndent('  ')
                                .convert(selectedTool.inputSchema)
                            : (node.mcpToolInputSchema != null
                                ? const JsonEncoder.withIndent('  ')
                                    .convert(node.mcpToolInputSchema)
                                : null);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoLabel(
                              label: l10n.toolName,
                              child: ComboBox<String?>(
                                isExpanded: true,
                                value: selectedName,
                                items: items,
                                onChanged: (val) {
                                  if (val == null) {
                                    notifier.updateMcpNodeConfig(
                                      node.id,
                                      toolName: null,
                                      toolInputSchema: null,
                                    );
                                    return;
                                  }

                                  final tool = tools.firstWhere(
                                    (t) => t.name == val,
                                    orElse: () => tools.first,
                                  );
                                  notifier.updateMcpNodeConfig(
                                    node.id,
                                    toolName: tool.name,
                                    toolInputSchema: tool.inputSchema,
                                  );
                                },
                              ),
                            ),
                            if (schemaPretty != null) ...[
                              const SizedBox(height: 10),
                              readonlyBlock(
                                  l10n.mcpToolInputSchema, schemaPretty),
                            ],
                          ],
                        );
                      },
                    );
                  }),
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
                const SizedBox(height: 10),
                _buildValidationSection(context, node),
                if (node.type == AgentWorkflowNodeType.llm) ...[
                  const SizedBox(height: 10),
                  _buildStructuredOutputSection(context, node),
                ],
                const SizedBox(height: 8),
                _buildPortsSection(context, node),
                if (!node.isFixed) ...[
                  const SizedBox(height: 8),
                  _buildEdgesSection(context, node),
                ],
                if (nodeRun != null) ...[
                  const SizedBox(height: 12),
                  sectionTitle(l10n.debug),
                  kv(l10n.status, nodeRun.status.name),
                  if (nodeRun.durationMs != null)
                    kv(l10n.durationMs, '${nodeRun.durationMs}'),
                  if (nodeRun.warnings.isNotEmpty)
                    InfoBar(
                      title: Text(l10n.warnings),
                      content: Text(nodeRun.warnings.join('\n')),
                      severity: InfoBarSeverity.warning,
                      isLong: true,
                    ),
                  if (nodeRun.error != null && nodeRun.error!.trim().isNotEmpty)
                    readonlyBlock(l10n.error, nodeRun.error ?? ''),
                  if (nodeRun.output != null &&
                      nodeRun.output!.trim().isNotEmpty)
                    readonlyBlock(l10n.output, nodeRun.output ?? ''),
                  if (nodeRun.outputJsonPretty != null &&
                      nodeRun.outputJsonPretty!.trim().isNotEmpty)
                    readonlyBlock(
                        l10n.outputJsonPretty, nodeRun.outputJsonPretty ?? ''),
                  if (nodeRun.rawOutput != null &&
                      nodeRun.rawOutput!.trim().isNotEmpty)
                    readonlyBlock(l10n.rawOutput, nodeRun.rawOutput ?? ''),
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
      child: Text(l10n.defaultModelSameAsChat, style: theme.typography.caption),
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
                m.providerId == current.providerId &&
                m.modelId == current.modelId,
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

  Widget _buildValidationSection(BuildContext context, AgentWorkflowNode node) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(agentWorkflowProvider.notifier);

    String modeLabel(AgentWorkflowValidationMode mode) {
      switch (mode) {
        case AgentWorkflowValidationMode.off:
          return l10n.validationOff;
        case AgentWorkflowValidationMode.warn:
          return l10n.validationWarn;
        case AgentWorkflowValidationMode.strict:
          return l10n.validationStrict;
      }
    }

    List<ComboBoxItem<AgentWorkflowValidationMode>> modeItems() {
      return [
        for (final mode in AgentWorkflowValidationMode.values)
          ComboBoxItem(
            value: mode,
            child: Text(modeLabel(mode), style: theme.typography.caption),
          ),
      ];
    }

    final showInput = node.inputs.isNotEmpty;
    final showOutput = node.outputs.isNotEmpty;
    if (!showInput && !showOutput) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.validation, style: theme.typography.bodyStrong),
        if (showInput) ...[
          const SizedBox(height: 6),
          InfoLabel(
            label: l10n.inputValidation,
            child: ComboBox<AgentWorkflowValidationMode>(
              isExpanded: true,
              value: node.inputValidation,
              items: modeItems(),
              onChanged: (val) {
                if (val == null) return;
                notifier.updateNodeValidation(node.id, inputValidation: val);
              },
            ),
          ),
        ],
        if (showOutput) ...[
          const SizedBox(height: 10),
          InfoLabel(
            label: l10n.outputValidation,
            child: ComboBox<AgentWorkflowValidationMode>(
              isExpanded: true,
              value: node.outputValidation,
              items: modeItems(),
              onChanged: (val) {
                if (val == null) return;
                notifier.updateNodeValidation(node.id, outputValidation: val);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStructuredOutputSection(
      BuildContext context, AgentWorkflowNode node) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(agentWorkflowProvider.notifier);

    final primaryOutput = node.outputs
        .where((p) => p.name.trim().toLowerCase() != 'error')
        .firstOrNull;
    final schema = primaryOutput?.schema;

    final issues = <String>[];
    if (primaryOutput == null) {
      issues.add(l10n.structuredOutputMissingPrimaryPort);
    } else {
      if (primaryOutput.valueType != AgentWorkflowPortValueType.json) {
        issues.add(l10n.structuredOutputRequiresJsonPort(primaryOutput.name));
      }
      if (schema == null) {
        issues.add(l10n.structuredOutputRequiresSchema(primaryOutput.name));
      } else if (schema['type'] != 'object') {
        issues
            .add(l10n.structuredOutputRequiresObjectSchema(primaryOutput.name));
      }
    }

    final attempts = node.autoRepairAttempts.clamp(0, 5).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.structuredOutput, style: theme.typography.bodyStrong),
        const SizedBox(height: 6),
        ToggleSwitch(
          checked: node.structuredOutput,
          content: Text(l10n.structuredOutput),
          onChanged: (val) {
            notifier.updateNodeStructuredOutput(
              node.id,
              structuredOutput: val,
            );
          },
        ),
        if (node.structuredOutput) ...[
          const SizedBox(height: 10),
          InfoLabel(
            label: l10n.autoRepairAttempts,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(AuroraIcons.minus, size: 14),
                  onPressed: attempts <= 0
                      ? null
                      : () => notifier.updateNodeStructuredOutput(
                            node.id,
                            autoRepairAttempts: attempts - 1,
                          ),
                ),
                const SizedBox(width: 6),
                Text('$attempts', style: theme.typography.body),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(AuroraIcons.add, size: 14),
                  onPressed: attempts >= 5
                      ? null
                      : () => notifier.updateNodeStructuredOutput(
                            node.id,
                            autoRepairAttempts: attempts + 1,
                          ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.structuredOutputHint, style: theme.typography.caption),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 10),
            InfoBar(
              title: Text(l10n.warning),
              content: Text(issues.join('\n')),
              severity: InfoBarSeverity.warning,
              isLong: true,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPortsSection(BuildContext context, AgentWorkflowNode node) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(agentWorkflowProvider.notifier);

    String valueTypeLabel(AgentWorkflowPortValueType type) {
      switch (type) {
        case AgentWorkflowPortValueType.text:
          return l10n.typeText;
        case AgentWorkflowPortValueType.json:
          return l10n.typeJson;
      }
    }

    Future<void> editPort({
      required AgentWorkflowPort port,
      required bool isInput,
    }) async {
      final isErrorOutput = !isInput && port.name.trim() == 'error';
      if (isErrorOutput) return;

      final canEditName = !node.isFixed;
      final nameController = TextEditingController(text: port.name);
      final schemaController = TextEditingController(
        text: port.schema == null
            ? ''
            : const JsonEncoder.withIndent('  ').convert(port.schema),
      );

      var valueType = port.valueType;
      Map<String, dynamic>? parsedSchema = port.schema;
      String? schemaError;

      void validateSchema(String text) {
        final raw = text.trim();
        if (raw.isEmpty) {
          parsedSchema = null;
          schemaError = null;
          return;
        }

        dynamic decoded;
        try {
          decoded = jsonDecode(raw);
        } catch (e) {
          schemaError = '${l10n.invalidJson}: $e';
          return;
        }
        if (decoded is! Map) {
          schemaError = l10n.schemaMustBeObject;
          return;
        }
        final schema = decoded.map((k, v) => MapEntry('$k', v));
        try {
          AgentWorkflowJsonSchema.validateInstance(
              schema: schema, instance: null);
        } catch (e) {
          schemaError = '${l10n.invalidSchema}: $e';
          return;
        }

        parsedSchema = schema;
        schemaError = null;
      }

      validateSchema(schemaController.text);

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            final nameOk =
                !canEditName || nameController.text.trim().isNotEmpty;
            final canSave = nameOk && schemaError == null;

            return ContentDialog(
              title: Text(l10n.portConfig),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoLabel(
                    label: l10n.name,
                    child: TextBox(
                      controller: nameController,
                      enabled: canEditName,
                      placeholder: l10n.name,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InfoLabel(
                    label: l10n.valueType,
                    child: ComboBox<AgentWorkflowPortValueType>(
                      isExpanded: true,
                      value: valueType,
                      items: [
                        ComboBoxItem(
                          value: AgentWorkflowPortValueType.text,
                          child: Text(l10n.typeText),
                        ),
                        ComboBoxItem(
                          value: AgentWorkflowPortValueType.json,
                          child: Text(l10n.typeJson),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          valueType = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  InfoLabel(
                    label: l10n.schemaJson,
                    child: TextBox(
                      controller: schemaController,
                      maxLines: 8,
                      placeholder: l10n.schemaJsonHint,
                      onChanged: (v) {
                        setState(() {
                          validateSchema(v);
                        });
                      },
                    ),
                  ),
                  if (schemaError != null) ...[
                    const SizedBox(height: 10),
                    InfoBar(
                      title: Text(l10n.error),
                      content: Text(schemaError!),
                      severity: InfoBarSeverity.error,
                      isLong: true,
                    ),
                  ],
                ],
              ),
              actions: [
                Button(
                  child: Text(l10n.cancel),
                  onPressed: () => Navigator.pop(ctx),
                ),
                FilledButton(
                  onPressed: canSave
                      ? () {
                          notifier.updatePortConfig(
                            nodeId: node.id,
                            portId: port.id,
                            isInput: isInput,
                            name: nameController.text.trim(),
                            valueType: valueType,
                            schema: parsedSchema,
                          );
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
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
                  onPressed: node.isFixed
                      ? null
                      : () {
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
                  Text(
                    valueTypeLabel(p.valueType),
                    style: (theme.typography.caption ?? const TextStyle())
                        .copyWith(
                      color: theme.resources.textFillColorSecondary
                          .withValues(alpha: 0.9),
                    ),
                  ),
                  if (p.schema != null) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: l10n.schemaJson,
                      child: Icon(
                        AuroraIcons.parameter,
                        size: 12,
                        color: theme.resources.textFillColorSecondary
                            .withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  Tooltip(
                    message: l10n.portConfig,
                    child: IconButton(
                      icon: const Icon(AuroraIcons.edit, size: 14),
                      onPressed: (!isInput && p.name.trim() == 'error')
                          ? null
                          : () => editPort(port: p, isInput: isInput),
                    ),
                  ),
                  Tooltip(
                    message: l10n.delete,
                    child: IconButton(
                      icon: const Icon(AuroraIcons.delete, size: 14),
                      onPressed:
                          node.isFixed || (!isInput && p.name.trim() == 'error')
                              ? null
                              : () => notifier.deletePort(
                                    nodeId: node.id,
                                    portId: p.id,
                                    isInput: isInput,
                                  ),
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
      final ports =
          isInput ? (n?.inputs ?? const []) : (n?.outputs ?? const []);
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
