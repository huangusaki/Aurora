import 'dart:io';
import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'features/chat/presentation/chat_screen.dart';

import 'features/settings/data/settings_storage.dart';
import 'features/settings/presentation/settings_provider.dart';
import 'shared/utils/windows_injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: null, // Use default opaque background for better performance
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Inject key data to fix Win+V clipboard history paste
    WindowsInjector.instance.injectKeyData();
  }

  // Initialize Storage
  final storage = SettingsStorage();
  await storage.init();
  
  // Load persisted data
  final providerEntities = await storage.loadProviders();
  final appSettings = await storage.loadAppSettings();
  
  // Map to Domain Models
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
      
      if (e.customParametersJson != null && e.customParametersJson!.isNotEmpty) {
        try {
          customParams = jsonDecode(e.customParametersJson!) as Map<String, dynamic>;
        } catch (_) {}
      }
      
      if (e.modelSettingsJson != null && e.modelSettingsJson!.isNotEmpty) {
         try {
           final decoded = jsonDecode(e.modelSettingsJson!);
           if (decoded is Map) {
             modelSettings = decoded.map((key, value) => MapEntry(key.toString(), value as Map<String, dynamic>));
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
      );
    }).toList();
    
    // Ensure default providers exist if not in DB (backward compatibility/safety)
    if (!initialProviders.any((p) => p.id == 'openai')) {
       initialProviders.insert(0, ProviderConfig(id: 'openai', name: 'OpenAI', isCustom: false));
    }
     if (!initialProviders.any((p) => p.id == 'custom')) {
       initialProviders.add(ProviderConfig(id: 'custom', name: 'Custom', isCustom: true));
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
    final settings = ref.watch(settingsProvider);
    final themeModeStr = settings.themeMode;
    
    // Map string to ThemeMode
    fluent.ThemeMode fluentMode;
    ThemeMode materialMode;
    
    if (themeModeStr == 'light') {
      fluentMode = fluent.ThemeMode.light;
      materialMode = ThemeMode.light;
    } else if (themeModeStr == 'dark') {
      fluentMode = fluent.ThemeMode.dark;
      materialMode = ThemeMode.dark;
    } else {
      fluentMode = fluent.ThemeMode.system;
      materialMode = ThemeMode.system;
    }

    return fluent.FluentApp(
      title: 'Aurora',
      debugShowCheckedModeBanner: false,
      themeMode: fluentMode,
      theme: fluent.FluentThemeData(
        fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
        accentColor: fluent.Colors.blue,
        brightness: fluent.Brightness.light,
        scaffoldBackgroundColor: fluent.Colors.white,
        cardColor: fluent.Colors.white,
        navigationPaneTheme: fluent.NavigationPaneThemeData(
          backgroundColor: fluent.Colors.grey[20], // Light grey for nav pane
        ),
      ),
      darkTheme: fluent.FluentThemeData(
        fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
        accentColor: fluent.Colors.blue,
        brightness: fluent.Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF202020),
        cardColor: const Color(0xFF2D2D2D),
        navigationPaneTheme: const fluent.NavigationPaneThemeData(
          backgroundColor: Color(0xFF181818), // Darker grey for nav pane
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
