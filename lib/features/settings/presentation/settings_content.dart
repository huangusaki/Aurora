import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'settings_provider.dart';
import 'usage_stats_view.dart';
import 'preset_settings_page.dart';
import '../../../shared/utils/avatar_cropper.dart';

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
    final settingsPageIndex = ref.watch(settingsPageIndexProvider);
    if (Platform.isWindows) {
      final theme = fluent.FluentTheme.of(context);
      final l10n = AppLocalizations.of(context)!;
      final settingsPages = [
        (icon: fluent.FluentIcons.cloud_download, label: l10n.modelProvider),
        (icon: fluent.FluentIcons.chat, label: l10n.chatSettings),
        (icon: fluent.FluentIcons.edit, label: l10n.promptPresets),
        (icon: fluent.FluentIcons.color, label: l10n.displaySettings),
        (icon: fluent.FluentIcons.database, label: l10n.dataSettings),
        (icon: fluent.FluentIcons.analytics_view, label: l10n.usageStats),
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
                    final isSelected = settingsPageIndex == index;
                    return fluent.HoverButton(
                      onPressed: () => ref
                          .read(settingsPageIndexProvider.notifier)
                          .state = index,
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
                index: settingsPageIndex,
                children: [
                  _buildProviderSettings(settingsState, viewingProvider),
                  _buildChatSettings(settingsState),
                  const PresetSettingsPage(),
                  _buildDisplaySettings(),
                  _buildDataSettings(),
                  const UsageStatsView(),
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
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 140,
          decoration: BoxDecoration(
            border: Border(
                right: BorderSide(
                    color: fluent.FluentTheme.of(context)
                        .resources
                        .dividerStrokeColorDefault)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(l10n.providers,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Expanded(
                child: fluent.ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: settingsState.providers.length,
                  itemBuilder: (context, index) {
                    final provider = settingsState.providers[index];
                    final isSelected =
                        provider.id == settingsState.viewingProviderId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? fluent.FluentTheme.of(context)
                                .accentColor
                                .withOpacity(0.1)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: fluent.ListTile(
                        title: Text(
                          provider.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? fluent.FluentTheme.of(context).accentColor
                                : null,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(settingsProvider.notifier)
                              .viewProvider(provider.id);
                        },
                        trailing: fluent.IconButton(
                          icon: Icon(fluent.FluentIcons.delete,
                              size: 12,
                              color: fluent.FluentTheme.of(context)
                                  .resources
                                  .textFillColorSecondary),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return fluent.ContentDialog(
                                    title: Text(l10n.deleteProvider),
                                    content: Text(l10n.deleteProviderConfirm),
                                    actions: [
                                      fluent.Button(
                                        child: Text(l10n.cancel),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      fluent.FilledButton(
                                        child: Text(l10n.delete),
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
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: fluent.Button(
                    onPressed: () =>
                        ref.read(settingsProvider.notifier).addProvider(),
                    child: fluent.Text(l10n.addProvider),
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
                      label: l10n.providerName,
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
                      label: l10n.enabledStatus,
                      child: Row(
                        children: [
                          fluent.ToggleSwitch(
                            checked: viewingProvider.isEnabled,
                            onChanged: (v) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .toggleProviderEnabled(viewingProvider.id);
                            },
                            content: fluent.Text(viewingProvider.isEnabled
                                ? l10n.enabled
                                : l10n.disabled),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        fluent.Text(l10n.availableModels,
                            overflow: TextOverflow.ellipsis,
                            style: fluent.FluentTheme.of(context)
                                .typography
                                .subtitle),
                        const SizedBox(width: 16),
                        Container(
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
                                : fluent.Text(l10n.refreshList,
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
                              onPressed: () {},
                              builder: (context, states) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: states.isHovering
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
                                          color: theme.typography.body?.color
                                              ?.withOpacity(0.7)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(model,
                                              overflow: TextOverflow.ellipsis)),
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
                        child: fluent.Text(l10n.noModelsData),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatSettings(SettingsState settingsState) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fluent.Text(l10n.chatSettings,
              style: fluent.FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.smartTopicGeneration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fluent.ToggleSwitch(
                  checked: settingsState.enableSmartTopic,
                  onChanged: (v) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleSmartTopicEnabled(v);
                  },
                  content: fluent.Text(settingsState.enableSmartTopic
                      ? l10n.enabled
                      : l10n.disabled),
                ),
                if (settingsState.enableSmartTopic) ...[
                  const SizedBox(height: 12),
                  fluent.DropDownButton(
                    title: Text(() {
                      if (settingsState.topicGenerationModel == null) {
                        return l10n.selectTopicModel;
                      }
                      final parts =
                          settingsState.topicGenerationModel!.split('@');
                      if (parts.length == 2) {
                        final provider = settingsState.providers.firstWhere(
                            (p) => p.id == parts[0],
                            orElse: () => settingsState.providers.first);
                        return '${provider.name} - ${parts[1]}';
                      }
                      return settingsState.topicGenerationModel!;
                    }()),
                    items: () {
                      final items = <fluent.MenuFlyoutItemBase>[];
                      for (final provider in settingsState.providers) {
                        if (provider.isEnabled) {
                          for (final model in provider.models) {
                            final value = '${provider.id}@$model';
                            final isSelected =
                                settingsState.topicGenerationModel == value;
                            items.add(fluent.MenuFlyoutItem(
                              leading: isSelected
                                  ? const Icon(fluent.FluentIcons.check_mark,
                                      size: 12)
                                  : null,
                              text: Text('${provider.name} - $model'),
                              onPressed: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setTopicGenerationModel(value);
                              },
                            ));
                          }
                        }
                      }
                      return items;
                    }(),
                  ),
                  if (settingsState.topicGenerationModel == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        l10n.noModelFallback,
                        style: TextStyle(
                            color: fluent.Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const fluent.Divider(),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.userName,
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
            label: l10n.userAvatar,
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
                  child: Text(l10n.selectImage),
                  onPressed: () async {
                    final result = await openFile(
                      acceptedTypeGroups: [
                        const XTypeGroup(
                            label: 'Images',
                            extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp']),
                      ],
                    );
                    if (result != null) {
                      final croppedPath =
                          await AvatarCropper.cropImage(context, result.path);
                      if (croppedPath != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setChatDisplaySettings(userAvatar: croppedPath);
                      }
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
            label: l10n.aiName,
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
            label: l10n.aiAvatar,
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
                      final croppedPath =
                          await AvatarCropper.cropImage(context, result.path);
                      if (croppedPath != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setChatDisplaySettings(llmAvatar: croppedPath);
                      }
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
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(settingsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fluent.Text(l10n.displaySettings,
              style: fluent.FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.language,
            child: fluent.ComboBox<String>(
              value: settingsState.language,
              items: [
                fluent.ComboBoxItem(
                  value: 'zh',
                  child: Text(l10n.languageChinese),
                ),
                fluent.ComboBoxItem(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setLanguage(value);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: fluent.Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
                child: Text(l10n.themeAndUiComingSoon,
                    style: const TextStyle(color: Colors.grey))),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fluent.Text(l10n.dataSettings,
              style: fluent.FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 24),
          fluent.Button(
            onPressed: null,
            child: Text(l10n.exportData),
          ),
          const SizedBox(height: 8),
          fluent.Button(
            onPressed: null,
            child: Text(l10n.importData),
          ),
          const SizedBox(height: 8),
          fluent.Button(
            onPressed: null,
            child: Text(l10n.clearAllData),
          ),
        ],
      ),
    );
  }

  void _openModelSettings(ProviderConfig provider, String modelName) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
        context: context,
        builder: (context) {
          return fluent.ContentDialog(
            title: fluent.Text('$modelName ${l10n.modelConfig}'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fluent.Text(l10n.thinkingConfig,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Consumer(builder: (context, ref, _) {
                          final liveSettings = ref.watch(settingsProvider);
                          final liveProvider = liveSettings.providers
                              .firstWhere((p) => p.id == provider.id,
                                  orElse: () => provider);
                          final liveParams =
                              liveProvider.modelSettings[modelName] ?? {};
                          final thinkingEnabled =
                              liveParams['_aurora_thinking_enabled'] == true;
                          final thinkingValue =
                              liveParams['_aurora_thinking_value']
                                      ?.toString() ??
                                  '';
                          final thinkingMode =
                              liveParams['_aurora_thinking_mode']?.toString() ??
                                  'auto';
                          void updateThinkingConfig({
                            bool? enabled,
                            String? value,
                            String? mode,
                          }) {
                            final newParams =
                                Map<String, dynamic>.from(liveParams);
                            if (enabled != null) {
                              newParams['_aurora_thinking_enabled'] = enabled;
                            }
                            if (value != null) {
                              newParams['_aurora_thinking_value'] = value;
                            }
                            if (mode != null) {
                              newParams['_aurora_thinking_mode'] = mode;
                            }
                            final newModelSettings =
                                Map<String, Map<String, dynamic>>.from(
                                    liveProvider.modelSettings);
                            newModelSettings[modelName] = newParams;
                            ref.read(settingsProvider.notifier).updateProvider(
                                  id: provider.id,
                                  modelSettings: newModelSettings,
                                );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  fluent.ToggleSwitch(
                                    checked: thinkingEnabled,
                                    onChanged: (v) =>
                                        updateThinkingConfig(enabled: v),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.enableThinking),
                                ],
                              ),
                              if (thinkingEnabled) ...[
                                const SizedBox(height: 12),
                                fluent.InfoLabel(
                                  label: l10n.thinkingBudget,
                                  child: _ThinkingBudgetInput(
                                    initialValue: thinkingValue,
                                    placeholder: l10n.thinkingBudgetHint,
                                    onChanged: (v) =>
                                        updateThinkingConfig(value: v),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                fluent.InfoLabel(
                                  label: l10n.transmissionMode,
                                  child: fluent.ComboBox<String>(
                                    value: thinkingMode,
                                    items: [
                                      fluent.ComboBoxItem(
                                          value: 'auto',
                                          child: Text(l10n.modeAuto)),
                                      fluent.ComboBoxItem(
                                          value: 'extra_body',
                                          child: Text(l10n.modeExtraBody)),
                                      fluent.ComboBoxItem(
                                          value: 'reasoning_effort',
                                          child:
                                              Text(l10n.modeReasoningEffort)),
                                    ],
                                    onChanged: (v) =>
                                        updateThinkingConfig(mode: v),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        fluent.Text(l10n.configureModelParams,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        fluent.Text(l10n.paramsHigherPriority,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: SingleChildScrollView(
                            child: Consumer(builder: (context, ref, _) {
                              final liveSettings = ref.watch(settingsProvider);
                              final liveProvider = liveSettings.providers
                                  .firstWhere((p) => p.id == provider.id,
                                      orElse: () => provider);
                              final liveParams =
                                  liveProvider.modelSettings[modelName] ?? {};
                              final displayParams =
                                  Map<String, dynamic>.fromEntries(
                                      liveParams.entries.where((e) =>
                                          !e.key.startsWith('_aurora_')));
                              return _ParamsEditor(
                                params: displayParams,
                                onChanged: (newParams) {
                                  final preservedKeys =
                                      Map<String, dynamic>.from(liveParams)
                                        ..removeWhere((k, v) =>
                                            !k.startsWith('_aurora_'));
                                  final merged = {
                                    ...preservedKeys,
                                    ...newParams
                                  };
                                  final newModelSettings =
                                      Map<String, Map<String, dynamic>>.from(
                                          liveProvider.modelSettings);
                                  if (merged.isEmpty) {
                                    newModelSettings.remove(modelName);
                                  } else {
                                    newModelSettings[modelName] = merged;
                                  }
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateProvider(
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
                ),
              ),
            ),
            actions: [
              fluent.Button(
                onPressed: () => Navigator.pop(context),
                child: fluent.Text(l10n.done),
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
        decoration: InputDecoration(
            labelText: 'JSON Parameters', border: const OutlineInputBorder()),
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
            child: Center(
                child: Text(AppLocalizations.of(context)!.noCustomParams,
                    style: const TextStyle(color: Colors.grey))),
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
            child: Text(AppLocalizations.of(context)!.addCustomParam),
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
    final l10n = AppLocalizations.of(context)!;
    if (Platform.isWindows) {
      return fluent.ContentDialog(
        title: Text(isEditing ? l10n.editParam : l10n.addCustomParam),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fluent.InfoLabel(
              label: l10n.paramKey,
              child: fluent.TextBox(
                controller: _keyController,
                placeholder: 'e.g. image_config',
              ),
            ),
            const SizedBox(height: 12),
            fluent.InfoLabel(
              label: l10n.paramType,
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
              label: l10n.paramValue,
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
            child: Text(l10n.cancel),
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
            child: Text(isEditing ? l10n.save : l10n.add),
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

class _ThinkingBudgetInput extends StatefulWidget {
  final String initialValue;
  final String placeholder;
  final ValueChanged<String> onChanged;
  const _ThinkingBudgetInput({
    required this.initialValue,
    required this.placeholder,
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
    return fluent.TextBox(
      controller: _controller,
      focusNode: _focusNode,
      placeholder: widget.placeholder,
      onSubmitted: (_) => _saveValue(),
      onEditingComplete: _saveValue,
    );
  }
}
