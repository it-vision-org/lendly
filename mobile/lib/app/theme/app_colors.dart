import 'package:flutter/material.dart';

/// Lendly's palette — navy/blue/teal, modern and trustworthy-financial.
/// Every screen should read colors from [AppTheme]'s [ColorScheme] /
/// [AppSemanticColors] rather than hard-coding hex values, so the palette
/// stays consistent and can be re-tuned from one place.
abstract final class AppColors {
  static const primary = Color(0xFF1E3A8A);
  static const primaryDark = Color(0xFF13275C);
  static const primaryLight = Color(0xFFDDE6FA);
  static const accent = Color(0xFF0D9488);

  static const background = Color(0xFFF6F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF101B33);
  static const textSecondary = Color(0xFF5B6B82);

  static const border = Color(0xFFE3E8F0);
  static const divider = Color(0xFFEBEFF5);

  /// "Owed to me" / lent / fully paid — positive money movement.
  static const success = Color(0xFF16A34A);

  /// "I owe" / borrowed / partially paid — needs attention.
  static const warning = Color(0xFFD97706);

  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF0EA5E9);

  static const shadow = Color(0xFF101B33);
}
