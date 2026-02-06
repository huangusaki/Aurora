import 'package:aurora/shared/theme/aurora_icons.dart';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import '../domain/skill_entity.dart';
import '../presentation/skill_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../chat/presentation/widgets/selectable_markdown/selectable_markdown.dart';
import '../../chat/presentation/widgets/custom_dropdown_overlay.dart';

class SkillSettingsPage extends ConsumerStatefulWidget {
  const SkillSettingsPage({super.key});

  @override
  ConsumerState<SkillSettingsPage> createState() => _SkillSettingsPageState();
}

class _SkillSettingsPageState extends ConsumerState<SkillSettingsPage> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final theme = fluent.FluentTheme.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => CustomDropdownOverlay(
        onDismiss: _removeOverlay,
        layerLink: _layerLink,
        offset: const Offset(0, 36),
        child: AnimatedDropdownList(
          backgroundColor: theme.menuColor,
          borderColor: theme.resources.surfaceStrokeColorDefault,
          width: 320,
          coloredItems: _buildExecutionModelItems(theme),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  List<ColoredDropdownItem> _buildExecutionModelItems(
      fluent.FluentThemeData theme) {
    final settings = ref.watch(settingsProvider);
    final executionModel = settings.executionModel;
    final l10n = AppLocalizations.of(context)!;
    final List<ColoredDropdownItem> items = [];

    // Default option
    items.add(ColoredDropdownItem(
      label: l10n.defaultModelSameAsChat,
      onPressed: () {
        _removeOverlay();
        ref
            .read(settingsProvider.notifier)
            .setExecutionSettings(model: null, providerId: null);
      },
      isSelected: executionModel == null,
      textColor: executionModel == null
          ? theme.accentColor
          : theme.typography.caption?.color,
      icon: executionModel == null
          ? fluent.Icon(AuroraIcons.check, size: 12, color: theme.accentColor)
          : null,
    ));

    items.add(const DropdownSeparator());

    for (final provider in settings.providers) {
      if (!provider.isEnabled || provider.models.isEmpty) continue;

      // Get provider color
      Color providerColor;
      if (provider.color != null && provider.color!.isNotEmpty) {
        providerColor = Color(
            int.tryParse(provider.color!.replaceFirst('#', '0xFF')) ??
                0xFF000000);
      } else {
        providerColor = generateColorFromString(provider.id);
      }

      // Add provider header
      items.add(ColoredDropdownItem(
        label: provider.name,
        backgroundColor: providerColor,
        isBold: true,
        textColor: theme.typography.caption?.color ?? fluent.Colors.grey,
      ));

      // Add enabled models
      for (final model in provider.models) {
        if (!provider.isModelEnabled(model)) continue;
        final isSelected = executionModel == model;
        items.add(ColoredDropdownItem(
          label: model,
          onPressed: () {
            _removeOverlay();
            ref
                .read(settingsProvider.notifier)
                .setExecutionSettings(model: model, providerId: provider.id);
          },
          backgroundColor: providerColor,
          isSelected: isSelected,
          textColor: isSelected ? theme.accentColor : null,
          icon: isSelected
              ? fluent.Icon(AuroraIcons.check,
                  size: 12, color: theme.accentColor)
              : null,
        ));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider.select((s) => s.language), (previous, next) {
      if (previous != next) {
        ref.read(skillProvider.notifier).refresh(language: next);
      }
    });

    final skillState = ref.watch(skillProvider);
    final theme = fluent.FluentTheme.of(context);
    final settings = ref.watch(settingsProvider);
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
                          const Icon(AuroraIcons.add, size: 14),
                          const SizedBox(width: 8),
                          Text(l10n.newSkill),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    fluent.Button(
                      onPressed: () => ref.read(skillProvider.notifier).refresh(
                          language: ref.read(settingsProvider).language),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AuroraIcons.refresh, size: 14),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  l10n.executionModel,
                  style: theme.typography.bodyStrong,
                ),
                const SizedBox(width: 12),
                CompositedTransformTarget(
                  link: _layerLink,
                  child: fluent.HoverButton(
                    onPressed: _toggleDropdown,
                    builder: (context, states) {
                      return Container(
                        constraints:
                            const BoxConstraints(minWidth: 200, maxWidth: 350),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isOpen || states.isHovered
                              ? theme.resources.subtleFillColorSecondary
                              : theme.resources.controlFillColorDefault,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isOpen
                                ? theme.accentColor
                                : theme.resources.controlStrokeColorDefault,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                settings.executionModel ??
                                    l10n.defaultModelSameAsChat,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: settings.executionModel != null
                                      ? theme.typography.body?.color
                                      : theme.typography.caption?.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            fluent.Icon(
                                _isOpen
                                    ? AuroraIcons.chevronUp
                                    : AuroraIcons.chevronDown,
                                size: 10,
                                color: theme.typography.caption?.color),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                fluent.Tooltip(
                  message: 'The model used by Worker Agents to execute skills.',
                  child: Icon(AuroraIcons.info,
                      size: 14, color: theme.typography.caption?.color),
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
                    const Icon(AuroraIcons.script,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(l10n.noSkillsFound),
                    const SizedBox(height: 8),
                    fluent.Button(
                      onPressed: () =>
                          _openSkillsFolder(skillState.skillsDirectory),
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
                            AuroraIcons.script,
                            size: 16,
                            color: skill.isEnabled
                                ? theme.accentColor
                                : theme.typography.caption?.color,
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
                                        color: skill.isEnabled
                                            ? null
                                            : theme.typography.caption?.color,
                                      ),
                                    ),
                                    if (!skill.platforms.contains('all')) ...[
                                      const SizedBox(width: 8),
                                      ...skill.platforms.map((p) => Container(
                                            margin:
                                                const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: skill.isCompatible(
                                                      Platform.operatingSystem)
                                                  ? theme.accentColor
                                                      .withValues(alpha: 0.1)
                                                  : Colors.red
                                                      .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: skill.isCompatible(
                                                        Platform
                                                            .operatingSystem)
                                                    ? theme.accentColor
                                                        .withValues(alpha: 0.3)
                                                    : Colors.red
                                                        .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              p,
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: skill.isCompatible(
                                                        Platform
                                                            .operatingSystem)
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
                                    color: skill.isEnabled
                                        ? null
                                        : theme.typography.caption?.color
                                            ?.withValues(alpha: 0.5),
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
                              onChanged: (v) => ref
                                  .read(skillProvider.notifier)
                                  .toggleSkill(skill),
                            ),
                          const SizedBox(width: 12),
                          fluent.IconButton(
                            icon: const Icon(AuroraIcons.edit, size: 14),
                            onPressed: () =>
                                _showEditSkillDialog(context, ref, skill),
                          ),
                          if (!skill.isLocked) ...[
                            const SizedBox(width: 4),
                            fluent.IconButton(
                              icon: const Icon(AuroraIcons.delete, size: 14),
                              onPressed: () =>
                                  _showDeleteConfirmDialog(context, ref, skill),
                            ),
                          ],
                          const SizedBox(width: 4),
                          fluent.IconButton(
                            icon: const Icon(AuroraIcons.folderOpen, size: 14),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
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
                                textColor: theme.typography.caption?.color ??
                                    (theme.brightness == Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87),
                                baseFontSize: 12.5,
                              ),
                            ),
                            if (skill.tools.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(l10n.tools,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              ...skill.tools.map((tool) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      children: [
                                        const Icon(AuroraIcons.repair,
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
                color: theme.accentColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: theme.accentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(AuroraIcons.info, size: 16, color: theme.accentColor),
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

  Future<void> _showDeleteConfirmDialog(
      BuildContext context, WidgetRef ref, Skill skill) async {
    final l10n = AppLocalizations.of(context)!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    if (isWindows) {
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
                backgroundColor: WidgetStateProperty.all(fluent.Colors.red),
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
    } else {
      final confirmed = await AuroraBottomSheet.showConfirm(
        context: context,
        title: l10n.deleteSkillTitle,
        content: '${l10n.deleteSkillConfirm}: ${skill.name}',
        confirmText: l10n.deleteSkill,
        isDestructive: true,
      );
      if (confirmed == true) {
        ref.read(skillProvider.notifier).deleteSkill(skill);
      }
    }
  }

  Future<void> _showEditSkillDialog(
      BuildContext context, WidgetRef ref, Skill skill) async {
    final l10n = AppLocalizations.of(context)!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    // Initial fetch of content
    final content =
        await ref.read(skillProvider.notifier).getSkillMarkdown(skill);
    if (!context.mounted) return;
    final controller = TextEditingController(text: content);

    if (isWindows) {
      await fluent.showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: Row(
            children: [
              const Icon(AuroraIcons.edit, size: 16),
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
                await ref
                    .read(skillProvider.notifier)
                    .saveSkill(skill, controller.text);
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
    } else {
      AuroraBottomSheet.show(
        context: context,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuroraBottomSheet.buildTitle(context, l10n.editSkill),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(skill.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 15,
                    minLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'SKILL.md content...',
                    ),
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            await ref
                                .read(skillProvider.notifier)
                                .saveSkill(skill, controller.text);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              showAuroraNotice(
                                context,
                                l10n.saveSuccess,
                                icon: Icons.check_circle_outline_rounded,
                              );
                            }
                          },
                          child: Text(l10n.updateSkill),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
  }

  Future<void> _showAddSkillDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    if (isWindows) {
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
    } else {
      AuroraBottomSheet.show(
        context: context,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuroraBottomSheet.buildTitle(context, l10n.newSkill),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.skillName,
                      hintText: l10n.skillNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final name = controller.text.trim();
                            if (name.isNotEmpty) {
                              ref
                                  .read(skillProvider.notifier)
                                  .createSkill(name);
                              Navigator.pop(ctx);
                            }
                          },
                          child: Text(l10n.confirm),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
  }

  Future<void> _openSkillsFolder(String? path) async {
    if (path == null) return;
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
