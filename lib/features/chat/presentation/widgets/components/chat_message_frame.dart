import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class ChatMessageFrame extends StatelessWidget {
  const ChatMessageFrame({
    super.key,
    required this.isUser,
    required this.settingsState,
    required this.theme,
    required this.body,
    this.header,
    this.leadingAvatar,
    this.trailingAvatar,
    this.reserveLeadingAvatarSpace = false,
    this.isEditing = false,
    this.margin,
    this.desktopActionItems = const <Widget>[],
    this.mobileActionItems = const <Widget>[],
    this.showDesktopActions = true,
    this.showMobileActions = true,
    this.maintainDesktopActionSpace = false,
    this.bodyPadding = const EdgeInsets.all(12),
    this.desktopActionsPadding,
    this.mobileActionsPadding,
  });

  final bool isUser;
  final SettingsState settingsState;
  final fluent.FluentThemeData theme;
  final Widget body;
  final Widget? header;
  final Widget? leadingAvatar;
  final Widget? trailingAvatar;
  final bool reserveLeadingAvatarSpace;
  final bool isEditing;
  final EdgeInsetsGeometry? margin;
  final List<Widget> desktopActionItems;
  final List<Widget> mobileActionItems;
  final bool showDesktopActions;
  final bool showMobileActions;
  final bool maintainDesktopActionSpace;
  final EdgeInsetsGeometry bodyPadding;
  final EdgeInsetsGeometry? desktopActionsPadding;
  final EdgeInsetsGeometry? mobileActionsPadding;

  bool get _hasBackground =>
      settingsState.useCustomTheme &&
      settingsState.backgroundImagePath != null &&
      settingsState.backgroundImagePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cardColor = _hasBackground
        ? theme.cardColor.withValues(alpha: 0.55)
        : theme.cardColor;

    final frame = Container(
      margin: margin ??
          EdgeInsets.only(
            top: 8,
            bottom: 16,
            left: PlatformUtils.isDesktop ? 10 : 2,
            right: PlatformUtils.isDesktop ? 10 : 2,
          ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                if (leadingAvatar != null) ...[
                  leadingAvatar!,
                  const SizedBox(width: 8),
                ] else if (reserveLeadingAvatarSpace)
                  const SizedBox(width: 40),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (header != null) header!,
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 0),
                      child: Container(
                        padding: isEditing ? EdgeInsets.zero : bodyPadding,
                        decoration: BoxDecoration(
                          color:
                              isEditing ? fluent.Colors.transparent : cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: isEditing
                              ? null
                              : Border.all(
                                  color: theme
                                      .resources.dividerStrokeColorDefault),
                        ),
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUser && trailingAvatar != null) ...[
                const SizedBox(width: 8),
                trailingAvatar!,
              ],
            ],
          ),
          _buildDesktopActions(),
          _buildMobileActions(),
        ],
      ),
    );

    return MouseRegion(child: frame);
  }

  Widget _buildDesktopActions() {
    if (!PlatformUtils.isDesktop) {
      return const SizedBox.shrink();
    }
    final strip = _buildActionStrip(
      items: desktopActionItems,
      padding: desktopActionsPadding ??
          EdgeInsets.only(
            top: 4,
            left: isUser ? 0 : 40,
            right: isUser ? 40 : 0,
          ),
    );
    if (maintainDesktopActionSpace) {
      return Visibility(
        visible: showDesktopActions,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: strip,
      );
    }
    return showDesktopActions ? strip : const SizedBox.shrink();
  }

  Widget _buildMobileActions() {
    if (PlatformUtils.isDesktop) {
      return const SizedBox.shrink();
    }
    if (!showMobileActions || mobileActionItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildActionStrip(
      items: mobileActionItems,
      padding: mobileActionsPadding ??
          EdgeInsets.only(
            top: 4,
            left: isUser ? 0 : 40,
            right: isUser ? 40 : 0,
          ),
      isCompact: true,
    );
  }

  Widget _buildActionStrip({
    required List<Widget> items,
    required EdgeInsetsGeometry padding,
    bool isCompact = false,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[];
    for (int i = 0; i < items.length; i += 1) {
      if (i > 0) {
        children.add(SizedBox(width: isCompact ? 0 : 4));
      }
      children.add(items[i]);
    }

    return Padding(
      padding: padding,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
