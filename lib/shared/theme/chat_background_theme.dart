import 'package:flutter/material.dart';

class ChatBackgroundTheme {
  static const _lightDefaultGradient = [
    Color(0xFFE0F7FA),
    Color(0xFFF1F8E9),
  ];

  static const _gradients = <String, ({List<Color> dark, List<Color> light})>{
    'default': (
      dark: [Color(0xFF2B2B2B), Color(0xFF2B2B2B)],
      light: _lightDefaultGradient,
    ),
    'warm': (
      dark: [Color(0xFF1E1C1A), Color(0xFF2E241E)],
      light: [Color(0xFFFFF8F0), Color(0xFFFFEBD6)],
    ),
    'cool': (
      dark: [Color(0xFF1A1C1E), Color(0xFF1E252E)],
      light: [Color(0xFFF0F8FF), Color(0xFFD6EAFF)],
    ),
    'rose': (
      dark: [Color(0xFF2D1A1E), Color(0xFF3B1E26)],
      light: [Color(0xFFFFF0F5), Color(0xFFFFD6E4)],
    ),
    'lavender': (
      dark: [Color(0xFF1F1A2D), Color(0xFF261E3B)],
      light: [Color(0xFFF3E5F5), Color(0xFFE6D6FF)],
    ),
    'mint': (
      dark: [Color(0xFF1A2D24), Color(0xFF1E3B2E)],
      light: [Color(0xFFE0F2F1), Color(0xFFC2E8DC)],
    ),
    'sky': (
      dark: [Color(0xFF1A202D), Color(0xFF1E263B)],
      light: [Color(0xFFE1F5FE), Color(0xFFC7E6FF)],
    ),
    'gray': (
      dark: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
      light: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
    ),
    'sunset': (
      dark: [Color(0xFF1A0B0E), Color(0xFF4A1F28)],
      light: [Color(0xFFFFF3E0), Color(0xFFFFCCBC)],
    ),
    'ocean': (
      dark: [Color(0xFF05101A), Color(0xFF0D2B42)],
      light: [Color(0xFFE1F5FE), Color(0xFF81D4FA)],
    ),
    'forest': (
      dark: [Color(0xFF051408), Color(0xFF0E3316)],
      light: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
    ),
    'dream': (
      dark: [Color(0xFF120817), Color(0xFF261233)],
      light: [Color(0xFFF3E5F5), Color(0xFFBBDEFB)],
    ),
    'aurora': (
      dark: [Color(0xFF051715), Color(0xFF181533)],
      light: [Color(0xFFE0F2F1), Color(0xFFD1C4E9)],
    ),
    'volcano': (
      dark: [Color(0xFF1F0808), Color(0xFF3E1212)],
      light: [Color(0xFFFFEBEE), Color(0xFFFFCCBC)],
    ),
    'midnight': (
      dark: [Color(0xFF020205), Color(0xFF141426)],
      light: [Color(0xFFECEFF1), Color(0xFF90A4AE)],
    ),
    'dawn': (
      dark: [Color(0xFF141005), Color(0xFF33260D)],
      light: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
    ),
    'neon': (
      dark: [Color(0xFF08181A), Color(0xFF240C21)],
      light: [Color(0xFFE0F7FA), Color(0xFFE1BEE7)],
    ),
    'blossom': (
      dark: [Color(0xFF1F050B), Color(0xFF3D0F19)],
      light: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
    ),
  };

  static List<Color>? getGradient(String style, {required bool isDark}) {
    if (style == 'pure_black') {
      return isDark ? const [Color(0xFF000000), Color(0xFF000000)] : null;
    }

    final gradient = _gradients[style];
    if (gradient == null) {
      return isDark ? null : _lightDefaultGradient;
    }
    return isDark ? gradient.dark : gradient.light;
  }

  static Color getSolidBackgroundColor(String style, {required bool isDark}) {
    if (!isDark) {
      return Colors.white;
    }

    switch (style) {
      case 'pure_black':
        return const Color(0xFF000000);
      case 'warm':
        return const Color(0xFF1E1C1A);
      case 'cool':
        return const Color(0xFF1A1C1E);
      case 'default':
      default:
        return const Color(0xFF202020);
    }
  }
}
