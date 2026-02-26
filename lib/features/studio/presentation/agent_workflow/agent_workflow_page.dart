import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../domain/agent_workflow/agent_workflow_models.dart';
import '../widgets/studio_surface_components.dart';
import 'agent_workflow_provider.dart';
import 'widgets/workflow_canvas.dart';
import 'widgets/workflow_inspector.dart';

class AgentWorkflowPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const AgentWorkflowPage({super.key, this.onBack});

  @override
  ConsumerState<AgentWorkflowPage> createState() => _AgentWorkflowPageState();
}

class _AgentWorkflowPageState extends ConsumerState<AgentWorkflowPage> {
  final _startInputController = TextEditingController();
  final _addNodeFlyout = FlyoutController();

  bool _syncingStartInput = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(agentWorkflowProvider.notifier).load());
  }

  @override
  void dispose() {
    _startInputController.dispose();
    _addNodeFlyout.dispose();
    super.dispose();
  }

  void _syncStartInput(String value) {
    if (_syncingStartInput) return;
    if (_startInputController.text == value) return;
    _syncingStartInput = true;
    _startInputController.text = value;
    _syncingStartInput = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final workflowState = ref.watch(agentWorkflowProvider);
    final notifier = ref.read(agentWorkflowProvider.notifier);
    final settings = ref.watch(settingsProvider);

    final hasBackground = settings.useCustomTheme &&
        (settings.backgroundImagePath?.isNotEmpty ?? false);

    _syncStartInput(workflowState.startInput);

    final template = workflowState.selectedTemplate;
    final selectedNode = (template?.nodes)
        ?.firstWhereOrNull((n) => n.id == workflowState.selectedNodeId);

    final interactionEnabled = !workflowState.isRunning;

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(context, l10n, theme),
          const Divider(),
          _buildToolbar(context, l10n, theme, workflowState, notifier),
          if (workflowState.error?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: InfoBar(
                title: Text(l10n.error),
                content: Text(workflowState.error!),
                severity: InfoBarSeverity.error,
                isLong: true,
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 260,
                    child: StudioPanel(
                      hasBackground: hasBackground,
                      padding: const EdgeInsets.all(12),
                      child: _buildTemplateList(
                        context,
                        l10n,
                        workflowState,
                        notifier,
                        interactionEnabled: interactionEnabled,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StudioPanel(
                      hasBackground: hasBackground,
                      padding: EdgeInsets.zero,
                      clipBehavior: Clip.hardEdge,
                      child: template == null
                          ? StudioEmptyState(
                              icon: AuroraIcons.info,
                              title: l10n.noTemplate,
                              subtitle: l10n.createTemplateHint,
                            )
                          : WorkflowCanvas(
                              template: template,
                              runStates: workflowState.runStates,
                              selectedNodeId: workflowState.selectedNodeId,
                              interactionEnabled: interactionEnabled,
                              onSelectNode: notifier.selectNode,
                              onUpdateNodePosition: notifier.updateNodePosition,
                              onUpdateNodeTitle: notifier.updateNodeTitle,
                              onDeleteNode: notifier.deleteNode,
                              onConnectEdge: ({
                                required fromNodeId,
                                required fromPortId,
                                required toNodeId,
                                required toPortId,
                              }) =>
                                  notifier.connectEdge(
                                fromNodeId: fromNodeId,
                                fromPortId: fromPortId,
                                toNodeId: toNodeId,
                                toPortId: toPortId,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 360,
                    child: WorkflowInspector(
                      template: template ?? const AgentWorkflowTemplate(id: '', name: ''),
                      selectedNode: selectedNode,
                      workflowState: workflowState,
                      hasBackground: hasBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    FluentThemeData theme,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.transparent,
      child: Row(
        children: [
          if (widget.onBack != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(AuroraIcons.back, size: 14),
                onPressed: widget.onBack,
              ),
            ),
          Icon(AuroraIcons.branch, size: 16, color: theme.accentColor),
          const SizedBox(width: 10),
          Text(
            l10n.agentWorkflow,
            style: theme.typography.bodyStrong,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AppLocalizations l10n,
    FluentThemeData theme,
    AgentWorkflowState state,
    AgentWorkflowNotifier notifier,
  ) {
    final canRun = !state.isRunning && state.selectedTemplate != null;
    final canStop = state.isRunning && !state.isStopping;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: InfoLabel(
              label: l10n.startInput,
              child: TextBox(
                controller: _startInputController,
                placeholder: l10n.startInputHint,
                onChanged: (v) {
                  if (_syncingStartInput) return;
                  notifier.setStartInput(v);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: canRun ? notifier.runSelectedTemplate : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AuroraIcons.play, size: 14),
                const SizedBox(width: 6),
                Text(l10n.run),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Button(
            onPressed: canStop ? notifier.stopRun : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AuroraIcons.stop, size: 14),
                const SizedBox(width: 6),
                Text(l10n.stop),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Button(
            onPressed: state.isRunning ? null : notifier.resetRun,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AuroraIcons.reset, size: 14),
                const SizedBox(width: 6),
                Text(l10n.reset),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FlyoutTarget(
            controller: _addNodeFlyout,
            child: Button(
              onPressed: state.isRunning || state.selectedTemplate == null
                  ? null
                  : () async {
                      await _addNodeFlyout.showFlyout<void>(
                        barrierColor: Colors.transparent,
                        placementMode: FlyoutPlacementMode.bottomCenter,
                        builder: (context) => MenuFlyout(
                          items: [
                            MenuFlyoutItem(
                              text: Text(l10n.addLlmNode),
                              onPressed: () {
                                notifier.addNode(AgentWorkflowNodeType.llm);
                              },
                            ),
                            MenuFlyoutItem(
                              text: Text(l10n.addSkillNode),
                              onPressed: () {
                                notifier.addNode(AgentWorkflowNodeType.skill);
                              },
                            ),
                            MenuFlyoutItem(
                              text: Text(l10n.addMcpNode),
                              onPressed: () {
                                notifier.addNode(AgentWorkflowNodeType.mcp);
                              },
                            ),
                          ],
                        ),
                      );
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AuroraIcons.add, size: 14),
                  const SizedBox(width: 6),
                  Text(l10n.addNode),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Button(
            onPressed: state.isRunning
                ? null
                : () async {
                    await notifier.saveNow();
                    if (context.mounted) {
                      showAuroraNotice(
                        context,
                        l10n.saved,
                        icon: AuroraIcons.save,
                      );
                    }
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AuroraIcons.save, size: 14),
                const SizedBox(width: 6),
                Text(l10n.save),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList(
    BuildContext context,
    AppLocalizations l10n,
    AgentWorkflowState state,
    AgentWorkflowNotifier notifier, {
    required bool interactionEnabled,
  }) {
    final theme = FluentTheme.of(context);
    final templates = state.document.templates;

    Future<void> promptCreateTemplate() async {
      final controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: Text(l10n.newTemplate),
          content: TextBox(
            controller: controller,
            placeholder: l10n.templateNameHint,
            autofocus: true,
          ),
          actions: [
            Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(ctx),
            ),
            FilledButton(
              child: Text(l10n.confirm),
              onPressed: () {
                notifier.createTemplate(controller.text);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    }

    Future<void> promptRenameTemplate(AgentWorkflowTemplate template) async {
      final controller = TextEditingController(text: template.name);
      await showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: Text(l10n.renameTemplate),
          content: TextBox(
            controller: controller,
            placeholder: l10n.templateNameHint,
            autofocus: true,
          ),
          actions: [
            Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(ctx),
            ),
            FilledButton(
              child: Text(l10n.confirm),
              onPressed: () {
                notifier.renameTemplate(template.id, controller.text);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    }

    Future<void> confirmDeleteTemplate(AgentWorkflowTemplate template) async {
      await showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: Text(l10n.delete),
          content: Text(l10n.deleteTemplateConfirm(template.name)),
          actions: [
            Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(ctx),
            ),
            FilledButton(
              child: Text(l10n.delete),
              onPressed: () {
                notifier.deleteTemplate(template.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.templates, style: theme.typography.bodyStrong),
            const Spacer(),
            IconButton(
              icon: const Icon(AuroraIcons.add, size: 14),
              onPressed: interactionEnabled ? promptCreateTemplate : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: templates.isEmpty
              ? StudioEmptyState(
                  icon: AuroraIcons.info,
                  title: l10n.noTemplate,
                  subtitle: l10n.createTemplateHint,
                )
              : ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final t = templates[index];
                    final selected = t.id == state.selectedTemplateId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.accentColor.withValues(alpha: 0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? theme.accentColor.withValues(alpha: 0.35)
                                : theme.resources.surfaceStrokeColorDefault
                                    .withValues(alpha: 0.25),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: interactionEnabled
                              ? () => notifier.selectTemplate(t.id)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(AuroraIcons.edit, size: 14),
                                onPressed: interactionEnabled
                                    ? () => promptRenameTemplate(t)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(AuroraIcons.delete, size: 14),
                                onPressed: interactionEnabled
                                    ? () => confirmDeleteTemplate(t)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
