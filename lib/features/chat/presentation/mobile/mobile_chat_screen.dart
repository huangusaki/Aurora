import 'dart:async';
import 'package:aurora/shared/theme/aurora_icons.dart';
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
import '../../../sync/presentation/mobile_sync_settings_page.dart';
import '../mobile_translation_page.dart';
import '../widgets/cached_page_stack.dart';
import 'mobile_navigation_drawer.dart';
import '../../../assistant/presentation/mobile_assistant_page.dart';
import '../../../studio/presentation/pages/mobile_studio_page.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/number_format_utils.dart';
import 'package:aurora/shared/theme/chat_background_theme.dart';
import 'package:aurora/shared/widgets/aurora_bottom_sheet.dart';
import 'package:aurora/shared/widgets/aurora_notice.dart';

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
  static const String keyBackup = '__backup__';
  static const String keyStudio = '__studio__';
  static const String keyAssistant = '__assistant__';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentViewKey = 'new_chat';
  String _lastSessionId = 'new_chat';
  DateTime? _lastPopTime;
  Timer? _exitTimer;
  bool _isDrawerOpen = false;

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

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
    FocusManager.instance.primaryFocus?.unfocus();
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
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentViewKey = _lastSessionId;
      ref.read(selectedHistorySessionIdProvider.notifier).state =
          _lastSessionId;
    });
  }

  bool _isSpecialKey(String key) {
    return key == keySettings ||
        key == keyTranslation ||
        key == keyUser ||
        key == keyStudio ||
        key == keyAppSettings ||
        key == keyBackup ||
        key == keyAssistant;
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
      } else if (next == null && !_isSpecialKey(_currentViewKey)) {
        setState(() {
          _currentViewKey = 'new_chat';
          _lastSessionId = 'new_chat';
        });
      }
    });
    final settingsState = ref.watch(settingsProvider);
    final selectedSessionId = ref.watch(selectedHistorySessionIdProvider);
    final sessionsState = ref.watch(sessionsProvider);
    String sessionTitle = AppLocalizations.of(context)!.startNewChat;

    if (selectedSessionId != null &&
        selectedSessionId != 'new_chat' &&
        !sessionsState.isLoading) {
      final sessionMatch =
          sessionsState.sessions.where((s) => s.sessionId == selectedSessionId);
      if (sessionMatch.isNotEmpty) {
        sessionTitle = sessionMatch.first.title;
      } else if (sessionsState.sessions.isEmpty) {
        // Fallback for unexpected empty store during state sync
        sessionTitle = AppLocalizations.of(context)!.startNewChat;
      }
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundGradient = ChatBackgroundTheme.getGradient(
      settingsState.backgroundColor,
      isDark: isDark,
    );
    final bool isSpecialView = _isSpecialKey(_currentViewKey);
    final bool isFirstRoute = ModalRoute.of(context)?.isFirst ?? true;
    final bool canPop = _isDrawerOpen ||
        (!isSpecialView && (!isFirstRoute || _lastPopTime != null));
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isSpecialKey(_currentViewKey)) {
          _navigateBackToSession();
          return;
        }
        final now = DateTime.now();
        if (_lastPopTime == null ||
            now.difference(_lastPopTime!) > const Duration(seconds: 2)) {
          _lastPopTime = now;
          showAuroraNotice(
            context,
            AppLocalizations.of(context)!.pressAgainToExit,
            icon: AuroraIcons.info,
            top: MediaQuery.of(context).padding.top + 64 + 60,
          );
          _exitTimer?.cancel();
          _exitTimer = Timer(const Duration(seconds: 2), () {
            if (!mounted) return;
            setState(() => _lastPopTime = null);
          });
          setState(() {});
        }
      },
      child: Stack(
        children: [
          if (backgroundGradient != null &&
              (!settingsState.useCustomTheme ||
                  settingsState.backgroundImagePath == null ||
                  settingsState.backgroundImagePath!.isEmpty))
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
            onDrawerChanged: (isOpened) {
              if (_isDrawerOpen != isOpened) {
                setState(() => _isDrawerOpen = isOpened);
              }
              if (isOpened) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },
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
                backgroundColor:
                    fluent.FluentTheme.of(context).scaffoldBackgroundColor,
              ),
              child: CachedPageStack(
                selectedKey: _currentViewKey,
                cacheSize: 10,
                itemBuilder: (context, key) {
                  if (key == keySettings) {
                    return MobileSettingsPage(onBack: _navigateBackToSession);
                  } else if (key == keyAppSettings) {
                    return MobileAppSettingsPage(
                        onBack: _navigateBackToSession);
                  } else if (key == keyTranslation) {
                    return MobileTranslationPage(
                        onBack: _navigateBackToSession);
                  } else if (key == keyUser) {
                    return MobileUserPage(onBack: _navigateBackToSession);
                  } else if (key == keyStudio) {
                    return MobileStudioPage(onBack: _navigateBackToSession);
                  } else if (key == keyBackup) {
                    return MobileSyncSettingsPage(
                        onBack: _navigateBackToSession);
                  } else if (key == keyAssistant) {
                    return MobileAssistantPage(onBack: _navigateBackToSession);
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
                  const SizedBox(width: 14),
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
                                      .withValues(alpha: 0.1),
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
                                currentSettings.selectedModel ??
                                    AppLocalizations.of(context)!
                                        .modelNotSelected,
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
            tooltip: AppLocalizations.of(context)!.newChat,
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
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.read(settingsProvider);
    final providers = settingsState.providers;
    final activeProvider = settingsState.activeProvider;
    final selectedModel = settingsState.selectedModel;
    final hasAnyModels =
        providers.any((p) => p.isEnabled && p.models.isNotEmpty);
    if (!hasAnyModels) {
      showAuroraNotice(
        context,
        l10n.pleaseConfigureModel,
        icon: AuroraIcons.info,
        top: MediaQuery.of(context).padding.top + 64 + 60,
      );
      return;
    }
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuroraBottomSheet.buildTitle(context, l10n.switchModel),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Model Section
                    ListTile(
                      dense: true,
                      enabled: false,
                      title: Text(
                        l10n.selectModel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
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
                            AuroraBottomSheet.buildListItem(
                              context: context,
                              leading: Icon(
                                activeProvider.id == provider.id &&
                                        selectedModel == model
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: activeProvider.id == provider.id &&
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
                                if (context.mounted) Navigator.pop(ctx);
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
    final l10n = AppLocalizations.of(context)!;
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
    final modeLabel = next == 'light'
        ? l10n.lightMode
        : (next == 'dark' ? l10n.darkMode : l10n.followSystem);
    showAuroraNotice(
      context,
      l10n.switchedToTheme(modeLabel),
      icon: AuroraIcons.info,
      top: MediaQuery.of(context).padding.top + 64 + 60,
    );
  }

  void _showAboutDialog() {
    final l10n = AppLocalizations.of(context)!;
    AuroraBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuroraBottomSheet.buildTitle(context, l10n.appTitle),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.stars, size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                Text('${l10n.version}: v1.0.0',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(l10n.appTagline, textAlign: TextAlign.center),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
