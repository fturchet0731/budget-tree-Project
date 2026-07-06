import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_settings.dart';
import 'app_dims.dart';
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
  static const Color barkBrown = Color(0xFF8A6B4F);
  static Color get darkBark => _t.card;
  static Color get stoneBeigeColor => _t.textPrimary;
  static const Color riverBlue = Color(0xFF5B8DB8);
  static const Color skyBlue = Color(0xFFBFE0F5);
  static Color get soilDark => _t.canvas;
  static Color get soilMid => _t.canvasSoft;
  static const Color leafYellow = Color(0xFFD4A843);
  static const Color leafOrange = Color(0xFFE8873A);
  static Color get warningAmber => _t.warning;
  static Color get dangerRed => _t.danger;
}

/// LEGACY — facade over [AppTokens]; deleted in the final redesign sweep.
/// The old full-screen forest/sky gradients are now near-flat neutral washes
/// so unmigrated screens sit on the new canvas. Each screen phase removes its
/// uses in favor of plain token backgrounds.
class AppPalettes {
  AppPalettes._();

  /// Was the dim interior forest gradient; now a near-flat canvas wash.
  static LinearGradient deepForest() {
    final t = AppTokens.current;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [t.canvas, t.canvasSoft],
    );
  }

  /// Was the bright sky-to-grass gradient; now a soft sky-tinted wash.
  static LinearGradient sky() {
    final t = AppTokens.current;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [t.skyTint, t.canvas, t.accentTint],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  /// Sun (light) / moon (dark) disc color.
  static Color celestial() => AppSettings.instance.isDark
      ? const Color(0xFFE3EEF7)
      : const Color(0xFFFFD54F);

  /// Soft glow around the celestial body.
  static Color celestialGlow() => AppSettings.instance.isDark
      ? const Color(0xFFB3C9E0)
      : const Color(0xFFFFE082);

  /// Scenery depth ramp — farther layers read lighter (light mode) or
  /// deeper (dark mode).
  static Color hillBack() => AppSettings.instance.isDark
      ? const Color(0xFF1B2410)
      : Conifer.c100;

  static Color hillMid() => AppSettings.instance.isDark
      ? const Color(0xFF1F2A12)
      : Conifer.c200;

  static Color groundClose() => AppSettings.instance.isDark
      ? const Color(0xFF2A3618)
      : Conifer.c400;

  static Color groundMid() => AppSettings.instance.isDark
      ? const Color(0xFF243014)
      : Conifer.c300;
}

/// The two app themes, built from the same [AppTokens] roles. Type is set
/// once here (Fredoka for display, Nunito for body) so per-widget GoogleFonts
/// calls can collapse over time.
class AppTheme {
  static ThemeData get light => _build(AppTokens.light);
  static ThemeData get dark => _build(AppTokens.dark);

  /// LEGACY — old single dark theme accessor; now resolves to the active
  /// token theme. Migrate call sites to [light]/[dark] via main.dart.
  static ThemeData get theme =>
      AppSettings.instance.isDark ? dark : light;

  static TextStyle _fredoka(double size, Color color,
          {FontWeight weight = FontWeight.w600, double? spacing}) =>
      GoogleFonts.fredoka(
        fontSize: size,
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
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: _fredoka(34, t.textPrimary),
        displayMedium: _fredoka(30, t.textPrimary),
        displaySmall: _fredoka(28, t.textPrimary),
        headlineLarge: _fredoka(26, t.textPrimary),
        headlineMedium: _fredoka(22, t.textPrimary),
        headlineSmall: _fredoka(20, t.textPrimary),
        titleLarge: _fredoka(18, t.textPrimary),
        titleMedium: _nunito(16, t.textPrimary, weight: FontWeight.w700),
        titleSmall: _nunito(14, t.textPrimary, weight: FontWeight.w700),
        bodyLarge: _nunito(16, t.textPrimary),
        bodyMedium: _nunito(14, t.textSecondary),
        bodySmall: _nunito(12.5, t.textSecondary),
        labelLarge: _nunito(12, t.textSecondary,
            weight: FontWeight.w800, spacing: 1.1),
        labelMedium: _nunito(11, t.textSecondary,
            weight: FontWeight.w700, spacing: 0.8),
        labelSmall: _nunito(10, t.textTertiary,
            weight: FontWeight.w700, spacing: 0.8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.brightness == Brightness.light ? t.canvasSoft : t.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rInner),
          borderSide: BorderSide(color: t.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rInner),
          borderSide: BorderSide(color: t.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rInner),
          borderSide: BorderSide(color: t.accent, width: 2),
        ),
        labelStyle: _nunito(15, t.textSecondary),
        hintStyle: _nunito(15, t.textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          disabledBackgroundColor: t.accentSoft,
          disabledForegroundColor: t.textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: _fredoka(16, t.onAccent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accentStrong,
          textStyle: _nunito(15, t.accentStrong, weight: FontWeight.w700),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _fredoka(20, t.textPrimary),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          t.accentStrong.withValues(alpha: 0.45),
        ),
        thickness: const WidgetStatePropertyAll(5),
        radius: const Radius.circular(8),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppDims.rSheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDims.rCard),
        ),
        titleTextStyle: _fredoka(20, t.textPrimary),
        contentTextStyle: _nunito(15, t.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.brightness == Brightness.light
            ? t.textPrimary
            : t.card,
        contentTextStyle: _nunito(
            14,
            t.brightness == Brightness.light ? Colors.white : t.textPrimary,
            weight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? t.onAccent : t.card),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? t.accent
                : t.canvasSoft),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? t.accent
                : t.cardBorder),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.canvasSoft,
        selectedColor: t.accentSoft,
        labelStyle: _nunito(13, t.textPrimary, weight: FontWeight.w700),
        side: BorderSide(color: t.cardBorder),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: t.cardBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.accentSoft,
      ),
    );
  }
}
