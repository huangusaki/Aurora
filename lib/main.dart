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
import 'shared/utils/windows_injector.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'features/chat/presentation/widgets/chat_image_bubble.dart'
    show clearImageCache;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
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
    WindowsInjector.instance.injectKeyData();
  } else if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }
  final storage = SettingsStorage();
  await storage.init();
  final providerEntities = await storage.loadProviders();
  final appSettings = await storage.loadAppSettings();
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
      if (apiKeys.isEmpty && e.apiKey.isNotEmpty) {
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
  runApp(ProviderScope(
    overrides: [
      settingsStorageProvider.overrideWithValue(storage),
      settingsProvider.overrideWith((ref) {
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
          searchEngine: appSettings?.searchEngine ?? 'duckduckgo',
          enableSmartTopic: appSettings?.enableSmartTopic ?? true,
          topicGenerationModel: appSettings?.topicGenerationModel,
          language: appSettings?.language ??
              (Platform.localeName.startsWith('zh') ? 'zh' : 'en'),
          themeColor: appSettings?.themeColor ?? 'teal',
          backgroundColor: appSettings?.backgroundColor ?? 'default',
          closeBehavior: appSettings?.closeBehavior ?? 0,
        );
      }),
    ],
    child: const MyApp(),
  ));
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
    final themeModeStr =
        ref.watch(settingsProvider.select((value) => value.themeMode));
    final language =
        ref.watch(settingsProvider.select((value) => value.language));
    final themeColorStr =
        ref.watch(settingsProvider.select((value) => value.themeColor));
    
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

    fluent.Color getBackgroundColor(
        String color, fluent.Brightness brightness) {
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
        return fluent.Colors.white;
      }
    }

    fluent.Color getNavBackgroundColor(
        String color, fluent.Brightness brightness) {
      if (brightness == fluent.Brightness.dark) {
        return getBackgroundColor(color, brightness);
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
    if (themeModeStr == 'light') {
      fluentMode = fluent.ThemeMode.light;
    } else if (themeModeStr == 'dark') {
      fluentMode = fluent.ThemeMode.dark;
    } else {
      fluentMode = fluent.ThemeMode.system;
    }
    final locale = language == 'en' ? const Locale('en') : const Locale('zh');
    final String? fontFamily = Platform.isWindows ? 'Microsoft YaHei' : null;
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
        scaffoldBackgroundColor:
            getBackgroundColor(backgroundColorStr, fluent.Brightness.light),
        cardColor: fluent.Colors.white,
        navigationPaneTheme: fluent.NavigationPaneThemeData(
          backgroundColor: getNavBackgroundColor(backgroundColorStr, fluent.Brightness.light),
        ),
      ),
      builder: (context, child) {
        final fluentTheme = fluent.FluentTheme.of(context);
        final brightness = fluentTheme.brightness;
        final accentColor = fluentTheme.accentColor;
        final materialPrimary = Color(accentColor.normal.value);
        return Theme(
          data: ThemeData(
            fontFamily: fontFamily,
            brightness: brightness == fluent.Brightness.dark
                ? Brightness.dark
                : Brightness.light,
            primaryColor: materialPrimary,
            scaffoldBackgroundColor: fluentTheme.scaffoldBackgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: materialPrimary,
              brightness: brightness == fluent.Brightness.dark
                  ? Brightness.dark
                  : Brightness.light,
              primary: materialPrimary,
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
                statusBarIconBrightness: brightness == fluent.Brightness.dark
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
                  ? const Color(0xFF3A5A80) // Neutral dark blue for dark mode
                  : const Color(0xFFB3D4FC), // Light blue for light mode
              cursorColor: materialPrimary,
              selectionHandleColor: materialPrimary,
            ),
          ),
          child: ScaffoldMessenger(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      darkTheme: fluent.FluentThemeData(
        fontFamily: fontFamily,
        accentColor: accentColorVal,
        brightness: fluent.Brightness.dark,
        scaffoldBackgroundColor:
            getBackgroundColor(backgroundColorStr, fluent.Brightness.dark),
        cardColor: const Color(0xFF2D2D2D),
        navigationPaneTheme: fluent.NavigationPaneThemeData(
          backgroundColor: getNavBackgroundColor(backgroundColorStr, fluent.Brightness.dark),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
