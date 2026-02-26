import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart';

import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';

import '../../../domain/agent_workflow/agent_workflow_models.dart';
import '../agent_workflow_provider.dart';
import 'workflow_edges_painter.dart';
import 'workflow_layout.dart';
import 'workflow_node_widget.dart';

class WorkflowCanvas extends StatefulWidget {
  final AgentWorkflowTemplate template;
  final Map<String, AgentWorkflowNodeRunState> runStates;
  final String? selectedNodeId;
  final bool interactionEnabled;

  final void Function(String? nodeId) onSelectNode;
  final void Function(String nodeId, double x, double y) onUpdateNodePosition;
  final void Function(String nodeId, String title) onUpdateNodeTitle;
  final void Function(String nodeId) onDeleteNode;
  final void Function({
    required String fromNodeId,
    required String fromPortId,
    required String toNodeId,
    required String toPortId,
  }) onConnectEdge;

  const WorkflowCanvas({
    super.key,
    required this.template,
    required this.runStates,
    required this.selectedNodeId,
    required this.onSelectNode,
    required this.onUpdateNodePosition,
    required this.onUpdateNodeTitle,
    required this.onDeleteNode,
    required this.onConnectEdge,
    this.interactionEnabled = true,
  });

  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  final TransformationController _controller = TransformationController();
  final GlobalKey _viewerKey = GlobalKey();
  final FlyoutController _nodeMenuController = FlyoutController();

  static const double _minSceneWidth = 3600;
  static const double _minSceneHeight = 2200;
  static const double _scenePadding = 600;

  WorkflowPortRef? _connectingFrom;
  Offset? _connectingToScene;
  WorkflowPortRef? _hoveredInput;
  Offset? _lastPointerGlobal;

  String? _draggingNodeId;
  Offset? _draggingNodeScenePos;
  Offset? _dragLastPointerScene;

