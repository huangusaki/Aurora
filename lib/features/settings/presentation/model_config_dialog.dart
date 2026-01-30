import 'dart:convert';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/l10n/app_localizations.dart';
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
  late Map<String, dynamic> _modelSettings;
  
  // Thinking config temporary state
  bool _thinkingEnabled = false;
  String _thinkingMode = 'auto';

  // Controllers
  late final TextEditingController _thinkingBudgetController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _maxTokensController;
  late final TextEditingController _contextLengthController;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // Initialize controllers with loaded values
    _thinkingBudgetController = TextEditingController(
      text: _modelSettings['_aurora_thinking_config']?['budget']?.toString() ?? ''
    );
    _temperatureController = TextEditingController(
      text: _modelSettings['_aurora_generation_config']?['temperature']?.toString() ?? ''
    );
    _maxTokensController = TextEditingController(
      text: _modelSettings['_aurora_generation_config']?['max_tokens']?.toString() ?? ''
    );
    _contextLengthController = TextEditingController(
      text: _modelSettings['_aurora_generation_config']?['context_length']?.toString() ?? ''
    );
  }

  @override
  void dispose() {
    _thinkingBudgetController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    _contextLengthController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final liveProvider = ref.read(settingsProvider).providers.firstWhere(
        (p) => p.id == widget.provider.id,
        orElse: () => widget.provider);
        
    final existingSettings = liveProvider.modelSettings[widget.modelName] ?? {};
    _modelSettings = Map<String, dynamic>.from(existingSettings);

    final thinkingConfig = _modelSettings['_aurora_thinking_config'];
    if (thinkingConfig != null && thinkingConfig is Map) {
      _thinkingEnabled = thinkingConfig['enabled'] == true;
      _thinkingMode = thinkingConfig['mode']?.toString() ?? 'auto';
    } else {
      _thinkingEnabled = false;
      _thinkingMode = 'auto';
    }
  }

  void _saveSettings({
    bool? thinkingEnabled,
    String? thinkingMode,
    Map<String, dynamic>? customParams,
  }) {
    // Update local state
    if (thinkingEnabled != null) _thinkingEnabled = thinkingEnabled;
    if (thinkingMode != null) _thinkingMode = thinkingMode;

    // Construct new settings map
    final newSettings = Map<String, dynamic>.from(_modelSettings);
    
    // Handle Thinking Config
    if (_thinkingEnabled) {
      newSettings['_aurora_thinking_config'] = {
        'enabled': true,
        'budget': _thinkingBudgetController.text,
        'mode': _thinkingMode,
      };
    } else {
      newSettings.remove('_aurora_thinking_config');
    }

    // Handle Generation Config
    final temp = _temperatureController.text;
    final maxTokens = _maxTokensController.text;
    final contextLength = _contextLengthController.text;

    if (temp.isNotEmpty || maxTokens.isNotEmpty || contextLength.isNotEmpty) {
      newSettings['_aurora_generation_config'] = {
        if (temp.isNotEmpty) 'temperature': temp,
        if (maxTokens.isNotEmpty) 'max_tokens': maxTokens,
        if (contextLength.isNotEmpty) 'context_length': contextLength,
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

    // Save to provider
    final liveProvider = ref.read(settingsProvider).providers
        .firstWhere((p) => p.id == widget.provider.id, orElse: () => widget.provider);
    
    final allModelSettings = Map<String, Map<String, dynamic>>.from(liveProvider.modelSettings);
    if (newSettings.isEmpty) {
      allModelSettings.remove(widget.modelName);
    } else {
      allModelSettings[widget.modelName] = newSettings;
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

    // Extract custom params for display (exclude _aurora_ keys)
    final customParams = Map<String, dynamic>.fromEntries(
      _modelSettings.entries.where((e) => !e.key.startsWith('_aurora_'))
    );

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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.provider.name,
                style: TextStyle(fontSize: 12, color: theme.resources.textFillColorSecondary),
              ),
            ],
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // Thinking Configuration Card
            _buildSectionCard(
              title: l10n.thinkingConfig,
              icon: AuroraIcons.lightbulb,

              headerAction: ToggleSwitch(
                checked: _thinkingEnabled,
                onChanged: (v) => _saveSettings(thinkingEnabled: v),
              ),
              child: _thinkingEnabled ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  InfoLabel(
                    label: l10n.thinkingBudget,
                    child: TextBox(
                      placeholder: l10n.thinkingBudgetHint,
                      controller: _thinkingBudgetController,
                      onChanged: (v) => _saveSettings(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.transmissionMode,
                    child: ComboBox<String>(
                      value: _thinkingMode,
                      isExpanded: true,
                      items: [
                        ComboBoxItem(value: 'auto', child: Text(l10n.modeAuto)),
                        ComboBoxItem(value: 'extra_body', child: Text(l10n.modeExtraBody)),
                        ComboBoxItem(value: 'reasoning_effort', child: Text(l10n.modeReasoningEffort)),
                      ],
                      onChanged: (v) {
                        if (v != null) _saveSettings(thinkingMode: v);
                      },
                    ),
                  ),
                ],
              ) : null,
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
                      controller: _temperatureController,
                      onChanged: (v) => _saveSettings(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.maxTokens,
                    child: TextBox(
                      placeholder: l10n.maxTokensHint,
                      controller: _maxTokensController,
                      onChanged: (v) => _saveSettings(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.contextLength,
                    child: TextBox(
                      placeholder: l10n.contextLengthHint,
                      controller: _contextLengthController,
                      onChanged: (v) => _saveSettings(),
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
                        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
                        borderRadius: BorderRadius.circular(8),
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: Column(
                        children: [
                          Icon(AuroraIcons.parameter, size: 32, color: theme.resources.textFillColorTertiary),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noCustomParams,
                            style: TextStyle(color: theme.resources.textFillColorSecondary),
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
            color: Colors.black.withOpacity(0.05),
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
                  color: theme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(
                      fontSize: 12, 
                      color: theme.resources.textFillColorSecondary
                    )),
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
