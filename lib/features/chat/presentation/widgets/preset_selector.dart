import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/chat/presentation/desktop/desktop_tabs.dart';
import '../chat_provider.dart';

import 'package:aurora/l10n/app_localizations.dart';

import 'custom_dropdown_overlay.dart';
import 'selector_overlay_scaffold.dart';

class PresetSelector extends SelectorOverlayScaffold {
  final String sessionId;
  const PresetSelector({super.key, required this.sessionId})
      : super(overlayWidth: 200, overlayOffset: const Offset(0, 36));

  static const int _desktopSettingsTabIndex = kDesktopTabSettings;
  static const int _presetSettingsPageIndex = 4;

  @override
  SelectorTriggerContentBuilder get triggerContentBuilder =>
      _buildTriggerContent;

  @override
  SelectorOverlayItemsBuilder get overlayItemsBuilder => _buildDropdownItems;

  Widget _buildTriggerContent(BuildContext context, WidgetRef ref,
      fluent.FluentThemeData theme, AppLocalizations l10n) {
    final textStyle = theme.typography.body?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    ref.watch(chatStateUpdateTriggerProvider);
    final settings = ref.watch(settingsProvider);
    final presets = settings.presets;
    final chatState = ref
        .watch(chatSessionManagerProvider)
        .getOrCreate(sessionId)
        .currentState;
    String? activePresetName = chatState.activePresetName;
    if (activePresetName == null) {
      final lastPresetId = settings.lastPresetId;
      if (lastPresetId != null) {
        final match = presets.where((p) => p.id == lastPresetId);
        if (match.isNotEmpty) {
          activePresetName = match.first.name;
        }
      }
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      child: fluent.Text(
        activePresetName ?? l10n.defaultPreset,
        style: textStyle,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<ColoredDropdownItem> _buildDropdownItems(
    BuildContext context,
    WidgetRef ref,
    fluent.FluentThemeData theme,
    AppLocalizations l10n,
    VoidCallback dismissOverlay,
  ) {
    final settings = ref.watch(settingsProvider);
    final presets = settings.presets;
    final List<ColoredDropdownItem> items = [];

    items.add(ColoredDropdownItem(
      onPressed: () {
        ref
            .read(chatSessionManagerProvider)
            .getOrCreate(sessionId)
            .updateSystemPrompt('', null);
        dismissOverlay();
      },
      child: Text(l10n.defaultPreset,
          style: const TextStyle(fontWeight: FontWeight.w500)),
    ));

    for (final preset in presets) {
      items.add(ColoredDropdownItem(
        onPressed: () {
          ref
              .read(chatSessionManagerProvider)
              .getOrCreate(sessionId)
              .updateSystemPrompt(preset.systemPrompt, preset.name);
          dismissOverlay();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(preset.name,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            if (preset.description.isNotEmpty)
              Text(preset.description,
                  style: TextStyle(
                      fontSize: 10, color: theme.typography.caption?.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      ));
    }

    items.add(const DropdownSeparator());
    items.add(ColoredDropdownItem(
      onPressed: () {
        dismissOverlay();
        ref.read(desktopActiveTabProvider.notifier).state =
            _desktopSettingsTabIndex;
        ref.read(settingsPageIndexProvider.notifier).state =
            _presetSettingsPageIndex;
      },
      child: Row(
        children: [
          Icon(AuroraIcons.settings, size: 12),
          const SizedBox(width: 8),
          Text(l10n.managePresets),
        ],
      ),
    ));
    return items;
  }
}
