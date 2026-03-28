import 'package:aurora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BackgroundStyleOption {
  final String key;
  final List<Color> darkPreviewColors;
  final List<Color> lightPreviewColors;

  const BackgroundStyleOption({
    required this.key,
    required this.darkPreviewColors,
    required this.lightPreviewColors,
  });

  bool get visibleInLightMode => key != 'pure_black';
}

const backgroundStyleOptions = <BackgroundStyleOption>[
  BackgroundStyleOption(
    key: 'default',
    darkPreviewColors: [Color(0xFF2B2B2B)],
    lightPreviewColors: [Color(0xFFE0F7FA), Color(0xFFF1F8E9)],
  ),
  BackgroundStyleOption(
    key: 'pure_black',
    darkPreviewColors: [Color(0xFF000000)],
    lightPreviewColors: [Color(0xFFFFFFFF)],
  ),
  BackgroundStyleOption(
    key: 'warm',
    darkPreviewColors: [Color(0xFF1E1C1A), Color(0xFF2E241E)],
    lightPreviewColors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
  ),
  BackgroundStyleOption(
    key: 'cool',
    darkPreviewColors: [Color(0xFF1A1C1E), Color(0xFF1E252E)],
    lightPreviewColors: [Color(0xFFE1F5FE), Color(0xFFE3F2FD)],
  ),
  BackgroundStyleOption(
    key: 'rose',
    darkPreviewColors: [Color(0xFF2D1A1E), Color(0xFF3B1E26)],
    lightPreviewColors: [Color(0xFFFCE4EC), Color(0xFFFFEBEE)],
  ),
  BackgroundStyleOption(
    key: 'lavender',
    darkPreviewColors: [Color(0xFF1F1A2D), Color(0xFF261E3B)],
    lightPreviewColors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
  ),
  BackgroundStyleOption(
    key: 'mint',
    darkPreviewColors: [Color(0xFF1A2D24), Color(0xFF1E3B2E)],
    lightPreviewColors: [Color(0xFFE0F2F1), Color(0xFFE8F5E9)],
  ),
  BackgroundStyleOption(
    key: 'sky',
    darkPreviewColors: [Color(0xFF1A202D), Color(0xFF1E263B)],
    lightPreviewColors: [Color(0xFFE0F7FA), Color(0xFFE1F5FE)],
  ),
  BackgroundStyleOption(
    key: 'gray',
    darkPreviewColors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
    lightPreviewColors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
  ),
  BackgroundStyleOption(
    key: 'sunset',
    darkPreviewColors: [Color(0xFF1A0B0E), Color(0xFF4A1F28)],
    lightPreviewColors: [Color(0xFFFFF3E0), Color(0xFFFBE9E7)],
  ),
  BackgroundStyleOption(
    key: 'ocean',
    darkPreviewColors: [Color(0xFF05101A), Color(0xFF0D2B42)],
    lightPreviewColors: [Color(0xFFE3F2FD), Color(0xFFE8EAF6)],
  ),
  BackgroundStyleOption(
    key: 'forest',
    darkPreviewColors: [Color(0xFF051408), Color(0xFF0E3316)],
    lightPreviewColors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
  ),
  BackgroundStyleOption(
    key: 'dream',
    darkPreviewColors: [Color(0xFF120817), Color(0xFF261233)],
    lightPreviewColors: [Color(0xFFEDE7F6), Color(0xFFE8EAF6)],
  ),
  BackgroundStyleOption(
    key: 'aurora',
    darkPreviewColors: [Color(0xFF051715), Color(0xFF181533)],
    lightPreviewColors: [Color(0xFFE0F2F1), Color(0xFFEDE7F6)],
  ),
  BackgroundStyleOption(
    key: 'volcano',
    darkPreviewColors: [Color(0xFF1F0808), Color(0xFF3E1212)],
    lightPreviewColors: [Color(0xFFFBE9E7), Color(0xFFFFEBEE)],
  ),
  BackgroundStyleOption(
    key: 'midnight',
    darkPreviewColors: [Color(0xFF020205), Color(0xFF141426)],
    lightPreviewColors: [Color(0xFFECEFF1), Color(0xFFFAFAFA)],
  ),
  BackgroundStyleOption(
    key: 'dawn',
    darkPreviewColors: [Color(0xFF141005), Color(0xFF33260D)],
    lightPreviewColors: [Color(0xFFFFFDE7), Color(0xFFFFF8E1)],
  ),
  BackgroundStyleOption(
    key: 'neon',
    darkPreviewColors: [Color(0xFF08181A), Color(0xFF240C21)],
    lightPreviewColors: [Color(0xFFE0F7FA), Color(0xFFF3E5F5)],
  ),
  BackgroundStyleOption(
    key: 'blossom',
    darkPreviewColors: [Color(0xFF1F050B), Color(0xFF3D0F19)],
    lightPreviewColors: [Color(0xFFFFEBEE), Color(0xFFFCE4EC)],
  ),
];

Iterable<BackgroundStyleOption> visibleBackgroundStyleOptions(bool isDark) {
  return isDark
      ? backgroundStyleOptions
      : backgroundStyleOptions.where((style) => style.visibleInLightMode);
}

String backgroundStyleLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'default':
      return l10n.bgDefault;
    case 'pure_black':
      return l10n.bgPureBlack;
    case 'warm':
      return l10n.bgWarm;
    case 'cool':
      return l10n.bgCool;
    case 'rose':
      return l10n.bgRose;
    case 'lavender':
      return l10n.bgLavender;
    case 'mint':
      return l10n.bgMint;
    case 'sky':
      return l10n.bgSky;
    case 'gray':
      return l10n.bgGray;
    case 'sunset':
      return l10n.bgSunset;
    case 'ocean':
      return l10n.bgOcean;
    case 'forest':
      return l10n.bgForest;
    case 'dream':
      return l10n.bgDream;
    case 'aurora':
      return l10n.bgAurora;
    case 'volcano':
      return l10n.bgVolcano;
    case 'midnight':
      return l10n.bgMidnight;
    case 'dawn':
      return l10n.bgDawn;
    case 'neon':
      return l10n.bgNeon;
    case 'blossom':
      return l10n.bgBlossom;
    default:
      return l10n.bgDefault;
  }
}
