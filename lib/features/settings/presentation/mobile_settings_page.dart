import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
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
  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final activeProvider = settingsState.activeProvider;
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
                subtitle: activeProvider.name.isNotEmpty
                    ? activeProvider.name
                    : l10n.notConfigured,
                onTap: () => _showProviderPicker(context, settingsState),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.key),
                title: l10n.apiKeys,
                subtitle: activeProvider.apiKeys.isNotEmpty == true
                    ? '${activeProvider.apiKeys.length} ${activeProvider.apiKeys.length > 1 ? "keys" : "key"}'
                    : l10n.notConfigured,
                trailing: (activeProvider.apiKeys.length > 1)
                    ? SizedBox(
                        height: 32,
                        child: FittedBox(
                          child: Switch.adaptive(
                            value: activeProvider.autoRotateKeys,
                            onChanged: (v) => ref
                                .read(settingsProvider.notifier)
                                .setAutoRotateKeys(activeProvider.id, v),
                          ),
                        ),
                      )
                    : null,
                onTap: () => _showApiKeysManager(context, activeProvider),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.link),
                title: 'API Base URL',
                subtitle: activeProvider.baseUrl.isNotEmpty
                    ? activeProvider.baseUrl
                    : 'https://api.openai.com/v1',
                onTap: () => _showBaseUrlEditor(context, activeProvider),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.power_settings_new),
                title: l10n.enabledStatus,
                subtitle: activeProvider.isEnabled == true
                    ? l10n.enabled
                    : l10n.disabled,
                trailing: Switch.adaptive(
                  value: activeProvider.isEnabled == true,
                  onChanged: (v) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleProviderEnabled(activeProvider.id);
                  },
                ),
              ),
              MobileSettingsTile(
                leading: const Icon(Icons.settings_applications),
                title: l10n.globalConfig,
                onTap: () {
                  _showGlobalConfigDialog(context, activeProvider);
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
                    : () {
                        ref.read(settingsProvider.notifier).fetchModels();
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
              if (activeProvider.models.isNotEmpty)
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
                                .setAllModelsEnabled(activeProvider.id, true),
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
                                .setAllModelsEnabled(activeProvider.id, false),
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
              if (activeProvider.models.isNotEmpty)
                ...activeProvider.models.map((model) {
                  return MobileSettingsTile(
                    leading: const Icon(Icons.account_tree_outlined),
                    title: model,
                    showChevron: false,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            activeProvider.isModelEnabled(model)
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: activeProvider.isModelEnabled(model)
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .toggleModelDisabled(activeProvider.id, model),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20),
                          onPressed: () => _showModelConfigDialog(
                              context, activeProvider, model),
                        ),
                      ],
                    ),
                  );
                })
              else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No models found'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProviderPicker(BuildContext context, SettingsState paramState) {
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
                        p.id == state.activeProviderId
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: p.id == state.activeProviderId
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
                        ref
                            .read(settingsProvider.notifier)
                            .selectProvider(p.id);
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
      hintText: 'sk-xxxxxxxx',
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
      hintText: 'https://api.openai.com/v1',
    );
    if (newUrl != null) {
      ref.read(settingsProvider.notifier).updateProvider(
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
  late Map<String, dynamic> _modelSettings;

  // Thinking config temporary state
  bool _thinkingEnabled = false;
  String _thinkingBudget = '';
  String _thinkingMode = 'auto';

  // Generation config temporary state
  String _temperature = '';
  String _maxTokens = '';
  String _contextLength = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _modelSettings = Map<String, dynamic>.from(widget.initialSettings);

    final thinkingConfig = _modelSettings['_aurora_thinking_config'];
    // Check for new structure first
    if (thinkingConfig != null && thinkingConfig is Map) {
      _thinkingEnabled = thinkingConfig['enabled'] == true;
      _thinkingBudget = thinkingConfig['budget']?.toString() ?? '';
      _thinkingMode = thinkingConfig['mode']?.toString() ?? 'auto';
    } else {
      // Fallback/Migration for old structure if present
      // Old keys: _aurora_thinking_enabled, _aurora_thinking_value, _aurora_thinking_mode
      if (_modelSettings.containsKey('_aurora_thinking_enabled')) {
        _thinkingEnabled = _modelSettings['_aurora_thinking_enabled'] == true;
        _thinkingBudget =
            _modelSettings['_aurora_thinking_value']?.toString() ?? '';
        _thinkingMode =
            _modelSettings['_aurora_thinking_mode']?.toString() ?? 'auto';

        // Clean up old keys immediately from local copy so they don't persist
        _modelSettings.remove('_aurora_thinking_enabled');
        _modelSettings.remove('_aurora_thinking_value');
        _modelSettings.remove('_aurora_thinking_mode');
      } else {
        _thinkingEnabled = false;
        _thinkingBudget = '';
        _thinkingMode = 'auto';
      }
    }

    // Load generation config
    final generationConfig = _modelSettings['_aurora_generation_config'];
    if (generationConfig != null && generationConfig is Map) {
      _temperature = generationConfig['temperature']?.toString() ?? '';
      _maxTokens = generationConfig['max_tokens']?.toString() ?? '';
      _contextLength = generationConfig['context_length']?.toString() ?? '';
    } else {
      _temperature = '';
      _maxTokens = '';
      _contextLength = '';
    }
  }

  void _saveSettings({
    bool? thinkingEnabled,
    String? thinkingBudget,
    String? thinkingMode,
    String? temperature,
    String? maxTokens,
    String? contextLength,
    Map<String, dynamic>? customParams,
  }) {
    // Update local state
    if (thinkingEnabled != null) _thinkingEnabled = thinkingEnabled;
    if (thinkingBudget != null) _thinkingBudget = thinkingBudget;
    if (thinkingMode != null) _thinkingMode = thinkingMode;
    if (temperature != null) _temperature = temperature;
    if (maxTokens != null) _maxTokens = maxTokens;
    if (contextLength != null) _contextLength = contextLength;

    // Construct new settings map
    final newSettings = Map<String, dynamic>.from(_modelSettings);

    // Handle Thinking Config
    if (_thinkingEnabled) {
      newSettings['_aurora_thinking_config'] = {
        'enabled': true,
        'budget': _thinkingBudget,
        'mode': _thinkingMode,
      };
    } else {
      newSettings.remove('_aurora_thinking_config');
    }

    // Handle Generation Config
    if (_temperature.isNotEmpty ||
        _maxTokens.isNotEmpty ||
        _contextLength.isNotEmpty) {
      newSettings['_aurora_generation_config'] = {
        if (_temperature.isNotEmpty) 'temperature': _temperature,
        if (_maxTokens.isNotEmpty) 'max_tokens': _maxTokens,
        if (_contextLength.isNotEmpty) 'context_length': _contextLength,
      };
    } else {
      newSettings.remove('_aurora_generation_config');
    }

    // Handle Custom Params
    if (customParams != null) {
      // Remove all non-internal keys (those not starting with _aurora_)
      newSettings.removeWhere((key, _) => !key.startsWith('_aurora_'));
      // Add new custom params
      newSettings.addAll(customParams);
    }

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
          final currentParams = Map<String, dynamic>.fromEntries(_modelSettings
              .entries
              .where((e) => !e.key.startsWith('_aurora_')));

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
    final currentParams = Map<String, dynamic>.fromEntries(
        _modelSettings.entries.where((e) => !e.key.startsWith('_aurora_')));
    currentParams.remove(key);
    _saveSettings(customParams: currentParams);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Extract custom params for display (exclude _aurora_ keys)
    final customParams = Map<String, dynamic>.fromEntries(
        _modelSettings.entries.where((e) => !e.key.startsWith('_aurora_')));

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
                    value: _thinkingEnabled,
                    onChanged: (v) => _saveSettings(thinkingEnabled: v),
                  ),
                  child: _thinkingEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            TextField(
                              controller:
                                  TextEditingController(text: _thinkingBudget)
                                    ..selection = TextSelection.collapsed(
                                        offset: _thinkingBudget.length),
                              decoration: InputDecoration(
                                labelText: l10n.thinkingBudget,
                                hintText: l10n.thinkingBudgetHint,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) =>
                                  _saveSettings(thinkingBudget: v),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _thinkingMode,
                              decoration: InputDecoration(
                                labelText: l10n.transmissionMode,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                DropdownMenuItem(
                                    value: 'auto', child: Text(l10n.modeAuto)),
                                DropdownMenuItem(
                                    value: 'extra_body',
                                    child: Text(l10n.modeExtraBody)),
                                DropdownMenuItem(
                                    value: 'reasoning_effort',
                                    child: Text(l10n.modeReasoningEffort)),
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
                        controller: TextEditingController(text: _temperature)
                          ..selection = TextSelection.collapsed(
                              offset: _temperature.length),
                        decoration: InputDecoration(
                          labelText: l10n.temperature,
                          hintText: l10n.temperatureHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _saveSettings(temperature: v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: TextEditingController(text: _maxTokens)
                          ..selection = TextSelection.collapsed(
                              offset: _maxTokens.length),
                        decoration: InputDecoration(
                          labelText: l10n.maxTokens,
                          hintText: l10n.maxTokensHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _saveSettings(maxTokens: v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: TextEditingController(text: _contextLength)
                          ..selection = TextSelection.collapsed(
                              offset: _contextLength.length),
                        decoration: InputDecoration(
                          labelText: l10n.contextLength,
                          hintText: l10n.contextLengthHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _saveSettings(contextLength: v),
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
              child: Icon(Icons.delete_outline,
                  size: 16, color: Colors.red.withValues(alpha: 0.8)),
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
  String _type = 'string';
  @override
  void initState() {
    super.initState();
    if (widget.initialKey != null) {
      _keyController.text = widget.initialKey!;
      final val = widget.initialValue;
      if (val is bool) {
        _type = 'boolean';
        _valueController.text = val.toString();
      } else if (val is num) {
        _type = 'number';
        _valueController.text = val.toString();
      } else if (val is Map || val is List) {
        _type = 'json';
        try {
          _valueController.text =
              const JsonEncoder.withIndent('  ').convert(val);
        } catch (_) {
          _valueController.text = jsonEncode(val);
        }
      } else {
        _type = 'string';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialKey != null;
    final l10n = AppLocalizations.of(context)!;
    final typeMap = {
      'string': l10n.typeText,
      'number': l10n.typeNumber,
      'boolean': l10n.typeBoolean,
      'json': l10n.typeJson,
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
                  hintText: 'e.g. image_config',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                decoration: InputDecoration(
                  labelText: l10n.paramType,
                  border: const OutlineInputBorder(),
                ),
                items: typeMap.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valueController,
                maxLines: _type == 'json' ? 5 : 1,
                minLines: _type == 'json' ? 3 : 1,
                decoration: InputDecoration(
                  labelText: l10n.paramValue,
                  hintText: 'Value',
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
                    dynamic value;
                    try {
                      switch (_type) {
                        case 'number':
                          value = num.parse(valueStr);
                          break;
                        case 'boolean':
                          value = valueStr.toLowerCase() == 'true';
                          break;
                        case 'json':
                          value = jsonDecode(valueStr);
                          break;
                        default:
                          value = valueStr;
                      }
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
    return ListTile(
      leading: Radio<int>(value: widget.index),
      title: TextField(
        controller: _controller,
        focusNode: _focusNode,
        obscureText: !_isVisible,
        onChanged: widget.onEdit,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'sk-xxxxxxxx',
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
  late bool _thinkingEnabled;
  late String _thinkingBudget;
  late String _thinkingMode;
  late String _temperature;
  late String _maxTokens;
  late String _contextLength;
  late Map<String, dynamic> _customParams;
  late List<String> _excludedModels;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = widget.provider.globalSettings;
    // Thinking
    final thinking = settings['_aurora_thinking_config'];
    if (thinking != null && thinking is Map) {
      _thinkingEnabled = thinking['enabled'] == true;
      _thinkingBudget = thinking['budget']?.toString() ?? '';
      _thinkingMode = thinking['mode']?.toString() ?? 'auto';
    } else {
      _thinkingEnabled = false;
      _thinkingBudget = '';
      _thinkingMode = 'auto';
    }

    // Generation
    final gen = settings['_aurora_generation_config'];
    if (gen != null && gen is Map) {
      _temperature = gen['temperature']?.toString() ?? '';
      _maxTokens = gen['max_tokens']?.toString() ?? '';
      _contextLength = gen['context_length']?.toString() ?? '';
    } else {
      _temperature = '';
      _maxTokens = '';
      _contextLength = '';
    }

    // Excluded Models
    _excludedModels = List<String>.from(widget.provider.globalExcludeModels);

    // Custom Params
    _customParams = Map<String, dynamic>.fromEntries(
        settings.entries.where((e) => !e.key.startsWith('_aurora_')));
  }

  void _saveSettings({
    bool? thinkingEnabled,
    String? thinkingBudget,
    String? thinkingMode,
    String? temperature,
    String? maxTokens,
    String? contextLength,
  }) {
    setState(() {
      if (thinkingEnabled != null) _thinkingEnabled = thinkingEnabled;
      if (thinkingBudget != null) _thinkingBudget = thinkingBudget;
      if (thinkingMode != null) _thinkingMode = thinkingMode;
      if (temperature != null) _temperature = temperature;
      if (maxTokens != null) _maxTokens = maxTokens;
      if (contextLength != null) _contextLength = contextLength;
    });
    _persist();
  }

  void _saveCustomParams(Map<String, dynamic> newParams) {
    setState(() {
      _customParams = newParams;
    });
    _persist();
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
    final Map<String, dynamic> newGlobalSettings = {};
    if (_thinkingEnabled ||
        _thinkingBudget.isNotEmpty ||
        _thinkingMode != 'auto') {
      newGlobalSettings['_aurora_thinking_config'] = {
        'enabled': _thinkingEnabled,
        'budget': int.tryParse(_thinkingBudget),
        'mode': _thinkingMode,
      };
    }
    if (_temperature.isNotEmpty ||
        _maxTokens.isNotEmpty ||
        _contextLength.isNotEmpty) {
      newGlobalSettings['_aurora_generation_config'] = {
        if (_temperature.isNotEmpty) 'temperature': _temperature,
        if (_maxTokens.isNotEmpty) 'max_tokens': _maxTokens,
        if (_contextLength.isNotEmpty) 'context_length': _contextLength,
      };
    }
    newGlobalSettings.addAll(_customParams);

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
          final newParams = Map<String, dynamic>.from(_customParams);
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
    final newParams = Map<String, dynamic>.from(_customParams);
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
                    value: _thinkingEnabled,
                    onChanged: (v) => _saveSettings(thinkingEnabled: v),
                  ),
                  child: _thinkingEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            TextField(
                              controller:
                                  TextEditingController(text: _thinkingBudget)
                                    ..selection = TextSelection.collapsed(
                                        offset: _thinkingBudget.length),
                              decoration: InputDecoration(
                                labelText: l10n.thinkingBudget,
                                hintText: l10n.thinkingBudgetHint,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) =>
                                  _saveSettings(thinkingBudget: v),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _thinkingMode,
                              decoration: InputDecoration(
                                labelText: l10n.transmissionMode,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                DropdownMenuItem(
                                    value: 'auto', child: Text(l10n.modeAuto)),
                                DropdownMenuItem(
                                    value: 'extra_body',
                                    child: Text(l10n.modeExtraBody)),
                                DropdownMenuItem(
                                    value: 'reasoning_effort',
                                    child: Text(l10n.modeReasoningEffort)),
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
                        controller: TextEditingController(text: _temperature)
                          ..selection = TextSelection.collapsed(
                              offset: _temperature.length),
                        decoration: InputDecoration(
                          labelText: l10n.temperature,
                          hintText: l10n.temperatureHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _saveSettings(temperature: v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: TextEditingController(text: _maxTokens)
                          ..selection = TextSelection.collapsed(
                              offset: _maxTokens.length),
                        decoration: InputDecoration(
                          labelText: l10n.maxTokens,
                          hintText: l10n.maxTokensHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _saveSettings(maxTokens: v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: TextEditingController(text: _contextLength)
                          ..selection = TextSelection.collapsed(
                              offset: _contextLength.length),
                        decoration: InputDecoration(
                          labelText: l10n.contextLength,
                          hintText: l10n.contextLengthHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _saveSettings(contextLength: v),
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
                      if (_customParams.isEmpty)
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
                        ..._customParams.entries.map((e) {
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
