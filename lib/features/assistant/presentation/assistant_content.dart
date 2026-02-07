import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/utils/avatar_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aurora/features/assistant/presentation/assistant_provider.dart';
import 'package:aurora/features/assistant/presentation/widgets/assistant_avatar.dart';
import 'package:aurora/features/assistant/domain/assistant.dart';
import 'package:aurora/features/assistant/presentation/mobile_assistant_page.dart';
import 'package:aurora/features/knowledge/presentation/knowledge_provider.dart';
import 'package:aurora/features/skills/presentation/skill_provider.dart';

class AssistantContent extends ConsumerStatefulWidget {
  const AssistantContent({super.key});

  @override
  ConsumerState<AssistantContent> createState() => _AssistantContentState();
}

class _AssistantContentState extends ConsumerState<AssistantContent> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  String? _selectedAssistantId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _loadAssistant(Assistant? assistant) {
    if (assistant == null) {
      _nameController.clear();
      _descriptionController.clear();
      _systemPromptController.clear();
    } else {
      _nameController.text = assistant.name;
      _descriptionController.text = assistant.description;
      _systemPromptController.text = assistant.systemPrompt;
    }
  }

  Future<void> _saveCurrent(Assistant original) async {
    final updated = original.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      systemPrompt: _systemPromptController.text,
    );
    await ref.read(assistantProvider.notifier).saveAssistant(updated);
  }

  @override
  Widget build(BuildContext context) {
    final assistantState = ref.watch(assistantProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = fluent.FluentTheme.of(context);

    if (PlatformUtils.isDesktop) {
      return Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                    color: theme.resources.dividerStrokeColorDefault),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: fluent.FilledButton(
                    onPressed: () async {
                      final newAssistant = await ref
                          .read(assistantProvider.notifier)
                          .createAssistant(name: l10n.newAssistant);
                      setState(() {
                        _selectedAssistantId = newAssistant.id;
                      });
                      _loadAssistant(newAssistant);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(AuroraIcons.add, size: 14),
                        const SizedBox(width: 8),
                        Text(l10n.add),
                      ],
                    ),
                  ),
                ),
                const fluent.Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: assistantState.assistants.length,
                    itemBuilder: (context, index) {
                      final assistant = assistantState.assistants[index];
                      final isSelected = assistant.id == _selectedAssistantId;
                      return fluent.HoverButton(
                        onPressed: () {
                          setState(() {
                            _selectedAssistantId = assistant.id;
                          });
                          _loadAssistant(assistant);
                          ref
                              .read(assistantProvider.notifier)
                              .selectAssistant(assistant.id);
                        },
                        builder: (context, states) {
                          return Container(
                            height: 48,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.accentColor.withValues(alpha: 0.1)
                                  : states.isHovered
                                      ? theme.resources.subtleFillColorSecondary
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                AssistantAvatar(assistant: assistant, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    assistant.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          isSelected ? theme.accentColor : null,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : null,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  fluent.IconButton(
                                    icon: const Icon(AuroraIcons.delete,
                                        size: 12),
                                    onPressed: () {
                                      _showDeleteDialog(assistant);
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedAssistantId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(AuroraIcons.robot,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(l10n.assistantSystem,
                            style: theme.typography.title
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text('选择或创建一个助理开始配置',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : _buildDetailView(
                    assistantState.assistants
                        .firstWhere((a) => a.id == _selectedAssistantId),
                    l10n,
                    theme,
                  ),
          ),
        ],
      );
    } else {
      return MobileAssistantPage(
        onBack: () {
          // This depends on how the parent handles navigation,
          // but usually on mobile we want to pop or go back to session list.
          // Since it's in a CachedPageStack, the parent should handle it.
        },
      );
    }
  }

  Widget _buildDetailView(Assistant assistant, AppLocalizations l10n,
      fluent.FluentThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _pickAvatar(assistant),
                child: Stack(
                  children: [
                    AssistantAvatar(assistant: assistant, size: 80),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(AuroraIcons.edit,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fluent.InfoLabel(
                      label: l10n.userName, // Reuse l10n for now
                      child: fluent.TextBox(
                        controller: _nameController,
                        onChanged: (_) => _saveCurrent(assistant),
                        placeholder: l10n.assistantName,
                      ),
                    ),
                    const SizedBox(height: 16),
                    fluent.InfoLabel(
                      label: l10n.assistantDescription,
                      child: fluent.TextBox(
                        controller: _descriptionController,
                        onChanged: (_) => _saveCurrent(assistant),
                        placeholder: l10n.assistantDescription,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          fluent.InfoLabel(
            label: l10n.systemPrompt,
            child: fluent.TextBox(
              controller: _systemPromptController,
              onChanged: (_) => _saveCurrent(assistant),
              maxLines: 15,
              minLines: 8,
              placeholder: l10n.systemPromptPlaceholder,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          _buildSkillSettings(assistant, l10n),
          const SizedBox(height: 24),
          _buildKnowledgeSettings(assistant, l10n),
          const SizedBox(height: 24),
          fluent.Expander(
            header: const Text('高级设置'),
            content: Column(
              children: [
                fluent.Checkbox(
                  checked: assistant.enableMemory,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(assistantProvider.notifier).saveAssistant(
                            assistant.copyWith(enableMemory: v),
                          );
                    }
                  },
                  content: Text(l10n.assistantLongTermMemory),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSettings(Assistant assistant, AppLocalizations l10n) {
    final skills = ref
        .watch(skillProvider)
        .skills
        .where((s) => s.isEnabled && s.forAI)
        .toList();

    return fluent.Expander(
      header: Text(l10n.assistantAvailableSkillsTitle),
      content: skills.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(l10n.assistantNoSkillsAvailable),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: skills.map((skill) {
                final isChecked = assistant.skillIds.contains(skill.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: fluent.Checkbox(
                    checked: isChecked,
                    onChanged: (v) {
                      final newIds = List<String>.from(assistant.skillIds);
                      if (v == true) {
                        newIds.add(skill.id);
                      } else {
                        newIds.remove(skill.id);
                      }
                      ref.read(assistantProvider.notifier).saveAssistant(
                            assistant.copyWith(skillIds: newIds),
                          );
                    },
                    content: fluent.Tooltip(
                      message: skill.description,
                      child: Text(skill.name),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildKnowledgeSettings(Assistant assistant, AppLocalizations l10n) {
    final knowledgeState = ref.watch(knowledgeProvider);
    final bases = knowledgeState.bases.where((b) => b.isEnabled).toList();

    return fluent.Expander(
      header: Text(l10n.knowledgeBase),
      content: knowledgeState.isLoading
          ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: fluent.ProgressRing(strokeWidth: 2),
              ),
            )
          : bases.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(l10n.noKnowledgeBaseYetCreateOne),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assistantKnowledgeBindingHint,
                      style: TextStyle(
                        color: fluent.FluentTheme.of(context)
                            .resources
                            .textFillColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...bases.map((base) {
                      final isChecked =
                          assistant.knowledgeBaseIds.contains(base.baseId);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: fluent.Checkbox(
                          checked: isChecked,
                          onChanged: (v) {
                            final nextIds =
                                List<String>.from(assistant.knowledgeBaseIds);
                            if (v == true) {
                              if (!nextIds.contains(base.baseId)) {
                                nextIds.add(base.baseId);
                              }
                            } else {
                              nextIds.remove(base.baseId);
                            }
                            ref.read(assistantProvider.notifier).saveAssistant(
                                  assistant.copyWith(knowledgeBaseIds: nextIds),
                                );
                          },
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(base.name),
                              Text(
                                l10n.knowledgeDocsAndChunks(
                                    base.documentCount, base.chunkCount),
                                style: TextStyle(
                                  color: fluent.FluentTheme.of(context)
                                      .resources
                                      .textFillColorSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

  Future<void> _pickAvatar(Assistant assistant) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      final croppedPath = await AvatarCropper.cropImage(context, image.path);
      if (croppedPath != null) {
        ref.read(assistantProvider.notifier).saveAssistant(
              assistant.copyWith(avatar: croppedPath),
            );
      }
    }
  }

  void _showDeleteDialog(Assistant assistant) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text(l10n.assistantDeleteTitle),
        content: Text(l10n.assistantDeleteConfirm(assistant.name)),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          fluent.FilledButton(
            onPressed: () {
              ref
                  .read(assistantProvider.notifier)
                  .deleteAssistant(assistant.id);
              if (_selectedAssistantId == assistant.id) {
                setState(() {
                  _selectedAssistantId = null;
                });
                _loadAssistant(null);
              }
              Navigator.pop(context);
            },
            style: fluent.ButtonStyle(
              backgroundColor:
                  fluent.WidgetStateProperty.all(fluent.Colors.red),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
