import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../chat_provider.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../settings/presentation/usage_stats_view.dart';
import '../../../history/presentation/history_content.dart';
import '../widgets/topic_dropdown.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../../../sync/presentation/mobile_sync_settings_page.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
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
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
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
                        Expanded(
                          child: _MobileDrawerNavItem(
                            icon: _getThemeIcon(ref.watch(settingsProvider).themeMode),
                            label: AppLocalizations.of(context)!.theme,
                            onTap: onThemeCycle,
                          ),
                        ),
                        Expanded(
                          child: _MobileDrawerNavItem(
                              icon: Icons.cloud_sync_outlined,
                              label: AppLocalizations.of(context)!.backup,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const MobileSyncSettingsPage()),
                                );
                              }),
                        ),
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
                              icon: Icons.work_outline,
                              label: AppLocalizations.of(context)!.studio,
                              onTap: () => onNavigate('__studio__')),
                        ),
                        Expanded(
                          child: _MobileDrawerNavItem(
                              icon: Icons.settings_outlined,
                              label: AppLocalizations.of(context)!.settings,
                              onTap: () => onNavigate('__app_settings__')),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Text(label, 
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
