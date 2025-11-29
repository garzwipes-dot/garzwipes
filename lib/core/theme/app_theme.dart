// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlack = Color(0xFF0E0F0E);
  static const Color primaryRed = Color(0xFF6A0D37); // Rojo más oscuro
  static const Color secondaryGrey = Color(0xFF2A2B2A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color accentRed = Color(
    0xFF8B1538,
  ); // Rojo original para acentos

  // Método helper para aplicar Poppins fácilmente
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    FontStyle? style,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textWhite,
      height: height,
      fontStyle: style,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBlack,
      primaryColor: primaryRed,
      fontFamily: 'Poppins',

      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: accentRed,
        surface: secondaryGrey,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlack,
        elevation: 0,
        titleTextStyle: poppins(fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: textWhite),
      ),

      // Text Theme con todos los pesos
      textTheme: TextTheme(
        displayLarge: poppins(fontSize: 32, fontWeight: FontWeight.w900),
        displayMedium: poppins(fontSize: 28, fontWeight: FontWeight.w800),
        displaySmall: poppins(fontSize: 24, fontWeight: FontWeight.w700),
        headlineLarge: poppins(fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: poppins(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: poppins(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: poppins(fontSize: 16, fontWeight: FontWeight.w500),
        titleMedium: poppins(fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: poppins(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: poppins(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: poppins(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textGrey,
        ),
        labelLarge: poppins(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: poppins(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: poppins(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: textGrey,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        labelStyle: poppins(color: textGrey),
        hintStyle: poppins(color: textGrey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: textWhite,
          textStyle: poppins(fontWeight: FontWeight.w600, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRed,
          textStyle: poppins(fontWeight: FontWeight.w500),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: secondaryGrey,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryBlack,
        selectedItemColor: primaryRed,
        unselectedItemColor: textGrey,
        selectedLabelStyle: poppins(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
