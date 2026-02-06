import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class AuroraNotice {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
    double? top,
  }) {
    _timer?.cancel();
    _entry?.remove();

    final overlay = Overlay.of(context, rootOverlay: true);
    final fluentTheme = fluent.FluentTheme.maybeOf(context);
    final materialTheme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final cardColor =
        fluentTheme?.cardColor ?? materialTheme.colorScheme.surface;
    final borderColor = fluentTheme?.resources.dividerStrokeColorDefault ??
        materialTheme.colorScheme.outlineVariant.withValues(alpha: 0.7);
    final textColor = fluentTheme?.typography.body?.color ??
        materialTheme.colorScheme.onSurface;
    final iconColor = materialTheme.colorScheme.primary;
    final topOffset = top ?? mediaQuery.padding.top + 60;

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        top: topOffset,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - value)),
                  child: child,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: iconColor),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

void showAuroraNotice(
  BuildContext context,
  String message, {
  IconData? icon,
  Duration duration = const Duration(seconds: 2),
  double? top,
}) {
  AuroraNotice.show(
    context,
    message: message,
    icon: icon,
    duration: duration,
    top: top,
  );
}
