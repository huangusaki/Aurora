import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../application/agent_workflow/agent_workflow_runner.dart';
import '../../../domain/agent_workflow/agent_workflow_models.dart';
import '../agent_workflow_provider.dart';
import 'workflow_layout.dart';

class WorkflowNodeWidget extends StatelessWidget {
  final AgentWorkflowNode node;
  final AgentWorkflowNodeRunState? runState;
  final bool isSelected;
  final bool isDark;
  final Color accentColor;
  final double sceneScale;
  final String? hoveredInputPortId;

  final VoidCallback onTap;
  final void Function(String nodeId, Offset globalPos) onBeginMoveNode;
  final void Function(Offset globalPos) onUpdateMoveNode;
  final VoidCallback onEndMoveNode;
  final void Function(String nodeId, Offset globalPos)? onShowNodeMenu;

  final void Function(String nodeId, String portId, Offset globalPos)
      onBeginConnection;
  final void Function(Offset globalPos) onUpdateConnection;
  final VoidCallback onEndConnection;

  const WorkflowNodeWidget({
    super.key,
    required this.node,
    required this.runState,
    required this.isSelected,
    required this.isDark,
    required this.accentColor,
    required this.sceneScale,
    required this.onTap,
    required this.onBeginMoveNode,
    required this.onUpdateMoveNode,
    required this.onEndMoveNode,
    this.onShowNodeMenu,
    required this.onBeginConnection,
    required this.onUpdateConnection,
    required this.onEndConnection,
    this.hoveredInputPortId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final status = runState?.status ?? AgentWorkflowNodeRunStatus.idle;
    final statusColor = _statusColor(theme, status);

    final bg = isDark
        ? theme.cardColor.withValues(alpha: 0.98)
        : theme.cardColor.withValues(alpha: 0.94);
    final borderColor = isSelected
        ? accentColor.withValues(alpha: 0.95)
        : theme.resources.surfaceStrokeColorDefault
            .withValues(alpha: isDark ? 0.70 : 0.55);

    final rows = WorkflowLayout.portRowCount(node);
    final height = WorkflowLayout.nodeHeight(node);
    final footerText = _footerText(status);
    final footerPreview = _previewForStatus(status);
    final footerValue = footerPreview ?? footerText;

    return SizedBox(
      width: WorkflowLayout.nodeWidth,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onSecondaryTapUp: (details) => onShowNodeMenu?.call(
            node.id,
            details.globalPosition,
          ),
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                  blurRadius: isSelected ? 18 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(theme, statusColor),
                    for (var i = 0; i < rows; i += 1) _buildPortRow(theme, i),
                    _buildFooter(theme, footerValue, status),
                  ],
                ),
                ..._buildPortCircles(theme, statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FluentThemeData theme, Color statusColor) {
    final icon = _nodeIcon(node.type);
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        onPanStart: (details) =>
            onBeginMoveNode(node.id, details.globalPosition),
        onPanUpdate: (details) => onUpdateMoveNode(details.globalPosition),
        onPanEnd: (details) => onEndMoveNode(),
        onPanCancel: onEndMoveNode,
        child: Container(
          height: WorkflowLayout.headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: theme.accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.bodyStrong,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortRow(FluentThemeData theme, int rowIndex) {
    final inputName = rowIndex < node.inputs.length ? node.inputs[rowIndex].name : '';
    final outputName = rowIndex < node.outputs.length ? node.outputs[rowIndex].name : '';
    final leftPad = WorkflowLayout.portInset + WorkflowLayout.portDiameter + 8;
    final rightPad = leftPad;

    return SizedBox(
      height: WorkflowLayout.portRowHeight,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: leftPad, right: 8),
              child: Text(
                inputName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.caption,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: rightPad, left: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  outputName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    FluentThemeData theme,
    String footerValue,
    AgentWorkflowNodeRunStatus status,
  ) {
    final color = status == AgentWorkflowNodeRunStatus.error
        ? const Color(0xFFE35D6A)
        : theme.typography.caption?.color;
    return Container(
      height: WorkflowLayout.footerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        color: isDark
            ? Colors.black.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.18),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        footerValue,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (theme.typography.caption ?? const TextStyle()).copyWith(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }

  List<Widget> _buildPortCircles(FluentThemeData theme, Color statusColor) {
    final widgets = <Widget>[];
    final baseStroke =
        theme.resources.controlStrokeColorDefault.withValues(alpha: 0.35);

    for (var i = 0; i < node.inputs.length; i += 1) {
      final port = node.inputs[i];
      final isHovered = hoveredInputPortId == port.id;
      widgets.add(Positioned(
        left: WorkflowLayout.inputPortLeft(),
        top: WorkflowLayout.portTop(i),
        child: _portCircle(
          fill: isHovered
              ? accentColor.withValues(alpha: 0.9)
              : Colors.transparent,
          stroke: isHovered ? accentColor : baseStroke,
        ),
      ));
    }

    for (var i = 0; i < node.outputs.length; i += 1) {
      final port = node.outputs[i];
      widgets.add(Positioned(
        right: WorkflowLayout.outputPortRight(),
        top: WorkflowLayout.portTop(i),
        child: MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: GestureDetector(
            onPanStart: (details) =>
                onBeginConnection(node.id, port.id, details.globalPosition),
            onPanUpdate: (details) => onUpdateConnection(details.globalPosition),
            onPanEnd: (details) => onEndConnection(),
            onPanCancel: () => onEndConnection(),
            child: _portCircle(
              fill: statusColor.withValues(alpha: 0.92),
              stroke: baseStroke,
            ),
          ),
        ),
      ));
    }

    return widgets;
  }

  Widget _portCircle({
    required Color fill,
    required Color stroke,
  }) {
    return Container(
      width: WorkflowLayout.portDiameter,
      height: WorkflowLayout.portDiameter,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(WorkflowLayout.portRadius),
        border: Border.all(color: stroke),
      ),
    );
  }

  String _footerText(AgentWorkflowNodeRunStatus status) {
    switch (status) {
      case AgentWorkflowNodeRunStatus.idle:
        return '';
      case AgentWorkflowNodeRunStatus.running:
        return 'Running...';
      case AgentWorkflowNodeRunStatus.success:
        return 'Done';
      case AgentWorkflowNodeRunStatus.error:
        return 'Error';
      case AgentWorkflowNodeRunStatus.stopped:
        return 'Stopped';
    }
  }

  String? _previewForStatus(AgentWorkflowNodeRunStatus status) {
    final value = status == AgentWorkflowNodeRunStatus.error
        ? runState?.error
        : runState?.output;
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final maxChars = status == AgentWorkflowNodeRunStatus.error ? 60 : 80;
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars)}...';
  }

  Color _statusColor(FluentThemeData theme, AgentWorkflowNodeRunStatus status) {
    switch (status) {
      case AgentWorkflowNodeRunStatus.running:
        return accentColor;
      case AgentWorkflowNodeRunStatus.success:
        return isDark ? const Color(0xFF3DDC84) : const Color(0xFF2EAD66);
      case AgentWorkflowNodeRunStatus.error:
        return const Color(0xFFE35D6A);
      case AgentWorkflowNodeRunStatus.stopped:
        return const Color(0xFFF4C07A);
      case AgentWorkflowNodeRunStatus.idle:
        return theme.resources.textFillColorSecondary.withValues(alpha: 0.55);
    }
  }

  IconData _nodeIcon(AgentWorkflowNodeType type) {
    switch (type) {
      case AgentWorkflowNodeType.start:
        return AuroraIcons.play;
      case AgentWorkflowNodeType.end:
        return AuroraIcons.flag;
      case AgentWorkflowNodeType.llm:
        return AuroraIcons.zap;
      case AgentWorkflowNodeType.skill:
        return AuroraIcons.skills;
      case AgentWorkflowNodeType.mcp:
        return AuroraIcons.mcp;
    }
  }
}
