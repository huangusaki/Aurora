import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:aurora/shared/riverpod_compat.dart';
import '../../features/settings/presentation/settings_provider.dart';

class GlobalBackground extends ConsumerWidget {
  final Widget child;

  const GlobalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final config = _GlobalBackgroundConfig.fromSettings(settings);

    if (!config.enabled) {
      return child;
    }

    if (!config.imageFile.existsSync()) {
      return child;
    }

    return Stack(
      children: _buildLayers(config),
    );
  }

  List<Widget> _buildLayers(_GlobalBackgroundConfig config) {
    return [
      Positioned.fill(
        child: Image.file(
          config.imageFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ),
      if (config.blur > 0)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: config.blur, sigmaY: config.blur),
            child: const SizedBox.shrink(),
          ),
        ),
      Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 1.0 - config.brightness),
        ),
      ),
      Positioned.fill(child: child),
    ];
  }
}

class _GlobalBackgroundConfig {
  final File imageFile;
  final double blur;
  final double brightness;
  final bool enabled;

  const _GlobalBackgroundConfig({
    required this.imageFile,
    required this.blur,
    required this.brightness,
    required this.enabled,
  });

  factory _GlobalBackgroundConfig.fromSettings(SettingsState settings) {
    final customThemeEnabled =
        settings.useCustomTheme || settings.themeMode == 'custom';
    final imagePath = settings.backgroundImagePath;
    return _GlobalBackgroundConfig(
      imageFile: File(imagePath ?? ''),
      blur: settings.backgroundBlur,
      brightness: settings.backgroundBrightness,
      enabled: customThemeEnabled && imagePath != null && imagePath.isNotEmpty,
    );
  }
}
