import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'text_styles.dart';

/// Govipala Application Theme
class GoviTheme {
  GoviTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: GoviColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GoviColors.primary,
        primary: GoviColors.primary,
        secondary: GoviColors.accent,
        surface: GoviColors.surface,
        error: GoviColors.danger,
      ),
      fontFamily: GoviTextStyles.sinhalaFontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: GoviColors.background,
        foregroundColor: GoviColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoviTextStyles.sectionTitle,
      ),
      cardTheme: CardThemeData(
        color: GoviColors.surface,
        elevation: 0, // No heavy shadows (06_UI_UX_GUIDE.md Section 2.4)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
          side: const BorderSide(color: GoviColors.border, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GoviColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(GoviSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
          ),
          textStyle: GoviTextStyles.buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GoviColors.primary,
          minimumSize: const Size.fromHeight(GoviSpacing.buttonHeight),
          side: const BorderSide(color: GoviColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
          ),
          textStyle: GoviTextStyles.bodyBold.copyWith(color: GoviColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GoviColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
          borderSide: const BorderSide(color: GoviColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
          borderSide: const BorderSide(color: GoviColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
          borderSide: const BorderSide(color: GoviColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
          borderSide: const BorderSide(color: GoviColors.danger),
        ),
        labelStyle: GoviTextStyles.body.copyWith(color: GoviColors.textSecondary),
        hintStyle: GoviTextStyles.body.copyWith(color: GoviColors.textSecondary),
      ),
    );
  }
}
