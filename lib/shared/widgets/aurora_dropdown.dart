import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
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

bool auroraUseMaterialDropdownStyle() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

InputDecoration auroraDropdownInputDecoration(
  BuildContext context, {
  String? label,
  EdgeInsetsGeometry? contentPadding,
  double borderRadius = 12,
}) {
  final theme = Theme.of(context);
  final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.7);
  return InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: theme.colorScheme.surface.withValues(alpha: 0.72),
    contentPadding: contentPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: theme.colorScheme.primary.withValues(alpha: 0.82),
        width: 1.4,
      ),
    ),
  );
}

class AuroraMaterialDropdownField<T> extends StatelessWidget {
  const AuroraMaterialDropdownField({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.enabled = true,
    this.menuMaxHeight = 320,
    this.borderRadius = 12,
    this.contentPadding,
    this.decoration,
    this.textStyle,
    this.dropdownColor,
  });

  final List<AuroraDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final bool enabled;
  final double menuMaxHeight;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final Color? dropdownColor;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: menuMaxHeight,
      borderRadius: BorderRadius.circular(borderRadius),
      dropdownColor: dropdownColor ?? Theme.of(context).colorScheme.surface,
      decoration: decoration ??
          auroraDropdownInputDecoration(
            context,
            label: label,
            contentPadding: contentPadding,
            borderRadius: borderRadius,
          ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option.value,
              enabled: option.enabled,
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
    );
  }
}

class AuroraFluentDropdownField<T> extends StatelessWidget {
  const AuroraFluentDropdownField({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.placeholder,
    this.isExpanded = true,
    this.textStyle,
  });

  final List<AuroraDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String? placeholder;
  final bool isExpanded;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final combo = AuroraDropdown<T>(
      value: value,
      isExpanded: isExpanded,
      placeholder: placeholder,
      options: options,
      onChanged: (val) {
        if (onChanged != null) onChanged!(val);
      },
      textStyle: textStyle,
      disabled: onChanged == null,
    );
    if (label == null || label!.isEmpty) {
      return combo;
    }
    return fluent.InfoLabel(
      label: label!,
      child: combo,
    );
  }
}

class AuroraAdaptiveDropdownField<T> extends StatelessWidget {
  const AuroraAdaptiveDropdownField({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.placeholder,
    this.menuMaxHeight = 320,
    this.borderRadius = 12,
    this.contentPadding,
    this.textStyle,
  });

  final List<AuroraDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final String? label;
  final String? placeholder;
  final double menuMaxHeight;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (auroraUseMaterialDropdownStyle()) {
      return AuroraMaterialDropdownField<T>(
        value: value,
        label: label,
        options: options,
        onChanged: onChanged,
        menuMaxHeight: menuMaxHeight,
        borderRadius: borderRadius,
        contentPadding: contentPadding,
        textStyle: textStyle,
      );
    }

    return AuroraFluentDropdownField<T>(
      value: value,
      label: label,
      options: options,
      onChanged: onChanged,
      placeholder: placeholder,
      textStyle: textStyle,
    );
  }
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
    this.placement = fluent.FlyoutPlacementMode.bottomCenter,
    this.verticalOffset = 2.0,
    this.leading,
    this.textStyle,
    this.isExpanded = false,
  });

  final List<AuroraDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final T? value;
  final String? placeholder;
  final String? selectedLabel;
  final bool disabled;
  final fluent.FlyoutPlacementMode placement;
  final double verticalOffset;
  final Widget? leading;
  final TextStyle? textStyle;
  final bool isExpanded;

  @override
  State<AuroraDropdown<T>> createState() => _AuroraDropdownState<T>();
}

class _AuroraDropdownState<T> extends State<AuroraDropdown<T>> {
  final fluent.FlyoutController _flyoutController = fluent.FlyoutController();
  bool _isHovering = false;

  @override
  void dispose() {
    _flyoutController.dispose();
    super.dispose();
  }

  bool get _isEnabled => !widget.disabled && widget.options.isNotEmpty;

  Future<void> _open() async {
    if (!_isEnabled || _flyoutController.isOpen) return;
    
    // Explicitly update state to show active chevron animation
    setState(() {});
    
    final placementMode = widget.placement == fluent.FlyoutPlacementMode.auto
        ? widget.placement
        : widget.placement.resolve(Directionality.of(context));
    
    await _flyoutController.showFlyout<void>(
      barrierColor: Colors.transparent,
      placementMode: placementMode,
      forceAvailableSpace: true,
      shouldConstrainToRootBounds: true,
      additionalOffset: widget.verticalOffset,
      margin: 4.0,
      builder: (context) {
        return fluent.MenuFlyout(
          items: widget.options.map(_buildItem).toList(growable: false),
        );
      },
    );
    
    // Explicitly update state when flyout closes
    if (mounted) {
      setState(() {});
    }
  }

  fluent.MenuFlyoutItem _buildItem(AuroraDropdownOption<T> option) {
    final isSelected = option.value == widget.value;
    final theme = fluent.FluentTheme.of(context);
    return fluent.MenuFlyoutItem(
      leading: isSelected 
        ? Icon(AuroraIcons.check, size: 14, color: theme.accentColor) 
        : const SizedBox(width: 14),
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
    final theme = fluent.FluentTheme.of(context);
    
    final bool isOpen = _flyoutController.isOpen;

    // Determine colors based on state
    final Color backgroundColor = _isEnabled 
      ? (isOpen 
          ? theme.resources.subtleFillColorTertiary
          : _isHovering 
            ? theme.resources.subtleFillColorSecondary
            : theme.resources.subtleFillColorTransparent)
      : theme.resources.subtleFillColorDisabled;
      
    final Color borderColor = _isEnabled
      ? (isOpen || _isHovering
          ? theme.resources.textFillColorSecondary.withValues(alpha: 0.2)
          : theme.resources.textFillColorSecondary.withValues(alpha: 0.1))
      : theme.resources.textFillColorDisabled.withValues(alpha: 0.05);
      
    final Color textColor = _isEnabled
      ? (isOpen 
          ? theme.resources.textFillColorPrimary
          : _isHovering 
            ? theme.resources.textFillColorPrimary 
            : theme.resources.textFillColorSecondary)
      : theme.resources.textFillColorDisabled;

    Widget buttonContent = Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (widget.textStyle ?? const TextStyle()).copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
        if (!widget.isExpanded) const SizedBox(width: 12),
        AnimatedRotation(
          turns: isOpen ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Icon(
            fluent.FluentIcons.chevron_down,
            size: 10,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: buttonContent,
    );

    return fluent.FlyoutTarget(
      controller: _flyoutController,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: _isEnabled ? _open : null,
          behavior: HitTestBehavior.opaque,
          child: container,
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
