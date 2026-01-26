import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:path/path.dart' as p;
import 'package:aurora/l10n/app_localizations.dart';
import '../../../settings/presentation/settings_content.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../history/presentation/history_content.dart';
import '../widgets/translation_content.dart';
import '../widgets/window_buttons.dart';
import '../widgets/model_selector.dart';
import '../widgets/preset_selector.dart';
import '../widgets/fade_indexed_stack.dart';
import '../../../studio/presentation/studio_content.dart';
import '../../../skills/presentation/skills_page.dart';
import '../chat_provider.dart';

class DesktopChatScreen extends ConsumerStatefulWidget {
  const DesktopChatScreen({super.key});
  @override
  ConsumerState<DesktopChatScreen> createState() => _DesktopChatScreenState();
}



class _DesktopChatScreenState extends ConsumerState<DesktopChatScreen> with WindowListener, TrayListener {
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
      if (Platform.isWindows) {
        final String exePath = Platform.resolvedExecutable;
        final String exeDir = File(exePath).parent.path;
        final List<String> possiblePaths = [
          p.join(exeDir, 'data', 'flutter_assets', 'assets', 'icon', 'app_icon.ico'),
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
    final isExpanded = ref.watch(isSidebarExpandedProvider);
    final selectedIndex = ref.watch(desktopActiveTabProvider);
    final l10n = AppLocalizations.of(context)!;
    final navItems = [
      (
        icon: fluent.FluentIcons.history,
        label: l10n.history,
        body: const HistoryContent()
      ),
      (
        icon: fluent.FluentIcons.translate,
        label: l10n.textTranslation,
        body: const TranslationContent()
      ),
      (
        icon: fluent.FluentIcons.script,
        label: l10n.agentSkills,
        body: const SkillSettingsPage()
      ),
      (
        icon: fluent.FluentIcons.toolbox,
        label: l10n.studio,
        body: const StudioContent()
      ),
      (
        icon: fluent.FluentIcons.settings,
        label: l10n.settings,
        body: const SettingsContent()
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
    final backgroundColor = ref.watch(settingsProvider.select((s) => s.backgroundColor));
    
    List<Color>? getBackgroundGradient(String bg, bool isDark) {
      if (isDark) {
        switch (bg) {
          case 'sunset':
            return [const Color(0xFF1A0B0E), const Color(0xFF4A1F28)];
          case 'ocean':
            return [const Color(0xFF05101A), const Color(0xFF0D2B42)];
          case 'forest':
            return [const Color(0xFF051408), const Color(0xFF0E3316)];
          case 'dream':
            return [const Color(0xFF120817), const Color(0xFF261233)];
          case 'aurora':
            return [const Color(0xFF051715), const Color(0xFF181533)];
          case 'volcano':
            return [const Color(0xFF1F0808), const Color(0xFF3E1212)];
          case 'midnight':
            return [const Color(0xFF020205), const Color(0xFF141426)];
          case 'dawn':
            return [const Color(0xFF141005), const Color(0xFF33260D)];
          case 'neon':
            return [const Color(0xFF08181A), const Color(0xFF240C21)];
          case 'blossom':
            return [const Color(0xFF1F050B), const Color(0xFF3D0F19)];
          case 'warm':
            return [const Color(0xFF1E1C1A), const Color(0xFF2E241E)];
          case 'cool':
            return [const Color(0xFF1A1C1E), const Color(0xFF1E252E)];
          case 'rose':
            return [const Color(0xFF2D1A1E), const Color(0xFF3B1E26)];
          case 'lavender':
            return [const Color(0xFF1F1A2D), const Color(0xFF261E3B)];
          case 'mint':
            return [const Color(0xFF1A2D24), const Color(0xFF1E3B2E)];
          case 'sky':
            return [const Color(0xFF1A202D), const Color(0xFF1E263B)];
          case 'gray':
            return [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)];
          default:
            return null; // Fallback to solid color
        }
      } else {
        switch (bg) {
          case 'warm':
            return [const Color(0xFFFFF8F0), const Color(0xFFFFEBD6)];
          case 'cool':
            return [const Color(0xFFF0F8FF), const Color(0xFFD6EAFF)];
          case 'rose':
            return [const Color(0xFFFFF0F5), const Color(0xFFFFD6E4)];
          case 'lavender':
            return [const Color(0xFFF3E5F5), const Color(0xFFE6D6FF)];
          case 'mint':
            return [const Color(0xFFE0F2F1), const Color(0xFFC2E8DC)];
          case 'sky':
            return [const Color(0xFFE1F5FE), const Color(0xFFC7E6FF)];
          case 'gray':
            return [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)];
          case 'sunset':
            return [const Color(0xFFFFF3E0), const Color(0xFFFFCCBC)];
          case 'ocean':
            return [const Color(0xFFE1F5FE), const Color(0xFF81D4FA)];
          case 'forest':
            return [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)];
          case 'dream':
            return [const Color(0xFFF3E5F5), const Color(0xFFBBDEFB)];
          case 'aurora':
            return [const Color(0xFFE0F2F1), const Color(0xFFD1C4E9)];
          case 'volcano':
            return [const Color(0xFFFFEBEE), const Color(0xFFFFCCBC)];
          case 'midnight':
            return [const Color(0xFFECEFF1), const Color(0xFF90A4AE)];
          case 'dawn':
            return [const Color(0xFFFFF8E1), const Color(0xFFFFE082)];
          case 'neon':
            return [const Color(0xFFE0F7FA), const Color(0xFFE1BEE7)];
          case 'blossom':
            return [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)];
          case 'pure_black':
            return null; // Pure white
          case 'default':
          default:
            return [const Color(0xFFE0F7FA), const Color(0xFFF1F8E9)];
        }
      }
    }

