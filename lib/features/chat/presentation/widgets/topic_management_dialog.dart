import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';

class TopicManagementDialog extends ConsumerStatefulWidget {
  final int? existingTopicId;
  final String? initialName;
  final Function(String) onConfirm;
  const TopicManagementDialog({
    super.key,
    this.existingTopicId,
    this.initialName,
    required this.onConfirm,
  });
  @override
  ConsumerState<TopicManagementDialog> createState() =>
      _TopicManagementDialogState();
}

class _TopicManagementDialogState extends ConsumerState<TopicManagementDialog> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existingTopicId != null;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    if (isWindows) {
      return fluent.ContentDialog(
        title: Text(isEditing ? l10n.editTopic : l10n.createTopic),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            fluent.TextBox(
              controller: _controller,
              placeholder: l10n.topicNamePlaceholder,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          fluent.FilledButton(
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                widget.onConfirm(_controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: Text(isEditing ? l10n.editTopic : l10n.createTopic),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.topicNamePlaceholder,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                widget.onConfirm(_controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      );
    }
  }
}
