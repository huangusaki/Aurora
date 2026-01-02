import 'dart:math';
import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class CustomDropdownOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  final LayerLink layerLink;
  final Widget child;
  final Offset offset;

  const CustomDropdownOverlay({
    super.key,
    required this.onDismiss,
    required this.layerLink,
    required this.child,
    this.offset = const Offset(0, 32),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent backdrop to detect clicks outside
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Positioned Dropdown
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: offset,
          child: Align(
            alignment: Alignment.topLeft,
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
  final List<fluent.CommandBarItem> items;
  final double width;
  final Color backgroundColor;
  final Color borderColor;

  const AnimatedDropdownList({
    super.key,
    required this.items,
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                color: Colors.black.withOpacity(0.2),
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
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                children: widget.items.map((item) {
                  if (item is fluent.CommandBarButton) {
                    return _buildMenuItem(item);
                  } else if (item is fluent.CommandBarSeparator) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(height: 1, thickness: 1, color: Colors.grey),
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(fluent.CommandBarButton item) {
    // Custom hover button implementation to ensure consistent styling
    return _HoverSelectButton(
      onPressed: item.onPressed,
      child: item.label ?? const SizedBox(),
      trailing: item.icon,
    );
  }
}

class _HoverSelectButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? trailing;

  const _HoverSelectButton({
    required this.onPressed,
    required this.child,
    this.trailing,
  });

  @override
  State<_HoverSelectButton> createState() => _HoverSelectButtonState();
}

class _HoverSelectButtonState extends State<_HoverSelectButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovering = true),
        onExit: (_) => setState(() => isHovering = false),
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isHovering ? theme.resources.subtleFillColorSecondary : Colors.transparent,
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: theme.typography.body?.color,
                    fontSize: 14,
                  ),
                  child: widget.child,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                IconTheme(
                  data: IconThemeData(
                    size: 14,
                    color: theme.accentColor,
                  ),
                  child: widget.trailing!,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
