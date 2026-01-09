import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:path_provider/path_provider.dart';
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

/// Returns a persistent directory for storing user-uploaded attachments.
/// Creates the directory if it doesn't exist.
Future<Directory> getAttachmentsDir() async {
  final appDir = await getApplicationDocumentsDirectory();
  final attachmentsDir = Directory('${appDir.path}${Platform.pathSeparator}Aurora${Platform.pathSeparator}attachments');
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
      {super.key, required this.icon, required this.tooltip, required this.onPressed});
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
  const MobileActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: Colors.grey[600]),
        onPressed: onPressed,
      ),
    );
  }
}
