import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../../domain/assistant.dart';
import '../../../../shared/theme/aurora_icons.dart';

class AssistantAvatar extends StatelessWidget {
  final Assistant? assistant;
  final double size;
  final Color? fallbackColor;
  final String? fallbackAvatarPath;

  const AssistantAvatar({
    super.key,
    this.assistant,
    this.size = 40,
    this.fallbackColor,
    this.fallbackAvatarPath,
  });

  @override
  Widget build(BuildContext context) {
    String? path = assistant?.avatar;
    if (path == null || path.isEmpty) {
      path = fallbackAvatarPath;
    }

    if (path != null && path.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(File(path)),
        backgroundColor: Colors.transparent,
      );
    }

    final isFluent = fluent.FluentTheme.maybeOf(context) != null;
    final color = fallbackColor ?? (isFluent 
        ? fluent.FluentTheme.of(context).accentColor 
        : Theme.of(context).primaryColor);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        AuroraIcons.robot,
        size: size * 0.6,
        color: color,
      ),
    );
  }
}
