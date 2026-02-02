import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../domain/message.dart';

abstract class DisplayItem {
  String get id;
}

class SingleMessageItem extends DisplayItem {
  final Message message;
  SingleMessageItem(this.message);
  @override
  String get id => message.id;
}

class MergedGroupItem extends DisplayItem {
  final List<Message> messages;
  MergedGroupItem(this.messages);
  @override
  String get id => messages.first.id;
  Message get latestMessage => messages.last;
}

Future<Directory> getAttachmentsDir() async {
  final appDir = await getApplicationSupportDirectory();
  final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
  if (!await attachmentsDir.exists()) {
    await attachmentsDir.create(recursive: true);
  }
  return attachmentsDir;
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const ActionButton(
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return fluent.Tooltip(
      message: tooltip,
      child: fluent.IconButton(
        icon: fluent.Icon(icon, size: 14),
        onPressed: onPressed,
      ),
    );
  }
}

class MobileActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  const MobileActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        onPressed: onPressed,
      ),
    );
  }
}
