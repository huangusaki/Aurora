import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:aurora/l10n/app_localizations.dart';
import '../../domain/backup_options.dart';

class BackupOptionsSelector extends StatelessWidget {
  final BackupOptions options;
  final ValueChanged<BackupOptions> onChanged;
  final bool isFluent;

  const BackupOptionsSelector({
    super.key,
    required this.options,
    required this.onChanged,
    this.isFluent = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isFluent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          fluent.Checkbox(
            checked: options.includeChatHistory,
            onChanged: (v) =>
                onChanged(options.copyWith(includeChatHistory: v)),
            content: Text(l10n.backupChatHistory),
          ),
          const SizedBox(height: 12),
          fluent.Checkbox(
            checked: options.includeChatPresets,
            onChanged: (v) =>
                onChanged(options.copyWith(includeChatPresets: v)),
            content: Text(l10n.backupChatPresets),
          ),
          const SizedBox(height: 12),
          fluent.Checkbox(
            checked: options.includeProviderConfigs,
            onChanged: (v) =>
                onChanged(options.copyWith(includeProviderConfigs: v)),
            content: Text(l10n.backupProviderConfigs),
          ),
          const SizedBox(height: 12),
          fluent.Checkbox(
            checked: options.includeStudioContent,
            onChanged: (v) =>
                onChanged(options.copyWith(includeStudioContent: v)),
            content: Text(l10n.backupStudioContent),
          ),
          const SizedBox(height: 12),
          fluent.Checkbox(
            checked: options.includeAppSettings,
            onChanged: (v) =>
                onChanged(options.copyWith(includeAppSettings: v)),
            content: Text(l10n.backupAppSettings),
          ),
          const SizedBox(height: 12),
          fluent.Checkbox(
            checked: options.includeAssistants,
            onChanged: (v) => onChanged(options.copyWith(includeAssistants: v)),
            content: Text(l10n.backupAssistants),
          ),
          const SizedBox(height: 12),
          fluent.Checkbox(
            checked: options.includeKnowledgeBases,
            onChanged: (v) =>
                onChanged(options.copyWith(includeKnowledgeBases: v)),
            content: Text(l10n.backupKnowledgeBases),
          ),
          const SizedBox(height: 12),
          fluent.Checkbox(
            checked: options.includeUsageStats,
            onChanged: (v) => onChanged(options.copyWith(includeUsageStats: v)),
            content: Text(l10n.backupUsageStats),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          title: Text(l10n.backupChatHistory),
          value: options.includeChatHistory,
          onChanged: (v) =>
              onChanged(options.copyWith(includeChatHistory: v ?? false)),
        ),
        CheckboxListTile(
          title: Text(l10n.backupChatPresets),
          value: options.includeChatPresets,
          onChanged: (v) =>
              onChanged(options.copyWith(includeChatPresets: v ?? false)),
        ),
        CheckboxListTile(
          title: Text(l10n.backupProviderConfigs),
          value: options.includeProviderConfigs,
          onChanged: (v) =>
              onChanged(options.copyWith(includeProviderConfigs: v ?? false)),
        ),
        CheckboxListTile(
          title: Text(l10n.backupStudioContent),
          value: options.includeStudioContent,
          onChanged: (v) =>
              onChanged(options.copyWith(includeStudioContent: v ?? false)),
        ),
        CheckboxListTile(
          title: Text(l10n.backupAppSettings),
          value: options.includeAppSettings,
          onChanged: (v) =>
              onChanged(options.copyWith(includeAppSettings: v ?? false)),
        ),
        CheckboxListTile(
          title: Text(l10n.backupAssistants),
          value: options.includeAssistants,
          onChanged: (v) =>
              onChanged(options.copyWith(includeAssistants: v ?? false)),
        ),
        CheckboxListTile(
          title: Text(l10n.backupKnowledgeBases),
          value: options.includeKnowledgeBases,
          onChanged: (v) =>
              onChanged(options.copyWith(includeKnowledgeBases: v ?? false)),
        ),
        CheckboxListTile(
          title: Text(l10n.backupUsageStats),
          value: options.includeUsageStats,
          onChanged: (v) =>
              onChanged(options.copyWith(includeUsageStats: v ?? false)),
        ),
      ],
    );
  }
}
