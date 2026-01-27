import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../chat_provider.dart';
import '../../../settings/presentation/settings_provider.dart';

import '../widgets/chat_view.dart';
import '../widgets/mobile_preset_selector.dart';
import '../../../settings/presentation/mobile_settings_page.dart';
import '../../../settings/presentation/mobile_user_page.dart';
import '../../../settings/presentation/mobile_app_settings_page.dart';
import '../mobile_translation_page.dart';
import '../widgets/cached_page_stack.dart';
import 'mobile_navigation_drawer.dart';
import '../../../skills/presentation/mobile_skills_page.dart';
import '../../../studio/presentation/pages/mobile_studio_page.dart';
import '../../../../shared/widgets/custom_toast.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/number_format_utils.dart';

class MobileChatScreen extends ConsumerStatefulWidget {
  const MobileChatScreen({super.key});
  @override
  ConsumerState<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends ConsumerState<MobileChatScreen> {
  static const String keySettings = '__settings__';
  static const String keyAppSettings = '__app_settings__';
  static const String keyTranslation = '__translation__';
  static const String keyUser = '__user__';
  static const String keyStudio = '__studio__';
  static const String keySkills = '__skills__';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentViewKey = 'new_chat';
  String _lastSessionId = 'new_chat';
  DateTime? _lastPopTime;
  double? _dragStartX;
  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedHistorySessionIdProvider);
    if (selected != null) {
      _currentViewKey = selected;
      _lastSessionId = selected;
    }
  }

  Future<void> _navigateTo(String key) async {
    if (_isSpecialKey(key)) {
      final currentId = ref.read(selectedHistorySessionIdProvider);
      if (currentId != null) {
        await ref
            .read(sessionsProvider.notifier)
            .cleanupSessionIfEmpty(currentId);
      }
    }
    setState(() {
      _currentViewKey = key;
      if (!_isSpecialKey(key)) {
        _lastSessionId = key;
        ref.read(selectedHistorySessionIdProvider.notifier).state = key;
      }
    });
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _navigateBackToSession() {
    setState(() {
      _currentViewKey = _lastSessionId;
      ref.read(selectedHistorySessionIdProvider.notifier).state =
          _lastSessionId;
    });
  }

  bool _isSpecialKey(String key) {
    return key == keySettings || key == keyTranslation || key == keyUser || key == keyStudio || key == keyAppSettings || key == keySkills;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(selectedHistorySessionIdProvider, (prev, next) {
      if (next != null &&
          next != _currentViewKey &&
          !_isSpecialKey(_currentViewKey)) {
        setState(() {
          _currentViewKey = next;
          _lastSessionId = next;
        });
      } else if (next != null && _isSpecialKey(_currentViewKey)) {
        _lastSessionId = next;
      }
    });
    final settingsState = ref.watch(settingsProvider);
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    final sessionsState = ref.watch(sessionsProvider);
    String sessionTitle = AppLocalizations.of(context)!.startNewChat;
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
    final backgroundGradient = _getBackgroundGradient(settingsState.backgroundColor, isDark);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          if (backgroundGradient != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: backgroundGradient,
                  ),
                ),
              ),
            ),
          Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.25,
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
            body: fluent.NavigationPaneTheme(
              data: fluent.NavigationPaneThemeData(
                backgroundColor: isDark
                    ? fluent.FluentTheme.of(context).scaffoldBackgroundColor
                    : Colors.transparent,
              ),
              child: CachedPageStack(
                selectedKey: _currentViewKey,
                cacheSize: 10,
                itemBuilder: (context, key) {
                  if (key == keySettings) {
                    return MobileSettingsPage(onBack: _navigateBackToSession);
                  } else if (key == keyAppSettings) {
                    return MobileAppSettingsPage(onBack: _navigateBackToSession);
                  } else if (key == keyTranslation) {
                    return MobileTranslationPage(
                        onBack: _navigateBackToSession);
                  } else if (key == keyUser) {
                    return MobileUserPage(onBack: _navigateBackToSession);
                  } else if (key == keyStudio) {
                    return MobileStudioPage(onBack: _navigateBackToSession);
                  } else if (key == keySkills) {
                    return MobileSkillsPage(onBack: _navigateBackToSession);
                  } else {
                    return _buildSessionPage(
                        context,
                        key,
                        sessionTitle,
                        settingsState,
                        sessionsState,
                        selectedSessionId,
                        isDark);
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
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      return true;
    }
    if (_isSpecialKey(_currentViewKey)) {
      _navigateBackToSession();
      return false;
    }
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
    return true;
  }

  Widget _buildSessionPage(
      BuildContext context,
      String sessionId,
      String sessionTitle,
      SettingsState settingsState,
      SessionsState sessionsState,
      String? selectedSessionId,
      bool isDark) {
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
            final sessionsState = ref.watch(sessionsProvider);
            String dynamicTitle = sessionTitle;
            int totalTokens = 0;
            if (sessionId != 'new_chat' && sessionsState.sessions.isNotEmpty) {
              final sessionMatch =
                  sessionsState.sessions.where((s) => s.sessionId == sessionId);
              if (sessionMatch.isNotEmpty) {
                dynamicTitle = sessionMatch.first.title;
                totalTokens = sessionMatch.first.totalTokens;
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                dynamicTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (totalTokens > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${formatTokenCount(totalTokens)} tokens',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
          if (sessionId != 'new_chat')
            MobilePresetSelector(sessionId: sessionId),
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
    final hasAnyModels =
        providers.any((p) => p.isEnabled && p.models.isNotEmpty);
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
                        for (final model in provider.models)
                          if (provider.isModelEnabled(model))
                            ListTile(
                              contentPadding:
                                  const EdgeInsets.only(left: 32, right: 16),
                              leading: Icon(
                                activeProvider?.id == provider.id &&
                                        selectedModel == model
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: activeProvider?.id == provider.id &&
                                        selectedModel == model
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                              title: Text(model),
                              onTap: () async {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .selectProvider(provider.id);
                                await ref
                                    .read(settingsProvider.notifier)
                                    .setSelectedModel(model);
                                Navigator.pop(ctx);
                              },
                            ),
                        if (provider !=
                            providers
                                .where(
                                    (p) => p.isEnabled && p.models.isNotEmpty)
                                .last)
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

  List<Color>? _getBackgroundGradient(String style, bool isDark) {
    if (style == 'pure_black') {
      return isDark ? [const Color(0xFF000000), const Color(0xFF000000)] : null;
    }
    
    final gradients = <String, (List<Color>, List<Color>)>{
      'default': ([const Color(0xFF2B2B2B), const Color(0xFF2B2B2B)], [const Color(0xFFE0F7FA), const Color(0xFFF1F8E9)]),
      'warm': ([const Color(0xFF1E1C1A), const Color(0xFF2E241E)], [const Color(0xFFFFF8F0), const Color(0xFFFFEBD6)]),
      'cool': ([const Color(0xFF1A1C1E), const Color(0xFF1E252E)], [const Color(0xFFF0F8FF), const Color(0xFFD6EAFF)]),
      'rose': ([const Color(0xFF2D1A1E), const Color(0xFF3B1E26)], [const Color(0xFFFFF0F5), const Color(0xFFFFD6E4)]),
      'lavender': ([const Color(0xFF1F1A2D), const Color(0xFF261E3B)], [const Color(0xFFF3E5F5), const Color(0xFFE6D6FF)]),
      'mint': ([const Color(0xFF1A2D24), const Color(0xFF1E3B2E)], [const Color(0xFFE0F2F1), const Color(0xFFC2E8DC)]),
      'sky': ([const Color(0xFF1A202D), const Color(0xFF1E263B)], [const Color(0xFFE1F5FE), const Color(0xFFC7E6FF)]),
      'gray': ([const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)], [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)]),
      'sunset': ([const Color(0xFF1A0B0E), const Color(0xFF4A1F28)], [const Color(0xFFFFF3E0), const Color(0xFFFFCCBC)]),
      'ocean': ([const Color(0xFF05101A), const Color(0xFF0D2B42)], [const Color(0xFFE1F5FE), const Color(0xFF81D4FA)]),
      'forest': ([const Color(0xFF051408), const Color(0xFF0E3316)], [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)]),
      'dream': ([const Color(0xFF120817), const Color(0xFF261233)], [const Color(0xFFF3E5F5), const Color(0xFFBBDEFB)]),
      'aurora': ([const Color(0xFF051715), const Color(0xFF181533)], [const Color(0xFFE0F2F1), const Color(0xFFD1C4E9)]),
      'volcano': ([const Color(0xFF1F0808), const Color(0xFF3E1212)], [const Color(0xFFFFEBEE), const Color(0xFFFFCCBC)]),
      'midnight': ([const Color(0xFF020205), const Color(0xFF141426)], [const Color(0xFFECEFF1), const Color(0xFF90A4AE)]),
      'dawn': ([const Color(0xFF141005), const Color(0xFF33260D)], [const Color(0xFFFFF8E1), const Color(0xFFFFE082)]),
      'neon': ([const Color(0xFF08181A), const Color(0xFF240C21)], [const Color(0xFFE0F7FA), const Color(0xFFE1BEE7)]),
      'blossom': ([const Color(0xFF1F050B), const Color(0xFF3D0F19)], [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)]),
    };
    
    final gradient = gradients[style];
    if (gradient == null) return isDark ? null : [const Color(0xFFE0F7FA), const Color(0xFFF1F8E9)];
    return isDark ? gradient.$1 : gradient.$2;
  }
}
