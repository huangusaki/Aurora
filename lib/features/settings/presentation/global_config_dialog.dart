
import 'dart:convert';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'settings_provider.dart';

class GlobalConfigDialog extends ConsumerStatefulWidget {
  final ProviderConfig provider;

  const GlobalConfigDialog({super.key, required this.provider});

  @override
  ConsumerState<GlobalConfigDialog> createState() => _GlobalConfigDialogState();
}

class _GlobalConfigDialogState extends ConsumerState<GlobalConfigDialog> {
  late Map<String, dynamic> _globalSettings;
  late List<String> _globalExcludeModels;

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
    _globalSettings = Map<String, dynamic>.from(widget.provider.globalSettings);
    _globalExcludeModels =
        List<String>.from(widget.provider.globalExcludeModels);

    final thinkingConfig = _globalSettings['_aurora_thinking_config'];
    if (thinkingConfig != null && thinkingConfig is Map) {
      _thinkingEnabled = thinkingConfig['enabled'] == true;
      _thinkingBudget = thinkingConfig['budget']?.toString() ?? '';
      _thinkingMode = thinkingConfig['mode']?.toString() ?? 'auto';
    } else {
      _thinkingEnabled = false;
      _thinkingBudget = '';
      _thinkingMode = 'auto';
    }

    final generationConfig = _globalSettings['_aurora_generation_config'];
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

    final newSettings = Map<String, dynamic>.from(_globalSettings);

    // Apply Custom Params override if provided
    if (customParams != null) {
      // Remove all non-internal keys
      newSettings.removeWhere((key, value) => !key.startsWith('_aurora_'));
      // Add new custom params
      newSettings.addAll(customParams);
    }

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

    setState(() {
      _globalSettings = newSettings;
    });

