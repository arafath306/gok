import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF7C4DFF); // #7C4DFF
  static const Color primaryLight = Color(0xFFEDE7F6); // violet tint
  static const Color secondary = Color(0xFFFF6B4A); // #FF6B4A

  // Dark Background Colors
  static const Color background = Color(0xFF070B16); // #070B16
  static const Color backgroundWeb = Color(0xFF070B16);
  static const Color surface = Color(0xFF0D1323); // #0D1323
  static const Color card = Color(0xFF111827); // #111827

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC); // #F8FAFC
  static const Color lightCard = Color(0xFFFFFFFF);       // #FFFFFF
  static const Color lightDivider = Color(0xFFE2E8F0);    // #E2E8F0
  static const Color lightTextPrimary = Color(0xFF0F172A); // #0F172A
  static const Color lightTextSecondary = Color(0xFF64748B); // #64748B
  static const Color lightGreen = Color(0xFF1E824C);      // #1E824C

  // Legacy Text Colors (used in static contexts)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Colors.black38;

  // UI Colors
  static const Color divider = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFD32F2F);

  static TextStyle get logoTextStyle => GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
      );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: lightCard,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: lightCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17.5,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
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
        surface: surface, // #0D1323
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

  Color get scaffoldBg => isDarkMode ? const Color(0xFF070B16) : const Color(0xFFF8FAFC);
  Color get cardBg     => isDarkMode ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  Color get border     => isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  Color get textPrimary    => isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get textSecondary  => isDarkMode ? Colors.white70 : const Color(0xFF64748B);
  Color get textMuted      => isDarkMode ? Colors.white38 : const Color(0xFF94A3B8);
  Color get primaryAccent  => const Color(0xFF1E824C); // Brand green
  Color get greenAccent    => const Color(0xFF1E824C);

  // Added for Auth Screens
  Color get authPrimary    => const Color(0xFF5B7FFF);
  Color get authSecondary  => const Color(0xFF7B5FFF);
  Color get authAccent1    => const Color(0xFF7C3AED);
  Color get authAccent2    => const Color(0xFF4F46E5);
  Color get buttonBg       => isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF0F172A);
  Color get customCardBg   => isDarkMode ? const Color(0xFF10132A) : Colors.white;
  Color get mutedBg        => isDarkMode ? const Color(0xFF070B13).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
}
