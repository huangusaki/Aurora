import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../chat_provider.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../history/presentation/history_content.dart';
import '../widgets/chat_view.dart';
import '../../../settings/presentation/mobile_settings_page.dart';
import '../../../settings/presentation/mobile_user_page.dart';
import '../mobile_translation_page.dart';

class MobileChatScreen extends ConsumerStatefulWidget {
  const MobileChatScreen({super.key});

  @override
  ConsumerState<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends ConsumerState<MobileChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    final sessionsState = ref.watch(sessionsProvider);
    String sessionTitle = '新对话';
    if (selectedSessionId != null &&
        selectedSessionId != 'new_chat' &&
        sessionsState.sessions.isNotEmpty) {
      final sessionMatch =
          sessionsState.sessions.where((s) => s.sessionId == selectedSessionId);
      if (sessionMatch.isNotEmpty) {
        sessionTitle = sessionMatch.first.title;
      }
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: !isDark,
      backgroundColor: isDark
          ? fluent.FluentTheme.of(context).scaffoldBackgroundColor
          : Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 26),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openModelSwitcher,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sessionTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            settingsState.selectedModel ?? '未选择模型',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            size: 18, color: Colors.grey[600]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 26),
            tooltip: '新对话',
            onPressed: () {
              ref.read(selectedHistorySessionIdProvider.notifier).state =
                  'new_chat';
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
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
                            ref
                                .read(sessionSearchQueryProvider.notifier)
                                .state = value;
                          },
                          decoration: InputDecoration(
                            hintText: '搜索聊天记录',
                            hintStyle: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                size: 20, color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () {
                        ref.read(sessionSearchQueryProvider.notifier).state =
                            '';
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: InkWell(
                  onTap: () {
                    ref.read(selectedHistorySessionIdProvider.notifier).state =
                        'new_chat';
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
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
                child: SessionListWidget(
                  sessionsState: sessionsState,
                  selectedSessionId: selectedSessionId,
                  onSessionSelected: (sessionId) {
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
                          .state = 'new_chat';
                    }
                  },
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
                          _MobileDrawerNavItem(
                            icon: Icons.person_outline,
                            label: '用户',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const MobileUserPage()));
                            },
                          ),
                          _MobileDrawerNavItem(
                            icon: Icons.translate,
                            label: '翻译',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MobileTranslationPage()));
                            },
                          ),
                          _MobileDrawerNavItem(
                            icon: _getThemeIcon(
                                ref.watch(settingsProvider).themeMode),
                            label: '主题',
                            onTap: () {
                              _cycleTheme();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MobileDrawerNavItem(
                            icon: Icons.cloud_outlined,
                            label: '模型',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MobileSettingsPage()));
                            },
                          ),
                          _MobileDrawerNavItem(
                            icon: Icons.link_outlined,
                            label: '其它',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('敬请期待'),
                                    duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                          _MobileDrawerNavItem(
                            icon: Icons.info_outline,
                            label: '关于',
                            onTap: () {
                              Navigator.pop(context);
                              _showAboutDialog();
                            },
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
      ),
      body: Container(
        decoration: !isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE0F7FA), Color(0xFFF1F8E9)],
                ),
              )
            : null,
        child: Padding(
          padding: EdgeInsets.only(
              top: !isDark ? 64 + MediaQuery.of(context).padding.top : 0),
          child: ChatView(key: ValueKey(selectedSessionId)),
        ),
      ),
    );
  }

  void _openModelSwitcher() {
    final settingsState = ref.read(settingsProvider);
    final provider = settingsState.activeProvider;
    if (provider == null || provider.models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置模型')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('选择模型',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.models.length,
                  itemBuilder: (context, index) {
                    final model = provider.models[index];
                    final isSelected = model == settingsState.selectedModel;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                      title: Text(model),
                      onTap: () {
                        ref.read(settingsProvider.notifier).updateProvider(
                              id: provider.id,
                              selectedModel: model,
                            );
                        ref
                            .read(settingsProvider.notifier)
                            .selectProvider(provider.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

  void _cycleTheme() {
    final current = ref.read(settingsProvider).themeMode;
    String next;
    switch (current) {
      case 'system':
        next = 'light';
        break;
      case 'light':
        next = 'dark';
        break;
      default:
        next = 'system';
    }
    ref.read(settingsProvider.notifier).setThemeMode(next);
    final message =
        next == 'light' ? '浅色模式' : (next == 'dark' ? '深色模式' : '跟随系统');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('已切换到$message'), duration: const Duration(seconds: 1)),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.stars, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Aurora'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: v1.0.0'),
            SizedBox(height: 8),
            Text('一款优雅的跨平台 AI 对话助手'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