    ref.read(settingsProvider.notifier).updateProvider(
          id: widget.provider.id,
          globalSettings: newSettings,
          globalExcludeModels: _globalExcludeModels,
        );
  }

  void _updateExcludeModels(List<String> newModels) {
    setState(() {
      _globalExcludeModels = newModels;
    });
    ref.read(settingsProvider.notifier).updateProvider(
          id: widget.provider.id,
          globalExcludeModels: _globalExcludeModels,
        );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? headerAction,
    required Widget? child,
  }) {
    final theme = FluentTheme.of(context);
    return Card(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.typography.bodyStrong),
                    if (subtitle != null)
                      Text(subtitle,
                          style: theme.typography.caption
                              ?.copyWith(color: Colors.grey)),
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

  Widget _buildParamItem(String key, dynamic value, Map<String, dynamic> currentParams, FluentThemeData theme) {
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
            child: Text(
              key, 
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600)
            ),
          ),
          const SizedBox(width: 12),
          const Icon(AuroraIcons.chevronRight, size: 10, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatValue(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.resources.textFillColorSecondary, fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            icon: const Icon(AuroraIcons.edit, size: 14),
            onPressed: () => _editParam(key, value, currentParams),
          ),
          IconButton(
            icon: Icon(AuroraIcons.delete, size: 14, color: Colors.red.withOpacity(0.8)),
            onPressed: () => _removeParam(key, currentParams),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is String) return '"$value"';
    return jsonEncode(value);
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

  void _editParam(String key, dynamic value, Map<String, dynamic> currentParams) async {
    final result = await showDialog<MapEntry<String, dynamic>>(
      context: context,
      builder: (context) => _AddParamDialog(initialKey: key, initialValue: value),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = FluentTheme.of(context);
    
    // Extract custom settings (exclude internal _aurora_ keys)
    final customParams = Map<String, dynamic>.fromEntries(
        _globalSettings.entries.where((e) => !e.key.startsWith('_aurora_')));

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
      title: Text('${l10n.globalConfig} - ${widget.provider.name}'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Exclude Models Card
            _buildSectionCard(
              title: l10n.excludedModels,
              subtitle: l10n.excludedModelsHint,
              icon: AuroraIcons.blocked,
              headerAction: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  AutoSuggestBox<String>(
                    placeholder: l10n.enterModelNameHint,
                    items: widget.provider.models
                        .map((e) => AutoSuggestBoxItem(value: e, label: e))
                        .toList(),
                    onSelected: (item) {
                      if (item.value != null &&
                          !_globalExcludeModels.contains(item.value!)) {
                        _updateExcludeModels([..._globalExcludeModels, item.value!]);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_globalExcludeModels.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _globalExcludeModels.map((model) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(model),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(AuroraIcons.close, size: 10, color: Colors.red),
                                onPressed: () {
                                  _updateExcludeModels(
                                      _globalExcludeModels.where((e) => e != model).toList());
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thinking Configuration Card
            _buildSectionCard(
              title: l10n.thinkingConfig,
              icon: AuroraIcons.lightbulb,
              headerAction: ToggleSwitch(
                checked: _thinkingEnabled,
                onChanged: (v) => _saveSettings(thinkingEnabled: v),
              ),
              child: _thinkingEnabled
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
                            controller: TextEditingController(
                                text: _thinkingBudget)
                              ..selection = TextSelection.collapsed(
                                  offset: _thinkingBudget.length),
                            onChanged: (v) =>
                                _saveSettings(thinkingBudget: v),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InfoLabel(
                          label: l10n.transmissionMode,
                          child: ComboBox<String>(
                            value: _thinkingMode,
                            isExpanded: true,
                            items: [
                              ComboBoxItem(
                                  value: 'auto', child: Text(l10n.modeAuto)),
                              ComboBoxItem(
                                  value: 'extra_body',
                                  child: Text(l10n.modeExtraBody)),
                              ComboBoxItem(
                                  value: 'reasoning_effort',
                                  child: Text(l10n.modeReasoningEffort)),
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
                      controller: TextEditingController(text: _temperature)
                        ..selection = TextSelection.collapsed(
                            offset: _temperature.length),
                      onChanged: (v) => _saveSettings(temperature: v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.maxTokens,
                    child: TextBox(
                      placeholder: l10n.maxTokensHint,
                      controller: TextEditingController(text: _maxTokens)
                        ..selection = TextSelection.collapsed(
                            offset: _maxTokens.length),
                      onChanged: (v) => _saveSettings(maxTokens: v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.contextLength,
                    child: TextBox(
                      placeholder: l10n.contextLengthHint,
                      controller: TextEditingController(text: _contextLength)
                        ..selection = TextSelection.collapsed(
                            offset: _contextLength.length),
                      onChanged: (v) => _saveSettings(contextLength: v),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Custom Parameters Card
            _buildSectionCard(
              title: l10n.customParams,
              icon: AuroraIcons.edit,
              headerAction: IconButton(
                icon: const Icon(AuroraIcons.add),
                onPressed: () => _addParam(customParams),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  if (customParams.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        l10n.noCustomParams,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...customParams.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildParamItem(e.key, e.value, customParams, theme),
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
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
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
  String _type = 'String';
  @override
  void initState() {
    super.initState();
    if (widget.initialKey != null) {
      _keyController.text = widget.initialKey!;
    }
    if (widget.initialValue != null) {
      if (widget.initialValue is String) {
        _valueController.text = widget.initialValue;
        _type = 'String';
      } else {
        _valueController.text = jsonEncode(widget.initialValue);
        _type = 'JSON';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialKey != null;
    final l10n = AppLocalizations.of(context)!;
    
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
              placeholder: 'e.g. image_config',
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: l10n.paramType,
            child: ComboBox<String>(
              value: _type,
              isExpanded: true,
              items: ['String', 'JSON']
                  .map((e) => ComboBoxItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: l10n.paramValue,
            child: TextBox(
              controller: _valueController,
              placeholder: _type == 'JSON' ? '{"key": "value"}' : 'Value',
              maxLines: _type == 'JSON' ? 3 : 1,
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
            dynamic value;
            if (_type == 'String') {
              value = _valueController.text;
            } else {
              try {
                value = jsonDecode(_valueController.text);
              } catch (_) {
                return;
              }
            }
            Navigator.pop(context, MapEntry(key, value));
          },
          child: Text(isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
