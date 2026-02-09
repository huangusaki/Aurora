import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/chat/presentation/chat_provider.dart';
import 'features/chat/presentation/topic_provider.dart';
import 'features/settings/data/settings_storage.dart';
import 'features/settings/presentation/settings_provider.dart';
import 'shared/widgets/global_background.dart';
import 'shared/theme/wallpaper_tint.dart';
import 'shared/theme/wallpaper_tint_provider.dart';
import 'shared/utils/windows_injector.dart';
import 'features/skills/presentation/skill_provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'features/chat/presentation/widgets/chat_image_bubble.dart'
    show clearImageCache;

import 'shared/utils/platform_utils.dart';

void _bootLog(String message) {
  final timestamp = DateTime.now().toIso8601String();
  debugPrint('[AURORA_BOOT][$timestamp] $message');
}

void _bootError(String stage, Object error, StackTrace stackTrace) {
  final timestamp = DateTime.now().toIso8601String();
  debugPrint('[AURORA_BOOT][$timestamp][ERROR][$stage] $error');
  debugPrint(stackTrace.toString());
}

class StartupErrorApp extends StatelessWidget {
  final String title;
  final String detail;
  const StartupErrorApp({super.key, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: SelectableText(
                '$title\n\n$detail',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _bootError(
        'flutter_error', details.exception, details.stack ?? StackTrace.empty);
  };

  runZonedGuarded(() async {
    _bootLog('main start');
    WidgetsFlutterBinding.ensureInitialized();
    _bootLog('binding initialized');

    if (PlatformUtils.isDesktop) {
      _bootLog('desktop initialization start');
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1080, 640),
        center: true,
        backgroundColor: null,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setMinimumSize(const Size(1080, 640));
      });
      if (PlatformUtils.isWindows) {
        WindowsInjector.instance.injectKeyData();
      }
      _bootLog('desktop initialization done');
    } else if (PlatformUtils.isAndroid) {
      _bootLog('android initialization start');
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } catch (e, st) {
        _bootError('set_high_refresh_rate', e, st);
      }
      _bootLog('android initialization done');
    }

    _bootLog('storage initialization start');
    final storage = SettingsStorage();
    await storage.init();
    _bootLog('storage initialization done');

    _bootLog('loading providers and settings');
    final providerEntities = await storage.loadProviders();
    final appSettings = await storage.loadAppSettings();
    _bootLog(
        'providers=${providerEntities.length}, hasAppSettings=${appSettings != null}');

    final List<ProviderConfig> initialProviders;
    if (providerEntities.isEmpty) {
      initialProviders = [
        ProviderConfig(id: 'openai', name: 'OpenAI', isCustom: false),
        ProviderConfig(id: 'custom', name: 'Custom', isCustom: true),
      ];
    } else {
      initialProviders = providerEntities.map((e) {
        Map<String, dynamic> customParams = {};
        Map<String, Map<String, dynamic>> modelSettings = {};
        Map<String, dynamic> globalSettings = {};

        if (e.customParametersJson != null &&
            e.customParametersJson!.isNotEmpty) {
          try {
            customParams =
                jsonDecode(e.customParametersJson!) as Map<String, dynamic>;
          } catch (_) {}
        }
        if (e.modelSettingsJson != null && e.modelSettingsJson!.isNotEmpty) {
          try {
            final decoded = jsonDecode(e.modelSettingsJson!);
            if (decoded is Map) {
              modelSettings = decoded.map((key, value) =>
                  MapEntry(key.toString(), value as Map<String, dynamic>));
            }
          } catch (_) {}
        }
        if (e.globalSettingsJson != null && e.globalSettingsJson!.isNotEmpty) {
          try {
            globalSettings =
                jsonDecode(e.globalSettingsJson!) as Map<String, dynamic>;
          } catch (_) {}
        }
        // Migrate from legacy apiKey to apiKeys if needed
        List<String> apiKeys = e.apiKeys;
        // ignore: deprecated_member_use_from_same_package
        if (apiKeys.isEmpty && e.apiKey.isNotEmpty) {
          // ignore: deprecated_member_use_from_same_package
          apiKeys = [e.apiKey];
        }
        return ProviderConfig(
          id: e.providerId,
          name: e.name,
          color: e.color,
          apiKeys: apiKeys,
          currentKeyIndex: e.currentKeyIndex,
          autoRotateKeys: e.autoRotateKeys,
          baseUrl: e.baseUrl,
          isCustom: e.isCustom,
          customParameters: customParams,
          modelSettings: modelSettings,
          globalSettings: globalSettings,
          globalExcludeModels: e.globalExcludeModels,
          models: e.savedModels,
          selectedModel: e.lastSelectedModel,
          isEnabled: e.isEnabled,
        );
      }).toList();
      if (!initialProviders.any((p) => p.id == 'custom')) {
        initialProviders
            .add(ProviderConfig(id: 'custom', name: 'Custom', isCustom: true));
      }
    }
    final initialActiveId = appSettings?.activeProviderId ?? 'custom';

