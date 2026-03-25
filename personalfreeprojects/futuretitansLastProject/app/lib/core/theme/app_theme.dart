import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color primaryGoldDark = Color(0xFFB8952E);
  static const Color primaryGoldLight = Color(0xFFF5D76E);
  
  static const Color backgroundCream = Color(0xFFF5EDD6); // '#FAF8F3' but warmer cream
  static const Color surfaceWhite = Colors.white;
  static const Color darkBackground = Color(0xFF1A1A1A);
  
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Colors.white;
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGold,
        primary: primaryGold,
        onPrimary: textLight,
        secondary: primaryGoldDark,
        background: backgroundCream,
        surface: surfaceWhite,
        onSurface: textDark,
        onBackground: textDark,
      ),
      scaffoldBackgroundColor: backgroundCream,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textDark),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textDark),
        displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textDark),
        headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textDark),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textDark),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textDark),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: textLight,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
