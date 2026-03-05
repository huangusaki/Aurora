import 'package:aurora/features/settings/data/settings_storage.dart';
import 'package:aurora/features/settings/presentation/mobile_settings_page.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier({
    required super.storage,
    required super.initialProviders,
    required super.initialActiveId,
  });

  bool selectProviderCalled = false;

  @override
  Future<void> loadPresets() async {
    // No-op: avoids touching Isar in widget tests.
  }

  @override
  Future<void> selectProvider(String id) async {
    selectProviderCalled = true;
    state = state.copyWith(activeProviderId: id);
  }
}

void main() {
  testWidgets(
      'Switching provider in mobile settings only updates viewing provider',
      (tester) async {
    final notifier = _FakeSettingsNotifier(
      storage: SettingsStorage(),
      initialProviders: [
        ProviderConfig(id: 'p1', name: 'Provider A'),
        ProviderConfig(id: 'p2', name: 'Provider B'),
      ],
      initialActiveId: 'p1',
    );

    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => notifier),
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
          home: const MobileSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Provider A'), findsOneWidget);
    expect(container.read(settingsProvider).activeProviderId, 'p1');
    expect(container.read(settingsProvider).viewingProviderId, 'p1');

    await tester.tap(find.text('Current Provider'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Provider B'));
    await tester.pumpAndSettle();

    expect(find.text('Provider B'), findsOneWidget);
    expect(container.read(settingsProvider).activeProviderId, 'p1');
    expect(container.read(settingsProvider).viewingProviderId, 'p2');
    expect(notifier.selectProviderCalled, isFalse);
  });
}

