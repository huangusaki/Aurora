import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'settings_provider.dart';

class SettingsContent extends ConsumerStatefulWidget {
  const SettingsContent({super.key});
  @override
  ConsumerState<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<SettingsContent> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _llmNameController = TextEditingController();
  int _settingsPageIndex = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _nameController.dispose();
    _userNameController.dispose();
    _llmNameController.dispose();
    super.dispose();
  }

  void _updateControllers(ProviderConfig provider) {
    if (_apiKeyController.text != provider.apiKey) {
      _apiKeyController.text = provider.apiKey;
    }
    if (_baseUrlController.text != provider.baseUrl) {
      _baseUrlController.text = provider.baseUrl;
    }
    if (_nameController.text != provider.name) {
      _nameController.text = provider.name;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ref.read(settingsProvider);
    if (_userNameController.text.isEmpty && settings.userName.isNotEmpty) {
      _userNameController.text = settings.userName;
    }
    if (_llmNameController.text.isEmpty && settings.llmName.isNotEmpty) {
      _llmNameController.text = settings.llmName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final viewingProvider = settingsState.viewingProvider;
    _updateControllers(viewingProvider);
    if (Platform.isWindows) {
      final theme = fluent.FluentTheme.of(context);
      final settingsPages = [
        (icon: fluent.FluentIcons.cloud_download, label: '模型提供'),
        (icon: fluent.FluentIcons.chat, label: '对话设置'),
        (icon: fluent.FluentIcons.color, label: '显示设置'),
        (icon: fluent.FluentIcons.database, label: '数据设置'),
      ];
      return Row(
        children: [
          SizedBox(
            width: 180,
            child: Container(
              decoration: BoxDecoration(
                color: theme.navigationPaneTheme.backgroundColor,
                border: Border(
                    right: BorderSide(
                        color: theme.resources.dividerStrokeColorDefault)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ...settingsPages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final page = entry.value;
                    final isSelected = _settingsPageIndex == index;
                    return fluent.HoverButton(
                      onPressed: () =>
                          setState(() => _settingsPageIndex = index),
                      builder: (context, states) {
                        return Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.accentColor.withOpacity(0.1)
                                : states.isHovering
                                    ? theme.resources.subtleFillColorSecondary
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              fluent.Icon(page.icon,
                                  size: 16,
                                  color: isSelected ? theme.accentColor : null),
                              const SizedBox(width: 12),
                              Text(
                                page.label,
                                style: TextStyle(
                                  color: isSelected ? theme.accentColor : null,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: IndexedStack(
                index: _settingsPageIndex,
                children: [
                  _buildProviderSettings(settingsState, viewingProvider),
                  _buildChatSettings(settingsState),
                  _buildDisplaySettings(),
                  _buildDataSettings(),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('移动端设置',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('请使用顶部导航栏的设置按钮访问完整设置页面',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildProviderSettings(
      SettingsState settingsState, ProviderConfig viewingProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: Column(
            children: [
              Expanded(
                child: fluent.ListView.builder(
                  itemCount: settingsState.providers.length,
                  itemBuilder: (context, index) {
                    final provider = settingsState.providers[index];
                    final isSelected =
                        provider.id == settingsState.viewingProviderId;
                    return fluent.ListTile.selectable(
                      title: fluent.Text(provider.name),
                      selected: isSelected,
                      onPressed: () {
                        ref
                            .read(settingsProvider.notifier)
                            .viewProvider(provider.id);
                      },
                      trailing: fluent.IconButton(
                        icon: const Icon(fluent.FluentIcons.delete),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return fluent.ContentDialog(
                                  title: const Text('删除供应商'),
                                  content: const Text('确定要删除此供应商配置吗？此操作无法撤销。'),
                                  actions: [
                                    fluent.Button(
                                      child: const Text('取消'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    fluent.FilledButton(
                                      child: const Text('删除'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ref
                                            .read(settingsProvider.notifier)
                                            .deleteProvider(provider.id);
                                      },
                                    ),
                                  ],
                                );
                              });
                        },
                      ),
                    );
                  },
                ),
              ),
              const fluent.Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: fluent.Button(
                    onPressed: () =>
                        ref.read(settingsProvider.notifier).addProvider(),
                    child: const fluent.Text('添加供应商'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const fluent.Divider(direction: Axis.vertical),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fluent.InfoLabel(
                      label: '供应商名称',
                      child: fluent.TextBox(
                        controller: _nameController,
                        placeholder: 'My Provider',
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).updateProvider(
                              id: viewingProvider.id, name: value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    fluent.InfoLabel(
                      label: 'API Key',
                      child: fluent.PasswordBox(
                        controller: _apiKeyController,
                        placeholder: 'sk-xxxxxxxx',
                        revealMode: fluent.PasswordRevealMode.peek,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).updateProvider(
                              id: viewingProvider.id, apiKey: value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    fluent.InfoLabel(
                      label: 'API Base URL',
                      child: fluent.TextBox(
                        controller: _baseUrlController,
                        placeholder: 'https://api.openai.com/v1',
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).updateProvider(
                              id: viewingProvider.id, baseUrl: value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    fluent.InfoLabel(
                      label: '启用状态',
                      child: Row(
                        children: [
                          fluent.ToggleSwitch(
                            checked: viewingProvider.isEnabled,
                            onChanged: (v) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleProviderEnabled(viewingProvider.id);
                            },
                            content: fluent.Text(
                                viewingProvider.isEnabled ? '已启用' : '已禁用'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: fluent.Text('可用模型',
                              overflow: TextOverflow.ellipsis,
                              style: fluent.FluentTheme.of(context)
                                  .typography
                                  .subtitle),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: fluent.Button(
                            onPressed: settingsState.isLoadingModels
                                ? null
                                : () => ref
                                    .read(settingsProvider.notifier)
                                    .fetchModels(),
                            child: settingsState.isLoadingModels
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: fluent.ProgressRing())
                                : const fluent.Text('刷新列表',
                                    overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                    if (settingsState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: fluent.Text(settingsState.error!,
                            style: TextStyle(color: fluent.Colors.red)),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: viewingProvider.models.isNotEmpty
                    ? fluent.ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        itemCount: viewingProvider.models.length,
                        itemBuilder: (context, index) {
                          final model = viewingProvider.models[index];
                          final isSelected =
                              model == viewingProvider.selectedModel;
                          final theme = fluent.FluentTheme.of(context);


                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: fluent.HoverButton(
                              onPressed: () async {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .updateProvider(
                                        id: viewingProvider.id,
                                        selectedModel: model);
                                await ref
                                    .read(settingsProvider.notifier)
                                    .selectProvider(viewingProvider.id);
                              },
                              builder: (context, states) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: isSelected
                                        ? theme.accentColor.withOpacity(0.1)
                                        : states.isHovering
                                            ? theme.typography.body?.color
                                                    ?.withOpacity(0.05) ??
                                                Colors.transparent
                                            : Colors.transparent,
                                  ),
                                  width: double.infinity,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Icon(fluent.FluentIcons.org,
                                          size: 16,
                                          color: isSelected
                                              ? theme.accentColor
                                              : theme.typography.body?.color
                                                  ?.withOpacity(0.7)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(model,
                                              overflow: TextOverflow.ellipsis)),
                                      if (isSelected)
                                        Icon(fluent.FluentIcons.check_mark,
                                            size: 14, color: theme.accentColor),
                                      fluent.IconButton(
                                        icon: const fluent.Icon(
                                            fluent.FluentIcons.settings,
                                            size: 14),
                                        onPressed: () => _openModelSettings(
                                            viewingProvider, model),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );

                        },
                      )
                    : Container(
                        margin: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: fluent.Colors.grey.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const fluent.Text('暂无模型数据，请配置后点击获取'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatSettings(SettingsState settingsState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fluent.Text('对话设置',
              style: fluent.FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: '用户名称',
            child: fluent.TextBox(
              placeholder: 'User',
              controller: _userNameController,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setChatDisplaySettings(userName: value);
              },
            ),
          ),
          const SizedBox(height: 16),
          fluent.InfoLabel(
            label: '用户头像',
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: fluent.Colors.grey.withOpacity(0.3)),
                  ),
                  child: settingsState.userAvatar != null &&
                          settingsState.userAvatar!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(settingsState.userAvatar!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                fluent.FluentIcons.contact,
                                size: 24),
                          ),
                        )
                      : const Icon(fluent.FluentIcons.contact, size: 24),
                ),
                const SizedBox(width: 12),
                fluent.Button(
                  child: const Text('选择图片'),
                  onPressed: () async {
                    final result = await openFile(
                      acceptedTypeGroups: [
                        const XTypeGroup(
                            label: 'Images',
                            extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp']),
                      ],
                    );
                    if (result != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setChatDisplaySettings(userAvatar: result.path);
                    }
                  },
                ),
                if (settingsState.userAvatar != null) ...[
                  const SizedBox(width: 8),
                  fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.delete),
                    onPressed: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setChatDisplaySettings(userAvatar: '');
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: 'AI 名称',
            child: fluent.TextBox(
              placeholder: 'Assistant',
              controller: _llmNameController,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setChatDisplaySettings(llmName: value);
              },
            ),
          ),
          const SizedBox(height: 16),
          fluent.InfoLabel(
            label: 'AI 头像',
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: fluent.Colors.grey.withOpacity(0.3)),
                  ),
                  child: settingsState.llmAvatar != null &&
                          settingsState.llmAvatar!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(settingsState.llmAvatar!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(fluent.FluentIcons.robot, size: 24),
                          ),
                        )
                      : const Icon(fluent.FluentIcons.robot, size: 24),
                ),
                const SizedBox(width: 12),
                fluent.Button(
                  child: const Text('选择图片'),
                  onPressed: () async {
                    final result = await openFile(
                      acceptedTypeGroups: [
                        const XTypeGroup(
                            label: 'Images',
                            extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp']),
                      ],
                    );
                    if (result != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setChatDisplaySettings(llmAvatar: result.path);
                    }
                  },
                ),
                if (settingsState.llmAvatar != null) ...[
                  const SizedBox(width: 8),
                  fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.delete),
                    onPressed: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setChatDisplaySettings(llmAvatar: '');
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fluent.Text('显示设置',
              style: fluent.FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: fluent.Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
                child: Text('主题和 UI 样式设置 (即将推出)',
                    style: TextStyle(color: Colors.grey))),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fluent.Text('数据设置',
              style: fluent.FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 24),
          fluent.Button(
            onPressed: null,
            child: const Text('导出数据'),
          ),
          const SizedBox(height: 8),
          fluent.Button(
            onPressed: null,
            child: const Text('导入数据'),
          ),
          const SizedBox(height: 8),
          fluent.Button(
            onPressed: null,
            child: const Text('清除所有数据'),
          ),
        ],
      ),
    );
  }

  void _openModelSettings(ProviderConfig provider, String modelName) async {
    await showDialog(
        context: context,
        builder: (context) {
          return fluent.ContentDialog(
            title: fluent.Text('$modelName 配置'),
            content: Container(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const fluent.Text('为该模型配置专属参数',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const fluent.Text('这些参数优先级高于全局设置',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: SingleChildScrollView(
                      child: Consumer(builder: (context, ref, _) {
                        final liveSettings = ref.watch(settingsProvider);
                        final liveProvider = liveSettings.providers.firstWhere(
                            (p) => p.id == provider.id,
                            orElse: () => provider);
                        final liveParams =
                            liveProvider.modelSettings[modelName] ?? {};
                        return _ParamsEditor(
                          params: liveParams,
                          onChanged: (newParams) {
                            final newModelSettings =
                                Map<String, Map<String, dynamic>>.from(
                                    liveProvider.modelSettings);
                            if (newParams.isEmpty) {
                              newModelSettings.remove(modelName);
                            } else {
                              newModelSettings[modelName] = newParams;
                            }
                            ref.read(settingsProvider.notifier).updateProvider(
                                  id: provider.id,
                                  modelSettings: newModelSettings,
                                );
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              fluent.Button(
                onPressed: () => Navigator.pop(context),
                child: const fluent.Text('完成'),
              ),
            ],
          );
        });
  }
}

class _ParamsEditor extends StatefulWidget {
  final Map<String, dynamic> params;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _ParamsEditor({required this.params, required this.onChanged});
  @override
  State<_ParamsEditor> createState() => _ParamsEditorState();
}

class _ParamsEditorState extends State<_ParamsEditor> {
  void _addParam() async {
    final result = await showDialog<MapEntry<String, dynamic>>(
      context: context,
      builder: (context) => _AddParamDialog(),
    );
    if (result != null) {
      final newParams = Map<String, dynamic>.from(widget.params);
      newParams[result.key] = result.value;
      widget.onChanged(newParams);
    }
  }

  void _removeParam(String key) {
    final newParams = Map<String, dynamic>.from(widget.params);
    newParams.remove(key);
    widget.onChanged(newParams);
  }

  void _editParam(String key, dynamic value) async {
    final result = await showDialog<MapEntry<String, dynamic>>(
      context: context,
      builder: (context) =>
          _AddParamDialog(initialKey: key, initialValue: value),
    );
    if (result != null) {
      final newParams = Map<String, dynamic>.from(widget.params);
      newParams.remove(key);
      newParams[result.key] = result.value;
      widget.onChanged(newParams);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return TextField(
        controller: TextEditingController(text: jsonEncode(widget.params)),
        decoration: const InputDecoration(
            labelText: 'JSON Parameters', border: OutlineInputBorder()),
        maxLines: 3,
        onSubmitted: (v) {
          try {
            widget.onChanged(jsonDecode(v));
          } catch (_) {}
        },
      );
    }
    return Column(
      children: [
        if (widget.params.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: fluent.Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            width: double.infinity,
            child: const Center(
                child: Text('无自定义参数', style: TextStyle(color: Colors.grey))),
          )
        else
          ...widget.params.entries.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: fluent.Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(4),
                color: fluent.FluentTheme.of(context).cardColor,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(e.key,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(_formatValue(e.value),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.edit, size: 12),
                    onPressed: () => _editParam(e.key, e.value),
                  ),
                  const SizedBox(width: 4),
                  fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.delete, size: 12),
                    onPressed: () => _removeParam(e.key),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: fluent.Button(
            onPressed: _addParam,
            child: const Text('添加参数'),
          ),
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value is String) return '"$value"';
    return jsonEncode(value);
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
    if (Platform.isWindows) {
      return fluent.ContentDialog(
        title: Text(isEditing ? '编辑参数' : '添加自定义参数'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fluent.InfoLabel(
              label: '参数名 (Key)',
              child: fluent.TextBox(
                controller: _keyController,
                placeholder: 'e.g. image_config',
              ),
            ),
            const SizedBox(height: 12),
            fluent.InfoLabel(
              label: '类型',
              child: fluent.ComboBox<String>(
                value: _type,
                items: ['String', 'JSON']
                    .map((e) => fluent.ComboBoxItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
            ),
            const SizedBox(height: 12),
            fluent.InfoLabel(
              label: '值 (Value)',
              child: fluent.TextBox(
                controller: _valueController,
                placeholder: _type == 'JSON' ? '{"key": "value"}' : 'Value',
                maxLines: _type == 'JSON' ? 3 : 1,
              ),
            ),
          ],
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          fluent.FilledButton(
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
            child: Text(isEditing ? '保存' : '添加'),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title:
            const Text('Currently only supported on Windows UI for structure'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      );
    }
  }
}
