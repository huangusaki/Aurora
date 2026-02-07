import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';

import '../../knowledge/presentation/knowledge_provider.dart';
import 'settings_provider.dart';
import 'widgets/mobile_settings_widgets.dart';

class MobileKnowledgeSettingsPage extends ConsumerStatefulWidget {
  const MobileKnowledgeSettingsPage({super.key});

  @override
  ConsumerState<MobileKnowledgeSettingsPage> createState() =>
      _MobileKnowledgeSettingsPageState();
}

class _MobileKnowledgeSettingsPageState
    extends ConsumerState<MobileKnowledgeSettingsPage> {
  String? _selectedBaseId;
  bool _normalizingEmbeddingSettings = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final knowledgeState = ref.watch(knowledgeProvider);
    final bases = knowledgeState.bases;
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

    if (_selectedBaseId == null ||
        !bases.any((b) => b.baseId == _selectedBaseId)) {
      _selectedBaseId = bases.isNotEmpty ? bases.first.baseId : null;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.knowledgeBase),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          MobileSettingsSection(
            title: l10n.general,
            children: [
              MobileSettingsTile(
                leading: const Icon(Icons.auto_awesome),
                title: l10n.enableKnowledgeRetrieval,
                subtitle:
                    settings.isKnowledgeEnabled ? l10n.enabled : l10n.disabled,
                trailing: Switch.adaptive(
                  value: settings.isKnowledgeEnabled,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setKnowledgeEnabled(v),
                ),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.format_list_numbered),
                title: l10n.knowledgeTopKChunks,
                subtitle: settings.knowledgeTopK.toString(),
                onTap: _editTopK,
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.hub_outlined),
                title: l10n.useEmbeddingRerank,
                subtitle: hasValidEmbeddingModel
                    ? (settings.knowledgeUseEmbedding
                        ? l10n.enabled
                        : l10n.disabled)
                    : l10n.noEmbeddingModelsInProvider,
                trailing: Switch.adaptive(
                  value:
                      settings.knowledgeUseEmbedding && hasValidEmbeddingModel,
                  onChanged: hasValidEmbeddingModel
                      ? (v) => ref
                          .read(settingsProvider.notifier)
                          .setKnowledgeUseEmbedding(v)
                      : null,
                ),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.route_outlined),
                title: l10n.embeddingProvider,
                subtitle: embeddingProvider?.name ?? l10n.notConfigured,
                onTap: () => _pickEmbeddingProvider(
                  providers: providers,
                  currentProviderId: embeddingProviderId,
                  settings: settings,
                ),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.memory_outlined),
                title: l10n.embeddingModel,
                subtitle:
                    selectedEmbeddingModel ?? l10n.noEmbeddingModelsInProvider,
                onTap: () => _pickEmbeddingModel(
                  models: embeddingModels,
                  currentModel: selectedEmbeddingModel,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  '${l10n.embeddingModelAutoDetectHint}\n${l10n.knowledgeGlobalFallbackHint}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          MobileSettingsSection(
            title: l10n.knowledgeBases,
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createBase,
            ),
            children: [
              if (knowledgeState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (bases.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(l10n.noKnowledgeBaseYetCreateOne),
                )
              else
                ...bases.map((base) {
                  final isActive =
                      settings.activeKnowledgeBaseIds.contains(base.baseId);
                  final isSelected = _selectedBaseId == base.baseId;
                  return MobileSettingsTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: base.name,
                    subtitle: l10n.knowledgeDocsAndChunks(
                        base.documentCount, base.chunkCount),
                    trailing: Checkbox(
                      value: isActive,
                      onChanged: (v) {
                        final next =
                            List<String>.from(settings.activeKnowledgeBaseIds);
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
                    onTap: () {
                      setState(() {
                        _selectedBaseId = base.baseId;
                      });
                    },
                  );
                }),
              if (bases.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _importFiles,
                          icon: const Icon(Icons.upload_file),
                          label: Text(l10n.importFiles),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteSelectedBase,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.deleteBase),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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

  Future<void> _pickEmbeddingProvider({
    required List<ProviderConfig> providers,
    required String currentProviderId,
    required SettingsState settings,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await AuroraBottomSheet.show<String>(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(ctx, l10n.embeddingProvider),
            const Divider(height: 1),
            ...providers.map((p) {
              final selected = p.id == currentProviderId;
              return AuroraBottomSheet.buildListItem(
                context: ctx,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name),
                    Text(
                      p.id,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                ),
                selected: selected,
                trailing: selected
                    ? Icon(Icons.check, color: Theme.of(ctx).primaryColor)
                    : null,
                onTap: () => Navigator.pop(ctx, p.id),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null || picked == currentProviderId) return;

    final pickedProvider =
        providers.where((p) => p.id == picked).toList(growable: false);
    final providerModels = pickedProvider.isNotEmpty
        ? _extractEmbeddingModels(pickedProvider.first.models)
        : const <String>[];
    final settingsNotifier = ref.read(settingsProvider.notifier);
    await settingsNotifier.setKnowledgeEmbeddingProviderId(picked);

    final current = settings.knowledgeEmbeddingModel;
    if (current == null || !providerModels.contains(current)) {
      await settingsNotifier.setKnowledgeEmbeddingModel(null);
    }
    if (providerModels.isEmpty && settings.knowledgeUseEmbedding) {
      await settingsNotifier.setKnowledgeUseEmbedding(false);
    }
  }

  Future<void> _pickEmbeddingModel({
    required List<String> models,
    required String? currentModel,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (models.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noEmbeddingModelsInProvider)),
      );
      return;
    }

    final picked = await AuroraBottomSheet.show<String>(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(ctx, l10n.embeddingModel),
            const Divider(height: 1),
            ...models.map((m) {
              final selected = m == currentModel;
              return AuroraBottomSheet.buildListItem(
                context: ctx,
                title: Text(m),
                selected: selected,
                trailing: selected
                    ? Icon(Icons.check, color: Theme.of(ctx).primaryColor)
                    : null,
                onTap: () => Navigator.pop(ctx, m),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked == null) return;
    await ref
        .read(settingsProvider.notifier)
        .setKnowledgeEmbeddingModel(picked);
  }

  Future<void> _editTopK() async {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(settingsProvider);
    final input = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.knowledgeTopKChunks,
      hintText: '1-12',
      initialValue: settings.knowledgeTopK.toString(),
      confirmText: l10n.save,
      cancelText: l10n.cancel,
    );
    if (input == null) return;
    final parsed = int.tryParse(input.trim());
    if (parsed == null) return;
    ref.read(settingsProvider.notifier).setKnowledgeTopK(parsed);
  }

  Future<void> _createBase() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final confirmed = await AuroraBottomSheet.show<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuroraBottomSheet.buildTitle(ctx, l10n.createKnowledgeBase),
              const Divider(height: 1),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(hintText: l10n.knowledgeBaseName),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(hintText: l10n.descriptionOptional),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.createBase),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
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

    final confirmed = await AuroraBottomSheet.showConfirm(
      context: context,
      title: l10n.deleteKnowledgeBase,
      content: l10n.deleteKnowledgeBaseConfirm,
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
      isDestructive: true,
    );

    if (confirmed != true) return;
    await ref.read(knowledgeProvider.notifier).deleteBase(baseId);
  }

  Future<void> _importFiles() async {
    final l10n = AppLocalizations.of(context)!;
    final baseId = _selectedBaseId;
    if (baseId == null) return;

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

    await AuroraBottomSheet.show<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraBottomSheet.buildTitle(ctx, l10n.importFinished),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(summary.toString()),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
