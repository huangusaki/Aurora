import 'dart:async';
import 'dart:convert';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:aurora/shared/riverpod_legacy.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/widgets/aurora_dropdown.dart';
import 'settings_config_draft.dart';
import 'settings_provider.dart';

class GlobalConfigDialog extends ConsumerStatefulWidget {
  final ProviderConfig provider;

  const GlobalConfigDialog({super.key, required this.provider});

  @override
  ConsumerState<GlobalConfigDialog> createState() => _GlobalConfigDialogState();
}

class _GlobalConfigDialogState extends ConsumerState<GlobalConfigDialog> {
  late SettingsConfigDraft _draft;
  late List<String> _globalExcludeModels;
  final FocusNode _thinkingBudgetFocusNode = FocusNode();
  final FocusNode _temperatureFocusNode = FocusNode();
  final FocusNode _maxTokensFocusNode = FocusNode();
  final FocusNode _contextLengthFocusNode = FocusNode();
  bool _isDirty = false;
  Future<bool>? _pendingCommit;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _attachCommitOnBlur(_thinkingBudgetFocusNode);
    _attachCommitOnBlur(_temperatureFocusNode);
    _attachCommitOnBlur(_maxTokensFocusNode);
    _attachCommitOnBlur(_contextLengthFocusNode);
  }

  void _loadSettings() {
    _draft = SettingsConfigDraft.fromSettings(widget.provider.globalSettings);
    _globalExcludeModels =
        List<String>.from(widget.provider.globalExcludeModels);
    _isDirty = false;
  }

  void _attachCommitOnBlur(FocusNode focusNode) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        unawaited(_commitDraftIfNeeded());
      }
    });
  }

  @override
  void dispose() {
    _thinkingBudgetFocusNode.dispose();
    _temperatureFocusNode.dispose();
    _maxTokensFocusNode.dispose();
    _contextLengthFocusNode.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _updateDraft({
    bool? thinkingEnabled,
    String? thinkingMode,
    Map<String, dynamic>? customParams,
    List<String>? globalExcludeModels,
  }) {
    setState(() {
      if (thinkingEnabled != null) {
        _draft.thinkingEnabled = thinkingEnabled;
      }
      if (thinkingMode != null) {
        _draft.thinkingMode = thinkingMode;
      }
      if (globalExcludeModels != null) {
        _globalExcludeModels = globalExcludeModels;
      }
      if (thinkingEnabled != null ||
          thinkingMode != null ||
          customParams != null) {
        _draft.buildSettings(customParams: customParams);
      }
      _isDirty = true;
    });
  }

  void _updateExcludeModels(List<String> newModels) {
    _updateDraft(globalExcludeModels: newModels);
  }

  void _markDirty() {
    if (_isDirty) {
      return;
    }
    setState(() {
      _isDirty = true;
    });
  }

  Future<bool> _commitDraftIfNeeded() {
    final pendingCommit = _pendingCommit;
    if (pendingCommit != null) {
      return pendingCommit;
    }
    if (!_isDirty) {
      return Future.value(true);
    }

    final future = _commitDraft();
    _pendingCommit = future;
    future.whenComplete(() {
      if (identical(_pendingCommit, future)) {
        _pendingCommit = null;
      }
    });
    return future;
  }

  Future<bool> _commitDraft() async {
    final liveProvider = ref.read(settingsProvider).providers.firstWhere(
          (item) => item.id == widget.provider.id,
          orElse: () => widget.provider,
        );
    final newSettings = _draft.buildSettings();
    final hasSettingsChange =
        jsonEncode(newSettings) != jsonEncode(liveProvider.globalSettings);
    final hasExcludeModelsChange = jsonEncode(_globalExcludeModels) !=
        jsonEncode(liveProvider.globalExcludeModels);

    if (!hasSettingsChange && !hasExcludeModelsChange) {
      if (mounted && _isDirty) {
        setState(() {
          _isDirty = false;
        });
      }
      return true;
    }

    try {
      await ref.read(settingsProvider.notifier).updateProvider(
            id: widget.provider.id,
            globalSettings: newSettings,
            globalExcludeModels: _globalExcludeModels,
          );
      if (mounted) {
        setState(() {
          _isDirty = false;
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _scheduleCommitIfNeeded() {
    if (!_isDirty) {
      return;
    }
    unawaited(_commitDraftIfNeeded());
  }

  Future<void> _saveAndClose() async {
    final saved = await _commitDraftIfNeeded();
    if (saved && mounted) {
      Navigator.pop(context);
    }
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
                  color: theme.accentColor.withValues(alpha: 0.1),
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
      _updateDraft(customParams: newParams);
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
      _updateDraft(customParams: newParams);
    }
  }

  void _removeParam(String key, Map<String, dynamic> currentParams) {
    final newParams = Map<String, dynamic>.from(currentParams);
    newParams.remove(key);
    _updateDraft(customParams: newParams);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = FluentTheme.of(context);

    // Extract custom settings (exclude internal _aurora_ keys)
    final customParams = _draft.customParams;

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
                        _updateExcludeModels(
                            [..._globalExcludeModels, item.value!]);
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(model),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(AuroraIcons.close,
                                    size: 10, color: Colors.red),
                                onPressed: () {
                                  _updateExcludeModels(_globalExcludeModels
                                      .where((e) => e != model)
                                      .toList());
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
                checked: _draft.thinkingEnabled,
                onChanged: (v) => _updateDraft(thinkingEnabled: v),
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
                            focusNode: _thinkingBudgetFocusNode,
                            onChanged: (_) => _markDirty(),
                            onSubmitted: (_) => _scheduleCommitIfNeeded(),
                            onTapOutside: (_) => _scheduleCommitIfNeeded(),
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
                              if (v != null) {
                                _updateDraft(thinkingMode: v);
                              }
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
                      focusNode: _temperatureFocusNode,
                      onChanged: (_) => _markDirty(),
                      onSubmitted: (_) => _scheduleCommitIfNeeded(),
                      onTapOutside: (_) => _scheduleCommitIfNeeded(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.maxTokens,
                    child: TextBox(
                      placeholder: l10n.maxTokensHint,
                      controller: _draft.maxTokensController,
                      focusNode: _maxTokensFocusNode,
                      onChanged: (_) => _markDirty(),
                      onSubmitted: (_) => _scheduleCommitIfNeeded(),
                      onTapOutside: (_) => _scheduleCommitIfNeeded(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoLabel(
                    label: l10n.contextLength,
                    child: TextBox(
                      placeholder: l10n.contextLengthHint,
                      controller: _draft.contextLengthController,
                      focusNode: _contextLengthFocusNode,
                      onChanged: (_) => _markDirty(),
                      onSubmitted: (_) => _scheduleCommitIfNeeded(),
                      onTapOutside: (_) => _scheduleCommitIfNeeded(),
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
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saveAndClose,
          child: Text(l10n.save),
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
