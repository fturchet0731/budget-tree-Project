import 'package:flutter/material.dart';
import '../services/app_settings.dart';

/// The conifer accent ramp — the app's single source of green. Brightness
/// independent; illustrations, accents, and progress fills pull from here.
///
/// The pixel redesign uses this ramp unchanged: the handoff's greens
/// (`#b3e465`, `#9CD744`, `#7EBD25`, `#4A7318`, `#3D5B19`) are exactly
/// c300/c400/c500/c700/c800.
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

/// The 16-bit chrome palette: parchment neutrals, hard outlines, and the two
/// non-green accent hues (gold for streak/XP/completed, water for goal
/// watering). Brightness independent — [AppTokens] picks per theme.
class Pixel {
  Pixel._();

  // Parchment / canvas.
  static const canvas = Color(0xFFEFE4CF);
  static const card = Color(0xFFFBF4E2);
  static const cardHi = Color(0xFFFFFDF5);

  // Inset panel tints (green / blue / soil).
  static const insetGreen = Color(0xFFEAF8CF);
  static const insetBlue = Color(0xFFEAF4FB);
  static const insetSoil = Color(0xFFF0E7DA);

  // Ink and outlines.
  static const ink = Color(0xFF2F2418); // primary 3px outline
  static const inkDeep = Color(0xFF16110A); // deep outline on dark panels
  static const hairline = Color(0xFFC9B48C); // hard drop shadow / hairline
  static const inkSoft = Color(0xFF6B5539); // secondary text
  static const soil = Color(0xFF8A6B4F); // tertiary text / soil
  static const body = Color(0xFF7A6A52); // Nunito helper copy

  // Gold — streaks, XP, completed goals.
  static const gold = Color(0xFFF2C14E);
  static const goldHi = Color(0xFFFFE08A);
  static const goldDeep = Color(0xFFD49A2A);
  static const goldShadow = Color(0xFFA87A1C);

  // Water — goal watering.
  static const water = Color(0xFF7FB8D9);
  static const waterDeep = Color(0xFF5C9BC0);
  static const waterShadow = Color(0xFF4A7FA0);

  // Alerts.
  static const ember = Color(0xFFE07A5F);
  static const alarm = Color(0xFFCC4B44);

  // Progress bar track.
  static const track = Color(0xFFD9C9A6);

  // Night chrome.
  static const nightCanvas = Color(0xFF241C14);
  static const nightPanel = Color(0xFF3A2E20);
  static const nightInset = Color(0xFF4A3B2A);
  static const nightBorder = Color(0xFF6B5539);
  static const nightText = Color(0xFFF4ECD8);
}

/// Semantic color roles for the 16-bit pixel look: parchment canvas, hard
/// outlined cards, and colour delivered through the Conifer ramp plus the gold
/// and water accents.
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

  /// The card's hard outline. In the pixel skin this is a real 3px border,
  /// not a hairline.
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

  // ── Pixel chrome ──────────────────────────────────────────────
  /// The colour of every hard offset drop shadow (cards, panels).
  final Color boxShadow;

  /// Deep outline used on dark/NPC panels.
  final Color inkDeep;

  /// Progress-bar track behind the striped fill.
  final Color track;

  /// Gold accent family (streaks, XP, completed).
  final Color gold;
  final Color goldHi;
  final Color goldShadow;

  /// Water accent family (goal watering).
  final Color water;
  final Color waterShadow;

  /// Shadow under a green [accent] button.
  final Color accentShadow;

  /// Dark NPC/dialogue panel (Acorn quest card, reflections).
  final Color panelDark;
  final Color panelDarkInset;
  final Color panelDarkBorder;
  final Color panelDarkText;

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
    required this.boxShadow,
    required this.inkDeep,
    required this.track,
    required this.gold,
    required this.goldHi,
    required this.goldShadow,
    required this.water,
    required this.waterShadow,
    required this.accentShadow,
    required this.panelDark,
    required this.panelDarkInset,
    required this.panelDarkBorder,
    required this.panelDarkText,
  });

  static const light = AppTokens._(
    brightness: Brightness.light,
    canvas: Pixel.canvas,
    canvasSoft: Pixel.insetSoil,
    card: Pixel.card,
    cardBorder: Pixel.ink,
    textPrimary: Pixel.ink,
    textSecondary: Pixel.inkSoft,
    textTertiary: Pixel.soil,
    accent: Conifer.c500,
    accentStrong: Conifer.c700,
    accentSoft: Conifer.c200,
    accentTint: Conifer.c100,
    onAccent: Pixel.inkDeep,
    success: Conifer.c700,
    warning: Pixel.ember,
    danger: Pixel.alarm,
    skyTint: Pixel.insetBlue,
    soilTint: Pixel.insetSoil,
    boxShadow: Pixel.hairline,
    inkDeep: Pixel.inkDeep,
    track: Pixel.track,
    gold: Pixel.gold,
    goldHi: Pixel.goldHi,
    goldShadow: Pixel.goldShadow,
    water: Pixel.water,
    waterShadow: Pixel.waterShadow,
    accentShadow: Conifer.c800,
    panelDark: Pixel.ink,
    panelDarkInset: Pixel.nightInset,
    panelDarkBorder: Pixel.inkDeep,
    panelDarkText: Pixel.nightText,
  );

  static const dark = AppTokens._(
    brightness: Brightness.dark,
    canvas: Pixel.nightCanvas,
    canvasSoft: Color(0xFF2E251A),
    card: Pixel.nightPanel,
    cardBorder: Pixel.nightBorder,
    textPrimary: Pixel.nightText,
    textSecondary: Color(0xFFC5B393),
    textTertiary: Color(0xFF9A876A),
    accent: Conifer.c500,
    accentStrong: Conifer.c300,
    accentSoft: Color(0xFF3F3A1E),
    accentTint: Color(0xFF32301B),
    onAccent: Pixel.inkDeep,
    success: Conifer.c300,
    warning: Pixel.ember,
    danger: Color(0xFFE06A63),
    skyTint: Color(0xFF2A3140),
    soilTint: Color(0xFF33291D),
    boxShadow: Pixel.inkDeep,
    inkDeep: Color(0xFF0C0906),
    track: Color(0xFF4A3B2A),
    gold: Pixel.gold,
    goldHi: Pixel.goldHi,
    goldShadow: Pixel.goldShadow,
    water: Pixel.water,
    waterShadow: Pixel.waterShadow,
    accentShadow: Conifer.c850,
    panelDark: Color(0xFF1B150E),
    panelDarkInset: Pixel.nightInset,
    panelDarkBorder: Pixel.inkDeep,
    panelDarkText: Pixel.nightText,
  );

  static AppTokens get current =>
      AppSettings.instance.isDark ? dark : light;

  static AppTokens of(BuildContext context) => current;
}
