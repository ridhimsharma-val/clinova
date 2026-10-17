import 'package:flutter/material.dart';
import 'clinova_colors.dart';

class ClinovaTheme {
  ClinovaTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ClinovaColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ClinovaColors.primaryAccent,
        onPrimary: Colors.white,
        primaryContainer: ClinovaColors.primaryBackground,
        onPrimaryContainer: ClinovaColors.primaryText,
        secondary: ClinovaColors.secondaryAccent,
        onSecondary: Colors.white,
        secondaryContainer: ClinovaColors.secondaryBackground,
        onSecondaryContainer: ClinovaColors.primaryText,
        surface: ClinovaColors.surfaceWhite,
        onSurface: ClinovaColors.primaryText,
        error: ClinovaColors.error,
        onError: Colors.white,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: ClinovaColors.primaryText,
          letterSpacing: -0.5,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: ClinovaColors.primaryText,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ClinovaColors.primaryText,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ClinovaColors.primaryText,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ClinovaColors.primaryText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ClinovaColors.primaryText,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ClinovaColors.secondaryText,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ClinovaColors.tertiaryText,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ClinovaColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
          color: ClinovaColors.tertiaryText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: ClinovaColors.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClinovaColors.borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClinovaColors.primaryAccent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClinovaColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ClinovaColors.error, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ClinovaColors.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ClinovaColors.primaryText),
        titleTextStyle: TextStyle(
          color: ClinovaColors.primaryText,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
