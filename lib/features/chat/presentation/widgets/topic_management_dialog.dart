import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_legacy.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuroraBottomSheet.buildTitle(
            context, isEditing ? l10n.editTopic : l10n.createTopic),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: l10n.topicNamePlaceholder,
              hintText: l10n.topicNamePlaceholder,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      widget.onConfirm(_controller.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.confirm),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


