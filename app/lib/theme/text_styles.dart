import 'package:flutter/material.dart';
import 'colors.dart';

/// Govipala Typography (06_UI_UX_GUIDE.md Section 2.3)
/// Line height 1.4-1.5 for Sinhala font rendering without clipping.
class GoviTextStyles {
  GoviTextStyles._();

  static const String sinhalaFontFamily = 'NotoSansSinhala';

  static const TextStyle screenTitle = TextStyle(
    fontFamily: sinhalaFontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    height: 1.4,
    color: GoviColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: sinhalaFontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    height: 1.4,
    color: GoviColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: sinhalaFontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: GoviColors.textPrimary,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: sinhalaFontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    height: 1.5,
    color: GoviColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: sinhalaFontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: GoviColors.textSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: sinhalaFontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    height: 1.4,
    color: Colors.white,
  );

  // Typography aliases
  static const TextStyle heading1 = screenTitle;
  static const TextStyle heading2 = sectionTitle;
  static const TextStyle bodyText = body;
}