  @override
  void dispose() {
    _controller.dispose();
    _nodeMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<Matrix4>(
      valueListenable: _controller,
      builder: (context, value, child) {
        final scale = _controller.value.getMaxScaleOnAxis();
        final renderTemplate = _templateForRender();
        final sceneSize = _computeSceneSize(renderTemplate);
        final panEnabled =
            _draggingNodeId == null && _connectingFrom == null;

        return FlyoutTarget(
          controller: _nodeMenuController,
          child: Container(
            key: _viewerKey,
            color: Colors.transparent,
            child: InteractiveViewer(
              transformationController: _controller,
              constrained: false,
              minScale: 0.3,
            maxScale: 2.5,
            panEnabled: panEnabled,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: SizedBox(
              width: sceneSize.width,
              height: sceneSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                        painter: _WorkflowGridPainter(
                          isDark: isDark,
                          accentColor: theme.accentColor,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WorkflowEdgesPainter(
                          template: renderTemplate,
                          runStates: widget.runStates,
                          accentColor: theme.accentColor,
                          isDark: isDark,
                          connectingFrom: _connectingFrom,
                          connectingToScene: _connectingToScene,
                          hoveredInput: _hoveredInput,
                        ),
                      ),
                    ),
                    for (final node in renderTemplate.nodes)
                      Positioned(
                        left: node.x,
                        top: node.y,
                        child: WorkflowNodeWidget(
                          node: node,
                          runState: widget.runStates[node.id],
                          isSelected: widget.selectedNodeId == node.id,
                          isDark: isDark,
                          accentColor: theme.accentColor,
                          sceneScale: scale,
                          hoveredInputPortId: _hoveredInput?.nodeId == node.id
                              ? _hoveredInput?.portId
                              : null,
                          onTap: () => widget.onSelectNode(node.id),
                          onBeginMoveNode: widget.interactionEnabled
                              ? _beginNodeDrag
                              : (_, __) {},
                          onUpdateMoveNode: widget.interactionEnabled
                              ? _updateNodeDrag
                              : (_) {},
                          onEndMoveNode: widget.interactionEnabled
                              ? _endNodeDrag
                              : () {},
                          onShowNodeMenu: widget.interactionEnabled
                              ? _showNodeMenu
                              : null,
                          onBeginConnection: widget.interactionEnabled
                              ? _beginConnection
                              : (_, __, ___) {},
                          onUpdateConnection: widget.interactionEnabled
                              ? _updateConnection
                              : (_) {},
                          onEndConnection: widget.interactionEnabled
                              ? _endConnection
                              : () {},
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Size _computeSceneSize(AgentWorkflowTemplate template) {
    var width = _minSceneWidth;
    var height = _minSceneHeight;

    for (final node in template.nodes) {
      final right = node.x + WorkflowLayout.nodeWidth + _scenePadding;
      final bottom = node.y + WorkflowLayout.nodeHeight(node) + _scenePadding;
      width = math.max(width, right);
      height = math.max(height, bottom);
    }

    // Prevent pathological values.
    if (!width.isFinite || width.isNaN) width = _minSceneWidth;
    if (!height.isFinite || height.isNaN) height = _minSceneHeight;

    return Size(width, height);
  }

  AgentWorkflowTemplate _templateForRender() {
    final draggingId = _draggingNodeId;
    final scenePos = _draggingNodeScenePos;
    if (draggingId == null || scenePos == null) {
      return widget.template;
    }

    final nodes = widget.template.nodes
        .map((n) => n.id == draggingId ? n.copyWith(x: scenePos.dx, y: scenePos.dy) : n)
        .toList(growable: false);
    return widget.template.copyWith(nodes: nodes);
  }

  void _beginNodeDrag(String nodeId, Offset globalPos) {
    final scene = _globalToScene(globalPos);
    if (scene == null) return;

    AgentWorkflowNode? node;
    for (final n in widget.template.nodes) {
      if (n.id == nodeId) {
        node = n;
        break;
      }
    }
    if (node == null) return;

    widget.onSelectNode(nodeId);
    setState(() {
      _draggingNodeId = nodeId;
      _draggingNodeScenePos = Offset(node!.x, node.y);
      _dragLastPointerScene = scene;
    });
  }

  void _updateNodeDrag(Offset globalPos) {
    final nodeId = _draggingNodeId;
    final lastScene = _dragLastPointerScene;
    final nodePos = _draggingNodeScenePos;
    if (nodeId == null || lastScene == null || nodePos == null) return;

    final scene = _globalToScene(globalPos);
    if (scene == null) return;

    final delta = scene - lastScene;
    if (delta == Offset.zero) return;
    setState(() {
      _dragLastPointerScene = scene;
      _draggingNodeScenePos = nodePos + delta;
    });
  }

  void _endNodeDrag() {
    final nodeId = _draggingNodeId;
    final nodePos = _draggingNodeScenePos;
    if (nodeId == null || nodePos == null) {
      setState(() {
        _draggingNodeId = null;
        _draggingNodeScenePos = null;
        _dragLastPointerScene = null;
      });
      return;
    }

    widget.onUpdateNodePosition(
      nodeId,
      math.max(0, nodePos.dx),
      math.max(0, nodePos.dy),
    );
    setState(() {
      _draggingNodeId = null;
      _draggingNodeScenePos = null;
      _dragLastPointerScene = null;
    });
  }

  void _showNodeMenu(String nodeId, Offset globalPos) {
    AgentWorkflowNode? node;
    for (final n in widget.template.nodes) {
      if (n.id == nodeId) {
        node = n;
        break;
      }
    }
    if (node == null) return;

    widget.onSelectNode(nodeId);
    final l10n = AppLocalizations.of(context)!;

    _nodeMenuController.showFlyout(
      position: globalPos,
      builder: (ctx) {
        return MenuFlyout(
          items: [
            MenuFlyoutItem(
              leading: const Icon(AuroraIcons.edit, size: 14),
              text: Text(l10n.renameSession),
              onPressed: () {
                Flyout.of(ctx).close();
                _promptRenameNode(node!);
              },
            ),
            MenuFlyoutItem(
              leading: const Icon(AuroraIcons.delete, size: 14),
              text: Text(l10n.delete),
              onPressed: node!.isFixed
                  ? null
                  : () {
                      Flyout.of(ctx).close();
                      _confirmDeleteNode(node!);
                    },
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptRenameNode(AgentWorkflowNode node) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: node.title);
    try {
      await showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: Text(l10n.renameSession),
          content: TextBox(
            controller: controller,
            autofocus: true,
            placeholder: l10n.renameSessionHint,
          ),
          actions: [
            Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(ctx),
            ),
            FilledButton(
              child: Text(l10n.confirm),
              onPressed: () {
                widget.onUpdateNodeTitle(node.id, controller.text);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmDeleteNode(AgentWorkflowNode node) async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteNodeConfirm(node.title)),
        actions: [
          Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            child: Text(l10n.delete),
            onPressed: () {
              widget.onDeleteNode(node.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _beginConnection(String nodeId, String portId, Offset globalPos) {
    _lastPointerGlobal = globalPos;
    final scene = _globalToScene(globalPos);
    setState(() {
      _connectingFrom = WorkflowPortRef(nodeId: nodeId, portId: portId, isInput: false);
      _connectingToScene = scene;
      _hoveredInput = scene == null ? null : _hitTestInput(scene);
    });
  }

  void _updateConnection(Offset globalPos) {
    _lastPointerGlobal = globalPos;
    final scene = _globalToScene(globalPos);
    if (scene == null) return;
    setState(() {
      _connectingToScene = scene;
      _hoveredInput = _hitTestInput(scene);
    });
  }

  void _endConnection() {
    if (_connectingFrom == null) return;
    final globalPos = _lastPointerGlobal;
    final scene = globalPos == null ? _connectingToScene : _globalToScene(globalPos);
    final target = scene == null ? null : _hitTestInput(scene);

    if (target != null) {
      widget.onConnectEdge(
        fromNodeId: _connectingFrom!.nodeId,
        fromPortId: _connectingFrom!.portId,
        toNodeId: target.nodeId,
        toPortId: target.portId,
      );
    }

    setState(() {
      _connectingFrom = null;
      _connectingToScene = null;
      _hoveredInput = null;
      _lastPointerGlobal = null;
    });
  }

  Offset? _globalToScene(Offset global) {
    final ctx = _viewerKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox) return null;
    final local = box.globalToLocal(global);
    return _controller.toScene(local);
  }

  WorkflowPortRef? _hitTestInput(Offset scene) {
    WorkflowPortRef? best;
    double bestDist = double.infinity;

    for (final node in _templateForRender().nodes) {
      if (node.type == AgentWorkflowNodeType.start) continue;
      for (var i = 0; i < node.inputs.length; i += 1) {
        final port = node.inputs[i];
        final center = WorkflowLayout.inputPortCenter(node, i);
        final d = (scene - center).distance;
        if (d <= WorkflowLayout.portHitRadius && d < bestDist) {
          bestDist = d;
          best = WorkflowPortRef(nodeId: node.id, portId: port.id, isInput: true);
        }
      }
    }

    return best;
  }
}

class _WorkflowGridPainter extends CustomPainter {
  final bool isDark;
  final Color accentColor;

  _WorkflowGridPainter({
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    final major = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.055 : 0.045)
      ..strokeWidth = 1.0;

    const grid = 24.0;
    const majorEvery = 5;

    for (double x = 0; x <= size.width; x += grid) {
      final p = (x / grid).round();
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        p % majorEvery == 0 ? major : minor,
      );
    }
    for (double y = 0; y <= size.height; y += grid) {
      final p = (y / grid).round();
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        p % majorEvery == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorkflowGridPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.accentColor != accentColor;
  }
}
