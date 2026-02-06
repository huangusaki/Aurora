import 'package:flutter/material.dart';

Color applyBlackOverlay(Color color, double brightness) {
  final b = brightness.clamp(0.0, 1.0);
  final r = ((color.r * 255.0) * b).round().clamp(0, 255).toInt();
  final g = ((color.g * 255.0) * b).round().clamp(0, 255).toInt();
  final bl = ((color.b * 255.0) * b).round().clamp(0, 255).toInt();
  return Color.fromARGB(
    255,
    r,
    g,
    bl,
  );
}

Color tintSurfaceColor({
  required Color? wallpaperTint,
  required bool isDark,
  required Color fallback,
  double mix = 0.25,
}) {
  if (wallpaperTint == null) return fallback;
  final base = isDark ? Colors.black : Colors.white;
  return Color.lerp(base, wallpaperTint, mix) ?? wallpaperTint;
}

Color tintSurfaceColorFromBase({
  required Color? wallpaperTint,
  required Color base,
  required Color fallback,
  double mix = 0.25,
}) {
  if (wallpaperTint == null) return fallback;
  return Color.lerp(base, wallpaperTint, mix) ?? wallpaperTint;
}

Color tintedGlass({
  required Color? wallpaperTint,
  required bool isDark,
  required Color fallback,
  required double alpha,
  double mix = 0.25,
}) {
  return tintSurfaceColor(
    wallpaperTint: wallpaperTint,
    isDark: isDark,
    fallback: fallback,
    mix: mix,
  ).withValues(alpha: alpha);
}

Color tintedGlassFromBase({
  required Color? wallpaperTint,
  required Color base,
  required Color fallback,
  required double alpha,
  double mix = 0.25,
}) {
  return tintSurfaceColorFromBase(
    wallpaperTint: wallpaperTint,
    base: base,
    fallback: fallback,
    mix: mix,
  ).withValues(alpha: alpha);
}
