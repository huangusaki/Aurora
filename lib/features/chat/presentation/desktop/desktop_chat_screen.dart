import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:aurora/l10n/app_localizations.dart';
import '../../../settings/presentation/settings_content.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../history/presentation/history_content.dart';
import '../widgets/translation_content.dart';
import '../widgets/window_buttons.dart';
import '../widgets/model_selector.dart';
import '../widgets/preset_selector.dart';
import '../widgets/fade_indexed_stack.dart';
import '../chat_provider.dart';

class DesktopChatScreen extends ConsumerStatefulWidget {
  const DesktopChatScreen({super.key});
  @override
  ConsumerState<DesktopChatScreen> createState() => _DesktopChatScreenState();
}

class _DesktopChatScreenState extends ConsumerState<DesktopChatScreen> {
  @override
  Widget build(BuildContext context) {
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
    return Stack(
      children: [
        if (theme.brightness == fluent.Brightness.light)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE0F7FA), // Cyan 50
                    Color(0xFFF1F8E9), // Light Green 50
                  ],
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
                    width: 50,
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
                  const SizedBox(width: 12),
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
                        width: isExpanded ? 120 : 50,
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
                                            children: [
                                              Container(
                                                width: 40,
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
                                                      size: 20,
                                                      color: isSelected
                                                          ? theme.accentColor
                                                          : null),
                                                ),
                                              ),
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
                                            children: [
                                              SizedBox(
                                                width: 40,
                                                child: Center(
                                                  child: fluent.Icon(item.icon,
                                                      size: 20,
                                                      color: isSelected
                                                          ? theme.accentColor
                                                          : null),
                                                ),
                                              ),
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
                                              children: [
                                                SizedBox(
                                                  width: 40,
                                                  child: Center(
                                                    child: fluent.Icon(icon,
                                                        size: 20,
                                                        color: theme
                                                            .typography
                                                            .body
                                                            ?.color),
                                                  ),
                                                ),
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
