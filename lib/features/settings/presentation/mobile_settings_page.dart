import 'dart:io';
import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../../sync/presentation/mobile_sync_settings_page.dart';

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
                  title: Text(l10n.apiKeys),
                  subtitle: Text(activeProvider?.apiKeys.isNotEmpty == true
                      ? '${activeProvider!.apiKeys.length} ${activeProvider.apiKeys.length > 1 ? "keys" : "key"}'
                      : l10n.notConfigured),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (activeProvider != null && activeProvider.apiKeys.length > 1)
                        Switch(
                          value: activeProvider.autoRotateKeys,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setAutoRotateKeys(activeProvider.id, v),
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showApiKeysManager(context, activeProvider),
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
                ListTile(
                  leading: const Icon(Icons.settings_applications),
                  title: Text(l10n.globalConfig), // Use localized Global Config string
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                     if (activeProvider != null) {
                        _showGlobalConfigDialog(context, activeProvider);
                     }
                  },
                ),
                _SectionHeader(
                  title: l10n.availableModels,
                  icon: Icons.format_list_bulleted,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (activeProvider != null && activeProvider.models.isNotEmpty) ...[
                        TextButton(
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .setAllModelsEnabled(activeProvider.id, true),
                          child: Text(l10n.enableAll, 
                            style: const TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .setAllModelsEnabled(activeProvider.id, false),
                          child: Text(l10n.disableAll, 
                            style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                      SizedBox(
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
                    ],
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            activeProvider.isModelEnabled(model)
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: activeProvider.isModelEnabled(model)
                                ? Colors.green
                                : Colors.red,
                          ),
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .toggleModelDisabled(activeProvider.id, model),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () => _showModelConfigDialog(
                              context, activeProvider, model),
                        ),
                      ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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

  void _showGlobalConfigDialog(
      BuildContext context, ProviderConfig provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _GlobalConfigBottomSheet(
        provider: provider,
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

  void _showApiKeysManager(BuildContext context, ProviderConfig? provider) {
    if (provider == null) return;
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF202020)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Re-fetch provider to get latest state
          final currentProvider = ref.read(settingsProvider).providers
              .firstWhere((p) => p.id == provider.id, orElse: () => provider);
          
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        l10n.apiKeys,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      // Add key button
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _showAddKeyDialog(context, provider.id, () {
                          setModalState(() {});
                        }),
                      ),
                    ],
                  ),
                ),
                // Auto-rotate toggle
                if (currentProvider.apiKeys.length > 1)
                  SwitchListTile(
                    title: Text(l10n.autoRotateKeys),
                    value: currentProvider.autoRotateKeys,
                    onChanged: (v) {
                      ref.read(settingsProvider.notifier)
                          .setAutoRotateKeys(provider.id, v);
                      setModalState(() {});
                    },
                  ),
                const Divider(),
                // Key list
                Expanded(
                  child: currentProvider.apiKeys.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.key_off, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(l10n.notConfigured, style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showAddKeyDialog(context, provider.id, () {
                                  setModalState(() {});
                                }),
                                icon: const Icon(Icons.add),
                                label: Text(l10n.addApiKey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: currentProvider.apiKeys.length,
                          itemBuilder: (context, index) {
                            final key = currentProvider.apiKeys[index];
                            final isCurrent = index == currentProvider.safeCurrentKeyIndex;
                            
                            return _ApiKeyListItem(
                              apiKey: key,
                              isCurrent: isCurrent,
                              onSelect: () {
                                ref.read(settingsProvider.notifier)
                                    .setCurrentKeyIndex(provider.id, index);
                                setModalState(() {});
                              },
                              onEdit: (newValue) {
                                ref.read(settingsProvider.notifier)
                                    .updateApiKeyAtIndex(provider.id, index, newValue);
                                setModalState(() {});
                              },
                              onDelete: () {
                                ref.read(settingsProvider.notifier)
                                    .removeApiKey(provider.id, index);
                                setModalState(() {});
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddKeyDialog(BuildContext context, String providerId, VoidCallback onAdded) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF202020)
            : Colors.white,
        title: Text(l10n.addApiKey),
        content: TextField(
          controller: controller,
          autofocus: true,
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
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                ref.read(settingsProvider.notifier).addApiKey(providerId, newKey);
                onAdded();
              }
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.editBaseUrl, style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _baseUrlController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'https://api.openai.com/v1',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorEditor(BuildContext context, ProviderConfig? provider) {
    if (provider == null) return;
    final l10n = AppLocalizations.of(context)!;
    _colorController.text = provider.color ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Edit Color', style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _colorController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '#FF0000',
                    labelText: 'Hex Color',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
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
              ),
            ],
          ),
        ),
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
        _thinkingBudget = _modelSettings['_aurora_thinking_value']?.toString() ?? '';
        _thinkingMode = _modelSettings['_aurora_thinking_mode']?.toString() ?? 'auto';
        
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
    if (_temperature.isNotEmpty || _maxTokens.isNotEmpty || _contextLength.isNotEmpty) {
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
     await showDialog(
      context: context,
      builder: (ctx) => _ParameterConfigDialog(
        initialKey: key,
        initialValue: value,
        onSave: (newKey, newValue) {
          final currentParams = Map<String, dynamic>.fromEntries(
            _modelSettings.entries.where((e) => !e.key.startsWith('_aurora_'))
          );
          
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
      _modelSettings.entries.where((e) => !e.key.startsWith('_aurora_'))
    );
    currentParams.remove(key);
    _saveSettings(customParams: currentParams);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Extract custom params for display (exclude _aurora_ keys)
    final customParams = Map<String, dynamic>.fromEntries(
      _modelSettings.entries.where((e) => !e.key.startsWith('_aurora_'))
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.modelName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(l10n.modelConfig,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thinking Configuration Card
                  _buildSectionCard(
                    context,
                    title: l10n.thinkingConfig,
                    icon: Icons.lightbulb_outline,
                    headerAction: Switch(
                      value: _thinkingEnabled,
                      onChanged: (v) => _saveSettings(thinkingEnabled: v),
                    ),
                    child: _thinkingEnabled ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        TextField(
                          controller: TextEditingController(text: _thinkingBudget)
                            ..selection = TextSelection.collapsed(offset: _thinkingBudget.length),
                          decoration: InputDecoration(
                            labelText: l10n.thinkingBudget,
                            hintText: l10n.thinkingBudgetHint,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => _saveSettings(thinkingBudget: v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _thinkingMode,
                          decoration: InputDecoration(
                            labelText: l10n.transmissionMode,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(value: 'auto', child: Text(l10n.modeAuto)),
                            DropdownMenuItem(value: 'extra_body', child: Text(l10n.modeExtraBody)),
                            DropdownMenuItem(value: 'reasoning_effort', child: Text(l10n.modeReasoningEffort)),
                          ],
                          onChanged: (v) {
                            if (v != null) _saveSettings(thinkingMode: v);
                          },
                        ),
                      ],
                    ) : null,
                  ),

                  const SizedBox(height: 16),

                  // Generation Configuration Card
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
                            ..selection = TextSelection.collapsed(offset: _temperature.length),
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
                            ..selection = TextSelection.collapsed(offset: _maxTokens.length),
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
                            ..selection = TextSelection.collapsed(offset: _contextLength.length),
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
                    headerAction: null,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        if (customParams.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.tune, size: 32, color: Colors.grey),
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
          // Done button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.done),
              ),
            ),
          ),
        ],
      ),
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
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(
                        fontSize: 11, 
                        color: theme.textTheme.bodySmall?.color
                      )),
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
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key, 
              style: TextStyle(
                fontFamily: 'monospace', 
                fontSize: 12, 
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSecondaryContainer
              )
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatValue(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontFamily: 'monospace', fontSize: 13),
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
              child: Icon(Icons.delete_outline, size: 16, color: Colors.red.withOpacity(0.8)),
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

class _ApiKeyListItem extends StatefulWidget {
  final String apiKey;
  final bool isCurrent;
  final VoidCallback onSelect;
  final ValueChanged<String> onEdit;
  final VoidCallback onDelete;

  const _ApiKeyListItem({
    super.key,
    required this.apiKey,
    required this.isCurrent,
    required this.onSelect,
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
      leading: Radio<bool>(
        value: true,
        groupValue: widget.isCurrent,
        onChanged: (v) {
          if (v == true) widget.onSelect();
        },
      ),
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
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
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
    showDialog(
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Reuse helper methods from MobileSettingsPage if possible?
    // They are private to MobileSettingsPage. I need to duplicate _buildSectionCard and _buildParamItem.
    // Or make them static/public. Duplication is safer for now to avoid refactoring MobileSettingsPage massively.

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.globalConfig,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(widget.provider.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable content
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
                                  .map((m) =>
                                      Chip(label: Text(m, style: const TextStyle(fontSize: 10))))
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
                                controller: TextEditingController(
                                    text: _thinkingBudget)
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
                                value: _thinkingMode,
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
                    headerAction: null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller:
                              TextEditingController(text: _temperature)
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
                    headerAction: null,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        if (_customParams.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.3)),
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
          // Done button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.done),
              ),
            ),
          ),
        ],
      ),
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
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: theme.primaryColor.withOpacity(0.1),
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
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
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
                  size: 16, color: Colors.redAccent),
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
  const _ExclusionPicker({required this.allModels, required this.excludedModels});

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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.excludedModels,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
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
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _currentExclusions);
                },
                child: Text(l10n.save),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
