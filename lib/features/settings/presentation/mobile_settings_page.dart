import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import '../domain/provider_route_config.dart';
import 'settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora/shared/widgets/aurora_dropdown.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'model_display_name.dart';
import 'provider_route_labels.dart';
import 'settings_config_draft.dart';
import 'widgets/mobile_settings_widgets.dart';

class MobileSettingsPage extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const MobileSettingsPage({super.key, this.onBack});
  @override
  ConsumerState<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends ConsumerState<MobileSettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();

  final Map<String, bool> _enabledModelsExpandedByProvider = {};
  final Map<String, bool> _disabledModelsExpandedByProvider = {};
  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _refreshModelsWithNotice(AppLocalizations l10n) async {
    final success = await ref.read(settingsProvider.notifier).fetchModels();
    if (!mounted) return;

    if (success) {
      showAuroraNotice(
        context,
        '${l10n.fetchModelList} ${l10n.success}',
        icon: Icons.check_circle_outline_rounded,
      );
      return;
    }

    final errorMessage = ref.read(settingsProvider).error;
    final message = (errorMessage?.isNotEmpty ?? false)
        ? '${l10n.fetchModelList} ${l10n.failed}: $errorMessage'
        : '${l10n.fetchModelList} ${l10n.failed}';
    showAuroraNotice(
      context,
      message,
      icon: Icons.error_outline_rounded,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final viewingProvider = settingsState.viewingProvider;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          MobileSettingsSection(
            title: l10n.modelProvider,
            children: [
              MobileSettingsTile(
                leading: const Icon(Icons.business),
                title: l10n.currentProvider,
                subtitle: viewingProvider.name.isNotEmpty
                    ? viewingProvider.name
                    : l10n.notConfigured,
                onTap: () => _showProviderPicker(context),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.key),
                title: l10n.apiKeys,
                subtitle: viewingProvider.apiKeys.isNotEmpty
                    ? l10n.apiKeysCount(viewingProvider.apiKeys.length)
                    : l10n.notConfigured,
                trailing: (viewingProvider.apiKeys.length > 1)
                    ? SizedBox(
                        height: 32,
                        child: FittedBox(
                          child: Switch.adaptive(
                            value: viewingProvider.autoRotateKeys,
                            onChanged: (v) => ref
                                .read(settingsProvider.notifier)
                                .setAutoRotateKeys(viewingProvider.id, v),
                          ),
                        ),
                      )
                    : null,
                onTap: () => _showApiKeysManager(context, viewingProvider),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.link),
                title: l10n.apiBaseUrl,
                subtitle: viewingProvider.baseUrl.isNotEmpty
                    ? viewingProvider.baseUrl
                    : l10n.baseUrlPlaceholder,
                onTap: () => _showBaseUrlEditor(context, viewingProvider),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.alt_route),
                title: l10n.providerProtocol,
                subtitle: providerProtocolLabel(
                    context, viewingProvider.providerProtocol),
                onTap: () =>
                    _showProviderProtocolPicker(context, viewingProvider),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.power_settings_new),
                title: l10n.enabledStatus,
                subtitle: viewingProvider.isEnabled == true
                    ? l10n.enabled
                    : l10n.disabled,
                trailing: Switch.adaptive(
                  value: viewingProvider.isEnabled == true,
                  onChanged: (v) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleProviderEnabled(viewingProvider.id);
                  },
                ),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.settings_applications),
                title: l10n.globalConfig,
                onTap: () {
                  _showGlobalConfigDialog(context, viewingProvider);
                },
              ),
            ],
          ),
          MobileSettingsSection(
            title: l10n.availableModels,
            trailing: SizedBox(
              height: 28,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: BorderSide(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Theme.of(context).cardColor,
                ),
                onPressed: settingsState.isLoadingModels
                    ? null
                    : () async {
                        await _refreshModelsWithNotice(l10n);
                      },
                icon: settingsState.isLoadingModels
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 14),
                label: Text(l10n.fetchModelList,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.normal)),
              ),
            ),
            children: [
              if (viewingProvider.models.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: FilledButton.tonal(
                            onPressed: () => ref
                                .read(settingsProvider.notifier)
                                .setAllModelsEnabled(viewingProvider.id, true),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(l10n.enableAll,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () => ref
                                .read(settingsProvider.notifier)
                                .setAllModelsEnabled(viewingProvider.id, false),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(
                                  color: Theme.of(context).dividerColor),
                            ),
                            child: Text(l10n.disableAll,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).disabledColor)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (viewingProvider.models.isNotEmpty)
                ...(() {
                  final displayNameCounts =
                      buildModelDisplayNameCounts(viewingProvider.models);

                  MobileSettingsTile buildModelTile(
                    String model, {
                    required bool isEnabled,
                  }) {
                    final displayName =
                        resolveModelDisplayName(model, displayNameCounts);
                    return MobileSettingsTile(
                      title: displayName,
                      showChevron: false,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isEnabled
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isEnabled ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => ref
                                .read(settingsProvider.notifier)
                                .toggleModelDisabled(viewingProvider.id, model),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, size: 20),
                            onPressed: () => _showModelConfigDialog(
                                context, viewingProvider, model),
                          ),
                        ],
                      ),
                    );
                  }

                  Widget buildGroup({
                    required String title,
                    required List<String> models,
                    required bool isEnabled,
                    required bool isExpanded,
                    required VoidCallback onToggle,
                  }) {
                    final theme = Theme.of(context);
                    final chevronColor =
                        theme.iconTheme.color?.withValues(alpha: 0.7);
                    final groupIcon =
                        isEnabled ? Icons.check_circle_outline : Icons.block;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MobileSettingsTile(
                          leading: Icon(groupIcon),
                          title: '$title (${models.length})',
                          showChevron: false,
                          trailing: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: chevronColor,
                            ),
                          ),
                          onTap: onToggle,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topLeft,
                          clipBehavior: Clip.none,
                          child: isExpanded
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: models
                                      .map(
                                        (model) => buildModelTile(
                                          model,
                                          isEnabled: isEnabled,
                                        ),
                                      )
                                      .toList(),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  }

                  final enabledModels = <String>[];
                  final disabledModels = <String>[];
                  for (final model in viewingProvider.models) {
                    if (viewingProvider.isModelEnabled(model)) {
                      enabledModels.add(model);
                    } else {
                      disabledModels.add(model);
                    }
                  }

                  final providerId = viewingProvider.id;
                  final enabledExpanded =
                      _enabledModelsExpandedByProvider[providerId] ?? true;
                  final disabledExpanded =
                      _disabledModelsExpandedByProvider[providerId] ?? false;

                  final widgets = <Widget>[];
                  if (enabledModels.isNotEmpty) {
                    widgets.add(
                      buildGroup(
                        title: l10n.enabled,
                        models: enabledModels,
                        isEnabled: true,
                        isExpanded: enabledExpanded,
                        onToggle: () {
                          setState(() {
                            _enabledModelsExpandedByProvider[providerId] =
                                !enabledExpanded;
                          });
                        },
                      ),
                    );
                  }
                  if (disabledModels.isNotEmpty) {
                    if (widgets.isNotEmpty) {
                      widgets.add(const Divider(height: 1));
                    }
                    widgets.add(
                      buildGroup(
                        title: l10n.disabled,
                        models: disabledModels,
                        isEnabled: false,
                        isExpanded: disabledExpanded,
                        onToggle: () {
                          setState(() {
                            _disabledModelsExpandedByProvider[providerId] =
                                !disabledExpanded;
                          });
                        },
                      ),
                    );
                  }

                  return widgets;
                })()
              else
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(l10n.noModelsData),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProviderPicker(BuildContext context) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return Consumer(
          builder: (scopedContext, ref, _) {
            final state = ref.watch(settingsProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuroraBottomSheet.buildTitle(context, l10n.selectProvider),
                const Divider(height: 1),
                ...state.providers.map((p) => AuroraBottomSheet.buildListItem(
                      context: context,
                      leading: Icon(
                        p.id == state.viewingProviderId
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: p.id == state.viewingProviderId
                            ? Theme.of(scopedContext).primaryColor
                            : null,
                      ),
                      title: Text(p.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              final notifier =
                                  ref.read(settingsProvider.notifier);
                              Navigator.pop(ctx);
                              final confirmed =
                                  await AuroraBottomSheet.showConfirm(
                                context: context,
                                title: l10n.deleteProvider,
                                content: l10n.deleteProviderConfirm,
                                confirmText: l10n.delete,
                                isDestructive: true,
                              );
                              if (confirmed == true) {
                                notifier.deleteProvider(p.id);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showProviderRenameDialog(scopedContext, p);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        ref.read(settingsProvider.notifier).viewProvider(p.id);
                        Navigator.pop(ctx);
                      },
                    )),
                const Divider(),
                AuroraBottomSheet.buildListItem(
                  context: context,
                  leading: const Icon(Icons.add),
                  title: Text(l10n.addProvider),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(settingsProvider.notifier).addProvider();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showModelConfigDialog(
      BuildContext context, ProviderConfig provider, String modelName) {
    final currentSettings = provider.modelSettings[modelName] ?? {};
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => _ModelConfigDialog(
        modelName: modelName,
        initialSettings: currentSettings,
        onSave: (newSettings) {
          final updatedModelSettings =
              Map<String, Map<String, dynamic>>.from(provider.modelSettings);
          updatedModelSettings[modelName] = newSettings;
          ref.read(settingsProvider.notifier).updateProvider(
                id: provider.id,
                modelSettings: updatedModelSettings,
              );
        },
      ),
    );
  }

  void _showGlobalConfigDialog(BuildContext context, ProviderConfig provider) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => _GlobalConfigBottomSheet(
        provider: provider,
      ),
    );
  }

  void _showProviderProtocolPicker(
      BuildContext context, ProviderConfig provider) {
    final l10n = AppLocalizations.of(context)!;
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(context, l10n.providerProtocol),
          const Divider(height: 1),
          ...ProviderProtocol.values.map(
            (protocol) => ListTile(
              title: Text(providerProtocolLabel(context, protocol)),
              trailing: provider.providerProtocol == protocol
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () {
                ref.read(settingsProvider.notifier).updateProvider(
                      id: provider.id,
                      providerProtocol: protocol,
                    );
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showProviderRenameDialog(
      BuildContext context, ProviderConfig provider) async {
    final l10n = AppLocalizations.of(context)!;
    final newName = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.renameProvider,
      initialValue: provider.name,
      hintText: l10n.enterProviderName,
    );
    if (newName != null && newName.isNotEmpty) {
      ref.read(settingsProvider.notifier).updateProvider(
            id: provider.id,
            name: newName,
          );
    }
  }

  void _showApiKeysManager(BuildContext context, ProviderConfig? provider) {
    if (provider == null) return;
    final l10n = AppLocalizations.of(context)!;

    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Re-fetch provider to get latest state
          final currentProvider = ref
              .read(settingsProvider)
              .providers
              .firstWhere((p) => p.id == provider.id, orElse: () => provider);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuroraBottomSheet.buildTitle(context, l10n.apiKeys),
              const Divider(height: 1),
              // Auto-rotate toggle
              if (currentProvider.apiKeys.length > 1)
                SwitchListTile(
                  title: Text(l10n.autoRotateKeys),
                  value: currentProvider.autoRotateKeys,
                  onChanged: (v) {
                    ref
                        .read(settingsProvider.notifier)
                        .setAutoRotateKeys(provider.id, v);
                    setModalState(() {});
                  },
                ),
              // Key list
              Flexible(
                child: currentProvider.apiKeys.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.key_off,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(l10n.notConfigured,
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : RadioGroup<int>(
                        groupValue: currentProvider.safeCurrentKeyIndex,
                        onChanged: (index) {
                          if (index == null) return;
                          ref
                              .read(settingsProvider.notifier)
                              .setCurrentKeyIndex(provider.id, index);
                          setModalState(() {});
                        },
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: currentProvider.apiKeys.length,
                          itemBuilder: (context, index) {
                            final key = currentProvider.apiKeys[index];

                            return _ApiKeyListItem(
                              index: index,
                              apiKey: key,
                              onEdit: (newValue) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateApiKeyAtIndex(
                                        provider.id, index, newValue);
                                setModalState(() {});
                              },
                              onDelete: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .removeApiKey(provider.id, index);
                                setModalState(() {});
                              },
                            );
                          },
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        _showAddKeyDialog(context, provider.id, () {
                      setModalState(() {});
                    }),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addApiKey),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddKeyDialog(
      BuildContext context, String providerId, VoidCallback onAdded) async {
    final l10n = AppLocalizations.of(context)!;
    final newKey = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.addApiKey,
      hintText: l10n.apiKeyPlaceholder,
    );
    if (newKey != null && newKey.isNotEmpty) {
      ref.read(settingsProvider.notifier).addApiKey(providerId, newKey);
      onAdded();
    }
  }

  void _showBaseUrlEditor(
      BuildContext context, ProviderConfig? provider) async {
    if (provider == null) return;
    final l10n = AppLocalizations.of(context)!;
    final newUrl = await AuroraBottomSheet.showInput(
      context: context,
      title: l10n.editBaseUrl,
      initialValue: provider.baseUrl,
      hintText: l10n.baseUrlPlaceholder,
    );
    if (newUrl != null) {
      ref.read(settingsProvider.notifier).commitProviderBaseUrl(
            id: provider.id,
            baseUrl: newUrl,
          );
    }
  }
}

class _ModelConfigDialog extends StatefulWidget {
  final String modelName;
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic>) onSave;
  const _ModelConfigDialog({
    required this.modelName,
    required this.initialSettings,
    required this.onSave,
  });
  @override
  State<_ModelConfigDialog> createState() => _ModelConfigDialogState();
}

class _ModelConfigDialogState extends State<_ModelConfigDialog> {
  late SettingsConfigDraft _draft;
  late Map<String, dynamic> _modelSettings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _modelSettings = Map<String, dynamic>.from(widget.initialSettings);
    _draft = SettingsConfigDraft.fromSettings(_modelSettings);
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _saveSettings({
    bool? thinkingEnabled,
    String? thinkingMode,
    Map<String, dynamic>? customParams,
  }) {
    if (thinkingEnabled != null) {
      _draft.thinkingEnabled = thinkingEnabled;
    }
    if (thinkingMode != null) {
      _draft.thinkingMode = thinkingMode;
    }
    final newSettings = _draft.buildSettings(customParams: customParams);

    setState(() {
      _modelSettings = newSettings;
    });

    widget.onSave(newSettings);
  }

  Future<void> _showEditDialog([String? key, dynamic value]) async {
    await AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => _ParameterConfigDialog(
        initialKey: key,
        initialValue: value,
        onSave: (newKey, newValue) {
          final currentParams = _draft.customParams;

          if (key != null && key != newKey) {
            currentParams.remove(key);
          }
          currentParams[newKey] = newValue;
          _saveSettings(customParams: currentParams);
        },
      ),
    );
  }

  void _removeParam(String key) {
    final currentParams = _draft.customParams;
    currentParams.remove(key);
    _saveSettings(customParams: currentParams);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Extract custom params for display (exclude _aurora_ keys)
    final customParams = _draft.customParams;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraBottomSheet.buildTitle(context, widget.modelName),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l10n.modelConfig,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionCard(
                  context,
                  title: l10n.thinkingConfig,
                  icon: Icons.lightbulb_outline,
                  headerAction: Switch(
                    value: _draft.thinkingEnabled,
                    onChanged: (v) => _saveSettings(thinkingEnabled: v),
                  ),
                  child: _draft.thinkingEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _draft.thinkingBudgetController,
                              decoration: InputDecoration(
                                labelText: l10n.thinkingBudget,
                                hintText: l10n.thinkingBudgetHint,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => _saveSettings(),
                            ),
                            const SizedBox(height: 12),
                            AuroraMaterialDropdownField<String>(
                              value: _draft.thinkingMode,
                              label: l10n.transmissionMode,
                              options: [
                                AuroraDropdownOption(
                                  value: 'auto',
                                  label: l10n.modeAuto,
                                ),
                                AuroraDropdownOption(
                                  value: 'extra_body',
                                  label: l10n.modeExtraBody,
                                ),
                                AuroraDropdownOption(
                                  value: 'reasoning_effort',
                                  label: l10n.modeReasoningEffort,
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) _saveSettings(thinkingMode: v);
                              },
                            ),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context,
                  title: l10n.generationConfig,
                  icon: Icons.settings,
                  headerAction: null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: _draft.temperatureController,
                        decoration: InputDecoration(
                          labelText: l10n.temperature,
                          hintText: l10n.temperatureHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _saveSettings(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _draft.maxTokensController,
                        decoration: InputDecoration(
                          labelText: l10n.maxTokens,
                          hintText: l10n.maxTokensHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _saveSettings(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _draft.contextLengthController,
                        decoration: InputDecoration(
                          labelText: l10n.contextLength,
                          hintText: l10n.contextLengthHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _saveSettings(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context,
                  title: l10n.customParams,
                  subtitle: l10n.paramsHigherPriority,
                  icon: Icons.edit,
                  headerAction: null,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (customParams.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.tune,
                                  size: 32, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noCustomParams,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                child: Text(l10n.addCustomParam),
                                onPressed: () => _showEditDialog(),
                              )
                            ],
                          ),
                        )
                      else
                        ...customParams.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildParamItem(e.key, e.value, theme),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.done),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? headerAction,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color)),
                  ],
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildParamItem(String key, dynamic value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(key,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSecondaryContainer)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatSettingsParamValue(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontFamily: 'monospace',
                  fontSize: 13),
            ),
          ),
          InkWell(
            onTap: () => _showEditDialog(key, value),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.edit, size: 16),
            ),
          ),
          InkWell(
            onTap: () => _removeParam(key),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.delete_outline,
                  size: 16, color: Colors.red.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParameterConfigDialog extends StatefulWidget {
  final String? initialKey;
  final dynamic initialValue;
  final Function(String key, dynamic value) onSave;
  const _ParameterConfigDialog({
    this.initialKey,
    this.initialValue,
    required this.onSave,
  });
  @override
  State<_ParameterConfigDialog> createState() => _ParameterConfigDialogState();
}

class _ParameterConfigDialogState extends State<_ParameterConfigDialog> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  SettingsParamValueType _type = SettingsParamValueType.string;
  @override
  void initState() {
    super.initState();
    if (widget.initialKey != null) {
      _keyController.text = widget.initialKey!;
      final val = widget.initialValue;
      _type = detectSettingsParamValueType(val);
      if (_type == SettingsParamValueType.json) {
        try {
          _valueController.text =
              const JsonEncoder.withIndent('  ').convert(val);
        } catch (_) {
          _valueController.text = jsonEncode(val);
        }
      } else {
        _valueController.text = val.toString();
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialKey != null;
    final l10n = AppLocalizations.of(context)!;
    final typeMap = {
      SettingsParamValueType.string: l10n.typeText,
      SettingsParamValueType.number: l10n.typeNumber,
      SettingsParamValueType.boolean: l10n.typeBoolean,
      SettingsParamValueType.json: l10n.typeJson,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraBottomSheet.buildTitle(
            context, isEditing ? l10n.editParam : l10n.addCustomParam),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _keyController,
                decoration: InputDecoration(
                  labelText: l10n.paramKey,
                  hintText: l10n.paramKeyPlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              AuroraMaterialDropdownField<SettingsParamValueType>(
                value: _type,
                label: l10n.typeLabel,
                options: typeMap.entries
                    .map(
                      (entry) => AuroraDropdownOption<SettingsParamValueType>(
                        value: entry.key,
                        label: entry.value,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valueController,
                maxLines: _type == SettingsParamValueType.json ? 5 : 1,
                minLines: _type == SettingsParamValueType.json ? 3 : 1,
                decoration: InputDecoration(
                  labelText: l10n.paramValue,
                  hintText: l10n.paramValue,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final key = _keyController.text.trim();
                    final valueStr = _valueController.text.trim();
                    if (key.isEmpty) return;
                    try {
                      final value = parseSettingsParamValue(_type, valueStr);
                      widget.onSave(key, value);
                      Navigator.pop(context);
                    } catch (e) {
                      showAuroraNotice(
                        context,
                        '${l10n.formatError}: $e',
                        icon: Icons.error_outline_rounded,
                      );
                    }
                  },
                  child: Text(isEditing ? l10n.save : l10n.add),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApiKeyListItem extends StatefulWidget {
  final int index;
  final String apiKey;
  final ValueChanged<String> onEdit;
  final VoidCallback onDelete;

  const _ApiKeyListItem({
    required this.index,
    required this.apiKey,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ApiKeyListItem> createState() => _ApiKeyListItemState();
}

class _ApiKeyListItemState extends State<_ApiKeyListItem> {
  late TextEditingController _controller;
  bool _isVisible = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.apiKey);
  }

  @override
  void didUpdateWidget(_ApiKeyListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.apiKey != _controller.text) {
      _controller.text = widget.apiKey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Radio<int>(value: widget.index),
      title: TextField(
        controller: _controller,
        focusNode: _focusNode,
        obscureText: !_isVisible,
        onChanged: widget.onEdit,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: l10n.apiKeyPlaceholder,
          suffixIcon: IconButton(
            icon: Icon(
              _isVisible ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
          ),
        ),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          letterSpacing: _isVisible ? 0 : 2,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: widget.onDelete,
      ),
    );
  }
}

class _GlobalConfigBottomSheet extends ConsumerStatefulWidget {
  final ProviderConfig provider;
  const _GlobalConfigBottomSheet({required this.provider});
  @override
  ConsumerState<_GlobalConfigBottomSheet> createState() =>
      _GlobalConfigBottomSheetState();
}

class _GlobalConfigBottomSheetState
    extends ConsumerState<_GlobalConfigBottomSheet> {
  late SettingsConfigDraft _draft;
  late List<String> _excludedModels;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _draft = SettingsConfigDraft.fromSettings(widget.provider.globalSettings);
    _excludedModels = List<String>.from(widget.provider.globalExcludeModels);
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _saveSettings({
    bool? thinkingEnabled,
    String? thinkingMode,
  }) {
    if (thinkingEnabled != null) {
      _draft.thinkingEnabled = thinkingEnabled;
    }
    if (thinkingMode != null) {
      _draft.thinkingMode = thinkingMode;
    }
    _persist();
    setState(() {});
  }

  void _saveCustomParams(Map<String, dynamic> newParams) {
    _draft.buildSettings(customParams: newParams);
    _persist();
    setState(() {});
  }

  void _saveExclusions(List<String> newExclusions) {
    setState(() {
      _excludedModels = newExclusions;
    });
    ref.read(settingsProvider.notifier).updateProvider(
          id: widget.provider.id,
          globalExcludeModels: _excludedModels,
        );
  }

  void _persist() {
    final newGlobalSettings = _draft.buildSettings();

    ref.read(settingsProvider.notifier).updateProvider(
          id: widget.provider.id,
          globalSettings: newGlobalSettings,
        );
  }

  Future<void> _showExclusionPicker() async {
    final result = await AuroraBottomSheet.show<List<String>>(
      context: context,
      builder: (ctx) => _ExclusionPicker(
        allModels: widget.provider.models,
        excludedModels: _excludedModels,
      ),
    );
    if (result != null) {
      _saveExclusions(result);
    }
  }

  void _showEditDialog([String? key, dynamic value]) {
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => _ParameterConfigDialog(
        initialKey: key,
        initialValue: value,
        onSave: (k, v) {
          final newParams = _draft.customParams;
          if (key != null && key != k) {
            newParams.remove(key);
          }
          newParams[k] = v;
          _saveCustomParams(newParams);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _removeParam(String key) {
    final newParams = _draft.customParams;
    newParams.remove(key);
    _saveCustomParams(newParams);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        AuroraBottomSheet.buildTitle(context, l10n.globalConfig),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(widget.provider.name,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Excluded Models Card
                _buildSectionCard(
                  context,
                  title: l10n.excludedModels,
                  subtitle: '${_excludedModels.length} models excluded',
                  icon: Icons.block,
                  headerAction: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: _showExclusionPicker,
                  ),
                  child: _excludedModels.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _excludedModels
                                .map((m) => Chip(
                                    label: Text(m,
                                        style: const TextStyle(fontSize: 10))))
                                .toList(),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                // Thinking Configuration Card
                _buildSectionCard(
                  context,
                  title: l10n.thinkingConfig,
                  icon: Icons.lightbulb_outline,
                  headerAction: Switch(
                    value: _draft.thinkingEnabled,
                    onChanged: (v) => _saveSettings(thinkingEnabled: v),
                  ),
                  child: _draft.thinkingEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _draft.thinkingBudgetController,
                              decoration: InputDecoration(
                                labelText: l10n.thinkingBudget,
                                hintText: l10n.thinkingBudgetHint,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => _saveSettings(),
                            ),
                            const SizedBox(height: 12),
                            AuroraMaterialDropdownField<String>(
                              value: _draft.thinkingMode,
                              label: l10n.transmissionMode,
                              options: [
                                AuroraDropdownOption(
                                  value: 'auto',
                                  label: l10n.modeAuto,
                                ),
                                AuroraDropdownOption(
                                  value: 'extra_body',
                                  label: l10n.modeExtraBody,
                                ),
                                AuroraDropdownOption(
                                  value: 'reasoning_effort',
                                  label: l10n.modeReasoningEffort,
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) _saveSettings(thinkingMode: v);
                              },
                            ),
                          ],
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                // Generation Configuration Card
                _buildSectionCard(
                  context,
                  title: l10n.generationConfig,
                  icon: Icons.settings,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: _draft.temperatureController,
                        decoration: InputDecoration(
                          labelText: l10n.temperature,
                          hintText: l10n.temperatureHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _saveSettings(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _draft.maxTokensController,
                        decoration: InputDecoration(
                          labelText: l10n.maxTokens,
                          hintText: l10n.maxTokensHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _saveSettings(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _draft.contextLengthController,
                        decoration: InputDecoration(
                          labelText: l10n.contextLength,
                          hintText: l10n.contextLengthHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _saveSettings(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Custom Parameters Card
                _buildSectionCard(
                  context,
                  title: l10n.customParams,
                  subtitle: l10n.paramsHigherPriority,
                  icon: Icons.edit,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (_draft.customParams.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.tune,
                                  size: 32, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noCustomParams,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                child: Text(l10n.addCustomParam),
                                onPressed: () => _showEditDialog(),
                              )
                            ],
                          ),
                        )
                      else
                        ..._draft.customParams.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildParamItem(e.key, e.value, theme),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.done),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? headerAction,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color)),
                  ],
                ),
              ),
              if (headerAction != null) headerAction,
            ],
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildParamItem(String key, dynamic value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(key,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSecondaryContainer)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatValue(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontFamily: 'monospace',
                  fontSize: 13),
            ),
          ),
          InkWell(
            onTap: () => _showEditDialog(key, value),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.edit, size: 16),
            ),
          ),
          InkWell(
            onTap: () => _removeParam(key),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child:
                  Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is String) return '"$value"';
    return jsonEncode(value);
  }
}

class _ExclusionPicker extends StatefulWidget {
  final List<String> allModels;
  final List<String> excludedModels;
  const _ExclusionPicker(
      {required this.allModels, required this.excludedModels});

  @override
  State<_ExclusionPicker> createState() => _ExclusionPickerState();
}

class _ExclusionPickerState extends State<_ExclusionPicker> {
  late List<String> _currentExclusions;

  @override
  void initState() {
    super.initState();
    _currentExclusions = List.from(widget.excludedModels);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraBottomSheet.buildTitle(context, l10n.excludedModels),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.allModels.length,
            itemBuilder: (context, index) {
              final model = widget.allModels[index];
              final isExcluded = _currentExclusions.contains(model);
              return CheckboxListTile(
                title: Text(model),
                value: isExcluded,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _currentExclusions.add(model);
                    } else {
                      _currentExclusions.remove(model);
                    }
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context, _currentExclusions);
              },
              child: Text(l10n.save),
            ),
          ),
        ),
      ],
    );
  }
}
