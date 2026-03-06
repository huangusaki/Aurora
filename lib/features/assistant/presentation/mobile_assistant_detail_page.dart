import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import '../domain/assistant.dart';
import 'widgets/assistant_avatar.dart';
import 'assistant_provider.dart';
import '../../settings/presentation/widgets/mobile_settings_widgets.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../skills/presentation/skill_provider.dart';
import '../../knowledge/presentation/knowledge_provider.dart';
import '../../mcp/domain/mcp_server_config.dart';
import '../../mcp/presentation/mcp_bindings_provider.dart';
import '../../mcp/presentation/mcp_server_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:aurora/shared/utils/avatar_storage.dart';

class MobileAssistantDetailPage extends ConsumerStatefulWidget {
  final Assistant assistant;

  const MobileAssistantDetailPage({super.key, required this.assistant});

  @override
  ConsumerState<MobileAssistantDetailPage> createState() =>
      _MobileAssistantDetailPageState();
}

class _MobileAssistantDetailPageState
    extends ConsumerState<MobileAssistantDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _systemPromptController;
  late Assistant _currentAssistant;

  @override
  void initState() {
    super.initState();
    _currentAssistant = widget.assistant;
    _nameController = TextEditingController(text: _currentAssistant.name);
    _descriptionController =
        TextEditingController(text: _currentAssistant.description);
    _systemPromptController =
        TextEditingController(text: _currentAssistant.systemPrompt);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = _currentAssistant.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      systemPrompt: _systemPromptController.text,
    );
    await ref.read(assistantProvider.notifier).saveAssistant(updated);
    if (mounted) {
      setState(() {
        _currentAssistant = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final knowledgeState = ref.watch(knowledgeProvider);
    final enabledKnowledgeBaseIds = knowledgeState.bases
        .where((b) => b.isEnabled)
        .map((b) => b.baseId)
        .toSet();
    final assistantKnowledgeBaseCount =
        (knowledgeState.isLoading || knowledgeState.error != null)
            ? _currentAssistant.knowledgeBaseIds.length
            : _currentAssistant.knowledgeBaseIds
                .where(enabledKnowledgeBaseIds.contains)
                .length;
    final configuredMcpServers = ref.watch(mcpServerProvider).servers;
    final enabledMcpServers = configuredMcpServers
        .where((s) => s.enabled && s.transport != McpServerTransport.stdio)
        .toList(growable: false);
    final enabledMcpIds = enabledMcpServers.map((s) => s.id).toSet();
    final assistantMcpOverride =
        ref.watch(mcpBindingsProvider).assistantOverrides[_currentAssistant.id];
    final followGlobalMcp = assistantMcpOverride == null;
    final selectedMcpCount = followGlobalMcp
        ? enabledMcpServers.length
        : assistantMcpOverride.where(enabledMcpIds.contains).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.65),
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Basic Info
          _buildHeroSection(context, theme, l10n),

          MobileSettingsSection(
            title: l10n.assistantBasicConfig,
            children: [
              _buildTextFieldTile(
                controller: _nameController,
                label: l10n.assistantName,
                onChanged: (_) => _save(),
              ),
              _buildTextFieldTile(
                controller: _descriptionController,
                label: l10n.assistantDescription,
                onChanged: (_) => _save(),
              ),
            ],
          ),

          MobileSettingsSection(
            title: l10n.assistantCoreSettings,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.systemPrompt,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _systemPromptController,
                      maxLines: 10,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.systemPromptPlaceholder,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.cardColor.withValues(alpha: 0.5),
                      ),
                      onChanged: (_) => _save(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          MobileSettingsSection(
            title: l10n.assistantCapabilities,
            children: [
              MobileSettingsTile(
                leading: const Icon(Icons.extension_outlined),
                title: l10n.assistantSkillManagement,
                subtitle: l10n.assistantSkillEnabledCount(
                    _currentAssistant.skillIds.length),
                onTap: () => _showSkillPicker(context),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.library_books_outlined),
                title: l10n.knowledgeBase,
                subtitle: assistantKnowledgeBaseCount == 0
                    ? l10n.disabled
                    : l10n.knowledgeEnabledWithActiveCount(
                        assistantKnowledgeBaseCount,
                      ),
                onTap: () => _showKnowledgeBasePicker(context),
              ),
              MobileSettingsTile(
                leading: const Icon(AuroraIcons.mcp),
                title: l10n.mcpServersTitle,
                subtitle: enabledMcpServers.isEmpty
                    ? l10n.disabled
                    : (followGlobalMcp
                        ? l10n.mcpFollowGlobal
                        : l10n.mcpServersSelectedCount(selectedMcpCount)),
                onTap: () => _showMcpServerPicker(context),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.memory_outlined),
                title: l10n.assistantLongTermMemory,
                subtitle: _currentAssistant.enableMemory
                    ? l10n.enabled
                    : l10n.disabled,
                trailing: Switch.adaptive(
                  value: _currentAssistant.enableMemory,
                  onChanged: (v) {
                    _updateAssistant(
                        _currentAssistant.copyWith(enableMemory: v));
                  },
                ),
                onTap: () {
                  _updateAssistant(_currentAssistant.copyWith(
                      enableMemory: !_currentAssistant.enableMemory));
                },
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.tune_outlined),
                title: l10n.assistantMemoryConsolidationModel,
                subtitle: _memoryModelSubtitle(),
                onTap: _currentAssistant.enableMemory
                    ? () => _showMemoryModelPicker(context)
                    : null,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  l10n.assistantKnowledgeBindingHint,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
      BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: GestureDetector(
          onTap: _pickAvatar,
          child: Stack(
            children: [
              _buildAvatar(context, _currentAssistant, size: 100),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldTile({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
        ),
        onChanged: onChanged,
      ),
    );
  }

  void _updateAssistant(Assistant updated) {
    setState(() {
      _currentAssistant = updated;
    });
    ref.read(assistantProvider.notifier).saveAssistant(updated);
  }

  String _memoryModelSubtitle() {
    final l10n = AppLocalizations.of(context)!;
    final providerId = _currentAssistant.memoryProviderId;
    final model = _currentAssistant.memoryModel;
    if (providerId == null ||
        providerId.isEmpty ||
        model == null ||
        model.isEmpty) {
      return l10n.assistantMemoryFollowCurrentChatModel;
    }
    final providers = ref.read(settingsProvider).providers;
    final provider = providers.where((p) => p.id == providerId).firstOrNull;
    if (provider == null) return '$providerId - $model';
    return '${provider.name} - $model';
  }

  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: l10n.cropAvatar,
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: l10n.cropAvatar,
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        var avatarPath = croppedFile.path;
        try {
          avatarPath = await AvatarStorage.persistAvatar(
            sourcePath: croppedFile.path,
            owner: AvatarOwner.assistant,
          );
        } catch (_) {}
        _updateAssistant(_currentAssistant.copyWith(avatar: avatarPath));
      }
    }
  }

  void _showSkillPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final skills = ref
        .read(skillProvider)
        .skills
        .where((s) => s.isEnabled && s.forAI)
        .toList();
    if (skills.isEmpty) {
      showAuroraNotice(
        context,
        l10n.assistantNoSkillsAvailable,
        icon: Icons.info_outline_rounded,
        top: MediaQuery.of(context).padding.top + 64 + 60,
      );
      return;
    }

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(
              context,
              l10n.assistantAvailableSkillsTitle,
            ),
            const Divider(height: 1),
            Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: skills.map((skill) {
                  final isSelected =
                      _currentAssistant.skillIds.contains(skill.id);
                  return CheckboxListTile(
                    title: Text(skill.name),
                    subtitle: Text(skill.description,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    value: isSelected,
                    onChanged: (v) {
                      final newIds =
                          List<String>.from(_currentAssistant.skillIds);
                      if (v == true) {
                        newIds.add(skill.id);
                      } else {
                        newIds.remove(skill.id);
                      }
                      // Update local state and parent state
                      final updated =
                          _currentAssistant.copyWith(skillIds: newIds);
                      // Update the main page state
                      setState(() {
                        _currentAssistant = updated;
                      });
                      // Update the bottom sheet state
                      setSheetState(() {});
                      ref
                          .read(assistantProvider.notifier)
                          .saveAssistant(updated);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }

  void _showMcpServerPicker(BuildContext context) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final l10n = AppLocalizations.of(ctx)!;
          final configuredServers = ref.watch(mcpServerProvider).servers;
          final enabledServers = configuredServers
              .where(
                  (s) => s.enabled && s.transport != McpServerTransport.stdio)
              .toList(growable: false);
          final enabledIds = enabledServers.map((s) => s.id).toSet();
          final bindingsState = ref.watch(mcpBindingsProvider);
          final override =
              bindingsState.assistantOverrides[_currentAssistant.id];
          final followGlobal = override == null;
          final selectedIds = followGlobal
              ? enabledIds
              : override.where(enabledIds.contains).toSet();

          Future<void> setFollowGlobal(bool follow) async {
            if (follow) {
              await ref
                  .read(mcpBindingsProvider.notifier)
                  .clearAssistantOverride(_currentAssistant.id);
              return;
            }
            final next = enabledIds.toList()..sort();
            await ref
                .read(mcpBindingsProvider.notifier)
                .setAssistantOverride(_currentAssistant.id, next);
          }

          Future<void> toggleServer(String serverId, bool enabled) async {
            final current = Set<String>.from(selectedIds);
            if (enabled) {
              current.add(serverId);
            } else {
              current.remove(serverId);
            }
            final next = current.toList()..sort();
            await ref
                .read(mcpBindingsProvider.notifier)
                .setAssistantOverride(_currentAssistant.id, next);
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuroraBottomSheet.buildTitle(ctx, l10n.mcpServersTitle),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    children: [
                      SwitchListTile.adaptive(
                        value: followGlobal,
                        onChanged: (v) => unawaited(setFollowGlobal(v)),
                        title: Text(l10n.mcpFollowGlobal),
                        subtitle: followGlobal
                            ? Text(l10n.mcpFollowGlobalHint)
                            : null,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (enabledServers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(l10n.mcpNoEnabledServers),
                        )
                      else
                        ...enabledServers.map((server) {
                          final checked = selectedIds.contains(server.id);
                          final summary = server.transport ==
                                  McpServerTransport.http
                              ? server.url.trim()
                              : [
                                  server.command,
                                  ...server.args,
                                ].where((s) => s.trim().isNotEmpty).join(' ');
                          return SwitchListTile.adaptive(
                            value: checked,
                            onChanged: followGlobal
                                ? null
                                : (v) => unawaited(toggleServer(server.id, v)),
                            title: Text(server.name.isNotEmpty
                                ? server.name
                                : l10n.unknown),
                            subtitle: summary.isEmpty ? null : Text(summary),
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showKnowledgeBasePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final knowledgeState = ref.read(knowledgeProvider);
    if (knowledgeState.isLoading) {
      showAuroraNotice(
        context,
        l10n.loadingEllipsis,
        icon: Icons.info_outline_rounded,
        top: MediaQuery.of(context).padding.top + 64 + 60,
      );
      return;
    }
    if (knowledgeState.error != null) {
      showAuroraNotice(
        context,
        knowledgeState.error!,
        icon: Icons.error_outline_rounded,
        top: MediaQuery.of(context).padding.top + 64 + 60,
      );
      return;
    }

    final bases = knowledgeState.bases.where((b) => b.isEnabled).toList();
    if (bases.isEmpty) {
      showAuroraNotice(
        context,
        l10n.noKnowledgeBaseYetCreateOne,
        icon: Icons.info_outline_rounded,
        top: MediaQuery.of(context).padding.top + 64 + 60,
      );
      return;
    }

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setSheetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(context, l10n.knowledgeBase),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: ListView(
                shrinkWrap: true,
                children: bases.map((base) {
                  final isSelected =
                      _currentAssistant.knowledgeBaseIds.contains(base.baseId);
                  return CheckboxListTile(
                    title: Text(base.name),
                    subtitle: Text(
                      l10n.knowledgeDocsAndChunks(
                          base.documentCount, base.chunkCount),
                    ),
                    value: isSelected,
                    onChanged: (v) {
                      final nextIds =
                          List<String>.from(_currentAssistant.knowledgeBaseIds);
                      if (v == true) {
                        if (!nextIds.contains(base.baseId)) {
                          nextIds.add(base.baseId);
                        }
                      } else {
                        nextIds.remove(base.baseId);
                      }
                      final updated =
                          _currentAssistant.copyWith(knowledgeBaseIds: nextIds);
                      setState(() {
                        _currentAssistant = updated;
                      });
                      setSheetState(() {});
                      ref
                          .read(assistantProvider.notifier)
                          .saveAssistant(updated);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }

  void _showDeleteDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assistantDeleteTitle),
        content: Text(l10n.assistantDeleteConfirm(_currentAssistant.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(assistantProvider.notifier)
                  .deleteAssistant(_currentAssistant.id);
              Navigator.pop(context); // close dialog
              Navigator.pop(this.context); // close page
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMemoryModelPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider);
    final options = <(String value, String label)>[
      ('__follow__', l10n.assistantMemoryFollowCurrentChatModel),
    ];
    for (final provider in settings.providers) {
      if (!provider.isEnabled) continue;
      for (final model in provider.models) {
        if (!provider.isModelEnabled(model)) continue;
        options.add(('${provider.id}@$model', '${provider.name} - $model'));
      }
    }

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(
            context,
            l10n.assistantMemoryConsolidationModel,
          ),
          const Divider(height: 1),
          ...options.map((option) {
            final selectedValue = _currentAssistant.memoryProviderId != null &&
                    _currentAssistant.memoryModel != null
                ? '${_currentAssistant.memoryProviderId}@${_currentAssistant.memoryModel}'
                : '__follow__';
            final isSelected = option.$1 == selectedValue;
            return AuroraBottomSheet.buildListItem(
              context: context,
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
              title: Text(option.$2),
              onTap: () {
                Navigator.pop(ctx);
                if (option.$1 == '__follow__') {
                  _updateAssistant(
                    _currentAssistant.copyWith(
                      memoryProviderId: null,
                      memoryModel: null,
                    ),
                  );
                  return;
                }
                final split = option.$1.split('@');
                if (split.length != 2) return;
                _updateAssistant(
                  _currentAssistant.copyWith(
                    memoryProviderId: split[0],
                    memoryModel: split[1],
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Assistant assistant,
      {double size = 40}) {
    return AssistantAvatar(assistant: assistant, size: size);
  }
}
