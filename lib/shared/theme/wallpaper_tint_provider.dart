import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_provider.dart';
import 'wallpaper_tint.dart';

const _kWallpaperSampleSize = 64;

int? _extractAverageArgbFromRgbaBytes(
  Uint8List rgbaBytes,
  int width,
  int height,
) {
  final length = width * height * 4;
  if (rgbaBytes.lengthInBytes < length) return null;

  num rSum = 0;
  num gSum = 0;
  num bSum = 0;
  num aSum = 0;

  for (var i = 0; i < length; i += 4) {
    final r = rgbaBytes[i];
    final g = rgbaBytes[i + 1];
    final b = rgbaBytes[i + 2];
    final a = rgbaBytes[i + 3];

    if (a <= 0) continue;
    rSum += r * a;
    gSum += g * a;
    bSum += b * a;
    aSum += a;
  }

  if (aSum <= 0) return null;

  final r = (rSum / aSum).round().clamp(0, 255);
  final g = (gSum / aSum).round().clamp(0, 255);
  final b = (bSum / aSum).round().clamp(0, 255);

  return (0xFF << 24) | (r << 16) | (g << 8) | b;
}

Future<int?> _extractAverageArgbFromFile(String path) async {
  final bytes = await File(path).readAsBytes();
  if (bytes.isEmpty) return null;

  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _kWallpaperSampleSize,
      targetHeight: _kWallpaperSampleSize,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    image = frame.image;
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (byteData == null) return null;

    final rgbaBytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    return _extractAverageArgbFromRgbaBytes(
      rgbaBytes,
      image.width,
      image.height,
    );
  } catch (e) {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}

final wallpaperBaseColorProvider = FutureProvider<Color?>((ref) async {
  final settings = ref.watch(settingsProvider.select((s) => (
        enabled: s.useCustomTheme || s.themeMode == 'custom',
        path: s.backgroundImagePath,
      )));

  if (!settings.enabled) return null;
  final path = settings.path;
  if (path == null || path.isEmpty) return null;

  final file = File(path);
  if (!await file.exists()) return null;

  final argb = await _extractAverageArgbFromFile(path);
  if (argb == null) return null;
  return Color(argb);
});

final wallpaperTintColorProvider = Provider<Color?>((ref) {
  final brightness =
      ref.watch(settingsProvider.select((s) => s.backgroundBrightness));
  final baseAsync = ref.watch(wallpaperBaseColorProvider);

  final base = baseAsync.maybeWhen(data: (value) => value, orElse: () => null);
  if (base == null) return null;
  return applyBlackOverlay(base, brightness);
});
