import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:file_selector/file_selector.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora_search/aurora_search.dart';
import 'package:aurora/shared/theme/wallpaper_tint.dart';
import 'package:aurora/shared/theme/wallpaper_tint_provider.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:aurora/shared/widgets/aurora_dropdown.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';
import 'settings_provider.dart';
import 'model_display_name.dart';
import 'usage_stats_view.dart';
import 'preset_settings_page.dart';
import 'knowledge_settings_panel.dart';

import '../../../shared/utils/avatar_cropper.dart';
import '../../../shared/utils/avatar_storage.dart';
import 'model_config_dialog.dart';
import 'global_config_dialog.dart';
import '../../sync/presentation/sync_settings_section.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';

part 'settings_content_sections.dart';
part 'settings_content_api_key_item.dart';

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

  Future<void> _refreshModelsWithNotice(AppLocalizations l10n) async {
    final success = await ref.read(settingsProvider.notifier).fetchModels();
    if (!mounted) return;

    if (success) {
      showAuroraNotice(
        context,
        '${l10n.fetchModelList} ${l10n.success}',
        icon: AuroraIcons.success,
      );
      return;
    }

    final errorMessage = ref.read(settingsProvider).error;
    final message = (errorMessage?.isNotEmpty ?? false)
        ? '${l10n.fetchModelList} ${l10n.failed}: $errorMessage'
        : '${l10n.fetchModelList} ${l10n.failed}';
    showAuroraNotice(
      context,
      message,
      icon: AuroraIcons.error,
    );
  }

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
    final l10n = AppLocalizations.of(context)!;
    if (PlatformUtils.isDesktop) {
      final theme = fluent.FluentTheme.of(context);
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
        appBar: AppBar(title: Text(l10n.settings)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AuroraIcons.settings, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.mobileSettings,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(l10n.mobileSettingsHint, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
  }
}
