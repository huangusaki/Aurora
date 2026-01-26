import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../domain/skill_entity.dart';
import '../presentation/skill_provider.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../chat/presentation/widgets/selectable_markdown/selectable_markdown.dart';

class MobileSkillsPage extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const MobileSkillsPage({
    super.key,
    required this.onBack,
  });

  @override
  ConsumerState<MobileSkillsPage> createState() => _MobileSkillsPageState();
}

class _MobileSkillsPageState extends ConsumerState<MobileSkillsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final skillState = ref.watch(skillProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(l10n.agentSkills),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(skillProvider.notifier).refresh(
                language: ref.read(settingsProvider).language),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSkillDialog(context),
          ),
        ],
      ),
      body: skillState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : skillState.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      '${l10n.error}: ${skillState.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : skillState.skills.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.extension_off_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(l10n.noSkillsFound),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: skillState.skills.length + 1,
                      itemBuilder: (context, index) {
                        if (index == skillState.skills.length) {
                           return Padding(
                             padding: const EdgeInsets.all(16.0),
                             child: Text(
                               l10n.agentSkillsDescription,
                               style: TextStyle(
                                 fontSize: 12,
                                 color: theme.textTheme.bodySmall?.color,
                               ),
                               textAlign: TextAlign.center,
                             ),
                           );
                        }
                        final skill = skillState.skills[index];
                        return _SkillCard(skill: skill);
                      },
                    ),
    );
  }

  Future<void> _showAddSkillDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newSkill),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l10n.skillName,
                hintText: l10n.skillNameHint,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
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
}

class _SkillCard extends ConsumerWidget {
  final Skill skill;

  const _SkillCard({required this.skill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCompatible = skill.isCompatible(Platform.operatingSystem);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(
                Icons.extension,
                size: 20,
                color: skill.isEnabled ? theme.colorScheme.primary : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  skill.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: skill.isEnabled ? null : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   if (!skill.platforms.contains('all')) ...[
                     ...skill.platforms.map((p) => Container(
                       margin: const EdgeInsets.only(right: 4),
                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                       decoration: BoxDecoration(
                         color: isCompatible
                           ? theme.colorScheme.primary.withOpacity(0.1)
                           : Colors.red.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(
                         p,
                         style: TextStyle(
                           fontSize: 10,
                           color: isCompatible
                             ? theme.colorScheme.primary
                             : Colors.red,
                         ),
                       ),
                     )),
                     const SizedBox(width: 8),
                   ],
                ],
              ),
            ],
          ),
          trailing: !skill.isLocked 
            ? Switch(
                value: skill.isEnabled,
                onChanged: (v) => ref.read(skillProvider.notifier).toggleSkill(skill),
              )
            : Tooltip(
                message: "System Skill",
                child: Icon(Icons.lock, size: 16, color: Colors.grey[400]),
              ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditSkillPage(context, ref, skill),
                        tooltip: l10n.editSkill,
                      ),
                      if (!skill.isLocked)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _showDeleteConfirmDialog(context, ref, skill),
                          tooltip: l10n.deleteSkill,
                          color: Colors.red,
                        ),
                      IconButton(
                        icon: const Icon(Icons.folder_open, size: 20),
                        onPressed: () => _openSkillsFolder(skill.path),
                        tooltip: l10n.openSkillsFolder,
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(l10n.instructions,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableMarkdown(
                      data: skill.instructions,
                      isDark: theme.brightness == Brightness.dark,
                      textColor: theme.textTheme.bodyMedium?.color ?? Colors.black,
                      baseFontSize: 13,
                    ),
                  ),
                  if (skill.tools.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(l10n.tools,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...skill.tools.map((tool) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.build_circle_outlined, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('${tool.name} (${tool.type})',
                                    style: theme.textTheme.bodySmall),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditSkillPage(BuildContext context, WidgetRef ref, Skill skill) async {
    final content = await ref.read(skillProvider.notifier).getSkillMarkdown(skill);
    
    // On mobile, better to push a full screen page for editing
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _SkillEditorPage(
            skill: skill,
            initialContent: content,
          ),
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, Skill skill) async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.deleteSkillTitle}: ${skill.name}'),
        content: Text(l10n.deleteSkillConfirm),
        actions: [
          TextButton(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
             style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

  Future<void> _openSkillsFolder(String? path) async {
    if (path == null) return;
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SkillEditorPage extends ConsumerStatefulWidget {
  final Skill skill;
  final String initialContent;

  const _SkillEditorPage({
    required this.skill,
    required this.initialContent,
  });

  @override
  ConsumerState<_SkillEditorPage> createState() => _SkillEditorPageState();
}

class _SkillEditorPageState extends ConsumerState<_SkillEditorPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.editSkill}: ${widget.skill.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await ref.read(skillProvider.notifier).saveSkill(widget.skill, _controller.text);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.saveSuccess)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'SKILL.md content...',
          ),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
