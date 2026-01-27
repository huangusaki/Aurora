import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../novel/novel_provider.dart';
import '../novel/novel_state.dart';

class MobileModelConfigSheet extends ConsumerStatefulWidget {
  const MobileModelConfigSheet({super.key});

  @override
  ConsumerState<MobileModelConfigSheet> createState() => _MobileModelConfigSheetState();
}

class _MobileModelConfigSheetState extends ConsumerState<MobileModelConfigSheet> {
  late Map<String, TextEditingController> _controllers;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'outline': TextEditingController(),
      'decompose': TextEditingController(),
      'writer': TextEditingController(),
      'reviewer': TextEditingController(),
    };
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final novelNotifier = ref.read(novelProvider.notifier);
    final novelState = ref.watch(novelProvider);
    final settingsState = ref.watch(settingsProvider);

    final allModels = <NovelModelConfig>[];
    for (final provider in settingsState.providers) {
      if (provider.isEnabled && provider.models.isNotEmpty) {
        for (final model in provider.models) {
          if (provider.isModelEnabled(model)) {
            allModels.add(NovelModelConfig(providerId: provider.id, modelId: model));
          }
        }
      }
    }

    if (!_isInitialized) {
      _controllers['outline']!.text = novelState.outlineModel?.systemPrompt ?? '';
      _controllers['decompose']!.text = novelState.decomposeModel?.systemPrompt ?? '';
      _controllers['writer']!.text = novelState.writerModel?.systemPrompt ?? '';
      _controllers['reviewer']!.text = novelState.reviewerModel?.systemPrompt ?? '';
      _isInitialized = true;
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text(l10n.modelConfig),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              // 全局预设管理
            IconButton(
              tooltip: l10n.newNovelPreset,
              icon: const Icon(Icons.add),
              onPressed: () => _showSavePresetDialog(context, ref),
            ),
            PopupMenuButton<NovelPromptPreset?>(
              tooltip: l10n.selectPreset,
              icon: const Icon(Icons.bookmark_outline),
              itemBuilder: (context) {
                final presets = ref.read(novelProvider).promptPresets;
                return [
                  PopupMenuItem<NovelPromptPreset?>(
                    value: null,
                    child: Text(l10n.systemDefault, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                    if (presets.isNotEmpty) const PopupMenuDivider(),
                    ...presets.map((preset) => PopupMenuItem<NovelPromptPreset?>(
                      value: preset,
                      child: Row(
                        children: [
                          Expanded(child: Text(preset.name, style: const TextStyle(fontSize: 12))),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              ref.read(novelProvider.notifier).deletePromptPreset(preset.id);
                              Navigator.pop(context); // Close menu to refresh
                            },
                          ),
                        ],
                      ),
                    )),
                  ];
                },
                onSelected: (preset) {
                  if (preset == null) {
                    // 应用系统默认
                    _controllers['outline']!.text = NovelPromptPresets.outline;
                    novelNotifier.setOutlinePrompt(NovelPromptPresets.outline);
                    _controllers['decompose']!.text = NovelPromptPresets.decompose;
                    novelNotifier.setDecomposePrompt(NovelPromptPresets.decompose);
                    _controllers['writer']!.text = NovelPromptPresets.writer;
                    novelNotifier.setWriterPrompt(NovelPromptPresets.writer);
                    _controllers['reviewer']!.text = NovelPromptPresets.reviewer;
                    novelNotifier.setReviewerPrompt(NovelPromptPresets.reviewer);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.systemDefaultRestored)),
                    );
                    return;
                  }
                  
                  // 应用整套预设
                  if (preset.outlinePrompt.isNotEmpty) {
                    _controllers['outline']!.text = preset.outlinePrompt;
                    novelNotifier.setOutlinePrompt(preset.outlinePrompt);
                  }
                  if (preset.decomposePrompt.isNotEmpty) {
                    _controllers['decompose']!.text = preset.decomposePrompt;
                    novelNotifier.setDecomposePrompt(preset.decomposePrompt);
                  }
                  if (preset.writerPrompt.isNotEmpty) {
                    _controllers['writer']!.text = preset.writerPrompt;
                    novelNotifier.setWriterPrompt(preset.writerPrompt);
                  }
                  if (preset.reviewerPrompt.isNotEmpty) {
                    _controllers['reviewer']!.text = preset.reviewerPrompt;
                    novelNotifier.setReviewerPrompt(preset.reviewerPrompt);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.presetLoaded(preset.name))),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
                _buildModelSection(
                  context,
                  'outline',
                  l10n.outlineModel,
                  NovelPromptPresets.outline,
                  novelState.outlineModel,
                  allModels,
                  settingsState,
                  novelNotifier.setOutlineModel,
                  novelNotifier.setOutlinePrompt,
                ),
                _buildModelSection(
                  context,
                  'decompose',
                  l10n.decomposeModel,
                  NovelPromptPresets.decompose,
                  novelState.decomposeModel,
                  allModels,
                  settingsState,
                  novelNotifier.setDecomposeModel,
                  novelNotifier.setDecomposePrompt,
                ),
                _buildModelSection(
                  context,
                  'writer',
                  l10n.writerModel,
                  NovelPromptPresets.writer,
                  novelState.writerModel,
                  allModels,
                  settingsState,
                  novelNotifier.setWriterModel,
                  novelNotifier.setWriterPrompt,
                ),
                _buildModelSection(
                  context,
                  'reviewer',
                  l10n.reviewModel,
                  NovelPromptPresets.reviewer,
                  novelState.reviewerModel,
                  allModels,
                  settingsState,
                  novelNotifier.setReviewerModel,
                  novelNotifier.setReviewerPrompt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSection(
    BuildContext context,
    String key,
    String label,
    String presetPrompt,
    NovelModelConfig? currentConfig,
    List<NovelModelConfig> allModels,
    SettingsState settingsState,
    void Function(NovelModelConfig?) onModelChanged,
    void Function(String) onPromptChanged,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    final selectedBase = currentConfig != null 
        ? allModels.firstWhere(
            (m) => m.providerId == currentConfig.providerId && m.modelId == currentConfig.modelId, 
            orElse: () => NovelModelConfig(providerId: currentConfig.providerId, modelId: currentConfig.modelId))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<NovelModelConfig>(
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: Text(l10n.selectModel),
          value: allModels.contains(selectedBase) ? selectedBase : null,
          items: allModels.map((item) {
            final providerName = settingsState.providers
                .firstWhere((p) => p.id == item.providerId, orElse: () => ProviderConfig(id: item.providerId, name: 'Unknown'))
                .name;
            return DropdownMenuItem<NovelModelConfig>(
              value: item,
              child: Text('$providerName - ${item.modelId}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              final currentText = _controllers[key]!.text;
              final newConfig = val.copyWith(systemPrompt: currentText);
              onModelChanged(newConfig);
            } else {
              onModelChanged(null);
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.systemPrompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            // 恢复默认
            TextButton(
              onPressed: () {
                _controllers[key]!.text = presetPrompt;
                onPromptChanged(presetPrompt);
              },
              child: Text(l10n.defaultPreset, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        TextField(
          controller: _controllers[key],
          maxLines: null,
          minLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n.systemPromptPlaceholder,
          ),
          onChanged: onPromptChanged,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showSavePresetDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newNovelPreset),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.presetName,
                hintText: '${l10n.pleaseEnter}${l10n.presetName}...',
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.savePresetHint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final preset = NovelPromptPreset.create(
                  name: name,
                  outlinePrompt: _controllers['outline']?.text ?? '',
                  decomposePrompt: _controllers['decompose']?.text ?? '',
                  writerPrompt: _controllers['writer']?.text ?? '',
                  reviewerPrompt: _controllers['reviewer']?.text ?? '',
                );
                ref.read(novelProvider.notifier).addPromptPreset(preset);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.presetSaved(name))),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
