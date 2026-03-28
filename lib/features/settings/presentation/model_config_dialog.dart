import 'dart:convert';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/services/llm_transport_mode.dart';
import 'package:aurora/shared/services/model_capability_registry.dart';
import 'package:aurora/shared/widgets/aurora_dropdown.dart';
import 'settings_config_draft.dart';
import 'settings_provider.dart';

class ModelConfigDialog extends ConsumerStatefulWidget {
  final ProviderConfig provider;
  final String modelName;

  const ModelConfigDialog({
    super.key,
    required this.provider,
    required this.modelName,
  });

  @override
  ConsumerState<ModelConfigDialog> createState() => _ModelConfigDialogState();
}

class _ModelConfigDialogState extends ConsumerState<ModelConfigDialog> {
  late SettingsConfigDraft _draft;
  late Map<String, dynamic> _modelSettings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final liveProvider = ref.read(settingsProvider).providers.firstWhere(
        (p) => p.id == widget.provider.id,
        orElse: () => widget.provider);

    final existingSettings = liveProvider.modelSettings[widget.modelName] ?? {};
    _modelSettings = Map<String, dynamic>.from(existingSettings);
    _draft = SettingsConfigDraft.fromSettings(_modelSettings);
  }

  void _saveSettings({
    bool? thinkingEnabled,
    String? thinkingMode,
    GeminiNativeToolsConfig? geminiNativeTools,
    Map<String, dynamic>? customParams,
  }) {
    if (thinkingEnabled != null) {
      _draft.thinkingEnabled = thinkingEnabled;
    }
    if (thinkingMode != null) {
      _draft.thinkingMode = thinkingMode;
    }
    final newSettings = _draft.buildSettings(customParams: customParams);

    var normalizedSettings = Map<String, dynamic>.from(newSettings);
    if (geminiNativeTools != null) {
      normalizedSettings =
          withGeminiNativeTools(normalizedSettings, geminiNativeTools);
    }

    setState(() {
      _modelSettings = normalizedSettings;
    });
    _draft.replaceSettings(normalizedSettings);

    // Save to provider
    final liveProvider = ref.read(settingsProvider).providers.firstWhere(
        (p) => p.id == widget.provider.id,
        orElse: () => widget.provider);

    final allModelSettings =
        Map<String, Map<String, dynamic>>.from(liveProvider.modelSettings);
    if (normalizedSettings.isEmpty) {
      allModelSettings.remove(widget.modelName);
    } else {
      allModelSettings[widget.modelName] = normalizedSettings;
    }

    ref.read(settingsProvider.notifier).updateProvider(
          id: widget.provider.id,
          modelSettings: allModelSettings,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = FluentTheme.of(context);
    final provider = ref.watch(settingsProvider).providers.firstWhere(
          (item) => item.id == widget.provider.id,
          orElse: () => widget.provider,
        );
    final nativeTools = resolveGeminiNativeToolsFromSettings(_modelSettings);
    final showGeminiNativeTools =
        provider.providerFamily == ProviderModelFamily.geminiNative;

    // Extract custom params for display (exclude _aurora_ keys)
    final customParams = _draft.customParams;

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
      title: Row(
        children: [
          const Icon(AuroraIcons.robot, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.modelName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.provider.name,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.resources.textFillColorSecondary),
              ),
            ],
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            if (showGeminiNativeTools) ...[
              _buildSectionCard(
                title: l10n.geminiNativeTools,
                subtitle: l10n.geminiNativeToolsSubtitle,
                icon: AuroraIcons.skills,
                headerAction: null,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text(l10n.geminiNativeGoogleSearch)),
                        ToggleSwitch(
                          checked: nativeTools.googleSearch,
                          onChanged: (v) {
                            _saveSettings(
                              geminiNativeTools: GeminiNativeToolsConfig(
                                googleSearch: v,
                                urlContext: nativeTools.urlContext,
                                codeExecution: nativeTools.codeExecution,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: Text(l10n.geminiNativeUrlContext)),
                        ToggleSwitch(
                          checked: nativeTools.urlContext,
                          onChanged: (v) {
                            _saveSettings(
                              geminiNativeTools: GeminiNativeToolsConfig(
                                googleSearch: nativeTools.googleSearch,
                                urlContext: v,
                                codeExecution: nativeTools.codeExecution,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: Text(l10n.geminiNativeCodeExecution)),
                        ToggleSwitch(
                          checked: nativeTools.codeExecution,
                          onChanged: (v) {
                            _saveSettings(
                              geminiNativeTools: GeminiNativeToolsConfig(
                                googleSearch: nativeTools.googleSearch,
                                urlContext: nativeTools.urlContext,
                                codeExecution: v,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.resources.subtleFillColorSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.geminiNativeSearchDisablesLegacySearch,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.resources.textFillColorPrimary
                              .withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Thinking Configuration Card
            _buildSectionCard(
              title: l10n.thinkingConfig,
              icon: AuroraIcons.lightbulb,
              headerAction: ToggleSwitch(
                checked: _draft.thinkingEnabled,
                onChanged: (v) => _saveSettings(thinkingEnabled: v),
              ),
              child: _draft.thinkingEnabled
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        InfoLabel(
                          label: l10n.thinkingBudget,
                          child: TextBox(
                            placeholder: l10n.thinkingBudgetHint,
                            controller: _draft.thinkingBudgetController,
                            onChanged: (_) => _saveSettings(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InfoLabel(
                          label: l10n.transmissionMode,
                          child: AuroraFluentDropdownField<String>(
                            value: _draft.thinkingMode,
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
                        ),
                      ],
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            // Generation Configuration Card
            _buildSectionCard(
              title: l10n.generationConfig,
              icon: AuroraIcons.settings,
              headerAction: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  InfoLabel(
                    label: l10n.temperature,
                    child: TextBox(
                      placeholder: l10n.temperatureHint,
                      controller: _draft.temperatureController,
                      onChanged: (_) => _saveSettings(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.maxTokens,
                    child: TextBox(
                      placeholder: l10n.maxTokensHint,
                      controller: _draft.maxTokensController,
                      onChanged: (_) => _saveSettings(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.contextLength,
                    child: TextBox(
                      placeholder: l10n.contextLengthHint,
                      controller: _draft.contextLengthController,
                      onChanged: (_) => _saveSettings(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Custom Parameters Card
            _buildSectionCard(
              title: l10n.customParams,
              subtitle: l10n.paramsHigherPriority,
              icon: AuroraIcons.edit,
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
                            color: theme.resources.dividerStrokeColorDefault),
                        borderRadius: BorderRadius.circular(8),
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: Column(
                        children: [
                          Icon(AuroraIcons.parameter,
                              size: 32,
                              color: theme.resources.textFillColorTertiary),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noCustomParams,
                            style: TextStyle(
                                color: theme.resources.textFillColorSecondary),
                          ),
                          const SizedBox(height: 8),
                          Button(
                            child: Text(l10n.addCustomParam),
                            onPressed: () => _addParam(customParams),
                          )
                        ],
                      ),
                    )
                  else
                    ...customParams.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildParamItem(
                            e.key, e.value, customParams, theme),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          child: Text(l10n.done),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? headerAction,
    Widget? child,
  }) {
    final theme = FluentTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.resources.cardStrokeColorDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.resources.textFillColorSecondary)),
                ],
              ),
              const Spacer(),
              if (headerAction != null) headerAction,
            ],
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildParamItem(String key, dynamic value,
      Map<String, dynamic> currentParams, FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.resources.controlFillColorSecondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(key,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          const Icon(AuroraIcons.chevronRight, size: 10, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatSettingsParamValue(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: theme.resources.textFillColorSecondary,
                  fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            icon: const Icon(AuroraIcons.edit, size: 14),
            onPressed: () => _editParam(key, value, currentParams),
          ),
          IconButton(
            icon: Icon(AuroraIcons.delete,
                size: 14, color: Colors.red.withValues(alpha: 0.8)),
            onPressed: () => _removeParam(key, currentParams),
          ),
        ],
      ),
    );
  }

  void _addParam(Map<String, dynamic> currentParams) async {
    final result = await showDialog<MapEntry<String, dynamic>>(
      context: context,
      builder: (context) => const _AddParamDialog(),
    );
    if (result != null) {
      final newParams = Map<String, dynamic>.from(currentParams);
      newParams[result.key] = result.value;
      _saveSettings(customParams: newParams);
    }
  }

  void _editParam(
      String key, dynamic value, Map<String, dynamic> currentParams) async {
    final result = await showDialog<MapEntry<String, dynamic>>(
      context: context,
      builder: (context) =>
          _AddParamDialog(initialKey: key, initialValue: value),
    );
    if (result != null) {
      final newParams = Map<String, dynamic>.from(currentParams);
      newParams.remove(key);
      newParams[result.key] = result.value;
      _saveSettings(customParams: newParams);
    }
  }

  void _removeParam(String key, Map<String, dynamic> currentParams) {
    final newParams = Map<String, dynamic>.from(currentParams);
    newParams.remove(key);
    _saveSettings(customParams: newParams);
  }
}

class _AddParamDialog extends StatefulWidget {
  final String? initialKey;
  final dynamic initialValue;
  const _AddParamDialog({this.initialKey, this.initialValue});
  @override
  State<_AddParamDialog> createState() => _AddParamDialogState();
}

class _AddParamDialogState extends State<_AddParamDialog> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  SettingsParamValueType _type = SettingsParamValueType.string;

  @override
  void initState() {
    super.initState();
    if (widget.initialKey != null) {
      _keyController.text = widget.initialKey!;
    }
    if (widget.initialValue != null) {
      _type = detectSettingsParamValueType(widget.initialValue);
      if (_type == SettingsParamValueType.json) {
        _valueController.text = jsonEncode(widget.initialValue);
      } else {
        _valueController.text = widget.initialValue.toString();
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
    final typeLabels = <SettingsParamValueType, String>{
      SettingsParamValueType.string: l10n.typeText,
      SettingsParamValueType.number: l10n.typeNumber,
      SettingsParamValueType.boolean: l10n.typeBoolean,
      SettingsParamValueType.json: l10n.typeJson,
    };

    return ContentDialog(
      title: Text(isEditing ? l10n.editParam : l10n.addCustomParam),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLabel(
            label: l10n.paramKey,
            child: TextBox(
              controller: _keyController,
              placeholder: l10n.paramKeyPlaceholder,
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: l10n.typeLabel,
            child: AuroraFluentDropdownField<SettingsParamValueType>(
              value: _type,
              options: typeLabels.entries
                  .map(
                    (entry) => AuroraDropdownOption<SettingsParamValueType>(
                      value: entry.key,
                      label: entry.value,
                    ),
                  )
                  .toList(growable: false),
              onChanged: (v) => setState(() => _type = v!),
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: l10n.paramValue,
            child: TextBox(
              controller: _valueController,
              placeholder: _type == SettingsParamValueType.json
                  ? '{"key": "value"}'
                  : l10n.paramValue,
              maxLines: _type == SettingsParamValueType.json ? 3 : 1,
            ),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final key = _keyController.text.trim();
            if (key.isEmpty) return;
            try {
              final value =
                  parseSettingsParamValue(_type, _valueController.text);
              Navigator.pop(context, MapEntry(key, value));
            } catch (_) {
              return;
            }
          },
          child: Text(isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
