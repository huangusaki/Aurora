import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsState provider resolution', () {
    test('falls back to custom when activeProviderId is missing', () {
      final custom =
          ProviderConfig(id: 'custom', name: 'Custom', isCustom: true);
      final state = SettingsState(
        providers: [custom],
        activeProviderId: 'openai',
        viewingProviderId: 'openai',
      );

      expect(state.activeProvider.id, 'custom');
      expect(state.viewingProvider.id, 'custom');
      expect(state.selectedModel, isNull);
      expect(state.availableModels, isEmpty);
    });

    test('falls back to custom when activeProviderId is empty', () {
      final custom =
          ProviderConfig(id: 'custom', name: 'Custom', isCustom: true);
      final state = SettingsState(
        providers: [custom],
        activeProviderId: '   ',
        viewingProviderId: '   ',
      );

      expect(state.activeProvider.id, 'custom');
      expect(state.viewingProvider.id, 'custom');
    });

    test('falls back to first provider when custom is missing', () {
      final provider =
          ProviderConfig(id: 'p1', name: 'Provider 1', isCustom: true);
      final state = SettingsState(
        providers: [provider],
        activeProviderId: 'missing',
        viewingProviderId: 'missing',
      );

      expect(state.activeProvider.id, 'p1');
      expect(state.viewingProvider.id, 'p1');
    });
  });
}

