import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'package:flutter/material.dart';

import 'package:aurora/shared/riverpod_legacy.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../novel/novel_provider.dart';
import '../novel/novel_state.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';

class MobileModelConfigSheet extends ConsumerStatefulWidget {
  const MobileModelConfigSheet({super.key});

  @override
  ConsumerState<MobileModelConfigSheet> createState() =>
      _MobileModelConfigSheetState();
}

class _MobileModelConfigSheetState
    extends ConsumerState<MobileModelConfigSheet> {
  late Map<String, TextEditingController> _controllers;
  bool _isInitialized = false;
  String? _lastActivePresetId;

  static const double _controlRadius = 12;

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
    final novelNotifier = ref.read(novelProvider.notifier);
    final novelState = ref.watch(novelProvider);
    final settingsState = ref.watch(settingsProvider);
    final activePresetId = novelState.activePromptPresetId;
    NovelPromptPreset? activePreset;
    if (activePresetId != null) {
      for (final preset in novelState.promptPresets) {
        if (preset.id == activePresetId) {
          activePreset = preset;
          break;
        }
      }
    }

    final allModels = <NovelModelConfig>[];
    for (final provider in settingsState.providers) {
      if (provider.isEnabled && provider.models.isNotEmpty) {
        for (final model in provider.models) {
          if (provider.isModelEnabled(model)) {
            allModels
                .add(NovelModelConfig(providerId: provider.id, modelId: model));
          }
        }
      }
    }

    if (!_isInitialized) {
      _controllers['outline']!.text =
          novelState.outlineModel?.systemPrompt ?? '';
      _controllers['decompose']!.text =
          novelState.decomposeModel?.systemPrompt ?? '';
      _controllers['writer']!.text = novelState.writerModel?.systemPrompt ?? '';
      _controllers['reviewer']!.text =
          novelState.reviewerModel?.systemPrompt ?? '';
      _isInitialized = true;
      _lastActivePresetId = novelState.activePromptPresetId;
    } else if (_lastActivePresetId != novelState.activePromptPresetId) {
      // 检查是否发生了预设切换
      _controllers['outline']!.text =
          novelState.outlineModel?.systemPrompt ?? '';
      _controllers['decompose']!.text =
          novelState.decomposeModel?.systemPrompt ?? '';
      _controllers['writer']!.text = novelState.writerModel?.systemPrompt ?? '';
      _controllers['reviewer']!.text =
          novelState.reviewerModel?.systemPrompt ?? '';
      _lastActivePresetId = novelState.activePromptPresetId;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 顶部标题栏
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
          child: Row(
            children: [
              const Icon(AuroraIcons.settings, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.modelConfig,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // 预设管理按钮组
              IconButton(
                tooltip: l10n.selectPreset,
                icon: const Icon(AuroraIcons.parameter, size: 20),
                onPressed: () =>
                    _showPresetPicker(context, novelState, novelNotifier, l10n),
              ),
              if (activePreset != null)
                IconButton(
                  tooltip: '${l10n.save} "${activePreset.name}"',
                  icon: const Icon(AuroraIcons.save, size: 20),
                  onPressed: () {
                    final currentPreset = activePreset;
                    if (currentPreset == null) return;
                    final updatedPreset = currentPreset.copyWith(
                      outlinePrompt: _controllers['outline']?.text ?? '',
                      decomposePrompt: _controllers['decompose']?.text ?? '',
                      writerPrompt: _controllers['writer']?.text ?? '',
                      reviewerPrompt: _controllers['reviewer']?.text ?? '',
                    );
                    ref
                        .read(novelProvider.notifier)
                        .updatePromptPreset(updatedPreset);
                    showAuroraNotice(
                      context,
                      l10n.presetSaved(updatedPreset.name),
                      icon: AuroraIcons.success,
                    );
                  },
                ),
              IconButton(
                tooltip: l10n.newNovelPreset,
                icon: const Icon(AuroraIcons.add, size: 20),
                onPressed: () => _showSavePresetDialog(context, ref),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(AuroraIcons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
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
                AuroraIcons.list,
                NovelPromptPresets.outline,
                novelState.outlineModel,
                allModels,
                settingsState,
                novelNotifier.setOutlineModel,
                novelNotifier.setOutlinePrompt,
              ),
              const SizedBox(height: 16),
              _buildModelSection(
                context,
                'decompose',
                l10n.decomposeModel,
                AuroraIcons.split,
                NovelPromptPresets.decompose,
                novelState.decomposeModel,
                allModels,
                settingsState,
                novelNotifier.setDecomposeModel,
                novelNotifier.setDecomposePrompt,
              ),
              const SizedBox(height: 16),
              
              // 破限模式开关 - 独立卡片
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: novelState.isUnlimitedMode 
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                        : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(AuroraIcons.warning, 
                          size: 18, 
                          color: novelState.isUnlimitedMode ? Colors.orange : Theme.of(context).iconTheme.color),
                      const SizedBox(width: 8),
                      Text(l10n.novelUnlimitedMode,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Text(l10n.novelUnlimitedModeHint,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  value: novelState.isUnlimitedMode,
                  activeThumbColor: Colors.orange,
                  onChanged: (val) {
                    novelNotifier.setUnlimitedMode(val);
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              _buildModelSection(
                context,
                'writer',
                l10n.writerModel,
                AuroraIcons.edit,
                NovelPromptPresets.writerBase, // Use writerBase for display default
                novelState.writerModel,
                allModels,
                settingsState,
                novelNotifier.setWriterModel,
                novelNotifier.setWriterPrompt,
              ),
              const SizedBox(height: 16),
              _buildModelSection(
                context,
                'reviewer',
                l10n.reviewModel,
                AuroraIcons.view,
                NovelPromptPresets.reviewer,
                novelState.reviewerModel,
                allModels,
                settingsState,
                novelNotifier.setReviewerModel,
                novelNotifier.setReviewerPrompt,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelSection(
    BuildContext context,
    String key,
    String label,
    IconData icon,
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
            (m) =>
                m.providerId == currentConfig.providerId &&
                m.modelId == currentConfig.modelId,
            orElse: () => NovelModelConfig(
                providerId: currentConfig.providerId,
                modelId: currentConfig.modelId))
        : null;

    final providerName = selectedBase != null
        ? settingsState.providers
            .firstWhere((p) => p.id == selectedBase.providerId,
                orElse: () => ProviderConfig(id: '', name: 'Unknown'))
            .name
        : '';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Model Selector Button
          InkWell(
            onTap: () => _showModelPicker(
              context,
              label,
              allModels,
              settingsState,
              selectedBase,
              onModelChanged,
              key,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedBase != null 
                      ? theme.primaryColor.withValues(alpha: 0.3)
                      : theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedBase != null) 
                          Text(
                            providerName,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Text(
                          selectedBase != null ? selectedBase.modelId : l10n.selectModel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selectedBase != null ? theme.textTheme.bodyMedium?.color : theme.hintColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    AuroraIcons.chevronDown,
                    color: theme.hintColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // System Prompt Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.systemPrompt,
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.hintColor)),
              // Reset Button
              SizedBox(
                height: 24,
                child: TextButton.icon(
                  onPressed: () {
                    _controllers[key]!.text = presetPrompt;
                    onPromptChanged(presetPrompt);
                  },
                  icon: const Icon(AuroraIcons.reset, size: 14),
                  label: Text(l10n.defaultPreset,
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Prompt Input
          TextField(
            controller: _controllers[key],
            maxLines: null,
            minLines: 3,
            style: const TextStyle(fontSize: 13, height: 1.4),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
              hintText: l10n.systemPromptPlaceholder,
              hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.5)),
            ),
            onChanged: onPromptChanged,
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog(BuildContext context, WidgetRef ref) {
    _showSavePresetSheet(context, ref);
  }

  void _showPresetPicker(
    BuildContext context,
    NovelWritingState novelState,
    NovelNotifier novelNotifier,
    AppLocalizations l10n,
  ) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(context, l10n.selectPreset),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                AuroraBottomSheet.buildListItem(
                  context: context,
                  title: Text(l10n.systemDefault),
                  selected: novelState.activePromptPresetId == null,
                  onTap: () {
                    _controllers['outline']!.text = NovelPromptPresets.outline;
                    novelNotifier.setOutlinePrompt(NovelPromptPresets.outline);
                    _controllers['decompose']!.text =
                        NovelPromptPresets.decompose;
                    novelNotifier
                        .setDecomposePrompt(NovelPromptPresets.decompose);
                    _controllers['writer']!.text = NovelPromptPresets.writer;
                    novelNotifier.setWriterPrompt(NovelPromptPresets.writer);
                    _controllers['reviewer']!.text =
                        NovelPromptPresets.reviewer;
                    novelNotifier
                        .setReviewerPrompt(NovelPromptPresets.reviewer);
                    novelNotifier.setActivePromptPresetId(null);
                    showAuroraNotice(
                      context,
                      l10n.systemDefaultRestored,
                      icon: AuroraIcons.reset,
                    );
                    Navigator.pop(ctx);
                  },
                ),
                if (novelState.promptPresets.isNotEmpty) const Divider(),
                ...novelState.promptPresets
                    .map((preset) => AuroraBottomSheet.buildListItem(
                        context: context,
                        title: Text(preset.name),
                        selected: novelState.activePromptPresetId == preset.id,
                        onTap: () {
                          if (preset.outlinePrompt.isNotEmpty) {
                            _controllers['outline']!.text =
                                preset.outlinePrompt;
                            novelNotifier
                                .setOutlinePrompt(preset.outlinePrompt);
                          }
                          if (preset.decomposePrompt.isNotEmpty) {
                            _controllers['decompose']!.text =
                                preset.decomposePrompt;
                            novelNotifier
                                .setDecomposePrompt(preset.decomposePrompt);
                          }
                          if (preset.writerPrompt.isNotEmpty) {
                            _controllers['writer']!.text = preset.writerPrompt;
                            novelNotifier.setWriterPrompt(preset.writerPrompt);
                          }
                          if (preset.reviewerPrompt.isNotEmpty) {
                            _controllers['reviewer']!.text =
                                preset.reviewerPrompt;
                            novelNotifier
                                .setReviewerPrompt(preset.reviewerPrompt);
                          }
                          novelNotifier.setActivePromptPresetId(preset.id);
                          showAuroraNotice(
                            context,
                            l10n.presetLoaded(preset.name),
                            icon: AuroraIcons.success,
                          );
                          Navigator.pop(ctx);
                        },
                        trailing: IconButton(
                          icon: const Icon(AuroraIcons.delete, size: 20),
                          onPressed: () {
                            novelNotifier.deletePromptPreset(preset.id);
                          },
                        ))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showModelPicker(
    BuildContext context,
    String label,
    List<NovelModelConfig> allModels,
    SettingsState settingsState,
    NovelModelConfig? currentConfig,
    void Function(NovelModelConfig?) onModelChanged,
    String key,
  ) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(context, label),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final provider in settingsState.providers) ...[
                  if (provider.isEnabled && provider.models.isNotEmpty) ...[
                    ListTile(
                      dense: true,
                      enabled: false,
                      title: Text(
                        provider.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12),
                      ),
                    ),
                    ...provider.models
                        .where((m) => provider.isModelEnabled(m))
                        .map((modelId) {
                      final itemConfig = NovelModelConfig(
                          providerId: provider.id, modelId: modelId);
                      final isSelected =
                          currentConfig?.providerId == provider.id &&
                              currentConfig?.modelId == modelId;

                      return AuroraBottomSheet.buildListItem(
                        context: context,
                        title: Text(modelId),
                        selected: isSelected,
                        onTap: () {
                          final currentText = _controllers[key]!.text;
                          onModelChanged(
                              itemConfig.copyWith(systemPrompt: currentText));
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                    if (provider !=
                        settingsState.providers
                            .where((p) => p.isEnabled && p.models.isNotEmpty)
                            .last)
                      const Divider(height: 1),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSavePresetSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuroraBottomSheet.buildTitle(context, l10n.newNovelPreset),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.presetName,
                    hintText: '${l10n.pleaseEnter}${l10n.presetName}...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_controlRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.savePresetHint,
                  style:
                      TextStyle(fontSize: 12, color: Theme.of(ctx).hintColor),
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
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            final preset = NovelPromptPreset.create(
                              name: name,
                              outlinePrompt:
                                  _controllers['outline']?.text ?? '',
                              decomposePrompt:
                                  _controllers['decompose']?.text ?? '',
                              writerPrompt: _controllers['writer']?.text ?? '',
                              reviewerPrompt:
                                  _controllers['reviewer']?.text ?? '',
                            );
                            ref
                                .read(novelProvider.notifier)
                                .addPromptPreset(preset);
                            Navigator.pop(ctx);
                            showAuroraNotice(
                              context,
                              l10n.presetSaved(name),
                              icon: AuroraIcons.success,
                            );
                          }
                        },
                        child: Text(l10n.save),
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


