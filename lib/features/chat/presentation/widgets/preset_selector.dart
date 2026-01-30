import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../chat_provider.dart';

import 'custom_dropdown_overlay.dart';
import 'package:aurora/l10n/app_localizations.dart';

class PresetSelector extends ConsumerStatefulWidget {
  final String sessionId;
  const PresetSelector({super.key, required this.sessionId});
  @override
  ConsumerState<PresetSelector> createState() => _PresetSelectorState();
}

class _PresetSelectorState extends ConsumerState<PresetSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    _overlayEntry = OverlayEntry(
      builder: (context) => CustomDropdownOverlay(
        onDismiss: _removeOverlay,
        layerLink: _layerLink,
        offset: const Offset(0, 36),
        child: AnimatedDropdownList(
          backgroundColor: theme.menuColor,
          borderColor: theme.resources.surfaceStrokeColorDefault,
          width: 200,
          items: _buildDropdownItems(theme, l10n),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  List<fluent.CommandBarItem> _buildDropdownItems(
      fluent.FluentThemeData theme, AppLocalizations l10n) {
    final settings = ref.watch(settingsProvider);
    final presets = settings.presets;
    final List<fluent.CommandBarItem> items = [];
    items.add(fluent.CommandBarButton(
      onPressed: () {
        ref
            .read(chatSessionManagerProvider)
            .getOrCreate(widget.sessionId)
            .updateSystemPrompt('', null);
        _removeOverlay();
      },
      label: fluent.Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(l10n.defaultPreset,
            style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    ));
    if (presets.isNotEmpty) {
      items.add(const fluent.CommandBarSeparator());
    }
    for (final preset in presets) {
      items.add(fluent.CommandBarButton(
        onPressed: () {
          ref
              .read(chatSessionManagerProvider)
              .getOrCreate(widget.sessionId)
              .updateSystemPrompt(preset.systemPrompt, preset.name);
          _removeOverlay();
        },
        label: fluent.Padding(
          padding: const EdgeInsets.only(left: 8),
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
        ),
      ));
    }
    if (presets.isNotEmpty) {
      items.add(const fluent.CommandBarSeparator());
    }
    items.add(fluent.CommandBarButton(
      onPressed: () {
        _removeOverlay();
        ref.read(desktopActiveTabProvider.notifier).state = 4;
        ref.read(settingsPageIndexProvider.notifier).state = 2;
      },
      label: fluent.Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            Icon(AuroraIcons.settings, size: 12),
            const SizedBox(width: 8),
            Text(l10n.managePresets),
          ],
        ),
      ),
    ));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    ref.watch(chatStateUpdateTriggerProvider);
    final chatState = ref
        .watch(chatSessionManagerProvider)
        .getOrCreate(widget.sessionId)
        .currentState;
    String? activePresetName = chatState.activePresetName;
    if (activePresetName == null) {
      final settings = ref.watch(settingsProvider);
      final presets = settings.presets;
      final lastPresetId = settings.lastPresetId;
      if (lastPresetId != null) {
        final match = presets.where((p) => p.id == lastPresetId);
        if (match.isNotEmpty) {
          activePresetName = match.first.name;
        }
      }
    }
    return CompositedTransformTarget(
      link: _layerLink,
      child: fluent.HoverButton(
        onPressed: _toggleDropdown,
        builder: (context, states) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isOpen || states.isHovering
                  ? theme.resources.subtleFillColorSecondary
                  : fluent.Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: fluent.Text(
                    activePresetName ?? l10n.defaultPreset,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                fluent.Icon(
                    _isOpen
                        ? AuroraIcons.chevronUp
                        : AuroraIcons.chevronDown,
                    size: 8,
                    color: theme.typography.caption?.color),
              ],
            ),
          );
        },
      ),
    );
  }
}
