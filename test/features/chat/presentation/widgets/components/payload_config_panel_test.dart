import 'package:aurora/features/chat/presentation/widgets/components/payload_config_panel.dart';
import 'package:aurora/features/settings/data/provider_config_entity.dart';
import 'package:aurora/features/settings/data/settings_storage.dart';
import 'package:aurora/features/settings/domain/provider_route_config.dart';
import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/shared/services/llm_transport_mode.dart';
import 'package:aurora/shared/widgets/aurora_dropdown.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySettingsStorage extends SettingsStorage {
  ProviderConfigEntity? savedProvider;

  @override
  Future<List<ProviderConfigEntity>> loadProviders() async =>
      <ProviderConfigEntity>[];

  @override
  Future<AppSettingsEntity?> loadAppSettings() async => null;

  @override
  Future<void> saveProvider(ProviderConfigEntity provider) async {
    savedProvider = provider;
  }
}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier({
    required super.storage,
    required super.initialProviders,
    required super.initialActiveId,
  });

  @override
  Future<void> loadPresets() async {}
}

Widget _buildTestApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: FluentApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FluentLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const material.Material(
        type: material.MaterialType.transparency,
        child: NavigationView(
          content: ScaffoldPage(
            content: PayloadConfigPanel(
              providerId: 'gemini',
              modelName: 'gemini-3.1-flash-image-preview',
              forceImageConfig: true,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stores and re-renders image transport mode selection',
      (tester) async {
    final storage = _MemorySettingsStorage();
    final notifier = _TestSettingsNotifier(
      storage: storage,
      initialProviders: [
        ProviderConfig(
          id: 'gemini',
          name: 'Gemini',
          apiKeys: const ['test-key'],
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          providerProtocol: ProviderProtocol.gemini,
          selectedModel: 'gemini-3.1-flash-image-preview',
          modelSettings: const {
            'gemini-3.1-flash-image-preview': {
              auroraImageConfigKey: {
                'image_size': '4K',
              },
            },
          },
        ),
      ],
      initialActiveId: 'gemini',
    );

    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => notifier),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildTestApp(container));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PayloadConfigPanel));
    final l10n = AppLocalizations.of(context)!;
    final modeFinder = find.byWidgetPredicate(
      (widget) =>
          widget is AuroraAdaptiveDropdownField<String> &&
          widget.label == l10n.imageTransmissionMode,
    );

    final initialDropdown =
        tester.widget<AuroraAdaptiveDropdownField<String>>(modeFinder);
    expect(initialDropdown.value, ImageConfigTransportMode.auto.wireName);

    initialDropdown.onChanged
        ?.call(ImageConfigTransportMode.googleExtraBody.wireName);
    await tester.pumpAndSettle();

    final savedConfig = notifier.state.activeProvider.modelSettings[
            'gemini-3.1-flash-image-preview']![auroraImageConfigKey]
        as Map<String, dynamic>;
    expect(
      savedConfig[auroraImageConfigModeKey],
      ImageConfigTransportMode.googleExtraBody.wireName,
    );
    expect(savedConfig['image_size'], '4K');
    expect(storage.savedProvider?.providerId, 'gemini');

    final updatedDropdown =
        tester.widget<AuroraAdaptiveDropdownField<String>>(modeFinder);
    expect(
      updatedDropdown.value,
      ImageConfigTransportMode.googleExtraBody.wireName,
    );
  });
}
