import 'package:flutter/material.dart';

/// Govipala Color Tokens (06_UI_UX_GUIDE.md Section 2.1)
class GoviColors {
  GoviColors._();

  /// Main buttons, selected tab, headers ("paddy green")
  static const Color primary = Color(0xFF2E7D32);

  /// Pressed state, app bar text on light
  static const Color primaryDark = Color(0xFF1B5E20);

  /// Tinted backgrounds, selected chips
  static const Color primarySoft = Color(0xFFE8F5E9);

  /// Highlights, "waiting" status, rating stars ("harvest gold")
  static const Color accent = Color(0xFFF2A900);

  /// Screen background (warm off-white)
  static const Color background = Color(0xFFFAF8F3);

  /// Cards surface
  static const Color surface = Color(0xFFFFFFFF);

  /// Card outlines (used instead of shadows)
  static const Color border = Color(0xFFE3E8E0);

  /// Main text
  static const Color textPrimary = Color(0xFF1F2A1F);

  /// Hints, captions
  static const Color textSecondary = Color(0xFF5B665B);

  /// "In progress" status
  static const Color info = Color(0xFF1565C0);

  /// Errors, cancel, reject
  static const Color danger = Color(0xFFC62828);

  // Standard token aliases
  static const Color success = primary;
  static const Color warning = accent;
  static const Color error = danger;
  static const Color divider = border;
  static const Color accentDark = primaryDark;
  static const Color textMuted = textSecondary;
}
