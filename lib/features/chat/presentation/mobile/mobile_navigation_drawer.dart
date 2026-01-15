import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../chat_provider.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../settings/presentation/usage_stats_view.dart';
import '../../../history/presentation/history_content.dart';
import '../widgets/topic_dropdown.dart';
import 'package:aurora/l10n/app_localizations.dart';

class MobileNavigationDrawer extends ConsumerWidget {
  final SessionsState sessionsState;
  final String? selectedSessionId;
  final VoidCallback onNewChat;
  final Function(String) onNavigate;
  final VoidCallback onThemeCycle;
  final VoidCallback onAbout;
  const MobileNavigationDrawer({
    super.key,
    required this.sessionsState,
    required this.selectedSessionId,
    required this.onNewChat,
    required this.onNavigate,
    required this.onThemeCycle,
    required this.onAbout,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          ref.read(sessionSearchQueryProvider.notifier).state =
                              value;
                        },
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.searchChatHistory,
                          hintStyle:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              size: 20, color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () {
                      ref.read(sessionSearchQueryProvider.notifier).state = '';
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: TopicDropdown(isMobile: true),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: fluent.HoverButton(
                onPressed: () {
                  onNewChat();
                  Navigator.pop(context);
                },
                builder: (context, states) {
                  final theme = fluent.FluentTheme.of(context);
                  final isHovering = states.isHovered;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isHovering
                          ? theme.resources.subtleFillColorSecondary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isHovering
                            ? theme.resources.surfaceStrokeColorDefault
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(fluent.FluentIcons.add,
                            size: 14, color: theme.accentColor),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)!.startNewChat,
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.typography.body?.color,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        if (isHovering)
                          Icon(fluent.FluentIcons.chevron_right,
                              size: 10,
                              color: theme.resources.textFillColorSecondary),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: RepaintBoundary(
                child: SessionListWidget(
                  sessionsState: sessionsState,
                  selectedSessionId: selectedSessionId,
                  onSessionSelected: (sessionId) async {
                    final currentId =
                        ref.read(selectedHistorySessionIdProvider);
                    if (currentId != null && currentId != sessionId) {
                      await ref
                          .read(sessionsProvider.notifier)
                          .cleanupSessionIfEmpty(currentId);
                    }
                    ref.read(selectedHistorySessionIdProvider.notifier).state =
                        sessionId;
                    Navigator.pop(context);
                  },
                  onSessionDeleted: (sessionId) {
                    ref
                        .read(sessionsProvider.notifier)
                        .deleteSession(sessionId);
                    if (sessionId == selectedSessionId) {
                      ref
                          .read(selectedHistorySessionIdProvider.notifier)
                          .state = null;
                    }
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: fluent.FluentTheme.of(context).scaffoldBackgroundColor,
                border: Border(
                    top: BorderSide(
                        color: fluent.FluentTheme.of(context)
                            .resources
                            .dividerStrokeColorDefault)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _MobileDrawerNavItem(
                              icon: Icons.person_outline,
                              label: AppLocalizations.of(context)!.user,
                              onTap: () => onNavigate('__user__')),
                        ),
                        Expanded(
                          child: _MobileDrawerNavItem(
                              icon: Icons.translate,
                              label: AppLocalizations.of(context)!.translation,
                              onTap: () => onNavigate('__translation__')),
                        ),
                        Consumer(builder: (context, ref, _) {
                          return Expanded(
                            child: _MobileDrawerNavItem(
                              icon: _getThemeIcon(
                                  ref.watch(settingsProvider).themeMode),
                              label: AppLocalizations.of(context)!.theme,
                              onTap: onThemeCycle,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _MobileDrawerNavItem(
                              icon: Icons.cloud_outlined,
                              label: AppLocalizations.of(context)!.model,
                              onTap: () => onNavigate('__settings__')),
                        ),
                        Expanded(
                          child: _MobileDrawerNavItem(
                              icon: Icons.analytics_outlined,
                              label: AppLocalizations.of(context)!.stats,
                              onTap: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      const UsageStatsMobileSheet(),
                                );
                              }),
                        ),
                        Expanded(
                          child: _MobileDrawerNavItem(
                              icon: Icons.info_outline,
                              label: AppLocalizations.of(context)!.about,
                              onTap: () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.pop(context);
                                await Future.delayed(
                                    const Duration(milliseconds: 100));
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(AppLocalizations.of(context)!
                                          .aboutAurora),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(AppLocalizations.of(context)!
                                              .crossPlatformLlmClient),
                                          const SizedBox(height: 16),
                                          InkWell(
                                            onTap: () async {
                                              const url =
                                                  'https://github.com/huangusaki/Aurora';
                                              final uri = Uri.parse(url);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                const Icon(Icons.code,
                                                    size: 18),
                                                const SizedBox(width: 8),
                                                Text(
                                                  AppLocalizations.of(context)!
                                                      .githubProject,
                                                  style: const TextStyle(
                                                      color: Colors.blue,
                                                      decoration: TextDecoration
                                                          .underline),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .close),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon(String themeMode) {
    switch (themeMode) {
      case 'dark':
        return Icons.dark_mode;
      case 'light':
        return Icons.light_mode;
      default:
        return Icons.brightness_auto;
    }
  }
}

class _MobileDrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MobileDrawerNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
