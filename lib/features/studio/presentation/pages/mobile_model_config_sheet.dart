import 'dart:async';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../novel/novel_provider.dart';
import '../novel/novel_state.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';

class MobileModelConfigSheet extends ConsumerStatefulWidget {
  const MobileModelConfigSheet({super.key});

  @override
  ConsumerState<MobileModelConfigSheet> createState() => _MobileModelConfigSheetState();
}

class _MobileModelConfigSheetState extends ConsumerState<MobileModelConfigSheet> {
  late Map<String, TextEditingController> _controllers;
  bool _isInitialized = false;
  String? _lastActivePresetId;
  
  bool _toastVisible = false;
  String _toastMessage = '';
  IconData? _toastIcon;
  Timer? _toastTimer;

  void _showToast(String message, IconData icon) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIcon = icon;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  Widget _buildToastWidget() {
    final theme = Theme.of(context);
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: IgnorePointer(
        ignoring: !_toastVisible,
        child: Center(
          child: AnimatedOpacity(
            opacity: _toastVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_toastIcon != null) ...[
                    Icon(_toastIcon,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      _toastMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


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
    _toastTimer?.cancel();
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
      _lastActivePresetId = novelState.activePromptPresetId;
    } else if (_lastActivePresetId != novelState.activePromptPresetId) {
      // 检查是否发生了预设切换
      _controllers['outline']!.text = novelState.outlineModel?.systemPrompt ?? '';
      _controllers['decompose']!.text = novelState.decomposeModel?.systemPrompt ?? '';
      _controllers['writer']!.text = novelState.writerModel?.systemPrompt ?? '';
      _controllers['reviewer']!.text = novelState.reviewerModel?.systemPrompt ?? '';
      _lastActivePresetId = novelState.activePromptPresetId;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: Text(l10n.modelConfig, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            // 全局预设管理
            if (novelState.activePromptPresetId != null)
              IconButton(
                tooltip:
                    '${l10n.save} "${novelState.promptPresets.firstWhere((p) => p.id == novelState.activePromptPresetId).name}"',
                icon: const Icon(AuroraIcons.save),
                onPressed: () {
                  final activeId = novelState.activePromptPresetId!;
                  final currentPreset = novelState.promptPresets
                      .firstWhere((p) => p.id == activeId);
                  final updatedPreset = currentPreset.copyWith(
                    outlinePrompt: _controllers['outline']?.text ?? '',
                    decomposePrompt: _controllers['decompose']?.text ?? '',
                    writerPrompt: _controllers['writer']?.text ?? '',
                    reviewerPrompt: _controllers['reviewer']?.text ?? '',
                  );
                  ref
                      .read(novelProvider.notifier)
                      .updatePromptPreset(updatedPreset);
                  _showToast(
                      l10n.presetSaved(updatedPreset.name), Icons.check_circle);
                },
              ),
            IconButton(
              tooltip: l10n.newNovelPreset,
              icon: const Icon(AuroraIcons.add),
              onPressed: () => _showSavePresetDialog(context, ref),
            ),
            IconButton(
              tooltip: l10n.selectPreset,
              icon: const Icon(AuroraIcons.parameter),
              onPressed: () =>
                  _showPresetPicker(context, novelState, novelNotifier, l10n),
            ),
            IconButton(
              icon: const Icon(AuroraIcons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const Divider(height: 1),
        Flexible(
          child: Stack(
            children: [
              ListView(
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
                  const SizedBox(height: 16),
                ],
              ),
              _buildToastWidget(),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
              color: theme.cardColor.withOpacity(0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedBase != null 
                        ? '${settingsState.providers.firstWhere((p) => p.id == selectedBase.providerId, orElse: () => ProviderConfig(id: '', name: 'Unknown')).name} - ${selectedBase.modelId}'
                        : l10n.selectModel,
                    style: TextStyle(
                      fontSize: 13,
                      color: selectedBase != null ? null : theme.hintColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: theme.hintColor),
              ],
            ),
          ),
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
                    novelNotifier.setReviewerPrompt(NovelPromptPresets.reviewer);
                    novelNotifier.setActivePromptPresetId(null);
                    _showToast(l10n.systemDefaultRestored,
                        Icons.settings_backup_restore);
                    Navigator.pop(ctx);
                  },
                ),
                if (novelState.promptPresets.isNotEmpty) const Divider(),
                ...novelState.promptPresets.map((preset) =>
                    AuroraBottomSheet.buildListItem(
                        context: context,
                        title: Text(preset.name),
                        selected: novelState.activePromptPresetId == preset.id,
                        onTap: () {
                          if (preset.outlinePrompt.isNotEmpty) {
                            _controllers['outline']!.text = preset.outlinePrompt;
                            novelNotifier.setOutlinePrompt(preset.outlinePrompt);
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
                          _showToast(
                              l10n.presetLoaded(preset.name), Icons.check_circle);
                          Navigator.pop(ctx);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
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
    final l10n = AppLocalizations.of(context)!;
    
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
    final theme = Theme.of(context);
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
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.savePresetHint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                              outlinePrompt: _controllers['outline']?.text ?? '',
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
                            _showToast(
                                l10n.presetSaved(name), Icons.check_circle);
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
