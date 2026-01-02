import 'dart:io';
import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'settings_provider.dart';

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
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final activeProvider = settingsState.activeProvider;
    final fluentTheme = fluent.FluentTheme.of(context);
    return Scaffold(
      backgroundColor: fluentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: fluentTheme.scaffoldBackgroundColor,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: '模型提供', icon: Icons.cloud_outlined),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('当前供应商'),
            subtitle: Text(activeProvider?.name ?? '未配置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showProviderPicker(context, settingsState),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('API Key'),
            subtitle: Text(
                activeProvider?.apiKey.isNotEmpty == true ? '••••••••' : '未配置'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showApiKeyEditor(context, activeProvider),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('API Base URL'),
            subtitle:
                Text(activeProvider?.baseUrl ?? 'https://api.openai.com/v1'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showBaseUrlEditor(context, activeProvider),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '可用模型',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                OutlinedButton(
                  onPressed: settingsState.isLoadingModels
                      ? null
                      : () {
                          ref.read(settingsProvider.notifier).fetchModels();
                        },
                  child: settingsState.isLoadingModels
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('获取模型列表'),
                ),
              ],
            ),
          ),
          if (activeProvider != null && activeProvider.models.isNotEmpty)
            ...activeProvider.models.map((model) {
              final isSelected = model == settingsState.selectedModel;
              return ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(model),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(Icons.check, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => _showModelConfigDialog(
                          context, activeProvider, model),
                    ),
                  ],
                ),
                tileColor: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).updateProvider(
                        id: activeProvider.id,
                        selectedModel: model,
                      );
                  ref
                      .read(settingsProvider.notifier)
                      .selectProvider(activeProvider.id);
                },
              );
            }).toList()
          else if (activeProvider != null)
            const Padding(
              padding: EdgeInsets.all(16),
              child:
                  Text('暂无模型，请点击右上角获取', style: TextStyle(color: Colors.grey)),
            ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showProviderPicker(BuildContext context, SettingsState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('选择供应商',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ...state.providers.map((p) => ListTile(
                    leading: Icon(
                      p.id == state.activeProviderId
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: p.id == state.activeProviderId
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    title: Text(p.name),
                    subtitle: Text(p.selectedModel ?? '未选择模型'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showProviderRenameDialog(context, p);
                      },
                    ),
                    onTap: () {
                      ref.read(settingsProvider.notifier).selectProvider(p.id);
                      Navigator.pop(ctx);
                    },
                  )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('添加供应商'),
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
    final controller = TextEditingController(text: provider.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('重命名供应商'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入供应商名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
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
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyEditor(BuildContext context, ProviderConfig? provider) {
    if (provider == null) return;
    _apiKeyController.text = provider.apiKey;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('编辑 API Key'),
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
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).updateProvider(
                    id: provider.id,
                    apiKey: _apiKeyController.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showBaseUrlEditor(BuildContext context, ProviderConfig? provider) {
    if (provider == null) return;
    _baseUrlController.text = provider.baseUrl;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('编辑 API Base URL'),
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
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).updateProvider(
                    id: provider.id,
                    baseUrl: _baseUrlController.text,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
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
  const _SectionHeader({required this.title, required this.icon});
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF202020) : Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.modelName,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('配置', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_settings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child:
                        Text('暂无自定义参数', style: TextStyle(color: Colors.grey))),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _settings.length,
                  itemBuilder: (context, index) {
                    final key = _settings.keys.elementAt(index);
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
              title: const Text('添加自定义参数'),
              onTap: () => _showEditDialog(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('完成'),
        ),
      ],
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
  String _type = '文本';
  final List<String> _types = ['文本', '数字', '布尔值', 'JSON'];
  bool _isInit = true;
  @override
  void initState() {
    super.initState();
    if (widget.initialKey != null) {
      _keyController.text = widget.initialKey!;
      final val = widget.initialValue;
      if (val is bool) {
        _type = '布尔值';
        _valueController.text = val.toString();
      } else if (val is num) {
        _type = '数字';
        _valueController.text = val.toString();
      } else if (val is Map || val is List) {
        _type = 'JSON';
        try {
          _valueController.text =
              const JsonEncoder.withIndent('  ').convert(val);
        } catch (_) {
          _valueController.text = jsonEncode(val);
        }
      } else {
        _type = '文本';
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
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF202020) : Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text(isEditing ? '编辑参数' : '添加自定义参数'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              labelText: '参数名 (Key)',
              hintText: 'e.g. image_config',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            decoration: const InputDecoration(
              labelText: '类型',
              border: OutlineInputBorder(),
            ),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            maxLines: _type == 'JSON' ? 5 : 1,
            minLines: _type == 'JSON' ? 3 : 1,
            decoration: const InputDecoration(
              labelText: '值 (Value)',
              hintText: 'Value',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final key = _keyController.text.trim();
            final valueStr = _valueController.text.trim();
            if (key.isEmpty) return;
            dynamic value;
            try {
              switch (_type) {
                case '数字':
                  value = num.parse(valueStr);
                  break;
                case '布尔值':
                  value = valueStr.toLowerCase() == 'true';
                  break;
                case 'JSON':
                  value = jsonDecode(valueStr);
                  break;
                default:
                  value = valueStr;
              }
              widget.onSave(key, value);
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('格式错误: $e')),
              );
            }
          },
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }
}
