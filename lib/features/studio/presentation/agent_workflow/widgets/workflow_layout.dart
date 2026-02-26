import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../domain/agent_workflow/agent_workflow_models.dart';

class WorkflowLayout {
  static const double nodeWidth = 280;
  static const double headerHeight = 34;
  static const double portRowHeight = 22;
  static const double footerHeight = 24;

  static const double portDiameter = 10;
  static const double portRadius = portDiameter / 2;
  static const double portInset = 6;
  static const double portHitRadius = 14;

  static int portRowCount(AgentWorkflowNode node) {
    return math.max(node.inputs.length, node.outputs.length);
  }

  static double nodeHeight(AgentWorkflowNode node) {
    return headerHeight + (portRowCount(node) * portRowHeight) + footerHeight;
  }

  static Rect nodeRect(AgentWorkflowNode node) {
    return Rect.fromLTWH(node.x, node.y, nodeWidth, nodeHeight(node));
  }

  static double _portTop(int index) {
    return headerHeight + (index * portRowHeight) + (portRowHeight - portDiameter) / 2;
  }

  static Offset inputPortCenter(AgentWorkflowNode node, int inputIndex) {
    return Offset(
      node.x + portInset + portRadius,
      node.y + _portTop(inputIndex) + portRadius,
    );
  }

  static Offset outputPortCenter(AgentWorkflowNode node, int outputIndex) {
    return Offset(
      node.x + nodeWidth - portInset - portRadius,
      node.y + _portTop(outputIndex) + portRadius,
    );
  }

  static double inputPortLeft() => portInset;

  static double outputPortRight() => portInset;

  static double portTop(int index) => _portTop(index);

  static int inputIndexOf(AgentWorkflowNode node, String portId) {
    for (var i = 0; i < node.inputs.length; i += 1) {
      if (node.inputs[i].id == portId) return i;
    }
    return -1;
  }

  static int outputIndexOf(AgentWorkflowNode node, String portId) {
    for (var i = 0; i < node.outputs.length; i += 1) {
      if (node.outputs[i].id == portId) return i;
    }
    return -1;
  }
}

