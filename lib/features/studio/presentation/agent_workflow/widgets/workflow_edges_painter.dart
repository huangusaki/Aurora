import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../application/agent_workflow/agent_workflow_runner.dart';
import '../../../domain/agent_workflow/agent_workflow_models.dart';
import '../agent_workflow_provider.dart';
import 'workflow_layout.dart';

class WorkflowPortRef {
  final String nodeId;
  final String portId;
  final bool isInput;

  const WorkflowPortRef({
    required this.nodeId,
    required this.portId,
    required this.isInput,
  });
}

class WorkflowEdgesPainter extends CustomPainter {
  final AgentWorkflowTemplate template;
  final Map<String, AgentWorkflowNodeRunState> runStates;
  final Color accentColor;
  final bool isDark;
  final WorkflowPortRef? connectingFrom;
  final Offset? connectingToScene;
  final WorkflowPortRef? hoveredInput;

  WorkflowEdgesPainter({
    required this.template,
    required this.runStates,
    required this.accentColor,
    required this.isDark,
    this.connectingFrom,
    this.connectingToScene,
    this.hoveredInput,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeById = {for (final n in template.nodes) n.id: n};

    for (final edge in template.edges) {
      final fromNode = nodeById[edge.fromNodeId];
      final toNode = nodeById[edge.toNodeId];
      if (fromNode == null || toNode == null) continue;

      final fromIndex = WorkflowLayout.outputIndexOf(fromNode, edge.fromPortId);
      final toIndex = WorkflowLayout.inputIndexOf(toNode, edge.toPortId);
      if (fromIndex < 0 || toIndex < 0) continue;

      final p1 = WorkflowLayout.outputPortCenter(fromNode, fromIndex);
      final p2 = WorkflowLayout.inputPortCenter(toNode, toIndex);

      final status = runStates[fromNode.id]?.status ?? AgentWorkflowNodeRunStatus.idle;
      final color = _edgeColor(status);
      final strokeWidth = status == AgentWorkflowNodeRunStatus.running ? 2.2 : 1.6;
      _drawBezier(canvas, p1, p2, color, strokeWidth);
    }

    // Draft connection line.
    if (connectingFrom != null && connectingToScene != null) {
      final fromNode = nodeById[connectingFrom!.nodeId];
      if (fromNode != null) {
        final fromIndex =
            WorkflowLayout.outputIndexOf(fromNode, connectingFrom!.portId);
        if (fromIndex >= 0) {
          final p1 = WorkflowLayout.outputPortCenter(fromNode, fromIndex);
          final p2 = connectingToScene!;
          _drawBezier(canvas, p1, p2, accentColor.withValues(alpha: 0.85), 2.1,
              dashed: true);
        }
      }
    }

    // Hover highlight on input port target.
    if (hoveredInput != null && hoveredInput!.isInput) {
      final node = nodeById[hoveredInput!.nodeId];
      if (node != null) {
        final idx = WorkflowLayout.inputIndexOf(node, hoveredInput!.portId);
        if (idx >= 0) {
          final center = WorkflowLayout.inputPortCenter(node, idx);
          final paint = Paint()
            ..color = accentColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(center, 12, paint);
        }
      }
    }
  }

  void _drawBezier(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Color color,
    double strokeWidth, {
    bool dashed = false,
  }) {
    final dx = (p2.dx - p1.dx).abs();
    final controlX = math.max(70.0, dx * 0.55);
    final c1 = Offset(p1.dx + controlX, p1.dy);
    final c2 = Offset(p2.dx - controlX, p2.dy);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }

    // Simple dashed path drawing (good enough for MVP).
    const dash = 8.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = math.min(dist + dash, metric.length);
        final extract = metric.extractPath(dist, next);
        canvas.drawPath(extract, paint);
        dist = next + gap;
      }
    }
  }

  Color _edgeColor(AgentWorkflowNodeRunStatus status) {
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
        return isDark
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.22);
    }
  }

  @override
  bool shouldRepaint(covariant WorkflowEdgesPainter oldDelegate) {
    return !mapEquals(oldDelegate.runStates, runStates) ||
        oldDelegate.template != template ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.connectingFrom != connectingFrom ||
        oldDelegate.connectingToScene != connectingToScene ||
        oldDelegate.hoveredInput != hoveredInput;
  }
}