    final isDark = theme.brightness == fluent.Brightness.dark;
    final backgroundGradient = getBackgroundGradient(backgroundColor, isDark);
    
    // Determine solid background color fallback
    final solidBackgroundColor = () {
      if (isDark) {
        switch (backgroundColor) {
           case 'pure_black': return const Color(0xFF000000);
           case 'warm': return const Color(0xFF1E1C1A);
           case 'cool': return const Color(0xFF1A1C1E);
           case 'default':
           default: return const Color(0xFF202020);
        }
      } else {
        return Colors.white;
      }
    }();

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: solidBackgroundColor, // Base color
          ),
        ),
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
                        icon: const fluent.Icon(
                            fluent.FluentIcons.global_nav_button,
                            size: 16),
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
                  Expanded(
                      child: DragToMoveArea(
                          child: Container(color: Colors.transparent))),
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
                                      .take(navItems.length - 1)
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
                                              .read(
                                                  desktopActiveTabProvider.notifier)
                                              .state = index;
                                        }
                                      },
                                      builder: (context, states) {
                                        return Container(
                                          height: 40,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: states.isHovering
                                                ? theme.resources
                                                    .subtleFillColorSecondary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 26,
                                                height: 36,
                                                margin: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? theme.accentColor
                                                          .withOpacity(0.1)
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
                                    final index = navItems.length - 1;
                                    final item = navItems[index];
                                    final isSelected = selectedIndex == index;
                                    return fluent.HoverButton(
                                      onPressed: () => ref
                                          .read(desktopActiveTabProvider
                                              .notifier)
                                          .state = index,
                                      builder: (context, states) {
                                        return Container(
                                          height: 40,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: states.isHovering
                                                ? theme.resources
                                                    .subtleFillColorSecondary
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
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
                                      final currentTheme = ref
                                          .watch(settingsProvider)
                                          .themeMode;
                                      final bool isActuallyDark =
                                          (currentTheme == 'dark') ||
                                              (currentTheme == 'system' &&
                                                  MediaQuery.platformBrightnessOf(
                                                          context) ==
                                                      Brightness.dark);
                                      final IconData icon = isActuallyDark
                                          ? fluent.FluentIcons.clear_night
                                          : fluent.FluentIcons.sunny;
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
                                              color: states.isHovering
                                                  ? theme.resources
                                                      .subtleFillColorSecondary
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 30,
                                                  child: Center(
                                                    child: fluent.Icon(icon,
                                                        size: 16,
                                                        color: theme
                                                            .typography
                                                            .body
                                                            ?.color),
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
                            children:
                                navItems.map((item) => item.body).toList(),
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
