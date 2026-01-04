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
import '../widgets/cached_page_stack.dart';
import 'mobile_navigation_drawer.dart';

class MobileChatScreen extends ConsumerStatefulWidget {
  const MobileChatScreen({super.key});

  @override
  ConsumerState<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends ConsumerState<MobileChatScreen> {
  // Navigation Keys
  static const String keySettings = '__settings__';
  static const String keyTranslation = '__translation__';
  static const String keyUser = '__user__';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentViewKey = 'new_chat'; // Default to initial session
  String _lastSessionId = 'new_chat';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize session ID from provider on load if valid
    final selected = ref.read(selectedHistorySessionIdProvider);
    if (selected != null) {
      _currentViewKey = selected;
      _lastSessionId = selected;
    }
  }

  void _navigateTo(String key) {
    setState(() {
      _currentViewKey = key;
      // If it's a session key, update the last session reference
      if (!_isSpecialKey(key)) {
        _lastSessionId = key;
        // Also sync provider
        ref.read(selectedHistorySessionIdProvider.notifier).state = key;
      }
    });
    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }
  
  void _navigateBackToSession() {
     setState(() {
       _currentViewKey = _lastSessionId;
       // Sync provider
       ref.read(selectedHistorySessionIdProvider.notifier).state = _lastSessionId;
     });
  }

  bool _isSpecialKey(String key) {
    return key == keySettings || key == keyTranslation || key == keyUser;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider changes to update view key if changed externally (e.g. from drawer)
    ref.listen<String?>(selectedHistorySessionIdProvider, (prev, next) {
      if (next != null && next != _currentViewKey && !_isSpecialKey(_currentViewKey)) {
        setState(() {
          _currentViewKey = next;
          _lastSessionId = next;
        });
      } else if (next != null && _isSpecialKey(_currentViewKey)) {
         // If we are in settings but provider changed (e.g. cleared session), 
         // we update background session ID but don't force nav unless explicit
         _lastSessionId = next;
      }
    });

    final settingsState = ref.watch(settingsProvider);
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    final sessionsState = ref.watch(sessionsProvider);
    
    // Determine title for App Bar (only relevant if showing Session)
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
    
    return Stack(
      children: [
        if (!isDark)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE0F7FA), Color(0xFFF1F8E9)],
                ),
              ),
            ),
          ),
          
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent, // Let gradient show through
          drawer: MobileNavigationDrawer(
            sessionsState: sessionsState,
            selectedSessionId: selectedSessionId,
            onNewChat: () {
               ref.read(sessionsProvider.notifier).startNewSession();
            },
            onNavigate: _navigateTo,
            onThemeCycle: _cycleTheme,
            onAbout: _showAboutDialog,
          ),
          body:  fluent.NavigationPaneTheme(
              data: fluent.NavigationPaneThemeData(
                 backgroundColor: isDark ? fluent.FluentTheme.of(context).scaffoldBackgroundColor : Colors.transparent,
              ),
              child: CachedPageStack(
              selectedKey: _currentViewKey,
              cacheSize: 10,
              itemBuilder: (context, key) {
                if (key == keySettings) {
                  return MobileSettingsPage(onBack: _navigateBackToSession);
                } else if (key == keyTranslation) {
                  return MobileTranslationPage(onBack: _navigateBackToSession);
                } else if (key == keyUser) {
                  return MobileUserPage(onBack: _navigateBackToSession);
                } else {
                  // It's a Session ID
                  return _buildSessionPage(context, key, sessionTitle, settingsState, sessionsState, selectedSessionId, isDark);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionPage(BuildContext context, String sessionId, String sessionTitle, SettingsState settingsState, SessionsState sessionsState, String? selectedSessionId, bool isDark) {
    return Scaffold(
      extendBodyBehindAppBar: !isDark,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 26),
          onPressed: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            await Future.delayed(const Duration(milliseconds: 50));
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            await Future.delayed(const Duration(milliseconds: 50));
            _openModelSwitcher();
          },
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
              ref.read(sessionsProvider.notifier).startNewSession();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
            top: !isDark ? 64 + MediaQuery.of(context).padding.top : 0),
        child: ChatView(key: ValueKey(sessionId), sessionId: sessionId),
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
      isScrollControlled: true, // Allow flexible height up to limits
      useSafeArea: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // Max 70% height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('选择模型',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const Divider(height: 1),
              Flexible( // Use Flexible to let list adapt and scroll
                child: ListView.builder(
                  shrinkWrap: true, // Adapts to content size
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

