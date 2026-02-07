import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';

import '../../knowledge/presentation/knowledge_provider.dart';
import 'settings_provider.dart';

class KnowledgeSettingsPanel extends ConsumerStatefulWidget {
  const KnowledgeSettingsPanel({super.key});

  @override
  ConsumerState<KnowledgeSettingsPanel> createState() =>
      _KnowledgeSettingsPanelState();
}

class _KnowledgeSettingsPanelState
    extends ConsumerState<KnowledgeSettingsPanel> {
  String? _selectedBaseId;
  bool _normalizingEmbeddingSettings = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final knowledgeState = ref.watch(knowledgeProvider);
    final notifier = ref.read(knowledgeProvider.notifier);

    final bases = knowledgeState.bases;
    if (_selectedBaseId == null ||
        !bases.any((b) => b.baseId == _selectedBaseId)) {
      _selectedBaseId = bases.isNotEmpty ? bases.first.baseId : null;
    }

    final providers = settings.providers;
    final embeddingProviderId =
        settings.knowledgeEmbeddingProviderId ?? settings.activeProviderId;
    final selectedProvider =
        providers.where((p) => p.id == embeddingProviderId);
    final embeddingProvider =
        selectedProvider.isNotEmpty ? selectedProvider.first : null;
    final embeddingModels = _extractEmbeddingModels(embeddingProvider?.models);
    final selectedEmbeddingModel = embeddingModels
            .where((m) => m == settings.knowledgeEmbeddingModel)
            .isNotEmpty
        ? settings.knowledgeEmbeddingModel
        : null;
    final hasValidEmbeddingModel = selectedEmbeddingModel != null;

    if (!_normalizingEmbeddingSettings) {
      final shouldClearModel =
          settings.knowledgeEmbeddingModel != null && !hasValidEmbeddingModel;
      final shouldDisableEmbedding =
          settings.knowledgeUseEmbedding && !hasValidEmbeddingModel;
      if (shouldClearModel || shouldDisableEmbedding) {
        _normalizingEmbeddingSettings = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final settingsNotifier = ref.read(settingsProvider.notifier);
          if (shouldClearModel) {
            await settingsNotifier.setKnowledgeEmbeddingModel(null);
          }
          if (shouldDisableEmbedding) {
            await settingsNotifier.setKnowledgeUseEmbedding(false);
          }
          _normalizingEmbeddingSettings = false;
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              fluent.Text(
                l10n.knowledgeBase,
                style: fluent.FluentTheme.of(context).typography.subtitle,
              ),
              const Spacer(),
              fluent.Button(
                onPressed: knowledgeState.isLoading
                    ? null
                    : () => notifier.loadBases(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 14),
                    const SizedBox(width: 8),
                    Text(l10n.refreshList),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          fluent.InfoLabel(
            label: l10n.enableKnowledgeRetrieval,
            child: fluent.ToggleSwitch(
              checked: settings.isKnowledgeEnabled,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setKnowledgeEnabled(v),
              content: Text(
                  settings.isKnowledgeEnabled ? l10n.enabled : l10n.disabled),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.knowledgeGlobalFallbackHint,
            style: TextStyle(
              color: fluent.FluentTheme.of(context)
                  .resources
                  .textFillColorSecondary,
            ),
          ),
          const SizedBox(height: 12),
          fluent.InfoLabel(
            label: '${l10n.knowledgeTopKChunks} (${settings.knowledgeTopK})',
            child: fluent.Slider(
              min: 1,
              max: 12,
              value: settings.knowledgeTopK.toDouble(),
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setKnowledgeTopK(v.round()),
            ),
          ),
          const SizedBox(height: 12),
          fluent.InfoLabel(
            label: l10n.useEmbeddingRerank,
            child: fluent.ToggleSwitch(
              checked: settings.knowledgeUseEmbedding && hasValidEmbeddingModel,
              onChanged: hasValidEmbeddingModel
                  ? (v) => ref
                      .read(settingsProvider.notifier)
                      .setKnowledgeUseEmbedding(v)
                  : null,
              content: Text(
                hasValidEmbeddingModel
                    ? (settings.knowledgeUseEmbedding
                        ? l10n.enabled
                        : l10n.disabled)
                    : l10n.noEmbeddingModelsInProvider,
              ),
            ),
          ),
          const SizedBox(height: 12),
          fluent.InfoLabel(
            label: l10n.knowledgeLlmEnhancementMode,
            child: fluent.ComboBox<String>(
              value: settings.knowledgeLlmEnhanceMode,
              items: [
                fluent.ComboBoxItem(
                    value: 'off', child: Text(l10n.knowledgeModeOff)),
                fluent.ComboBoxItem(
                    value: 'rewrite', child: Text(l10n.knowledgeModeRewrite)),
              ],
              onChanged: (v) {
                if (v == null) return;
                ref
                    .read(settingsProvider.notifier)
                    .setKnowledgeLlmEnhanceMode(v);
              },
            ),
          ),
          const SizedBox(height: 12),
          fluent.InfoLabel(
            label: l10n.embeddingProvider,
            child: fluent.ComboBox<String>(
              value: embeddingProviderId,
              isExpanded: true,
              items: providers
                  .map(
                    (p) => fluent.ComboBoxItem<String>(
                      value: p.id,
                      child: Text(p.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final provider =
                    providers.where((p) => p.id == v).toList(growable: false);
                final providerModels = provider.isNotEmpty
                    ? _extractEmbeddingModels(provider.first.models)
                    : const <String>[];
                final settingsNotifier = ref.read(settingsProvider.notifier);
                settingsNotifier.setKnowledgeEmbeddingProviderId(v);
                final current = settings.knowledgeEmbeddingModel;
                if (current == null || !providerModels.contains(current)) {
                  settingsNotifier.setKnowledgeEmbeddingModel(null);
                }
                if (providerModels.isEmpty && settings.knowledgeUseEmbedding) {
                  settingsNotifier.setKnowledgeUseEmbedding(false);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          fluent.InfoLabel(
            label: l10n.embeddingModel,
            child: embeddingModels.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: fluent.FluentTheme.of(context)
                            .resources
                            .dividerStrokeColorDefault,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.noEmbeddingModelsInProvider,
                      style: TextStyle(
                        color: fluent.FluentTheme.of(context)
                            .resources
                            .textFillColorSecondary,
                      ),
                    ),
                  )
                : fluent.ComboBox<String>(
                    value: selectedEmbeddingModel,
                    isExpanded: true,
                    items: embeddingModels
                        .map(
                          (m) => fluent.ComboBoxItem<String>(
                            value: m,
                            child: Text(m),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      ref
                          .read(settingsProvider.notifier)
                          .setKnowledgeEmbeddingModel(v);
                    },
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.embeddingModelAutoDetectHint,
            style: TextStyle(
              color: fluent.FluentTheme.of(context)
                  .resources
                  .textFillColorSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          const fluent.Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              fluent.FilledButton(
                onPressed:
                    knowledgeState.isWorking ? null : _showCreateBaseDialog,
                child: Text(l10n.createBase),
              ),
              const SizedBox(width: 8),
              fluent.Button(
                onPressed: knowledgeState.isWorking || _selectedBaseId == null
                    ? null
                    : _importFiles,
                child: Text(l10n.importFiles),
              ),
              const SizedBox(width: 8),
              fluent.Button(
                onPressed: knowledgeState.isWorking || _selectedBaseId == null
                    ? null
                    : _deleteSelectedBase,
                child: Text(l10n.deleteBase),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (knowledgeState.error != null && knowledgeState.error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                knowledgeState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (knowledgeState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (bases.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.noKnowledgeBaseYetCreateOne),
            )
          else
            ...bases.map((base) {
              final isSelected = base.baseId == _selectedBaseId;
              final isActive =
                  settings.activeKnowledgeBaseIds.contains(base.baseId);
              final hintColor = fluent.FluentTheme.of(context)
                  .resources
                  .textFillColorSecondary;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? fluent.FluentTheme.of(context).accentColor
                        : fluent.FluentTheme.of(context)
                            .resources
                            .dividerStrokeColorDefault,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fluent.RadioButton(
                          checked: isSelected,
                          content: const SizedBox.shrink(),
                          onChanged: (v) {
                            if (v) {
                              setState(() {
                                _selectedBaseId = base.baseId;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            base.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (base.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 30, top: 4),
                        child: Text(
                          base.description,
                          style: TextStyle(
                            color: hintColor,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 30, top: 6),
                      child: Text(l10n.knowledgeDocsAndChunks(
                          base.documentCount, base.chunkCount)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.only(left: 30),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: fluent.FluentTheme.of(context)
                              .resources
                              .dividerStrokeColorDefault,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.knowledgeGlobalSelectionLabel),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.knowledgeGlobalSelectionHint,
                                      style: TextStyle(
                                        color: hintColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              fluent.Checkbox(
                                checked: isActive,
                                content: const SizedBox.shrink(),
                                onChanged: (v) {
                                  final next = List<String>.from(
                                      settings.activeKnowledgeBaseIds);
                                  if (v == true) {
                                    if (!next.contains(base.baseId)) {
                                      next.add(base.baseId);
                                    }
                                  } else {
                                    next.remove(base.baseId);
                                  }
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setActiveKnowledgeBaseIds(next);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.knowledgeBaseEnabledLabel),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.knowledgeBaseEnabledHint,
                                      style: TextStyle(
                                        color: hintColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              fluent.ToggleSwitch(
                                checked: base.isEnabled,
                                onChanged: (v) =>
                                    notifier.setBaseEnabled(base.baseId, v),
                                content: const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<String> _extractEmbeddingModels(List<String>? models) {
    if (models == null || models.isEmpty) {
      return const <String>[];
    }
    final picked = <String>{};
    for (final model in models) {
      final normalized = model.trim();
      if (normalized.isEmpty) {
        continue;
      }
      if (_looksLikeEmbeddingModel(normalized)) {
        picked.add(normalized);
      }
    }
    final list = picked.toList()..sort();
    return list;
  }

  bool _looksLikeEmbeddingModel(String model) {
    return model.toLowerCase().contains('embedding');
  }

  Future<void> _showCreateBaseDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return fluent.ContentDialog(
          title: Text(l10n.createKnowledgeBase),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fluent.TextBox(
                controller: nameController,
                placeholder: l10n.knowledgeBaseName,
              ),
              const SizedBox(height: 12),
              fluent.TextBox(
                controller: descriptionController,
                placeholder: l10n.descriptionOptional,
              ),
            ],
          ),
          actions: [
            fluent.Button(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            fluent.FilledButton(
              child: Text(l10n.createBase),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (created != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(knowledgeProvider.notifier).createBase(
          name: name,
          description: descriptionController.text.trim(),
        );
  }

  Future<void> _deleteSelectedBase() async {
    final l10n = AppLocalizations.of(context)!;
    final baseId = _selectedBaseId;
    if (baseId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text(l10n.deleteKnowledgeBase),
        content: Text(l10n.deleteKnowledgeBaseConfirm),
        actions: [
          fluent.Button(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          fluent.FilledButton(
            child: Text(l10n.delete),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(knowledgeProvider.notifier).deleteBase(baseId);
  }

  Future<void> _importFiles() async {
    final baseId = _selectedBaseId;
    if (baseId == null) return;

    final l10n = AppLocalizations.of(context)!;
    final typeGroup = XTypeGroup(
      label: l10n.knowledgeFiles,
      extensions: ['txt', 'md', 'csv', 'json', 'xml', 'yaml', 'yml', 'docx'],
    );

    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return;

    final settings = ref.read(settingsProvider);
    final report = await ref.read(knowledgeProvider.notifier).ingestFiles(
          baseId: baseId,
          paths: files.map((f) => f.path).toList(),
          settings: settings,
        );
    final summary = StringBuffer()
      ..write(l10n.knowledgeImportSummary(
          report.successCount, report.failureCount));
    if (report.errors.isNotEmpty) {
      summary
        ..writeln()
        ..writeln()
        ..write(report.errors.join('\n'));
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text(l10n.importFinished),
        content: Text(summary.toString()),
        actions: [
          fluent.FilledButton(
            child: Text(l10n.confirm),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
