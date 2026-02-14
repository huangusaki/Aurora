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
    final customThemeEnabled =
        settings.useCustomTheme || settings.themeMode == 'custom';
    final imagePath = settings.backgroundImagePath;
    final blur = settings.backgroundBlur;
    final brightness = settings.backgroundBrightness;

    if (!customThemeEnabled || imagePath == null || imagePath.isEmpty) {
      return child;
    }

    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      return child;
    }

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
        // Blur Effect
        if (blur > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: const SizedBox.shrink(),
            ),
          ),
        // Brightness / Overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 1.0 - brightness),
          ),
        ),
        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}
