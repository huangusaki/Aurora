import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

import 'custom_dropdown_overlay.dart';

typedef SelectorOverlayItemsBuilder = List<ColoredDropdownItem> Function(
  BuildContext context,
  WidgetRef ref,
  fluent.FluentThemeData theme,
  AppLocalizations l10n,
  VoidCallback dismissOverlay,
);

typedef SelectorTriggerContentBuilder = Widget Function(
  BuildContext context,
  WidgetRef ref,
  fluent.FluentThemeData theme,
  AppLocalizations l10n,
);

abstract class SelectorOverlayScaffold extends ConsumerStatefulWidget {
  final double overlayWidth;
  final Offset overlayOffset;
  final Alignment targetAnchor;
  final Alignment followerAnchor;

  const SelectorOverlayScaffold({
    super.key,
    required this.overlayWidth,
    this.overlayOffset = Offset.zero,
    this.targetAnchor = Alignment.bottomRight,
    this.followerAnchor = Alignment.topRight,
  });

  SelectorTriggerContentBuilder get triggerContentBuilder;
  SelectorOverlayItemsBuilder get overlayItemsBuilder;

  @override
  ConsumerState<SelectorOverlayScaffold> createState() =>
      _SelectorOverlayScaffoldState();
}

class _SelectorOverlayScaffoldState
    extends ConsumerState<SelectorOverlayScaffold> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay(notify: false);
    super.dispose();
  }

  void _removeOverlay({bool notify = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (notify && mounted) {
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
        onDismiss: () => _removeOverlay(),
        layerLink: _layerLink,
        offset: widget.overlayOffset,
        targetAnchor: widget.targetAnchor,
        followerAnchor: widget.followerAnchor,
        child: AnimatedDropdownList(
          backgroundColor: theme.menuColor,
          borderColor: theme.resources.surfaceStrokeColorDefault,
          width: widget.overlayWidth,
          coloredItems: widget.overlayItemsBuilder(
            context,
            ref,
            theme,
            l10n,
            () => _removeOverlay(),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                widget.triggerContentBuilder(context, ref, theme, l10n),
                const SizedBox(width: 4),
                fluent.Icon(
                  _isOpen ? AuroraIcons.chevronUp : AuroraIcons.chevronDown,
                  size: 8,
                  color: theme.typography.caption?.color,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
