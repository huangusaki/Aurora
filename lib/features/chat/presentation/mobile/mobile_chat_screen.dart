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
import '../../../../shared/widgets/custom_toast.dart';

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

  DateTime? _lastPopTime;

  @override
  void initState() {
    super.initState();
    // Initialize session ID from provider on load if valid
    final selected = ref.read(selectedHistorySessionIdProvider);
    if (selected != null) {
      _currentViewKey = selected;
      _lastSessionId = selected;
    }
  }

  Future<void> _navigateTo(String key) async {
    // If we are navigating away from a session to a special page (Settings, etc)
    // OR we are navigating to a different session, we should check cleanup
    
    // Note: If navigating to a different session via Drawer, the Drawer callback might have already handled it.
    // But _navigateTo is also used for User/Settings/Translation pages.
    
    if (_isSpecialKey(key)) {
       final currentId = ref.read(selectedHistorySessionIdProvider);
       if (currentId != null) {
         await ref.read(sessionsProvider.notifier).cleanupSessionIfEmpty(currentId);
       }
    }

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
      if (mounted) Navigator.pop(context);
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
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
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
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // If drawer is open, let Scaffold handle it (it usually closes drawer on back)
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      return true;
    }

    if (_isSpecialKey(_currentViewKey)) {
      _navigateBackToSession();
      return false; // Prevent exit, just navigate back
    }

    // In Chat Session
    final now = DateTime.now();
    if (_lastPopTime == null || 
        now.difference(_lastPopTime!) > const Duration(seconds: 2)) {
      _lastPopTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再按一次退出应用'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true; // Exit app
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
        title: Consumer(
          builder: (context, ref, _) {
            final currentSettings = ref.watch(settingsProvider);
            final sessionsState = ref.watch(sessionsProvider); // Watch sessions
            
            // Re-calculate title dynamically
            String dynamicTitle = sessionTitle; // Default/Fallback
            if (sessionId != 'new_chat' && sessionsState.sessions.isNotEmpty) {
               final sessionMatch = sessionsState.sessions.where((s) => s.sessionId == sessionId);
               if (sessionMatch.isNotEmpty) {
                 dynamicTitle = sessionMatch.first.title;
               }
            }

            return GestureDetector(
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
                          dynamicTitle,
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
                                currentSettings.selectedModel ?? '未选择模型',
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
            );
          },
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
    final providers = settingsState.providers;
    final activeProvider = settingsState.activeProvider;
    final selectedModel = settingsState.selectedModel;
    
    // Check if any provider has models
    final hasAnyModels = providers.any((p) => p.isEnabled && p.models.isNotEmpty);
    if (!hasAnyModels) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置模型')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
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
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final provider in providers) ...[
                      if (provider.isEnabled && provider.models.isNotEmpty) ...[
                        // Provider header
                        ListTile(
                          dense: true,
                          enabled: false,
                          title: Text(
                            provider.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        // Models under this provider
                        for (final model in provider.models)
                          ListTile(
                            contentPadding: const EdgeInsets.only(left: 32, right: 16),
                            leading: Icon(
                              activeProvider?.id == provider.id && selectedModel == model
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: activeProvider?.id == provider.id && selectedModel == model
                                  ? Theme.of(context).primaryColor
                                  : null,
                            ),
                            title: Text(model),
                            onTap: () async {
                              await ref.read(settingsProvider.notifier).selectProvider(provider.id);
                              await ref.read(settingsProvider.notifier).setSelectedModel(model);
                              Navigator.pop(ctx);
                            },
                          ),
                        // Divider after each provider (except last)
                        if (provider != providers.where((p) => p.isEnabled && p.models.isNotEmpty).last)
                          const Divider(),
                      ],
                    ],
                  ],
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
    showTopToast(context, '已切换到$message');
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

