import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

import 'package:aurora/shared/theme/aurora_icons.dart';

class AuroraDropdownOption<T> {
  const AuroraDropdownOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;
  final bool enabled;
}

class AuroraDropdown<T> extends StatefulWidget {
  const AuroraDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.placeholder,
    this.selectedLabel,
    this.disabled = false,
    this.placement = fluent.FlyoutPlacementMode.bottomLeft,
    this.verticalOffset = 2.0,
  });

  final List<AuroraDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final T? value;
  final String? placeholder;
  final String? selectedLabel;
  final bool disabled;
  final fluent.FlyoutPlacementMode placement;
  final double verticalOffset;

  @override
  State<AuroraDropdown<T>> createState() => _AuroraDropdownState<T>();
}

class _AuroraDropdownState<T> extends State<AuroraDropdown<T>> {
  final fluent.FlyoutController _flyoutController = fluent.FlyoutController();

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  bool get _isEnabled => !widget.disabled && widget.options.isNotEmpty;

  Future<void> _open() async {
    if (!_isEnabled || _flyoutController.isOpen) return;
    final placementMode = widget.placement == fluent.FlyoutPlacementMode.auto
        ? widget.placement
        : widget.placement.resolve(Directionality.of(context));
    await _flyoutController.showFlyout<void>(
      barrierColor: Colors.transparent,
      placementMode: placementMode,
      // Keep the menu pinned under the trigger even in constrained windows.
      forceAvailableSpace: true,
      shouldConstrainToRootBounds: true,
      additionalOffset: widget.verticalOffset,
      builder: (context) {
        return fluent.MenuFlyout(
          items: widget.options.map(_buildItem).toList(growable: false),
        );
      },
    );
  }

  fluent.MenuFlyoutItem _buildItem(AuroraDropdownOption<T> option) {
    final isSelected = option.value == widget.value;
    return fluent.MenuFlyoutItem(
      leading: isSelected ? const Icon(AuroraIcons.check, size: 12) : null,
      text: Text(
        option.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: option.enabled ? () => widget.onChanged(option.value) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = _resolveLabel();

    return fluent.FlyoutTarget(
      controller: _flyoutController,
      child: fluent.Button(
        onPressed: _isEnabled ? _open : null,
        child: Builder(
          builder: (context) {
            final theme = fluent.FluentTheme.of(context);
            final state = fluent.HoverButton.of(context).states;
            final iconColor = state.isDisabled
                ? theme.resources.textFillColorDisabled
                : state.isPressed
                    ? theme.resources.textFillColorTertiary
                    : state.isHovered
                        ? theme.resources.textFillColorSecondary
                        : theme.resources.textFillColorPrimary;

            return IconTheme.merge(
              data: IconThemeData(size: 20.0, color: iconColor),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  const fluent.ChevronDown(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _resolveLabel() {
    if (widget.selectedLabel != null && widget.selectedLabel!.isNotEmpty) {
      return widget.selectedLabel!;
    }
    for (final option in widget.options) {
      if (option.value == widget.value) {
        return option.label;
      }
    }
    if (widget.placeholder != null && widget.placeholder!.isNotEmpty) {
      return widget.placeholder!;
    }
    return '';
  }
}
