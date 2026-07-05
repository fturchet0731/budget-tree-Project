import 'package:flutter/material.dart';
import '../services/app_settings.dart';

/// The conifer accent ramp — the app's single source of green. Brightness
/// independent; illustrations, accents, and progress fills pull from here.
class Conifer {
  Conifer._();
  static const c50 = Color(0xFFF6FCE9);
  static const c100 = Color(0xFFEAF8CF);
  static const c200 = Color(0xFFD5F1A5);
  static const c300 = Color(0xFFB3E465);
  static const c400 = Color(0xFF9CD744);
  static const c500 = Color(0xFF7EBD25);
  static const c600 = Color(0xFF60961A);
  static const c700 = Color(0xFF4A7318);
  static const c800 = Color(0xFF3D5B19);
  static const c850 = Color(0xFF354E19);
  static const c950 = Color(0xFF192B08);
}

/// Semantic color roles for the modern minimal look: neutral canvas, white
/// cards, and color delivered through accents and illustration tints.
///
/// Two const instances exist (light/dark); everything reads [current], which
/// switches on `AppSettings.instance.palette`. A static accessor (rather than
/// a ThemeExtension) because many CustomPainters read colors without a
/// BuildContext, and the whole app already rebuilds via the AnimatedBuilder
/// on AppSettings in main.dart.
class AppTokens {
  final Brightness brightness;

  /// Scaffold background.
  final Color canvas;

  /// Tinted section background / input fill.
  final Color canvasSoft;

  /// Card surface.
  final Color card;

  /// Hairline border on cards and inputs.
  final Color cardBorder;

  final Color textPrimary;
  final Color textSecondary;

  /// Hints and disabled text.
  final Color textTertiary;

  /// Primary action / progress fill.
  final Color accent;

  /// Pressed / emphasis / small text sitting on a tint.
  final Color accentStrong;

  /// Chip and secondary-button fill.
  final Color accentSoft;

  /// Illustration container background.
  final Color accentTint;

  /// Text/icon on [accent].
  final Color onAccent;

  final Color success;
  final Color warning;
  final Color danger;

  /// Illustration sky wash.
  final Color skyTint;

  /// Illustration ground wash.
  final Color soilTint;

  const AppTokens._({
    required this.brightness,
    required this.canvas,
    required this.canvasSoft,
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentTint,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.skyTint,
    required this.soilTint,
  });

  static const light = AppTokens._(
    brightness: Brightness.light,
    canvas: Color(0xFFF7F6F1),
    canvasSoft: Color(0xFFEFEEE6),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE8E6DD),
    textPrimary: Color(0xFF20261B),
    textSecondary: Color(0xFF6B7263),
    textTertiary: Color(0xFF9AA091),
    accent: Conifer.c500,
    accentStrong: Conifer.c600,
    accentSoft: Conifer.c100,
    accentTint: Conifer.c50,
    onAccent: Colors.white,
    success: Conifer.c600,
    warning: Color(0xFFE8A230),
    danger: Color(0xFFCC4B44),
    skyTint: Color(0xFFEAF4FB),
    soilTint: Color(0xFFF0E7DA),
  );

  static const dark = AppTokens._(
    brightness: Brightness.dark,
    canvas: Color(0xFF15170F),
    canvasSoft: Color(0xFF1B1E13),
    card: Color(0xFF20241A),
    cardBorder: Color(0xFF2C3122),
    textPrimary: Color(0xFFF2F4EA),
    textSecondary: Color(0xFFA9B09B),
    textTertiary: Color(0xFF767D69),
    accent: Conifer.c400,
    accentStrong: Conifer.c300,
    accentSoft: Color(0xFF2A3618),
    accentTint: Color(0xFF222D14),
    onAccent: Conifer.c950,
    success: Conifer.c400,
    warning: Color(0xFFF0B24A),
    danger: Color(0xFFE06A63),
    skyTint: Color(0xFF1C2430),
    soilTint: Color(0xFF241F16),
  );

  static AppTokens get current =>
      AppSettings.instance.isDark ? dark : light;

  static AppTokens of(BuildContext context) => current;
}