    _bootLog('runApp start');
    runApp(ProviderScope(
      overrides: [
        settingsStorageProvider.overrideWithValue(storage),
        settingsProvider.overrideWith((ref) {
          // Load skills from a default directory (Desktop only)
          if (PlatformUtils.isDesktop) {
            Future.microtask(() {
              final skillsDir =
                  '${Directory.current.path}${Platform.pathSeparator}skills';
              final language = appSettings?.language ??
                  (Platform.localeName.startsWith('zh') ? 'zh' : 'en');
              ref
                  .read(skillProvider.notifier)
                  .loadSkills(skillsDir, language: language);
            });
          }

          return SettingsNotifier(
            storage: storage,
            initialProviders: initialProviders,
            initialActiveId: initialActiveId,
            userName: appSettings?.userName ?? 'User',
            userAvatar: appSettings?.userAvatar,
            llmName: appSettings?.llmName ?? 'Assistant',
            llmAvatar: appSettings?.llmAvatar,
            themeMode: appSettings?.themeMode ?? 'system',
            isStreamEnabled: appSettings?.isStreamEnabled ?? true,
            isSearchEnabled: appSettings?.isSearchEnabled ?? false,
            isKnowledgeEnabled: appSettings?.isKnowledgeEnabled ?? false,
            searchEngine: appSettings?.searchEngine ?? 'duckduckgo',
            searchRegion: appSettings?.searchRegion ?? 'us-en',
            searchSafeSearch: appSettings?.searchSafeSearch ?? 'moderate',
            searchMaxResults: appSettings?.searchMaxResults ?? 5,
            searchTimeoutSeconds: appSettings?.searchTimeoutSeconds ?? 15,
            knowledgeTopK: appSettings?.knowledgeTopK ?? 5,
            knowledgeUseEmbedding: appSettings?.knowledgeUseEmbedding ?? false,
            knowledgeLlmEnhanceMode:
                appSettings?.knowledgeLlmEnhanceMode ?? 'off',
            knowledgeEmbeddingModel: appSettings?.knowledgeEmbeddingModel,
            knowledgeEmbeddingProviderId:
                appSettings?.knowledgeEmbeddingProviderId,
            activeKnowledgeBaseIds:
                appSettings?.activeKnowledgeBaseIds ?? const [],
            enableSmartTopic: appSettings?.enableSmartTopic ?? true,
            topicGenerationModel: appSettings?.topicGenerationModel,
            language: appSettings?.language ??
                (Platform.localeName.startsWith('zh') ? 'zh' : 'en'),
            themeColor: appSettings?.themeColor ?? 'teal',
            backgroundColor: appSettings?.backgroundColor ?? 'default',
            closeBehavior: appSettings?.closeBehavior ?? 0,
            executionModel: appSettings?.executionModel,
            executionProviderId: appSettings?.executionProviderId,
            fontSize: appSettings?.fontSize ?? 14.0,
            backgroundImagePath: appSettings?.backgroundImagePath,
            backgroundBrightness: appSettings?.backgroundBrightness ?? 0.5,
            backgroundBlur: appSettings?.backgroundBlur ?? 0.0,
            useCustomTheme: appSettings?.useCustomTheme ?? false,
          );
        }),
      ],
      child: const MyApp(),
    ));
    _bootLog('runApp done');
  }, (error, stackTrace) {
    _bootError('uncaught_zone', error, stackTrace);
    runApp(StartupErrorApp(
      title: 'Aurora startup failed',
      detail: '$error\n\n$stackTrace',
    ));
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(selectedHistorySessionIdProvider, (prev, next) {
      if (prev != next) {
        clearImageCache();
      }
      if (next != null && next != 'new_chat' && next != 'translation') {
        ref.read(settingsStorageProvider).saveLastSessionId(next);
      }
    });
    ref.listen<int?>(selectedTopicIdProvider, (prev, next) {
      if (prev != next) {
        ref.read(settingsStorageProvider).saveLastTopicId(next?.toString());
      }
    });
    final language =
        ref.watch(settingsProvider.select((value) => value.language));
    final themeColorStr =
        ref.watch(settingsProvider.select((value) => value.themeColor));
    final fontSize =
        ref.watch(settingsProvider.select((value) => value.fontSize));

    fluent.AccentColor getAccentColor(String color) {
      switch (color) {
        case 'blue':
          return fluent.Colors.blue;
        case 'red':
          return fluent.Colors.red;
        case 'orange':
          return fluent.Colors.orange;
        case 'green':
          return fluent.Colors.green;
        case 'purple':
          return fluent.Colors.purple;
        case 'magenta':
          return fluent.Colors.magenta;
        case 'yellow':
          return fluent.Colors.yellow;
        case 'teal':
        default:
          return fluent.Colors.teal;
      }
    }

    final accentColorVal = getAccentColor(themeColorStr);

    final backgroundColorStr =
        ref.watch(settingsProvider.select((value) => value.backgroundColor));

    final wallpaperTint = ref.watch(wallpaperTintColorProvider);

    fluent.Color customBackgroundSurface(
      fluent.Brightness brightness, {
      required double alpha,
      double mix = 0.25,
    }) {
      final isDark = brightness == fluent.Brightness.dark;
      return tintedGlass(
        wallpaperTint: wallpaperTint,
        isDark: isDark,
        fallback: isDark ? Colors.black : Colors.white,
        alpha: alpha,
        mix: mix,
      );
    }

    bool hasCustomBackground(WidgetRef ref) {
      final settings = ref.watch(settingsProvider);
      return (settings.useCustomTheme || settings.themeMode == 'custom') &&
          settings.backgroundImagePath != null &&
          settings.backgroundImagePath!.isNotEmpty;
    }

    fluent.Color getBackgroundColor(
        String color, fluent.Brightness brightness, bool hasCustomBackground) {
      if (hasCustomBackground) {
        return customBackgroundSurface(brightness, alpha: 0.55, mix: 0.22);
      }
      if (brightness == fluent.Brightness.dark) {
        switch (color) {
          case 'pure_black':
            return const fluent.Color(0xFF000000);
          case 'warm':
            return const fluent.Color(0xFF2E2A25);
          case 'cool':
            return const fluent.Color(0xFF252A2E);
          case 'rose':
            return const fluent.Color(0xFF332026);
          case 'lavender':
            return const fluent.Color(0xFF2A2533);
          case 'mint':
            return const fluent.Color(0xFF203329);
          case 'sky':
            return const fluent.Color(0xFF202933);
          case 'gray':
            return const fluent.Color(0xFF252525);
          case 'sunset':
            return const fluent.Color(0xFF2D121D);
          case 'ocean':
            return const fluent.Color(0xFF09141F);
          case 'forest':
            return const fluent.Color(0xFF0A1F0F);
          case 'dream':
            return const fluent.Color(0xFF1F1221);
          case 'aurora':
            return const fluent.Color(0xFF0A1F1D);
          case 'volcano':
            return const fluent.Color(0xFF290A0A);
          case 'midnight':
            return const fluent.Color(0xFF0D0D14);
          case 'dawn':
            return const fluent.Color(0xFF1F1708);
          case 'neon':
            return const fluent.Color(0xFF0A1A1D);
          case 'blossom':
            return const fluent.Color(0xFF1F080E);
          case 'default':
          default:
            return const fluent.Color(0xFF2B2B2B);
        }
      } else {
        if (hasCustomBackground) return fluent.Colors.transparent;
        return fluent.Colors.white;
      }
    }

    fluent.Color getNavBackgroundColor(
        String color, fluent.Brightness brightness) {
      final hasCustomBg = hasCustomBackground(ref);
      if (hasCustomBg) {
        return customBackgroundSurface(brightness, alpha: 0.55, mix: 0.22);
      }

      if (brightness == fluent.Brightness.dark) {
        return getBackgroundColor(color, brightness, hasCustomBg);
      } else {
        // Light mode nav background
        switch (color) {
          case 'warm':
            return const fluent.Color(0xFFFFF8F0);
          case 'cool':
            return const fluent.Color(0xFFF0F8FF);
          case 'rose':
            return const fluent.Color(0xFFFFF0F5);
          case 'lavender':
            return const fluent.Color(0xFFF3E5F5);
          case 'mint':
            return const fluent.Color(0xFFE0F2F1);
          case 'sky':
            return const fluent.Color(0xFFE1F5FE);
          case 'gray':
            return const fluent.Color(0xFFF5F5F5);
          case 'default':
            return const fluent.Color(0xFFE0F7FA);
          default:
            return const fluent.Color(0xFFF3F3F3);
        }
      }
    }

    fluent.ThemeMode fluentMode;
    final settingsForMode = ref.watch(settingsProvider);
    if (hasCustomBackground(ref)) {
      fluentMode = fluent.ThemeMode.dark;
    } else if (settingsForMode.themeMode == 'light') {
      fluentMode = fluent.ThemeMode.light;
    } else if (settingsForMode.themeMode == 'dark') {
      fluentMode = fluent.ThemeMode.dark;
    } else if (settingsForMode.themeMode == 'custom') {
      fluentMode = fluent.ThemeMode.dark;
    } else {
      fluentMode = fluent.ThemeMode.system;
    }
    final locale = language == 'en' ? const Locale('en') : const Locale('zh');
    final String? fontFamily =
        PlatformUtils.isWindows ? 'Microsoft YaHei' : null;
    return fluent.FluentApp(
      title: 'Aurora',
      debugShowCheckedModeBanner: false,
      themeMode: fluentMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        fluent.FluentLocalizations.delegate,
      ],
      theme: fluent.FluentThemeData(
        fontFamily: fontFamily,
        accentColor: accentColorVal,
        brightness: fluent.Brightness.light,
        scaffoldBackgroundColor: getBackgroundColor(backgroundColorStr,
            fluent.Brightness.light, hasCustomBackground(ref)),
        cardColor: hasCustomBackground(ref)
            ? customBackgroundSurface(fluent.Brightness.light,
                alpha: 0.65, mix: 0.28)
            : fluent.Colors.white,
        navigationPaneTheme: fluent.NavigationPaneThemeData(
          backgroundColor: getNavBackgroundColor(
              backgroundColorStr, fluent.Brightness.light),
        ),
      ),
      builder: (context, child) {
        final hasCustomBg = hasCustomBackground(ref);
        return GlobalBackground(
          child: Builder(builder: (context) {
            final fluentTheme = fluent.FluentTheme.of(context);
            final brightness = fluentTheme.brightness;
            final accentColor = fluentTheme.accentColor;
            final materialPrimary = accentColor.normal;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(fontSize / 14.0),
              ),
              child: Theme(
                data: ThemeData(
                  fontFamily: fontFamily,
                  brightness: brightness == fluent.Brightness.dark
                      ? Brightness.dark
                      : Brightness.light,
                  primaryColor: materialPrimary,
                  scaffoldBackgroundColor: hasCustomBg
                      ? customBackgroundSurface(brightness,
                          alpha: 0.55, mix: 0.22)
                      : fluentTheme.scaffoldBackgroundColor,
                  cardColor: hasCustomBg
                      ? customBackgroundSurface(brightness,
                          alpha: 0.65, mix: 0.28)
                      : null,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: materialPrimary,
                    primary: materialPrimary,
                    brightness: brightness == fluent.Brightness.dark
                        ? Brightness.dark
                        : Brightness.light,
                  ),
                  dialogTheme: DialogThemeData(
                    backgroundColor: hasCustomBg
                        ? customBackgroundSurface(brightness,
                            alpha: 0.65, mix: 0.28)
                        : null,
                    surfaceTintColor: Colors.transparent,
                  ),
                  bottomSheetTheme: BottomSheetThemeData(
                    backgroundColor: hasCustomBg
                        ? customBackgroundSurface(brightness,
                            alpha: 0.65, mix: 0.28)
                        : null,
                    surfaceTintColor: Colors.transparent,
                  ),
                  popupMenuTheme: PopupMenuThemeData(
                    color: hasCustomBg
                        ? customBackgroundSurface(brightness,
                            alpha: 0.65, mix: 0.28)
                        : null,
                    surfaceTintColor: Colors.transparent,
                  ),
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(
                      color: brightness == fluent.Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    titleTextStyle: TextStyle(
                      color: brightness == fluent.Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness:
                          brightness == fluent.Brightness.dark
                              ? Brightness.light
                              : Brightness.dark,
                      statusBarBrightness: brightness == fluent.Brightness.dark
                          ? Brightness.dark
                          : Brightness.light,
                    ),
                  ),
                  useMaterial3: true,
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: brightness == fluent.Brightness.dark
                        ? const Color(
                            0xFF3A5A80) // Neutral dark blue for dark mode
                        : const Color(0xFFB3D4FC), // Light blue for light mode
                    cursorColor: materialPrimary,
                    selectionHandleColor: materialPrimary,
                  ),
                ),
                child: ScaffoldMessenger(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          }),
        );
      },
      darkTheme: fluent.FluentThemeData(
        fontFamily: fontFamily,
        accentColor: accentColorVal,
        brightness: fluent.Brightness.dark,
        scaffoldBackgroundColor: getBackgroundColor(backgroundColorStr,
            fluent.Brightness.dark, hasCustomBackground(ref)),
        cardColor: hasCustomBackground(ref)
            ? customBackgroundSurface(fluent.Brightness.dark,
                alpha: 0.65, mix: 0.28)
            : const Color(0xFF2D2D2D),
        navigationPaneTheme: fluent.NavigationPaneThemeData(
          backgroundColor:
              getNavBackgroundColor(backgroundColorStr, fluent.Brightness.dark),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
