import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF7C4DFF); // #7C4DFF
  static const Color primaryLight = Color(0xFFEDE7F6); // violet tint
  static const Color secondary = Color(0xFFFF6B4A); // #FF6B4A

  // Background Colors
  static const Color background = Color(0xFF070B16); // #070B16
  static const Color backgroundWeb = Color(0xFF070B16);
  static const Color surface = Color(0xFF0D1323); // #0D1323
  static const Color card = Color(0xFF111827); // #111827

  // Text Colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textMuted = Colors.black38;

  // UI Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);

  static TextStyle get logoTextStyle => GoogleFonts.poppins(
        fontWeight: FontWeight.w800, // Poppins ExtraBold
      );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFFF5F6F8),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        background: const Color(0xFFF5F6F8),
        surface: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17.5,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        space: 1,
        thickness: 0.5,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background, // #070B16
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        background: background, // #070B16
        surface: surface, // #0D1323
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E293B),
        space: 1,
        thickness: 0.5,
      ),
    );
  }
}

extension AppThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg => isDarkMode ? const Color(0xFF070B16) : const Color(0xFFF5F6F8);
  Color get cardBg => isDarkMode ? const Color(0xFF111827) : Colors.white;
  Color get border => isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEEEEEE);
  Color get textPrimary => isDarkMode ? Colors.white : Colors.black87;
  Color get textSecondary => isDarkMode ? Colors.white70 : Colors.black54;
  Color get textMuted => isDarkMode ? Colors.white38 : Colors.black38;
  Color get primaryAccent => const Color(0xFF7C4DFF);
}
