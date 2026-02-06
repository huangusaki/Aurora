import 'dart:io';
import 'package:aurora/shared/utils/platform_utils.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:path/path.dart' as p;
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/features/settings/presentation/settings_content.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/history/presentation/history_content.dart';
import 'package:aurora/features/chat/presentation/widgets/translation_content.dart';
import 'package:aurora/features/chat/presentation/widgets/window_buttons.dart';
import 'package:aurora/features/chat/presentation/widgets/model_selector.dart';
import 'package:aurora/features/chat/presentation/widgets/preset_selector.dart';
import 'package:aurora/features/chat/presentation/widgets/assistant_selector.dart';
import 'package:aurora/features/chat/presentation/widgets/fade_indexed_stack.dart';
import 'package:aurora/features/studio/presentation/studio_content.dart';
import 'package:aurora/features/skills/presentation/skills_page.dart';
import 'package:aurora/features/assistant/presentation/assistant_content.dart';
import 'package:aurora/shared/theme/aurora_icons.dart';
import 'package:aurora/shared/theme/chat_background_theme.dart';
import '../chat_provider.dart';

class DesktopChatScreen extends ConsumerStatefulWidget {
  const DesktopChatScreen({super.key});
  @override
  ConsumerState<DesktopChatScreen> createState() => _DesktopChatScreenState();
}

