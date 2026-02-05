import 'package:aurora/features/assistant/presentation/widgets/assistant_avatar.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora/features/assistant/presentation/assistant_provider.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';

import 'custom_dropdown_overlay.dart';
import 'package:aurora/l10n/app_localizations.dart';

class AssistantSelector extends ConsumerStatefulWidget {
  final String sessionId;
  const AssistantSelector({super.key, required this.sessionId});
  @override
  ConsumerState<AssistantSelector> createState() => _AssistantSelectorState();
}

class _AssistantSelectorState extends ConsumerState<AssistantSelector> {
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
        offset: const Offset(0, 0),
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        child: AnimatedDropdownList(
          backgroundColor: theme.menuColor,
          borderColor: theme.resources.surfaceStrokeColorDefault,
          width: 220,
          items: _buildDropdownItems(theme, l10n),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  List<fluent.CommandBarItem> _buildDropdownItems(
      fluent.FluentThemeData theme, AppLocalizations l10n) {
    final assistants = ref.watch(assistantProvider).assistants;
    ref.watch(settingsProvider);
    final List<fluent.CommandBarItem> items = [];

    // Add Default option first
    items.add(fluent.CommandBarButton(
      onPressed: () {
        ref.read(assistantProvider.notifier).selectAssistant(null);
        _removeOverlay();
      },
      label: fluent.Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            AssistantAvatar(assistant: null, size: 24),
            const SizedBox(width: 8),
            const Text('Default',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ));

    if (assistants.isEmpty) {
      return items;
    }

    for (final assistant in assistants) {
      items.add(fluent.CommandBarButton(
        onPressed: () {
          ref.read(assistantProvider.notifier).selectAssistant(assistant.id);
          _removeOverlay();
        },
        label: fluent.Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              AssistantAvatar(
                assistant: assistant,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(assistant.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (assistant.description.isNotEmpty)
                      Text(assistant.description,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.typography.caption?.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final selectedId = ref.watch(assistantProvider).selectedAssistantId;
    final assistants = ref.watch(assistantProvider).assistants;
    final selectedAssistant =
        assistants.where((a) => a.id == selectedId).firstOrNull;

    return CompositedTransformTarget(
      link: _layerLink,
      child: fluent.HoverButton(
        onPressed: _toggleDropdown,
        builder: (context, states) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isOpen || states.isHovered
                  ? theme.resources.subtleFillColorSecondary
                  : fluent.Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AssistantAvatar(
                  assistant: selectedAssistant,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: fluent.Text(
                    selectedAssistant?.name ?? 'Default',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                fluent.Icon(
                    _isOpen ? AuroraIcons.chevronUp : AuroraIcons.chevronDown,
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
