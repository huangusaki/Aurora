import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../chat_provider.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../settings/presentation/usage_stats_view.dart';
import '../../../history/presentation/history_content.dart';

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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          ref.read(sessionSearchQueryProvider.notifier).state = value;
                        },
                        decoration: InputDecoration(
                          hintText: '搜索聊天记录',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: InkWell(
                onTap: () {
                  onNewChat();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Text('新对话',
                          style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              // Wrap List in RepaintBoundary to isolate list updates from drawer structure
              child: RepaintBoundary(
                child: SessionListWidget(
                  sessionsState: sessionsState,
                  selectedSessionId: selectedSessionId,
                  onSessionSelected: (sessionId) async {
                    final currentId = ref.read(selectedHistorySessionIdProvider);
                    if (currentId != null && currentId != sessionId) {
                      await ref.read(sessionsProvider.notifier).cleanupSessionIfEmpty(currentId);
                    }
                    ref.read(selectedHistorySessionIdProvider.notifier).state = sessionId;
                    Navigator.pop(context);
                  },
                  onSessionDeleted: (sessionId) {
                    ref.read(sessionsProvider.notifier).deleteSession(sessionId);
                    if (sessionId == selectedSessionId) {
                      ref.read(selectedHistorySessionIdProvider.notifier).state = 'new_chat';
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
                        color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MobileDrawerNavItem(
                            icon: Icons.person_outline,
                            label: '用户',
                            onTap: () => onNavigate('__user__')),
                        _MobileDrawerNavItem(
                            icon: Icons.translate,
                            label: '翻译',
                            onTap: () => onNavigate('__translation__')),
                        Consumer(builder: (context, ref, _) {
                           return _MobileDrawerNavItem(
                            icon: _getThemeIcon(ref.watch(settingsProvider).themeMode),
                            label: '主题',
                            onTap: onThemeCycle,
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MobileDrawerNavItem(
                            icon: Icons.cloud_outlined,
                            label: '模型',
                            onTap: () => onNavigate('__settings__')),
                        _MobileDrawerNavItem(
                            icon: Icons.analytics_outlined,
                            label: '统计',
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const UsageStatsMobileSheet(),
                              );
                            }),
                        _MobileDrawerNavItem(
                            icon: Icons.info_outline,
                            label: '关于',
                            onTap: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              Navigator.pop(context);
                              await Future.delayed(const Duration(milliseconds: 100));
                              // Show about dialog with project link
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('关于 Aurora'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('一个跨平台 LLM 客户端'),
                                        const SizedBox(height: 16),
                                        InkWell(
                                          onTap: () async {
                                            const url = 'https://github.com/huangusaki/Aurora';
                                            final uri = Uri.parse(url);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            }
                                          },
                                          child: const Row(
                                            children: [
                                              Icon(Icons.code, size: 18),
                                              SizedBox(width: 8),
                                              Text(
                                                'GitHub 项目',
                                                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('关闭'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }),
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