class _DesktopChatScreenState extends ConsumerState<DesktopChatScreen>
    with WindowListener, TrayListener {
  final _trayManager = TrayManager.instance;
  final _windowManager = WindowManager.instance;

  @override
  void initState() {
    _windowManager.addListener(this);
    _trayManager.addListener(this);
    // 延迟初始化托盘，确保 UI 和上下文已就绪
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTray());
    super.initState();
  }

  @override
  void dispose() {
    _windowManager.removeListener(this);
    _trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initTray() async {
    try {
      String? iconPath;
      if (PlatformUtils.isWindows) {
        final String exePath = Platform.resolvedExecutable;
        final String exeDir = File(exePath).parent.path;
        final List<String> possiblePaths = [
          p.join(exeDir, 'data', 'flutter_assets', 'assets', 'icon',
              'app_icon.ico'),
          p.join(exeDir, 'assets', 'icon', 'app_icon.ico'),
        ];
        for (final path in possiblePaths) {
          if (File(path).existsSync()) {
            iconPath = path;
            break;
          }
        }
      }
      iconPath ??= 'assets/icon/app_icon.ico';
      await _trayManager.setIcon(iconPath);
      await _trayManager.setToolTip('Aurora');

      _updateTrayMenu();

      await _windowManager.setPreventClose(true);
    } catch (e) {
      // 保持静默失败或在非调试模式下忽略
    }
  }

  void _updateTrayMenu() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: l10n.trayShow,
        ),
        MenuItem(
          key: 'exit_app',
          label: l10n.trayExit,
        ),
      ],
    );
    _trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    _windowManager.show();
    _windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    // 获取焦点有助于菜单在点击外部时正常消失
    _windowManager.focus().then((_) {
      _trayManager.popUpContextMenu();
    });
  }

  @override
  void onTrayIconMouseUp() {}

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      _windowManager.show();
      _windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      _windowManager.setPreventClose(false);
      _windowManager.close();
    }
  }

  @override
  void onWindowClose() async {
    final closeBehavior = ref.read(settingsProvider).closeBehavior;

    if (closeBehavior == 1) {
      // 记忆为最小化
      _windowManager.hide();
      return;
    } else if (closeBehavior == 2) {
      // 记忆为退出
      _windowManager.setPreventClose(false);
      _windowManager.close();
      return;
    }

    bool isPreventClose = await _windowManager.isPreventClose();
    if (isPreventClose) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      bool remember = false;

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return fluent.ContentDialog(
                title: Text(l10n.confirmClose),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.minimizeToTray),
                    const SizedBox(height: 16),
                    fluent.Checkbox(
                      checked: remember,
                      onChanged: (v) => setState(() => remember = v ?? false),
                      content: Text(l10n.rememberChoice),
                    ),
                  ],
                ),
                actions: [
                  fluent.Button(
                    onPressed: () {
                      if (remember) {
                        ref.read(settingsProvider.notifier).setCloseBehavior(1);
                      }
                      Navigator.pop(context);
                      _windowManager.hide();
                    },
                    child: Text(l10n.minimize),
                  ),
                  fluent.FilledButton(
                    child: Text(l10n.exit),
                    onPressed: () {
                      if (remember) {
                        ref.read(settingsProvider.notifier).setCloseBehavior(2);
                      }
                      Navigator.pop(context);
                      _windowManager.setPreventClose(false);
                      _windowManager.close();
                    },
                  ),
                  fluent.Button(
                    child: Text(l10n.cancel),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听语言变化以更新托盘菜单
    ref.listen(settingsProvider.select((s) => s.language), (_, __) {
      _updateTrayMenu();
    });

    final theme = fluent.FluentTheme.of(context);
    final settings = ref.watch(settingsProvider);
    final isExpanded = ref.watch(isSidebarExpandedProvider);
    final selectedIndex = ref.watch(desktopActiveTabProvider);
    final l10n = AppLocalizations.of(context)!;
    final navItems = [
      (icon: AuroraIcons.history, label: l10n.history, body: HistoryContent()),
      (
        icon: AuroraIcons.translation,
        label: l10n.textTranslation,
        body: TranslationContent()
      ),
      (
        icon: AuroraIcons.skills,
        label: l10n.agentSkills,
        body: SkillSettingsPage()
      ),
      (icon: AuroraIcons.studio, label: l10n.studio, body: StudioContent()),
      (
        icon: AuroraIcons.settings,
        label: l10n.settings,
        body: SettingsContent()
      ),
      (
        icon: AuroraIcons.robot,
        label: l10n.assistantSystem,
        body: AssistantContent()
      ),
    ];
    String currentSessionId;
    if (selectedIndex == 0) {
      currentSessionId = ref.watch(selectedHistorySessionIdProvider) ?? '';
    } else if (selectedIndex == 1) {
      currentSessionId = 'translation';
    } else {
      currentSessionId = '';
    }
    final backgroundColor =
        ref.watch(settingsProvider.select((s) => s.backgroundColor));

    final isDark = theme.brightness == fluent.Brightness.dark;
    final backgroundGradient =
        ChatBackgroundTheme.getGradient(backgroundColor, isDark: isDark);
    final solidBackgroundColor = ChatBackgroundTheme.getSolidBackgroundColor(
      backgroundColor,
      isDark: isDark,
    );

    return Stack(
      children: [
        if (!settings.useCustomTheme ||
            settings.backgroundImagePath == null ||
            settings.backgroundImagePath!.isEmpty)
          Positioned.fill(
            child: Container(
              color: solidBackgroundColor, // Base color
            ),
          ),
        if (backgroundGradient != null &&
            (!settings.useCustomTheme ||
                settings.backgroundImagePath == null ||
                settings.backgroundImagePath!.isEmpty))
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
        Column(
          children: [
            Container(
              height: 32,
              color: Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 32,
                    child: Center(
                      child: fluent.IconButton(
                        icon: fluent.Icon(AuroraIcons.globalNav, size: 16),
                        onPressed: () {
                          ref
                              .read(isSidebarExpandedProvider.notifier)
                              .update((state) => !state);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const ModelSelector(isWindows: true),
                  if (currentSessionId.isNotEmpty &&
                      currentSessionId != 'translation') ...[
                    const SizedBox(width: 8),
                    PresetSelector(sessionId: currentSessionId),
                  ],
                  const Expanded(
                      child: DragToMoveArea(child: SizedBox.expand())),
                  if (currentSessionId.isNotEmpty &&
                      currentSessionId != 'translation') ...[
                    AssistantSelector(sessionId: currentSessionId),
                    const SizedBox(width: 8),
                  ],
                  const WindowButtons(),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    RepaintBoundary(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        width: isExpanded ? 120 : 40,
                        child: ClipRect(
                          child: OverflowBox(
                            minWidth: 120,
                            maxWidth: 120,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 120,
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: Column(
                                children: [
                                  ...navItems
                                      .take(navItems.length - 2)
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final isSelected = selectedIndex == index;
                                    return fluent.HoverButton(
                                      onPressed: () {
                                        if (index == 0) {
                                          if (selectedIndex == 0) {
                                            ref
                                                .read(
                                                    isHistorySidebarVisibleProvider
                                                        .notifier)
                                                .update((state) => !state);
                                          } else {
                                            ref
                                                .read(desktopActiveTabProvider
                                                    .notifier)
                                                .state = 0;
                                            ref
                                                .read(
                                                    isHistorySidebarVisibleProvider
                                                        .notifier)
                                                .state = true;
                                          }
                                        } else {
                                          ref
                                              .read(desktopActiveTabProvider
                                                  .notifier)
                                              .state = index;
                                        }
                                      },
                                      builder: (context, states) {
                                        return Container(
                                          height: 40,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: states.isHovered
                                                ? theme.resources
                                                    .subtleFillColorSecondary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 26,
                                                height: 36,
                                                margin: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? theme.accentColor
                                                          .withValues(
                                                              alpha: 0.1)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Center(
                                                  child: fluent.Icon(item.icon,
                                                      size: 16,
                                                      color: isSelected
                                                          ? theme.accentColor
                                                          : null),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 0.0),
                                                  child: Text(item.label,
                                                      style: TextStyle(
                                                          color: isSelected
                                                              ? theme
                                                                  .accentColor
                                                              : null,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight
                                                                  .normal),
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  const Spacer(),
                                  Builder(builder: (context) {
                                    final index =
                                        navItems.length - 1; // Assistant
                                    final item = navItems[index];
                                    final isSelected = selectedIndex == index;
                                    return fluent.HoverButton(
                                      onPressed: () => ref
                                          .read(
                                              desktopActiveTabProvider.notifier)
                                          .state = index,
                                      builder: (context, states) {
                                        return Container(
                                          height: 40,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: states.isHovered
                                                ? theme.resources
                                                    .subtleFillColorSecondary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 30,
                                                child: Center(
                                                  child: fluent.Icon(item.icon,
                                                      size: 16,
                                                      color: isSelected
                                                          ? theme.accentColor
                                                          : null),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 0.0),
                                                  child: Text(item.label,
                                                      style: TextStyle(
                                                          color: isSelected
                                                              ? theme
                                                                  .accentColor
                                                              : null,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight
                                                                  .normal),
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  Builder(builder: (context) {
                                    final index =
                                        navItems.length - 2; // Settings
                                    final item = navItems[index];
                                    final isSelected = selectedIndex == index;
                                    return fluent.HoverButton(
                                      onPressed: () => ref
                                          .read(
                                              desktopActiveTabProvider.notifier)
                                          .state = index,
                                      builder: (context, states) {
                                        return Container(
                                          height: 40,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: states.isHovered
                                                ? theme.resources
                                                    .subtleFillColorSecondary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 30,
                                                child: Center(
                                                  child: fluent.Icon(item.icon,
                                                      size: 16,
                                                      color: isSelected
                                                          ? theme.accentColor
                                                          : null),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 0.0),
                                                  child: Text(item.label,
                                                      style: TextStyle(
                                                          color: isSelected
                                                              ? theme
                                                                  .accentColor
                                                              : null,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight
                                                                  .normal),
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                  const SizedBox(height: 4),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final currentTheme =
                                          ref.watch(settingsProvider).themeMode;
                                      final bool isActuallyDark =
                                          (currentTheme == 'dark') ||
                                              (currentTheme == 'system' &&
                                                  MediaQuery
                                                          .platformBrightnessOf(
                                                              context) ==
                                                      Brightness.dark);
                                      final IconData icon = isActuallyDark
                                          ? AuroraIcons.themeDark
                                          : AuroraIcons.themeLight;
                                      return fluent.HoverButton(
                                        onPressed: () => ref
                                            .read(settingsProvider.notifier)
                                            .toggleThemeMode(),
                                        builder: (context, states) {
                                          return Container(
                                            height: 40,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: states.isHovered
                                                  ? theme.resources
                                                      .subtleFillColorSecondary
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 30,
                                                  child: Center(
                                                    child: fluent.Icon(icon,
                                                        size: 16,
                                                        color: theme.typography
                                                            .body?.color),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 0.0),
                                                    child: Text(l10n.theme,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal),
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RepaintBoundary(
                        child: Container(
                          color: Colors.transparent,
                          child: FadeIndexedStack(
                            index: selectedIndex,
                            children: navItems
                                .map<Widget>((item) => item.body)
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
