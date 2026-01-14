import 'dart:io';
import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';

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
  final TextEditingController _colorController = TextEditingController();
  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _userNameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final activeProvider = settingsState.activeProvider;
    final fluentTheme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: fluentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: fluentTheme.scaffoldBackgroundColor,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SectionHeader(
                    title: l10n.modelProvider, icon: Icons.cloud_outlined),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(l10n.currentProvider),
                  subtitle: Text(activeProvider?.name ?? l10n.notConfigured),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showProviderPicker(context, settingsState),
                ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Color'),
                  subtitle: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (activeProvider?.color != null &&
                          activeProvider!.color!.isNotEmpty)
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Color(int.tryParse(activeProvider.color!
                                    .replaceFirst('#', '0xFF')) ??
                                0xFF000000),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      Text(activeProvider?.color ?? l10n.notConfigured),
                    ],
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showColorEditor(context, activeProvider),
                ),
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('API Key'),
                  subtitle: Text(activeProvider?.apiKey.isNotEmpty == true
                      ? '••••••••'
                      : l10n.notConfigured),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showApiKeyEditor(context, activeProvider),
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('API Base URL'),
                  subtitle: Text(
                      activeProvider?.baseUrl ?? 'https://api.openai.com/v1'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showBaseUrlEditor(context, activeProvider),
                ),
                ListTile(
                  leading: const Icon(Icons.power_settings_new),
                  title: Text(l10n.enabledStatus),
                  subtitle: Text(activeProvider?.isEnabled == true
                      ? l10n.enabled
                      : l10n.disabled),
                  trailing: Switch(
                    value: activeProvider?.isEnabled == true,
                    onChanged: (v) {
                      if (activeProvider != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .toggleProviderEnabled(activeProvider.id);
                      }
                    },
                  ),
                  onTap: () {
                    if (activeProvider != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .toggleProviderEnabled(activeProvider.id);
                    }
                  },
                ),
                _SectionHeader(
                  title: l10n.availableModels,
                  icon: Icons.format_list_bulleted,
                  trailing: SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: settingsState.isLoadingModels
                          ? null
                          : () {
                              ref.read(settingsProvider.notifier).fetchModels();
                            },
                      child: settingsState.isLoadingModels
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.fetchModelList),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (activeProvider != null && activeProvider.models.isNotEmpty)
            SliverList.builder(
              itemCount: activeProvider.models.length,
              itemBuilder: (context, index) {
                final model = activeProvider.models[index];
                return ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(model),
                  trailing: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () =>
                        _showModelConfigDialog(context, activeProvider, model),
                  ),
                );
              },
            )
          else if (activeProvider != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noModelsFetch,
                    style: const TextStyle(color: Colors.grey)),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  void _showProviderPicker(BuildContext context, SettingsState paramState) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return Consumer(
          builder: (scopedContext, ref, _) {
            final state = ref.watch(settingsProvider);
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.selectProvider,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  ...state.providers.map((p) => ListTile(
                        leading: Icon(
                          p.id == state.activeProviderId
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: p.id == state.activeProviderId
                              ? Theme.of(scopedContext).primaryColor
                              : null,
                        ),
                        title: Text(p.name),
                        subtitle: Text(p.selectedModel ?? l10n.noModelSelected),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () {
                                Navigator.pop(ctx);
                                showDialog(
                                    context: scopedContext,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(l10n.deleteProvider),
                                        content:
                                            Text(l10n.deleteProviderConfirm),
                                        actions: [
                                          TextButton(
                                            child: Text(l10n.cancel),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          TextButton(
                                            child: Text(l10n.delete),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ref
                                                  .read(
                                                      settingsProvider.notifier)
                                                  .deleteProvider(p.id);
                                            },
                                          ),
                                        ],
                                      );
                                    });
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
                          if (!p.isEnabled) {}
                          ref
                              .read(settingsProvider.notifier)
                              .selectProvider(p.id);
                          Navigator.pop(ctx);
                        },
                      )),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(l10n.addProvider),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(settingsProvider.notifier).addProvider();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showModelConfigDialog(
      BuildContext context, ProviderConfig provider, String modelName) {
    final currentSettings = provider.modelSettings[modelName] ?? {};
    showDialog(
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

  void _showProviderRenameDialog(
      BuildContext context, ProviderConfig provider) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: provider.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.renameProvider),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.enterProviderName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(settingsProvider.notifier).updateProvider(
                      id: provider.id,
                      name: controller.text.trim(),
                    );
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showApiKeyEditor(BuildContext context, ProviderConfig? provider) {
    if (provider == null) return;
    final l10n = AppLocalizations.of(context)!;
    _apiKeyController.text = provider.apiKey;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.editApiKey),
        content: TextField(
          controller: _apiKeyController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'sk-xxxxxxxx',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).updateProvider(
                    id: provider.id,
                    apiKey: _apiKeyController.text,
                  );
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showBaseUrlEditor(BuildContext context, ProviderConfig? provider) {
    if (provider == null) return;
    final l10n = AppLocalizations.of(context)!;
    _baseUrlController.text = provider.baseUrl;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.editBaseUrl),
        content: TextField(
          controller: _baseUrlController,
          decoration: const InputDecoration(
            hintText: 'https://api.openai.com/v1',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).updateProvider(
                    id: provider.id,
                    baseUrl: _baseUrlController.text,
                  );
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showColorEditor(BuildContext context, ProviderConfig? provider) {
    if (provider == null) return;
    final l10n = AppLocalizations.of(context)!;
    _colorController.text = provider.color ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit Color'),
        content: TextField(
          controller: _colorController,
          decoration: const InputDecoration(
            hintText: '#FF0000',
            labelText: 'Hex Color',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            // Force rebuild if needed
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).updateProvider(
                    id: provider.id,
                    color: _colorController.text,
                  );
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showTextEditor(BuildContext context, String title, String currentValue,
      Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('编辑$title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '请输入$title',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar({required bool isUser}) async {
    final result = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
            label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp']),
      ],
    );
    if (result != null) {
      if (isUser) {
        ref
            .read(settingsProvider.notifier)
            .setChatDisplaySettings(userAvatar: result.path);
      } else {
        ref
            .read(settingsProvider.notifier)
            .setChatDisplaySettings(llmAvatar: result.path);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ModelConfigDialog extends StatefulWidget {
  final String modelName;
  final Map<String, dynamic> initialSettings;
  final Function(Map<String, dynamic>) onSave;
  const _ModelConfigDialog({
    super.key,
    required this.modelName,
    required this.initialSettings,
    required this.onSave,
  });
  @override
  State<_ModelConfigDialog> createState() => _ModelConfigDialogState();
}

class _ModelConfigDialogState extends State<_ModelConfigDialog> {
  late Map<String, dynamic> _settings;
  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.initialSettings);
  }

  void _saveParameter(String? oldKey, String newKey, dynamic value) {
    setState(() {
      if (oldKey != null && oldKey != newKey) {
        _settings.remove(oldKey);
      }
      _settings[newKey] = value;
    });
    widget.onSave(_settings);
  }

  void _removeParameter(String key) {
    setState(() {
      _settings.remove(key);
    });
    widget.onSave(_settings);
  }

  void _showEditDialog([String? key, dynamic value]) {
    showDialog(
      context: context,
      builder: (ctx) => _ParameterConfigDialog(
        initialKey: key,
        initialValue: value,
        onSave: (newKey, newValue) => _saveParameter(key, newKey, newValue),
      ),
    );
  }

  Widget _buildThinkingConfig(AppLocalizations l10n) {
    final thinkingEnabled = _settings['_aurora_thinking_enabled'] == true;
    final thinkingValue = _settings['_aurora_thinking_value']?.toString() ?? '';
    final thinkingMode =
        _settings['_aurora_thinking_mode']?.toString() ?? 'auto';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.thinkingConfig,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(l10n.enableThinking,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          value: thinkingEnabled,
          onChanged: (v) => _saveParameter(null, '_aurora_thinking_enabled', v),
        ),
        if (thinkingEnabled) ...[
          Padding(
            padding: const EdgeInsets.only(left: 0, bottom: 12, top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThinkingBudgetInput(
                  initialValue: thinkingValue,
                  labelText: l10n.thinkingBudget,
                  hintText: l10n.thinkingBudgetHint,
                  onChanged: (v) =>
                      _saveParameter(null, '_aurora_thinking_value', v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: thinkingMode,
                  decoration: InputDecoration(
                    labelText: l10n.transmissionMode,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  items: [
                    DropdownMenuItem(value: 'auto', child: Text(l10n.modeAuto)),
                    DropdownMenuItem(
                        value: 'extra_body', child: Text(l10n.modeExtraBody)),
                    DropdownMenuItem(
                        value: 'reasoning_effort',
                        child: Text(l10n.modeReasoningEffort)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _saveParameter(null, '_aurora_thinking_mode', v);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final displayKeys =
        _settings.keys.where((k) => !k.startsWith('_aurora_')).toList();
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF202020) : Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.modelName,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(l10n.modelConfig,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThinkingConfig(l10n),
            if (displayKeys.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: Text(l10n.noCustomParams,
                        style: const TextStyle(color: Colors.grey))),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: displayKeys.length,
                  itemBuilder: (context, index) {
                    final key = displayKeys[index];
                    final value = _settings[key];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(key,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('$value',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _showEditDialog(key, value),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _removeParameter(key),
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_circle_outline),
              title: Text(l10n.addCustomParam),
              onTap: () => _showEditDialog(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}

class _ThinkingBudgetInput extends StatefulWidget {
  final String initialValue;
  final String labelText;
  final String hintText;
  final ValueChanged<String> onChanged;
  const _ThinkingBudgetInput({
    required this.initialValue,
    required this.labelText,
    required this.hintText,
    required this.onChanged,
  });
  @override
  State<_ThinkingBudgetInput> createState() => _ThinkingBudgetInputState();
}

class _ThinkingBudgetInputState extends State<_ThinkingBudgetInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String _lastSavedValue = '';
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _lastSavedValue = widget.initialValue;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveValue();
      }
    });
  }

  @override
  void didUpdateWidget(_ThinkingBudgetInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _lastSavedValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _lastSavedValue = widget.initialValue;
    }
  }

  @override
  void dispose() {
    if (_controller.text != _lastSavedValue) {
      widget.onChanged(_controller.text);
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveValue() {
    if (_controller.text != _lastSavedValue) {
      _lastSavedValue = _controller.text;
      widget.onChanged(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      onSubmitted: (_) => _saveValue(),
      onEditingComplete: _saveValue,
    );
  }
}

class _ParameterConfigDialog extends StatefulWidget {
  final String? initialKey;
  final dynamic initialValue;
  final Function(String key, dynamic value) onSave;
  const _ParameterConfigDialog({
    super.key,
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
  bool _isInit = true;
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
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF202020) : Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text(isEditing ? l10n.editParam : l10n.addCustomParam),
      content: Column(
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
            value: _type,
            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            decoration: InputDecoration(
              labelText: l10n.paramType,
              border: const OutlineInputBorder(),
            ),
            items: typeMap.entries
                .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l10n.formatError}: $e')),
              );
            }
          },
          child: Text(isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
