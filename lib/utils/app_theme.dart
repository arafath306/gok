import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF1E824C);
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color secondary = Color(0xFF2E7D32);

  // Background Colors
  static const Color background = Color(0xFFF5F6F8);
  static const Color backgroundWeb = Color(0xFFF4F6F8);
  static const Color surface = Colors.white;

  // Text Colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textMuted = Colors.black38;

  // UI Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        background: background,
        surface: surface,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.hindSiliguri(
          fontSize: 17.5,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      textTheme: GoogleFonts.hindSiliguriTextTheme(
        ThemeData.light().textTheme,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        space: 1,
        thickness: 0.5,
      ),
    );
  }
}
