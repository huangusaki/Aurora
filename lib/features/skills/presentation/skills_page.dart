import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../domain/skill_entity.dart';
import '../presentation/skill_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../chat/presentation/widgets/selectable_markdown/selectable_markdown.dart';

class SkillSettingsPage extends ConsumerWidget {
  const SkillSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(settingsProvider.select((s) => s.language), (previous, next) {
       if (previous != next) {
         ref.read(skillProvider.notifier).refresh(language: next);
       }
    });

    final skillState = ref.watch(skillProvider);
    final theme = fluent.FluentTheme.of(context);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.agentSkills,
                  style: theme.typography.subtitle,
                ),
                Row(
                  children: [
                    fluent.FilledButton(
                      onPressed: () => _showAddSkillDialog(context, ref),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(fluent.FluentIcons.add, size: 14),
                          const SizedBox(width: 8),
                          Text(l10n.newSkill),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    fluent.Button(
                      onPressed: () => ref.read(skillProvider.notifier).refresh(language: ref.read(settingsProvider).language),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(fluent.FluentIcons.refresh, size: 14),
                          const SizedBox(width: 8),
                          Text(l10n.refreshList),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  l10n.executionModel, 
                  style: theme.typography.bodyStrong,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: fluent.ComboBox<String>(
                      isExpanded: true,
                      placeholder: Text(
                        ref.watch(settingsProvider).activeProvider?.selectedModel ?? 'Default',
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: ref.watch(settingsProvider).executionModel,
                      items: [
                        fluent.ComboBoxItem<String>(
                          value: null,
                          child: Text(
                            l10n.defaultModelSameAsChat, 
                            style: TextStyle(color: theme.typography.caption?.color),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...ref.watch(settingsProvider).availableModels.map((m) {
                          return fluent.ComboBoxItem<String>(
                            value: m,
                            child: fluent.Tooltip(
                              message: m,
                              child: Text(
                                m, 
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) async {
                        await ref.read(settingsProvider.notifier).setExecutionModel(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                fluent.Tooltip(
                  message: 'The model used by Worker Agents to execute skills.',
                  child: Icon(fluent.FluentIcons.info, size: 14, color: theme.typography.caption?.color),
                ),
              ],
            ),
          ),
          if (skillState.isLoading)
            const Center(child: fluent.ProgressRing())
          else if (skillState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                '${l10n.error}: ${skillState.error}',
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (skillState.skills.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(fluent.FluentIcons.script,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(l10n.noSkillsFound),
                    const SizedBox(height: 8),
                    fluent.Button(
                      onPressed: () => _openSkillsFolder(skillState.skillsDirectory),
                      child: Text(l10n.openSkillsFolder),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: skillState.skills.length,
                itemBuilder: (context, index) {
                  final skill = skillState.skills[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: fluent.Expander(
                      header: Row(
                        children: [
                          Icon(
                            fluent.FluentIcons.script,
                            size: 16,
                            color: skill.isEnabled ? theme.accentColor : theme.typography.caption?.color,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      skill.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: skill.isEnabled ? null : theme.typography.caption?.color,
                                      ),
                                    ),
                                    if (!skill.platforms.contains('all')) ...[
                                      const SizedBox(width: 8),
                                      ...skill.platforms.map((p) => Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: skill.isCompatible(Platform.operatingSystem) 
                                            ? theme.accentColor.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: skill.isCompatible(Platform.operatingSystem)
                                              ? theme.accentColor.withOpacity(0.3)
                                              : Colors.red.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          p,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: skill.isCompatible(Platform.operatingSystem)
                                              ? theme.accentColor
                                              : Colors.red,
                                          ),
                                        ),
                                      )),
                                    ],
                                  ],
                                ),
                                Text(
                                  skill.description,
                                  style: theme.typography.caption?.copyWith(
                                    color: skill.isEnabled ? null : theme.typography.caption?.color?.withOpacity(0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!skill.isLocked)
                            fluent.ToggleSwitch(
                              checked: skill.isEnabled,
                              onChanged: (v) => ref.read(skillProvider.notifier).toggleSkill(skill),
                            ),
                          const SizedBox(width: 12),
                          fluent.IconButton(
                            icon: const Icon(fluent.FluentIcons.edit,
                                size: 14),
                            onPressed: () => _showEditSkillDialog(context, ref, skill),
                          ),
                          if (!skill.isLocked) ...[
                            const SizedBox(width: 4),
                            fluent.IconButton(
                              icon: const Icon(fluent.FluentIcons.delete,
                                  size: 14),
                              onPressed: () => _showDeleteConfirmDialog(context, ref, skill),
                            ),
                          ],
                          const SizedBox(width: 4),
                          fluent.IconButton(
                            icon: const Icon(fluent.FluentIcons.folder_open,
                                size: 14),
                            onPressed: () => _openSkillsFolder(skill.path),
                          ),
                        ],
                      ),
                      content: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.instructions,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.resources.subtleFillColorSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SelectableMarkdown(
                                data: skill.instructions,
                                isDark: theme.brightness == Brightness.dark,
                                textColor: theme.typography.caption?.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                                baseFontSize: 12.5,
                              ),
                          ),
                          if (skill.tools.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(l10n.tools,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ...skill.tools.map((tool) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(fluent.FluentIcons.repair,
                                          size: 12),
                                      const SizedBox(width: 8),
                                      Text('${tool.name} (${tool.type})',
                                          style: theme.typography.caption),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.accentColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(fluent.FluentIcons.info,
                      size: 16, color: theme.accentColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.agentSkillsDescription,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, Skill skill) async {
    final l10n = AppLocalizations.of(context)!;

    await fluent.showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text('${l10n.deleteSkillTitle}: ${skill.name}'),
        content: Text(l10n.deleteSkillConfirm),
        actions: [
          fluent.Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          fluent.FilledButton(
            style: fluent.ButtonStyle(
              backgroundColor: fluent.ButtonState.all(fluent.Colors.red),
            ),
            child: Text(l10n.deleteSkill),
            onPressed: () {
              ref.read(skillProvider.notifier).deleteSkill(skill);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditSkillDialog(BuildContext context, WidgetRef ref, Skill skill) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = fluent.FluentTheme.of(context);
    
    // Initial fetch of content
    final content = await ref.read(skillProvider.notifier).getSkillMarkdown(skill);
    final controller = TextEditingController(text: content);

    await fluent.showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Row(
          children: [
            const Icon(fluent.FluentIcons.edit, size: 16),
            const SizedBox(width: 8),
            Text('${l10n.editSkill}: ${skill.name}'),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: fluent.InfoLabel(
                label: 'SKILL.md',
                child: fluent.TextBox(
                  controller: controller,
                  maxLines: null,
                  minLines: 20,
                  placeholder: 'SKILL.md content...',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          fluent.Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          fluent.FilledButton(
            child: Text(l10n.updateSkill),
            onPressed: () async {
              await ref.read(skillProvider.notifier).saveSkill(skill, controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                fluent.displayInfoBar(
                  context,
                  builder: (context, close) => fluent.InfoBar(
                    title: Text(l10n.saveSuccess),
                    severity: fluent.InfoBarSeverity.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSkillDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    await fluent.showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text(l10n.newSkill),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.skillName),
            const SizedBox(height: 8),
            fluent.TextBox(
              controller: controller,
              placeholder: l10n.skillNameHint,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          fluent.Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          fluent.FilledButton(
            child: Text(l10n.confirm),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(skillProvider.notifier).createSkill(name);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openSkillsFolder(String? path) async {
    if (path == null) return;
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
