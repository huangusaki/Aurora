import 'package:aurora/features/knowledge/data/knowledge_storage.dart';
import 'package:aurora/features/knowledge/domain/knowledge_models.dart';
import 'package:aurora/features/knowledge/presentation/knowledge_provider.dart';
import 'package:aurora/features/settings/data/daily_usage_stats_entity.dart';
import 'package:aurora/features/settings/data/settings_storage.dart';
import 'package:aurora/features/settings/data/usage_stats_entity.dart';
import 'package:aurora/features/settings/presentation/app_log_provider.dart';
import 'package:aurora/features/settings/presentation/log_records_page.dart';
import 'package:aurora/features/settings/presentation/mobile_app_settings_page.dart';
import 'package:aurora/features/settings/presentation/settings_content.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/features/settings/presentation/usage_stats_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/utils/app_log_repository.dart';
import 'package:aurora/shared/utils/app_logger.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier({
    required super.storage,
    required super.initialProviders,
    required super.initialActiveId,
  });

  @override
  Future<void> loadPresets() async {}
}

class _FakeAppLogRepository extends AppLogRepository {
  _FakeAppLogRepository({List<AppLogEntry> entries = const <AppLogEntry>[]})
      : super(autoInit: false) {
    state = AppLogState(entries: entries, isLoading: false);
  }

  @override
  Future<void> init() async {}

  void appendEntry(AppLogEntry entry) {
    state = AppLogState(
      entries: <AppLogEntry>[...state.entries, entry],
      isLoading: false,
    );
  }
}

class _FakeUsageStatsStorage extends SettingsStorage {
  @override
  Future<int> migrateTokenCounts() async => 0;

  @override
  Future<List<UsageStatsEntity>> loadAllUsageStats() async {
    return <UsageStatsEntity>[];
  }

  @override
  Future<List<DailyUsageStatsEntity>> loadDailyStats(int days) async {
    return <DailyUsageStatsEntity>[];
  }
}

class _FakeUsageStatsNotifier extends UsageStatsNotifier {
  _FakeUsageStatsNotifier() : super(_FakeUsageStatsStorage());
}

class _FakeKnowledgeStorage implements KnowledgeStorage {
  @override
  Future<List<KnowledgeBaseSummary>> loadBaseSummaries({
    String? scope,
    String? ownerProjectId,
  }) async {
    return <KnowledgeBaseSummary>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _FakeKnowledgeNotifier extends KnowledgeNotifier {
  _FakeKnowledgeNotifier() : super(_FakeKnowledgeStorage());
}

Widget _buildDesktopLogApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: fluent.FluentApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        fluent.FluentLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Material(
        type: MaterialType.transparency,
        child: LogRecordsView(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSettingsNotifier settingsNotifier;

  setUp(() {
    settingsNotifier = _FakeSettingsNotifier(
      storage: SettingsStorage(),
      initialProviders: [
        ProviderConfig(id: 'openai', name: 'OpenAI'),
        ProviderConfig(id: 'custom', name: 'Custom', isCustom: true),
      ],
      initialActiveId: 'openai',
    );
  });

  testWidgets('desktop settings navigation contains log records entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => settingsNotifier),
        knowledgeStorageProvider.overrideWithValue(_FakeKnowledgeStorage()),
        knowledgeProvider.overrideWith((ref) => _FakeKnowledgeNotifier()),
        usageStatsProvider.overrideWith((ref) => _FakeUsageStatsNotifier()),
        appLogRepositoryProvider.overrideWith(
          (ref) => _FakeAppLogRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: fluent.FluentApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            fluent.FluentLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Material(
            type: MaterialType.transparency,
            child: SettingsContent(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('日志记录'), findsWidgets);
  });

  testWidgets('mobile app settings shows log records entry', (tester) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => settingsNotifier),
        knowledgeStorageProvider.overrideWithValue(_FakeKnowledgeStorage()),
        knowledgeProvider.overrideWith((ref) => _FakeKnowledgeNotifier()),
        appLogRepositoryProvider.overrideWith(
          (ref) => _FakeAppLogRepository(),
        ),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'Aurora',
            packageName: 'dev.aurora.test',
            version: '1.0.0',
            buildNumber: '1',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MobileAppSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Log Records'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Log Records'), findsOneWidget);
  });

  testWidgets('mobile log page renders warning badge for warn logs',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        appLogRepositoryProvider.overrideWith(
          (ref) => _FakeAppLogRepository(
            entries: [
              AppLogEntry(
                timestamp: DateTime(2026, 3, 6, 12, 0, 0),
                level: AppLogLevel.warn,
                channel: 'CHAT',
                category: 'REQUEST',
                message: 'Request cancelled by user',
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MobileLogPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Warning'), findsWidgets);
    expect(find.text('Request cancelled by user'), findsOneWidget);
  });

  testWidgets('desktop log page does not throw before scroll metrics are ready',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        appLogRepositoryProvider.overrideWith(
          (ref) => _FakeAppLogRepository(
            entries: [
              AppLogEntry(
                timestamp: DateTime(2026, 3, 6, 12, 0, 0),
                level: AppLogLevel.info,
                channel: 'BOOT',
                message: 'startup entry',
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildDesktopLogApp(container));
    expect(tester.takeException(), isNull);

    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'desktop log page does not compensate viewport during active drag',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeAppLogRepository(
      entries: List<AppLogEntry>.generate(
        80,
        (index) => AppLogEntry(
          timestamp: DateTime(2026, 3, 6, 12, 0, index),
          level: AppLogLevel.info,
          channel: 'CHAT',
          category: 'STREAM',
          message: 'Log entry $index',
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appLogRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildDesktopLogApp(container));
    await tester.pumpAndSettle();

    final scrollableFinder = find.byType(Scrollable).first;
    final scrollableState = tester.state<ScrollableState>(scrollableFinder);
    scrollableState.position.jumpTo(900);
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(scrollableFinder));
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();

    final beforeAppend = scrollableState.position.pixels;

    repository.appendEntry(
      AppLogEntry(
        timestamp: DateTime(2026, 3, 6, 12, 2, 0),
        level: AppLogLevel.info,
        channel: 'CHAT',
        category: 'STREAM',
        message: 'Newest log entry',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      scrollableState.position.pixels,
      closeTo(beforeAppend, 0.1),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
