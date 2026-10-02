import 'package:flutter/material.dart';

/// Tema de la aplicación Multas AR.
class AppTheme {
  const AppTheme._();

  static const Color bg = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color surfaceEl = Color(0xFF21253A);
  static const Color border = Color(0xFF2D3150);
  static const Color accent = Color(0xFF4F6EF7);
  static const Color accentLight = Color(0xFF7B93F9);
  static const Color danger = Color(0xFFE05C5C);
  static const Color warning = Color(0xFFF0A800);
  static const Color success = Color(0xFF3ECF8E);
  static const Color text = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF9CA3B4);

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentLight,
        surface: surface,
        error: danger,
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }
}