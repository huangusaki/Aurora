import 'dart:math';
import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

/// Helper function to generate a consistent color from a string (e.g., provider ID)
Color generateColorFromString(String input) {
  final hash = input.hashCode;
  final random = Random(hash);
  // Generate pleasing pastel colors by keeping saturation and brightness in a good range
  final hue = random.nextDouble() * 360;
  final saturation = 0.5 + random.nextDouble() * 0.3; // 0.5-0.8
  final lightness = 0.4 + random.nextDouble() * 0.2; // 0.4-0.6
  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

/// A dropdown item with optional background color
class ColoredDropdownItem {
  final String label;
  final Widget? child;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final bool isBold;
  final bool isSelected;
  final Color? textColor;

  const ColoredDropdownItem({
    this.label = '',
    this.child,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.isBold = false,
    this.isSelected = false,
    this.textColor,
  });
}

/// Separator item for dropdown
class DropdownSeparator extends ColoredDropdownItem {
  const DropdownSeparator() : super(label: '');
}

class CustomDropdownOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final LayerLink layerLink;
  final Widget child;
  final Offset offset;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  const CustomDropdownOverlay({
    super.key,
    required this.onDismiss,
    required this.layerLink,
    required this.child,
    this.offset = const Offset(0, 32),
    this.targetAnchor = Alignment.topLeft,
    this.followerAnchor = Alignment.topLeft,
  });
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: offset,
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          child: Align(
            alignment: followerAnchor,
            child: Material(
              color: Colors.transparent,
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedDropdownList extends StatefulWidget {
  final List<ColoredDropdownItem>? coloredItems;
  final double width;
  final Color backgroundColor;
  final Color borderColor;
  const AnimatedDropdownList({
    super.key,
    this.coloredItems,
    this.width = 280,
    required this.backgroundColor,
    required this.borderColor,
  });
  @override
  State<AnimatedDropdownList> createState() => _AnimatedDropdownListState();
}

class _AnimatedDropdownListState extends State<AnimatedDropdownList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _selectedItemKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedItem();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToSelectedItem() {
    final selectedContext = _selectedItemKey.currentContext;
    if (selectedContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      selectedContext,
      alignment: 0.4,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: Alignment.topLeft,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: widget.width,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                children: _buildItems(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems() {
    if (widget.coloredItems == null || widget.coloredItems!.isEmpty) {
      return [];
    }
    return widget.coloredItems!.map((item) {
      if (item is DropdownSeparator) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Divider(height: 1, thickness: 1, color: Colors.grey),
        );
      }
      return _ColoredMenuItem(
        key: item.isSelected ? _selectedItemKey : null,
        item: item,
      );
    }).toList();
  }
}

class _ColoredMenuItem extends StatefulWidget {
  final ColoredDropdownItem item;
  const _ColoredMenuItem({super.key, required this.item});
  @override
  State<_ColoredMenuItem> createState() => _ColoredMenuItemState();
}

class _ColoredMenuItemState extends State<_ColoredMenuItem> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final bgColor = widget.item.backgroundColor;

    Color resolveBackground() {
      if (bgColor != null) {
        if (isHovered) {
          return bgColor.withValues(alpha: 0.25);
        }
        return bgColor.withValues(alpha: 0.1);
      }
      if (isHovered) {
        return theme.resources.subtleFillColorSecondary;
      }
      return Colors.transparent;
    }

    return GestureDetector(
      onTap: widget.item.onPressed,
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        cursor: widget.item.onPressed != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: resolveBackground(),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: widget.item.child ??
                    Text(
                      widget.item.label,
                      style: TextStyle(
                        color: widget.item.textColor ??
                            theme.typography.body?.color,
                        fontSize: 14,
                        fontWeight: widget.item.isBold
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
              ),
              if (widget.item.icon != null) ...[
                const SizedBox(width: 8),
                IconTheme(
                  data: IconThemeData(
                    size: 14,
                    color: theme.accentColor,
                  ),
                  child: widget.item.icon!,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
