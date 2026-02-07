import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora_search/aurora_search.dart';
import 'package:aurora/shared/theme/wallpaper_tint.dart';
import 'package:aurora/shared/theme/wallpaper_tint_provider.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'settings_provider.dart';
import 'usage_stats_view.dart';
import 'preset_settings_page.dart';
import 'knowledge_settings_panel.dart';

import '../../../shared/utils/avatar_cropper.dart';
import 'model_config_dialog.dart';
import 'global_config_dialog.dart';
import '../../sync/presentation/sync_settings_section.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';

class SettingsContent extends ConsumerStatefulWidget {
  const SettingsContent({super.key});
  @override
  ConsumerState<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<SettingsContent> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _llmNameController = TextEditingController();

  // Inline renaming state
  String? _editingProviderId;
  String? _currentProviderId;
  final TextEditingController _renameListController = TextEditingController();

  // Local state for API key visibility
  final Set<int> _visibleKeyIndices = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _nameController.dispose();
    _colorController.dispose();
    _userNameController.dispose();
    _llmNameController.dispose();
    _renameListController.dispose();
    super.dispose();
  }

  void _updateControllers(ProviderConfig provider) {
    if (_currentProviderId != provider.id) {
      _visibleKeyIndices.clear();
      _currentProviderId = provider.id;
    }

    if (_apiKeyController.text != provider.apiKey) {
      _apiKeyController.text = provider.apiKey;
    }
    if (_baseUrlController.text != provider.baseUrl) {
      _baseUrlController.text = provider.baseUrl;
    }
    if (_nameController.text != provider.name) {
      _nameController.text = provider.name;
    }
    if (_colorController.text != (provider.color ?? '')) {
      _colorController.text = provider.color ?? '';
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
    if (PlatformUtils.isDesktop) {
      final theme = fluent.FluentTheme.of(context);
      final l10n = AppLocalizations.of(context)!;
      final settingsPages = [
        (icon: AuroraIcons.model, label: l10n.modelProvider),
        (icon: AuroraIcons.translation, label: l10n.chatSettings),
        (icon: AuroraIcons.globe, label: l10n.searchSettings),
        (icon: AuroraIcons.database, label: l10n.knowledgeBase),
        (icon: AuroraIcons.edit, label: l10n.promptPresets),
        (icon: AuroraIcons.image, label: l10n.displaySettings),
        (icon: AuroraIcons.backup, label: l10n.dataSettings),
        (icon: AuroraIcons.stats, label: l10n.usageStats),
      ];
      return Container(
        color: Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 180,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
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
                                  ? theme.accentColor.withValues(alpha: 0.1)
                                  : states.isHovered
                                      ? theme.resources.subtleFillColorSecondary
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                fluent.Icon(page.icon,
                                    size: 16,
                                    color:
                                        isSelected ? theme.accentColor : null),
                                const SizedBox(width: 12),
                                Text(
                                  page.label,
                                  style: TextStyle(
                                    color:
                                        isSelected ? theme.accentColor : null,
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
                margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: settingsState.useCustomTheme &&
                          settingsState.backgroundImagePath != null &&
                          settingsState.backgroundImagePath!.isNotEmpty
                      ? theme.cardColor.withValues(alpha: 0.7)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: IndexedStack(
                    index: settingsPageIndex,
                    children: [
                      _buildProviderSettings(settingsState, viewingProvider),
                      _buildChatSettings(settingsState),
                      _buildSearchSettings(settingsState),
                      const KnowledgeSettingsPanel(),
                      const PresetSettingsPage(),
                      _buildDisplaySettings(),
                      _buildDataSettings(),
                      const UsageStatsView(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
                const Icon(AuroraIcons.settings, size: 48, color: Colors.grey),
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

  Widget _buildStyledTextBox({
    required TextEditingController controller,
    String? placeholder,
    ValueChanged<String>? onChanged,
    bool autofocus = false,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    double radius = 8,
    ValueChanged<String>? onSubmitted,
    void Function(PointerDownEvent)? onTapOutside,
  }) {
    final theme = fluent.FluentTheme.of(context);
    final settings = ref.watch(settingsProvider.select((s) => (
          enabled: s.useCustomTheme || s.themeMode == 'custom',
          path: s.backgroundImagePath,
        )));
    final hasBackground =
        settings.enabled && settings.path != null && settings.path!.isNotEmpty;
    final wallpaperTint = ref.watch(wallpaperTintColorProvider);
    final baseFill = theme.brightness.isDark
        ? const Color(0xFF3C3C3C)
        : const Color(0xFFF3F3F3);
    return fluent.TextBox(
      controller: controller,
      placeholder: placeholder,
      onChanged: onChanged,
      autofocus: autofocus,
      onSubmitted: onSubmitted,
      onTapOutside: onTapOutside,
      padding: padding,
      decoration: WidgetStateProperty.all(BoxDecoration(
        color: hasBackground
            ? tintedGlassFromBase(
                wallpaperTint: wallpaperTint,
                base: baseFill,
                fallback: baseFill,
                alpha: 0.72,
                mix: 0.22,
              )
            : baseFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: theme.resources.controlStrokeColorDefault,
        ),
      )),
      highlightColor: Colors.transparent,
      unfocusedColor: Colors.transparent,
      cursorColor: theme.accentColor,
    );
  }

  void _showKeyDialog(BuildContext context, String providerId,
      {int? index, String? initialValue}) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Text(index == null ? l10n.addApiKey : l10n.editApiKey),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStyledTextBox(
              controller: controller,
              placeholder: l10n.apiKeyPlaceholder,
              autofocus: true,
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
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                final notifier = ref.read(settingsProvider.notifier);
                if (index != null) {
                  notifier.updateApiKeyAtIndex(providerId, index, val);
                } else {
                  notifier.addApiKey(providerId, val);
                }
              }
              Navigator.pop(context);
            },
            child: Text(index == null ? l10n.add : l10n.save),
          ),
        ],
      ),
    );
    // controller.dispose is tricky in functional dialogs, letting GC handle or ignoring for now
  }

  Widget _buildProviderSettings(
      SettingsState settingsState, ProviderConfig viewingProvider) {
    final l10n = AppLocalizations.of(context)!;
    final theme = fluent.FluentTheme.of(context);
    final hasBackground =
        (settingsState.useCustomTheme || settingsState.themeMode == 'custom') &&
            settingsState.backgroundImagePath != null &&
            settingsState.backgroundImagePath!.isNotEmpty;
    final wallpaperTint = ref.watch(wallpaperTintColorProvider);
    final apiKeyCardBaseBg = theme.brightness.isDark
        ? const Color(0xFF323232)
        : const Color(0xFFF9F9F9);
    final apiKeyCardBg = hasBackground
        ? tintedGlassFromBase(
            wallpaperTint: wallpaperTint,
            base: apiKeyCardBaseBg,
            fallback: apiKeyCardBaseBg,
            alpha: 0.68,
            mix: 0.22,
          )
        : apiKeyCardBaseBg;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 160,
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
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(settingsProvider.notifier)
                        .reorderProviders(oldIndex, newIndex);
                  },
                  itemCount: settingsState.providers.length,
                  itemBuilder: (context, index) {
                    final provider = settingsState.providers[index];
                    final isSelected =
                        provider.id == settingsState.viewingProviderId;
                    final isEditing = provider.id == _editingProviderId;

                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(provider.id),
                      index: index,
                      child: fluent.FluentTheme(
                        data: fluent.FluentTheme.of(context),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? fluent.FluentTheme.of(context)
                                    .accentColor
                                    .withValues(alpha: 0.1)
                                : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: fluent.ListTile(
                            title: isEditing
                                ? _buildStyledTextBox(
                                    controller: _renameListController,
                                    autofocus: true,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    radius: 6,
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        ref
                                            .read(settingsProvider.notifier)
                                            .updateProvider(
                                                id: provider.id,
                                                name: value.trim());
                                      }
                                      setState(() {
                                        _editingProviderId = null;
                                      });
                                    },
                                    onTapOutside: (_) {
                                      if (_renameListController.text
                                          .trim()
                                          .isNotEmpty) {
                                        ref
                                            .read(settingsProvider.notifier)
                                            .updateProvider(
                                                id: provider.id,
                                                name: _renameListController.text
                                                    .trim());
                                      }
                                      setState(() {
                                        _editingProviderId = null;
                                      });
                                    },
                                  )
                                : Text(
                                    provider.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: fluent.FluentTheme.of(context)
                                        .typography
                                        .body
                                        ?.copyWith(
                                          color: isSelected
                                              ? fluent.FluentTheme.of(context)
                                                  .accentColor
                                              : null,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : null,
                                        ),
                                  ),
                            onPressed: isEditing
                                ? null
                                : () {
                                    ref
                                        .read(settingsProvider.notifier)
                                        .viewProvider(provider.id);
                                  },
                            trailing: isEditing
                                ? null // Hide actions while editing, TextBox takes focus
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      fluent.IconButton(
                                        icon: Icon(AuroraIcons.edit,
                                            size: 12,
                                            color:
                                                fluent.FluentTheme.of(context)
                                                    .resources
                                                    .textFillColorSecondary),
                                        onPressed: () {
                                          setState(() {
                                            _editingProviderId = provider.id;
                                            _renameListController.text =
                                                provider.name;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      fluent.IconButton(
                                        icon: Icon(AuroraIcons.delete,
                                            size: 12,
                                            color:
                                                fluent.FluentTheme.of(context)
                                                    .resources
                                                    .textFillColorSecondary),
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return fluent.ContentDialog(
                                                  title:
                                                      Text(l10n.deleteProvider),
                                                  content: Text(l10n
                                                      .deleteProviderConfirm),
                                                  actions: [
                                                    fluent.Button(
                                                      child: Text(l10n.cancel),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                    ),
                                                    fluent.FilledButton(
                                                      child: Text(l10n.delete),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        ref
                                                            .read(
                                                                settingsProvider
                                                                    .notifier)
                                                            .deleteProvider(
                                                                provider.id);
                                                      },
                                                    ),
                                                  ],
                                                );
                                              });
                                        },
                                      ),
                                    ],
                                  ),
                          ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header with Enable Toggle ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        fluent.Text(l10n.modelConfig,
                            style: fluent.FluentTheme.of(context)
                                .typography
                                .subtitle),
                        const SizedBox(width: 12),
                        fluent.IconButton(
                          icon: Icon(AuroraIcons.settings,
                              size: 20,
                              color:
                                  fluent.FluentTheme.of(context).accentColor),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  GlobalConfigDialog(provider: viewingProvider),
                            );
                          },
                        ),
                      ],
                    ),
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
                const SizedBox(height: 16),

                // --- API Keys Section ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            fluent.Text(l10n.apiKeys,
                                style: fluent.FluentTheme.of(context)
                                    .typography
                                    .bodyStrong),
                            const SizedBox(width: 16),
                            // Auto-rotate toggle moved here
                            fluent.ToggleSwitch(
                              checked: viewingProvider.autoRotateKeys,
                              onChanged: (v) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setAutoRotateKeys(viewingProvider.id, v);
                              },
                              content: fluent.Text(l10n.autoRotateKeys,
                                  style: fluent.FluentTheme.of(context)
                                      .typography
                                      .caption),
                            ),
                          ],
                        ),
                        fluent.IconButton(
                          icon: const fluent.Icon(AuroraIcons.add, size: 14),
                          onPressed: () {
                            _showKeyDialog(context, viewingProvider.id);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (viewingProvider.apiKeys.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: fluent.Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            fluent.Icon(AuroraIcons.info,
                                size: 14, color: fluent.Colors.grey),
                            const SizedBox(width: 8),
                            fluent.Text(l10n.noModelsData,
                                style: TextStyle(color: fluent.Colors.grey)),
                          ],
                        ),
                      )
                    else
                      ...viewingProvider.apiKeys.asMap().entries.map((entry) {
                        final index = entry.key;
                        final key = entry.value;
                        final isCurrent =
                            index == viewingProvider.safeCurrentKeyIndex;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: apiKeyCardBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isCurrent
                                    ? fluent.FluentTheme.of(context).accentColor
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                fluent.RadioButton(
                                  checked: isCurrent,
                                  onChanged: (checked) {
                                    if (checked == true) {
                                      ref
                                          .read(settingsProvider.notifier)
                                          .setCurrentKeyIndex(
                                              viewingProvider.id, index);
                                    }
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ApiKeyItem(
                                    key: ValueKey(
                                        '${viewingProvider.id}_$index'),
                                    apiKey: key,
                                    onUpdate: (value) {
                                      ref
                                          .read(settingsProvider.notifier)
                                          .updateApiKeyAtIndex(
                                              viewingProvider.id, index, value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                fluent.IconButton(
                                  icon: fluent.Icon(AuroraIcons.delete,
                                      size: 14,
                                      color: fluent.Colors.red
                                          .withValues(alpha: 0.7)),
                                  onPressed: () {
                                    ref
                                        .read(settingsProvider.notifier)
                                        .removeApiKey(
                                            viewingProvider.id, index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Base URL ---
                fluent.InfoLabel(
                  label: 'API Base URL',
                  child: _buildStyledTextBox(
                    controller: _baseUrlController,
                    placeholder: l10n.baseUrlPlaceholder,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).updateProvider(
                          id: viewingProvider.id, baseUrl: value);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // --- Available Models Section ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    fluent.Text(l10n.availableModels,
                        overflow: TextOverflow.ellipsis,
                        style:
                            fluent.FluentTheme.of(context).typography.subtitle),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (viewingProvider.models.isNotEmpty) ...[
                          fluent.Button(
                            onPressed: () => ref
                                .read(settingsProvider.notifier)
                                .setAllModelsEnabled(viewingProvider.id, true),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(AuroraIcons.selectAll, size: 14),
                                const SizedBox(width: 4),
                                fluent.Text(l10n.enableAll),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          fluent.Button(
                            onPressed: () => ref
                                .read(settingsProvider.notifier)
                                .setAllModelsEnabled(viewingProvider.id, false),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(AuroraIcons.deselectAll, size: 14),
                                const SizedBox(width: 4),
                                fluent.Text(l10n.disableAll),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        fluent.Button(
                          style: fluent.ButtonStyle(
                            padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6)),
                            backgroundColor: WidgetStateProperty.all(
                                fluent.FluentTheme.of(context)
                                    .accentColor
                                    .withValues(alpha: 0.1)),
                            shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide.none)),
                          ),
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
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(AuroraIcons.refresh,
                                        size: 14,
                                        color: fluent.FluentTheme.of(context)
                                            .accentColor),
                                    const SizedBox(width: 8),
                                    fluent.Text(
                                      l10n.refreshList,
                                      style: TextStyle(
                                        color: fluent.FluentTheme.of(context)
                                            .accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
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

                // --- Models List (no Expanded, just Column) ---
                if (viewingProvider.models.isNotEmpty)
                  ...viewingProvider.models.map((model) {
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
                              color: states.isHovered
                                  ? theme.typography.body?.color
                                          ?.withValues(alpha: 0.05) ??
                                      Colors.transparent
                                  : Colors.transparent,
                            ),
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(AuroraIcons.org,
                                    size: 16,
                                    color: theme.typography.body?.color
                                        ?.withValues(alpha: 0.7)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(model,
                                        overflow: TextOverflow.ellipsis)),
                                fluent.IconButton(
                                  icon: Icon(
                                      viewingProvider.isModelEnabled(model)
                                          ? AuroraIcons.success
                                          : AuroraIcons.blocked,
                                      size: 14,
                                      color:
                                          viewingProvider.isModelEnabled(model)
                                              ? fluent.Colors.green
                                              : fluent.Colors.red),
                                  onPressed: () => ref
                                      .read(settingsProvider.notifier)
                                      .toggleModelDisabled(
                                          viewingProvider.id, model),
                                ),
                                const SizedBox(width: 8),
                                fluent.IconButton(
                                  icon: const fluent.Icon(AuroraIcons.settings,
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
                  })
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: fluent.Colors.grey.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: fluent.Text(l10n.noModelsData),
                  ),

                const SizedBox(height: 16),

                // --- Color Selector ---
                fluent.InfoLabel(
                  label: l10n.providerColor,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (viewingProvider.color != null &&
                                  viewingProvider.color!.isNotEmpty)
                              ? Color(int.tryParse(viewingProvider.color!
                                      .replaceFirst('#', '0xFF')) ??
                                  0xFF000000)
                              : Colors.transparent,
                          border: Border.all(color: fluent.Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStyledTextBox(
                          controller: _colorController,
                          placeholder: '#FF0000',
                          onChanged: (value) {
                            ref.read(settingsProvider.notifier).updateProvider(
                                id: viewingProvider.id, color: value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                  Builder(builder: (context) {
                    final items = <fluent.MenuFlyoutItemBase>[];
                    for (final provider in settingsState.providers) {
                      if (provider.isEnabled) {
                        for (final model in provider.models) {
                          final value = '${provider.id}@$model';
                          final isSelected =
                              settingsState.topicGenerationModel == value;
                          items.add(fluent.MenuFlyoutItem(
                            leading: isSelected
                                ? const Icon(AuroraIcons.check, size: 12)
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

                    if (items.isEmpty) {
                      return fluent.Button(
                        onPressed: null,
                        child: Text(l10n.noModelsData),
                      );
                    }

                    return fluent.DropDownButton(
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
                      items: items,
                    );
                  }),
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
            child: _buildStyledTextBox(
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
                    border: Border.all(
                        color: fluent.Colors.grey.withValues(alpha: 0.3)),
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
                      if (!mounted) return;
                      final croppedPath =
                          await AvatarCropper.cropImage(context, result.path);
                      if (croppedPath != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final avatarDir = Directory(
                            '${appDir.path}${Platform.pathSeparator}avatars');
                        if (!await avatarDir.exists()) {
                          await avatarDir.create(recursive: true);
                        }
                        final fileName =
                            'avatar_user_${DateTime.now().millisecondsSinceEpoch}.png';
                        final persistentPath =
                            '${avatarDir.path}${Platform.pathSeparator}$fileName';
                        await File(croppedPath).copy(persistentPath);
                        ref
                            .read(settingsProvider.notifier)
                            .setChatDisplaySettings(userAvatar: persistentPath);
                      }
                    }
                  },
                ),
                if (settingsState.userAvatar != null) ...[
                  const SizedBox(width: 8),
                  fluent.IconButton(
                    icon: const Icon(AuroraIcons.delete),
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
            child: _buildStyledTextBox(
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
                    border: Border.all(
                        color: fluent.Colors.grey.withValues(alpha: 0.3)),
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
                      if (!mounted) return;
                      final croppedPath =
                          await AvatarCropper.cropImage(context, result.path);
                      if (croppedPath != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final avatarDir = Directory(
                            '${appDir.path}${Platform.pathSeparator}avatars');
                        if (!await avatarDir.exists()) {
                          await avatarDir.create(recursive: true);
                        }
                        final fileName =
                            'avatar_llm_${DateTime.now().millisecondsSinceEpoch}.png';
                        final persistentPath =
                            '${avatarDir.path}${Platform.pathSeparator}$fileName';
                        await File(croppedPath).copy(persistentPath);
                        ref
                            .read(settingsProvider.notifier)
                            .setChatDisplaySettings(llmAvatar: persistentPath);
                      }
                    }
                  },
                ),
                if (settingsState.llmAvatar != null) ...[
                  const SizedBox(width: 8),
                  fluent.IconButton(
                    icon: const Icon(AuroraIcons.delete),
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
          const SizedBox(height: 24),
          const fluent.Divider(),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.closeBehavior,
            child: Row(
              children: [
                fluent.RadioButton(
                  checked: settingsState.closeBehavior == 0,
                  onChanged: (v) {
                    if (v) {
                      ref.read(settingsProvider.notifier).setCloseBehavior(0);
                    }
                  },
                  content: Text(l10n.askEveryTime),
                ),
                const SizedBox(width: 24),
                fluent.RadioButton(
                  checked: settingsState.closeBehavior == 1,
                  onChanged: (v) {
                    if (v) {
                      ref.read(settingsProvider.notifier).setCloseBehavior(1);
                    }
                  },
                  content: Text(l10n.minimizeToTrayOption),
                ),
                const SizedBox(width: 24),
                fluent.RadioButton(
                  checked: settingsState.closeBehavior == 2,
                  onChanged: (v) {
                    if (v) {
                      ref.read(settingsProvider.notifier).setCloseBehavior(2);
                    }
                  },
                  content: Text(l10n.exitApplicationOption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSettings(SettingsState settingsState) {
    final l10n = AppLocalizations.of(context)!;

    String safeSearchLabel(String code) {
      switch (code) {
        case 'off':
          return l10n.searchSafeSearchOff;
        case 'moderate':
          return l10n.searchSafeSearchModerate;
        case 'on':
          return l10n.searchSafeSearchStrict;
        default:
          return code;
      }
    }

    final engines = <String>{
      ...getAvailableEngines('text'),
      settingsState.searchEngine,
    }.toList()
      ..sort();
    final region = SearchRegion.fromCode(settingsState.searchRegion);
    final safeSearchCode = settingsState.searchSafeSearch.trim().toLowerCase();
    final maxResults = settingsState.searchMaxResults.clamp(1, 50);
    final timeoutSeconds = settingsState.searchTimeoutSeconds.clamp(5, 60);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fluent.Text(
            l10n.searchSettings,
            style: fluent.FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.searchEngine,
            child: Builder(builder: (context) {
              final items = engines.map((engine) {
                final isSelected = settingsState.searchEngine == engine;
                return fluent.MenuFlyoutItem(
                  leading: isSelected
                      ? const Icon(AuroraIcons.check, size: 12)
                      : null,
                  text: Text(engine),
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .setSearchEngine(engine),
                );
              }).toList();
              return fluent.DropDownButton(
                title: Text(settingsState.searchEngine),
                items: items,
              );
            }),
          ),
          const SizedBox(height: 16),
          fluent.InfoLabel(
            label: l10n.searchRegion,
            child: Builder(builder: (context) {
              final items = SearchRegion.values.map((r) {
                final isSelected = region.code == r.code;
                return fluent.MenuFlyoutItem(
                  leading: isSelected
                      ? const Icon(AuroraIcons.check, size: 12)
                      : null,
                  text: Text('${r.code} - ${r.displayName}'),
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .setSearchRegion(r.code),
                );
              }).toList();

              return fluent.DropDownButton(
                title: Text('${region.code} - ${region.displayName}'),
                items: items,
              );
            }),
          ),
          const SizedBox(height: 16),
          fluent.InfoLabel(
            label: l10n.searchSafeSearch,
            child: Builder(builder: (context) {
              const levels = ['off', 'moderate', 'on'];
              final items = levels.map((level) {
                final isSelected = safeSearchCode == level;
                return fluent.MenuFlyoutItem(
                  leading: isSelected
                      ? const Icon(AuroraIcons.check, size: 12)
                      : null,
                  text: Text(safeSearchLabel(level)),
                  onPressed: () => ref
                      .read(settingsProvider.notifier)
                      .setSearchSafeSearch(level),
                );
              }).toList();
              return fluent.DropDownButton(
                title: Text(safeSearchLabel(safeSearchCode)),
                items: items,
              );
            }),
          ),
          const SizedBox(height: 16),
          fluent.InfoLabel(
            label: l10n.searchMaxResults,
            child: Row(
              children: [
                Expanded(
                  child: fluent.Slider(
                    value: maxResults.toDouble(),
                    min: 1,
                    max: 50,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setSearchMaxResults(v.round()),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${maxResults.toInt()}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          fluent.InfoLabel(
            label: l10n.searchTimeoutSeconds,
            child: Row(
              children: [
                Expanded(
                  child: fluent.Slider(
                    value: timeoutSeconds.toDouble(),
                    min: 5,
                    max: 60,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setSearchTimeoutSeconds(v.round()),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${timeoutSeconds.toInt()}s'),
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
    final theme = fluent.FluentTheme.of(context);

    final colors = [
      ('Teal', 'teal', fluent.Colors.teal),
      ('Blue', 'blue', fluent.Colors.blue),
      ('Red', 'red', fluent.Colors.red),
      ('Orange', 'orange', fluent.Colors.orange),
      ('Green', 'green', fluent.Colors.green),
      ('Purple', 'purple', fluent.Colors.purple),
      ('Magenta', 'magenta', fluent.Colors.magenta),
      ('Yellow', 'yellow', fluent.Colors.yellow),
    ];

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
          fluent.InfoLabel(
            label: l10n.themeMode,
            child: Row(
              children: [
                fluent.RadioButton(
                  checked: settingsState.themeMode == 'light',
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).setThemeMode('light'),
                  content: Text(l10n.themeLight),
                ),
                const SizedBox(width: 16),
                fluent.RadioButton(
                  checked: settingsState.themeMode == 'dark',
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).setThemeMode('dark'),
                  content: Text(l10n.themeDark),
                ),
                const SizedBox(width: 16),
                fluent.RadioButton(
                  checked: settingsState.themeMode == 'system',
                  onChanged: (_) => ref
                      .read(settingsProvider.notifier)
                      .setThemeMode('system'),
                  content: Text(l10n.themeSystem),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          fluent.ToggleSwitch(
            checked: settingsState.useCustomTheme,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setUseCustomTheme(v),
            content: Text(l10n.themeCustom),
          ),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.accentColor,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((c) {
                final isSelected = settingsState.themeColor == c.$2;
                return fluent.Tooltip(
                  message: c.$1,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(settingsProvider.notifier).setThemeColor(c.$2);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.$3,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: theme.typography.body!.color!,
                                width: 2,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(AuroraIcons.check,
                              size: 16,
                              color: c.$2 == 'yellow'
                                  ? Colors.black
                                  : Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.backgroundStyle,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                (
                  l10n.bgDefault,
                  'default',
                  [const Color(0xFF2B2B2B)],
                  [const Color(0xFFE0F7FA), const Color(0xFFF1F8E9)]
                ),
                (
                  l10n.bgPureBlack,
                  'pure_black',
                  [const Color(0xFF000000)],
                  [const Color(0xFFFFFFFF)]
                ),
                (
                  l10n.bgWarm,
                  'warm',
                  [const Color(0xFF1E1C1A), const Color(0xFF2E241E)],
                  [const Color(0xFFFFF8E1), const Color(0xFFFFF3E0)]
                ),
                (
                  l10n.bgCool,
                  'cool',
                  [const Color(0xFF1A1C1E), const Color(0xFF1E252E)],
                  [const Color(0xFFE1F5FE), const Color(0xFFE3F2FD)]
                ),
                (
                  l10n.bgRose,
                  'rose',
                  [const Color(0xFF2D1A1E), const Color(0xFF3B1E26)],
                  [const Color(0xFFFCE4EC), const Color(0xFFFFEBEE)]
                ),
                (
                  l10n.bgLavender,
                  'lavender',
                  [const Color(0xFF1F1A2D), const Color(0xFF261E3B)],
                  [const Color(0xFFF3E5F5), const Color(0xFFEDE7F6)]
                ),
                (
                  l10n.bgMint,
                  'mint',
                  [const Color(0xFF1A2D24), const Color(0xFF1E3B2E)],
                  [const Color(0xFFE0F2F1), const Color(0xFFE8F5E9)]
                ),
                (
                  l10n.bgSky,
                  'sky',
                  [const Color(0xFF1A202D), const Color(0xFF1E263B)],
                  [const Color(0xFFE0F7FA), const Color(0xFFE1F5FE)]
                ),
                (
                  l10n.bgGray,
                  'gray',
                  [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)],
                  [const Color(0xFFFAFAFA), const Color(0xFFF5F5F5)]
                ),
                (
                  l10n.bgSunset,
                  'sunset',
                  [const Color(0xFF1A0B0E), const Color(0xFF4A1F28)],
                  [const Color(0xFFFFF3E0), const Color(0xFFFBE9E7)]
                ),
                (
                  l10n.bgOcean,
                  'ocean',
                  [const Color(0xFF05101A), const Color(0xFF0D2B42)],
                  [const Color(0xFFE3F2FD), const Color(0xFFE8EAF6)]
                ),
                (
                  l10n.bgForest,
                  'forest',
                  [const Color(0xFF051408), const Color(0xFF0E3316)],
                  [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)]
                ),
                (
                  l10n.bgDream,
                  'dream',
                  [const Color(0xFF120817), const Color(0xFF261233)],
                  [const Color(0xFFEDE7F6), const Color(0xFFE8EAF6)]
                ),
                (
                  l10n.bgAurora,
                  'aurora',
                  [const Color(0xFF051715), const Color(0xFF181533)],
                  [const Color(0xFFE0F2F1), const Color(0xFFEDE7F6)]
                ),
                (
                  l10n.bgVolcano,
                  'volcano',
                  [const Color(0xFF1F0808), const Color(0xFF3E1212)],
                  [const Color(0xFFFBE9E7), const Color(0xFFFFEBEE)]
                ),
                (
                  l10n.bgMidnight,
                  'midnight',
                  [const Color(0xFF020205), const Color(0xFF141426)],
                  [const Color(0xFFECEFF1), const Color(0xFFFAFAFA)]
                ),
                (
                  l10n.bgDawn,
                  'dawn',
                  [const Color(0xFF141005), const Color(0xFF33260D)],
                  [const Color(0xFFFFFDE7), const Color(0xFFFFF8E1)]
                ),
                (
                  l10n.bgNeon,
                  'neon',
                  [const Color(0xFF08181A), const Color(0xFF240C21)],
                  [const Color(0xFFE0F7FA), const Color(0xFFF3E5F5)]
                ),
                (
                  l10n.bgBlossom,
                  'blossom',
                  [const Color(0xFF1F050B), const Color(0xFF3D0F19)],
                  [const Color(0xFFFFEBEE), const Color(0xFFFCE4EC)]
                ),
              ].map((c) {
                final isSelected = settingsState.backgroundColor == c.$2;
                final isDark = theme.brightness == fluent.Brightness.dark;
                final colors = isDark ? c.$3 : c.$4;

                return fluent.Tooltip(
                  message: c.$1,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setBackgroundColor(c.$2);
                    },
                    child: Container(
                      width: 48,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.length == 1 ? colors.first : null,
                        gradient: colors.length > 1
                            ? LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        border: isSelected
                            ? Border.all(
                                color: theme.accentColor,
                                width: 2,
                              )
                            : Border.all(
                                color:
                                    fluent.Colors.grey.withValues(alpha: 0.3),
                              ),
                      ),
                      child: isSelected
                          ? Icon(AuroraIcons.check,
                              size: 16,
                              color: isDark ? Colors.white : Colors.black)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.fontSize,
            child: Row(
              children: [
                Expanded(
                  child: fluent.Slider(
                    label: settingsState.fontSize.toStringAsFixed(1),
                    value: settingsState.fontSize,
                    min: 10,
                    max: 20,
                    onChanged: (v) {
                      ref.read(settingsProvider.notifier).setFontSize(v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text('${settingsState.fontSize.toStringAsFixed(1)} pt'),
                const SizedBox(width: 8),
                fluent.Button(
                  child: const Text('Reset'),
                  onPressed: () {
                    ref.read(settingsProvider.notifier).setFontSize(14.0);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 24),
          fluent.InfoLabel(
            label: l10n.backgroundImage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    fluent.Button(
                      onPressed: () async {
                        const typeGroup = XTypeGroup(
                          label: 'images',
                          extensions: ['jpg', 'png', 'jpeg', 'webp'],
                        );
                        final file =
                            await openFile(acceptedTypeGroups: [typeGroup]);
                        if (file != null) {
                          ref
                              .read(settingsProvider.notifier)
                              .setBackgroundImagePath(file.path);
                        }
                      },
                      child: Text(l10n.selectBackgroundImage),
                    ),
                    if (settingsState.backgroundImagePath != null &&
                        settingsState.backgroundImagePath!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      fluent.Button(
                        onPressed: () {
                          ref
                              .read(settingsProvider.notifier)
                              .setBackgroundImagePath(null);
                        },
                        child: Text(l10n.clearBackgroundImage),
                      ),
                    ],
                  ],
                ),
                if (settingsState.backgroundImagePath != null &&
                    settingsState.backgroundImagePath!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  fluent.InfoLabel(
                    label: l10n.backgroundBrightness,
                    child: Row(
                      children: [
                        Expanded(
                          child: fluent.Slider(
                            value: settingsState.backgroundBrightness,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (v) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setBackgroundBrightness(v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                            '${(settingsState.backgroundBrightness * 100).toInt()}%'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  fluent.InfoLabel(
                    label: l10n.backgroundBlur,
                    child: Row(
                      children: [
                        Expanded(
                          child: fluent.Slider(
                            value: settingsState.backgroundBlur,
                            min: 0.0,
                            max: 20.0,
                            onChanged: (v) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setBackgroundBlur(v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                            '${settingsState.backgroundBlur.toStringAsFixed(1)} px'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: SyncSettingsSection(),
    );
  }

  void _openModelSettings(ProviderConfig provider, String modelName) async {
    showDialog(
        context: context,
        builder: (context) {
          return ModelConfigDialog(
            provider: provider,
            modelName: modelName,
          );
        });
  }
}

class _ApiKeyItem extends StatefulWidget {
  final String apiKey;
  final ValueChanged<String> onUpdate;

  const _ApiKeyItem({
    super.key,
    required this.apiKey,
    required this.onUpdate,
  });

  @override
  State<_ApiKeyItem> createState() => _ApiKeyItemState();
}

class _ApiKeyItemState extends State<_ApiKeyItem> {
  late TextEditingController _controller;
  bool _isVisible = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.apiKey);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Optional: Trigger update on blur if we want to be safe,
        // but onChanged should handle it.
      }
    });
  }

  @override
  void didUpdateWidget(_ApiKeyItem oldWidget) {
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
    return fluent.TextBox(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: !_isVisible,
      onChanged: widget.onUpdate,
      placeholder: 'sk-................',
      suffix: fluent.IconButton(
        icon: fluent.Icon(
          _isVisible ? AuroraIcons.visibilityOff : AuroraIcons.visibility,
          size: 14,
        ),
        onPressed: () {
          setState(() {
            _isVisible = !_isVisible;
          });
        },
      ),
      decoration: WidgetStateProperty.all(BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.transparent),
      )),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        letterSpacing: _isVisible ? 0 : 2,
      ),
      highlightColor: Colors.transparent,
      unfocusedColor: Colors.transparent,
    );
  }
}
