import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:aurora/l10n/app_localizations.dart';
import '../../domain/backup_options.dart';
import 'backup_options_selector.dart';

class BackupOptionsDialog extends StatefulWidget {
  final String title;

  const BackupOptionsDialog({
    super.key,
    required this.title,
  });

  @override
  State<BackupOptionsDialog> createState() => _BackupOptionsDialogState();
}

class _BackupOptionsDialogState extends State<BackupOptionsDialog> {
  BackupOptions _options = const BackupOptions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return fluent.ContentDialog(
      title: Text(widget.title),
      content: BackupOptionsSelector(
        options: _options,
        onChanged: (newOptions) {
          setState(() {
            _options = newOptions;
          });
        },
        isFluent: true,
      ),
      actions: [
        fluent.Button(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
        fluent.FilledButton(
          child: Text(l10n.confirm),
          onPressed: _options.isNoneSelected
              ? null
              : () => Navigator.pop(context, _options),
        ),
      ],
    );
  }
}
