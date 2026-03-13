import 'package:aurora/features/settings/presentation/settings_provider.dart';
import 'package:aurora/shared/services/provider_display_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveProviderDisplayMetadata', () {
    test('returns the same color for providers from the same official vendor',
        () {
      final primary = resolveProviderDisplayMetadata(
        providerId: 'openai-primary',
        baseUrl: 'https://api.openai.com/v1',
      );
      final secondary = resolveProviderDisplayMetadata(
        providerId: 'openai-secondary',
        baseUrl: 'https://platform.openai.com/v1',
      );

      expect(primary.vendorKey, 'openai');
      expect(secondary.vendorKey, 'openai');
      expect(primary.displayColorHex, secondary.displayColorHex);
    });

    test('returns different stable colors for different custom hosts', () {
      final foo = resolveProviderDisplayMetadata(
        providerId: 'foo',
        baseUrl: 'https://foo.example.com/v1',
      );
      final bar = resolveProviderDisplayMetadata(
        providerId: 'bar',
        baseUrl: 'https://bar.example.com/v1',
      );
      final fooRepeat = resolveProviderDisplayMetadata(
        providerId: 'foo-again',
        baseUrl: 'https://foo.example.com/v1/chat/completions',
      );

      expect(foo.vendorKey, 'foo.example.com');
      expect(bar.vendorKey, 'bar.example.com');
      expect(foo.displayColorHex, isNot(bar.displayColorHex));
      expect(foo.displayColorHex, fooRepeat.displayColorHex);
    });

    test('falls back to provider id when base url is empty or invalid', () {
      final invalid = resolveProviderDisplayMetadata(
        providerId: 'custom_provider',
        baseUrl: 'not a valid uri',
      );
      final empty = resolveProviderDisplayMetadata(
        providerId: 'custom_provider',
        baseUrl: '',
      );

      expect(invalid.vendorKey, 'custom_provider');
      expect(empty.vendorKey, 'custom_provider');
      expect(invalid.displayColorHex, empty.displayColorHex);
    });

    test('ignores legacy explicit provider colors', () {
      final legacyGreen = ProviderConfig(
        id: 'legacy',
        name: 'Legacy',
        color: '#00FF00',
        baseUrl: 'https://api.openai.com/v1',
      );
      final legacyRed = ProviderConfig(
        id: 'legacy',
        name: 'Legacy',
        color: '#FF0000',
        baseUrl: 'https://api.openai.com/v1',
      );

      final greenMetadata = resolveProviderDisplayMetadata(
        providerId: legacyGreen.id,
        baseUrl: legacyGreen.baseUrl,
      );
      final redMetadata = resolveProviderDisplayMetadata(
        providerId: legacyRed.id,
        baseUrl: legacyRed.baseUrl,
      );

      expect(greenMetadata.displayColorHex, redMetadata.displayColorHex);
      expect(greenMetadata.vendorKey, 'openai');
    });
  });
}
