import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_settings.dart';
import 'app_tokens.dart';

/// LEGACY — migrate call sites to [AppTokens]; this class is deleted in the
/// final redesign sweep. Members are now theme-aware getters over the token
/// roles so every unmigrated screen adapts to light AND dark.
class AppColors {
  static AppTokens get _t => AppTokens.current;

  static Color get forestGreen => _t.accentStrong;
  static Color get darkForestGreen => _t.accentStrong;
  static Color get mossGreen => _t.textSecondary;
  static Color get leafGreen => _t.accent;
  static Color get lightLeaf => _t.accent;
  static const Color barkBrown = Pixel.soil;
  static Color get darkBark => _t.card;
  static Color get stoneBeigeColor => _t.textPrimary;
  static const Color riverBlue = Pixel.waterDeep;
  static const Color skyBlue = Color(0xFFBFE3F2);
  static Color get soilDark => _t.canvas;
  static Color get soilMid => _t.canvasSoft;
  static const Color leafYellow = Pixel.gold;
  static const Color leafOrange = Pixel.ember;
  static Color get warningAmber => _t.warning;
  static Color get dangerRed => _t.danger;
}

/// The two app themes, built from the same [AppTokens] roles.
///
/// **Type is a three-font system** (the handoff's rule):
/// * [display] — Pixelify Sans, headings and in-dialogue body.
/// * [label] — Silkscreen, all-caps stat/chip/badge text. Never below 9px.
/// * body — Nunito, small helper paragraphs (11–12px).
///
/// Everything is square: the theme sets zero-radius shapes so a stray
/// `ElevatedButton` or `Chip` can't reintroduce a pill.
class AppTheme {
  static ThemeData get light => _build(AppTokens.light);
  static ThemeData get dark => _build(AppTokens.dark);

  /// LEGACY — old single dark theme accessor; now resolves to the active
  /// token theme. Migrate call sites to [light]/[dark] via main.dart.
  static ThemeData get theme =>
      AppSettings.instance.isDark ? dark : light;

  /// Pixelify Sans — display type and Acorn's dialogue.
  static TextStyle display(double size, Color color,
          {FontWeight weight = FontWeight.w600, double? spacing}) =>
      GoogleFonts.pixelifySans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );

  /// Silkscreen — all-caps labels, stats, chips, badges.
  ///
  /// [size] is clamped to the handoff's 9px legibility floor; pass 10 for
  /// primary labels.
  static TextStyle label(double size, Color color,
          {FontWeight weight = FontWeight.w400, double spacing = 1.0}) =>
      GoogleFonts.silkscreen(
        fontSize: size < 9 ? 9 : size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );

  static TextStyle _nunito(double size, Color color,
          {FontWeight weight = FontWeight.w500, double? spacing}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );

  /// Square border used by every themed component.
  static const _square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);

  static ThemeData _build(AppTokens t) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Conifer.c500,
      brightness: t.brightness,
    ).copyWith(
      primary: t.accent,
      onPrimary: t.onAccent,
      secondary: t.accentStrong,
      surface: t.card,
      onSurface: t.textPrimary,
      error: t.danger,
      outline: t.cardBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.canvas,
      // No ripple — a spreading circle is the most "material" thing on screen
      // and fights the hard-edged press animation.
      splashFactory: NoSplash.splashFactory,
      textTheme: TextTheme(
        displayLarge: display(38, t.textPrimary, spacing: 0.5),
        displayMedium: display(30, t.textPrimary, spacing: 0.5),
        displaySmall: display(26, t.textPrimary, spacing: 0.5),
        headlineLarge: display(24, t.textPrimary),
        headlineMedium: display(22, t.textPrimary),
        headlineSmall: display(20, t.textPrimary),
        titleLarge: display(18, t.textPrimary),
        titleMedium: display(17, t.textPrimary),
        titleSmall: display(15, t.textPrimary),
        bodyLarge: _nunito(13, t.textPrimary),
        bodyMedium: _nunito(12, Pixel.body),
        bodySmall: _nunito(11, Pixel.body),
        labelLarge: label(10, t.textSecondary, spacing: 1.0),
        labelMedium: label(9, t.textSecondary, spacing: 1.2),
        labelSmall: label(9, t.textTertiary, spacing: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.brightness == Brightness.light ? t.card : t.canvasSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: t.cardBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: t.cardBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: t.accent, width: 3),
        ),
        labelStyle: label(10, t.textSecondary),
        hintStyle: _nunito(12, t.textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          disabledBackgroundColor: t.canvasSoft,
          disabledForegroundColor: t.textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: _square,
          side: BorderSide(color: t.cardBorder, width: 3),
          textStyle: label(11, t.onAccent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accentStrong,
          shape: _square,
          textStyle: label(10, t.accentStrong),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display(22, t.textPrimary),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(t.textTertiary),
        thickness: const WidgetStatePropertyAll(6),
        radius: Radius.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: _square,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: _square,
        titleTextStyle: display(20, t.textPrimary),
        contentTextStyle: _nunito(12, Pixel.body),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.panelDark,
        contentTextStyle: display(15, t.panelDarkText),
        shape: _square,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? t.onAccent : t.card),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? t.accent
                : t.canvasSoft),
        trackOutlineColor: WidgetStatePropertyAll(t.cardBorder),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.card,
        selectedColor: t.accent,
        labelStyle: label(9, t.textPrimary),
        side: BorderSide(color: t.cardBorder, width: 2),
        shape: _square,
      ),
      dividerTheme: DividerThemeData(
        color: t.cardBorder,
        thickness: 2,
        space: 2,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.track,
      ),
    );
  }
}
