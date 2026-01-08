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
import 'features/chat/presentation/widgets/chat_image_bubble.dart' show clearImageCache;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: null,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setMinimumSize(const Size(900, 600));
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
      return ProviderConfig(
        id: e.providerId,
        name: e.name,
        apiKey: e.apiKey,
        baseUrl: e.baseUrl,
        isCustom: e.isCustom,
        customParameters: customParams,
        modelSettings: modelSettings,
        models: e.savedModels,
        selectedModel: e.lastSelectedModel,
        isEnabled: e.isEnabled,
      );
    }).toList();
    // if (!initialProviders.any((p) => p.id == 'openai')) {
    //   initialProviders.insert(
    //       0, ProviderConfig(id: 'openai', name: 'OpenAI', isCustom: false));
    // }
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
          language: appSettings?.language ?? (Platform.localeName.startsWith('zh') ? 'zh' : 'en'),
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
      // Clear image cache when switching sessions to free memory
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

    final themeModeStr = ref.watch(settingsProvider.select((value) => value.themeMode));
    final language = ref.watch(settingsProvider.select((value) => value.language));
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
        accentColor: fluent.Colors.blue,
        brightness: fluent.Brightness.light,
        scaffoldBackgroundColor: fluent.Colors.white,
        cardColor: fluent.Colors.white,
        navigationPaneTheme: fluent.NavigationPaneThemeData(
          backgroundColor: fluent.Colors.grey[20],
        ),
      ),
      builder: (context, child) {
        final brightness = fluent.FluentTheme.of(context).brightness;
        return Theme(
          data: ThemeData(
            fontFamily: fontFamily,
            brightness: brightness == fluent.Brightness.dark ? Brightness.dark : Brightness.light,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
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
          ),
          child: ScaffoldMessenger(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      darkTheme: fluent.FluentThemeData(
        fontFamily: fontFamily,
        accentColor: fluent.Colors.blue,
        brightness: fluent.Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF202020),
        cardColor: const Color(0xFF2D2D2D),
        navigationPaneTheme: const fluent.NavigationPaneThemeData(
          backgroundColor: Color(0xFF181818),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
