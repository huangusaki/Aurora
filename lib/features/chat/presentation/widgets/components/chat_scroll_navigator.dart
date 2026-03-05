import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class ChatScrollNavigator extends StatelessWidget {
  final bool visible;
  final VoidCallback onJumpToTop;
  final VoidCallback onJumpToPrev;
  final VoidCallback onJumpToNext;
  final VoidCallback onJumpToBottom;

  const ChatScrollNavigator({
    super.key,
    required this.visible,
    required this.onJumpToTop,
    required this.onJumpToPrev,
    required this.onJumpToNext,
    required this.onJumpToBottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final iconColor = theme.typography.body?.color?.withValues(alpha: 0.85) ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.85));


    Widget buildButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      if (PlatformUtils.isDesktop) {
        return fluent.Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 32,
            height: 32,
            child: fluent.IconButton(
              icon: fluent.Icon(icon, size: 14, color: iconColor),
              onPressed: onPressed,
            ),
          ),
        );
      }
      return Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 16, color: iconColor),
            onPressed: onPressed,
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.1),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildButton(
                      icon: AuroraIcons.chevronsUp,
                      tooltip: l10n.chatJumpToTop,
                      onPressed: onJumpToTop,
                    ),
                    const SizedBox(height: 2),
                    buildButton(
                      icon: AuroraIcons.chevronUp,
                      tooltip: l10n.chatJumpToPrevMessage,
                      onPressed: onJumpToPrev,
                    ),
                    const SizedBox(height: 4),
                    buildButton(
                      icon: AuroraIcons.chevronDown,
                      tooltip: l10n.chatJumpToNextMessage,
                      onPressed: onJumpToNext,
                    ),
                    const SizedBox(height: 4),
                    buildButton(
                      icon: AuroraIcons.chevronsDown,
                      tooltip: l10n.chatJumpToBottom,
                      onPressed: onJumpToBottom,
                    ),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }
}

