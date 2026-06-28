import 'package:flutter/material.dart';
import '../services/app_settings.dart';

class AppColors {
  static const Color forestGreen = Color(0xFF2D5A27);
  static const Color darkForestGreen = Color(0xFF1A3A16);
  static const Color mossGreen = Color(0xFF8B9556);
  static const Color leafGreen = Color(0xFF4A7C40);
  static const Color lightLeaf = Color(0xFF6AB04C);
  static const Color barkBrown = Color(0xFF6B4226);
  static const Color darkBark = Color(0xFF3D2B1F);
  static const Color stoneBeigeColor = Color(0xFFC4B69A);
  static const Color riverBlue = Color(0xFF5B8DB8);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color soilDark = Color(0xFF0F0A05);
  static const Color soilMid = Color(0xFF1C1008);
  static const Color leafYellow = Color(0xFFD4A843);
  static const Color leafOrange = Color(0xFFE8873A);
  static const Color warningAmber = Color(0xFFE8A230);
  static const Color dangerRed = Color(0xFFB84040);
}

/// Palette-aware helpers. Reads the active [AppPalette] from
/// [AppSettings.instance] and returns gradient stops / colors tuned
/// to that palette. Every visual surface in the app pulls from here
/// so the Settings palette toggle changes the entire app's mood.
class AppPalettes {
  AppPalettes._();

  /// Dim interior background (dashboard, grove, settings, forest grid).
  static LinearGradient deepForest() {
    switch (AppSettings.instance.palette) {
      case AppPalette.forestDark:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1F08),
            Color(0xFF112B0E),
            Color(0xFF1A3A16),
            Color(0xFF1C1008),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        );
      case AppPalette.midnight:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF03060E),
            Color(0xFF080E1F),
            Color(0xFF0E1A2E),
            Color(0xFF0A1410),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        );
      case AppPalette.twilight:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF200A2C),
            Color(0xFF35153B),
            Color(0xFF3A1C3F),
            Color(0xFF1F1126),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        );
    }
  }

  /// Bright outdoor sky-to-grass gradient (home screen, immersive forest,
  /// goal detail, budget tree, create goal). Adapts by palette.
  static LinearGradient sky() {
    switch (AppSettings.instance.palette) {
      case AppPalette.forestDark:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A3D7A),
            Color(0xFF1565C0),
            Color(0xFF2196F3),
            Color(0xFF64B5F6),
            Color(0xFFB3E5FC),
            Color(0xFFAED581),
            Color(0xFF7CB342),
          ],
          stops: [0.0, 0.08, 0.22, 0.40, 0.58, 0.72, 1.0],
        );
      case AppPalette.midnight:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF030814),
            Color(0xFF0B1428),
            Color(0xFF152340),
            Color(0xFF1F3460),
            Color(0xFF2B4A80),
            Color(0xFF18382B),
            Color(0xFF12281C),
          ],
          stops: [0.0, 0.08, 0.22, 0.40, 0.58, 0.72, 1.0],
        );
      case AppPalette.twilight:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1F0A30),
            Color(0xFF3F1545),
            Color(0xFF6B2356),
            Color(0xFFAA3B5C),
            Color(0xFFD9684D),
            Color(0xFF8C5C44),
            Color(0xFF3D3528),
          ],
          stops: [0.0, 0.08, 0.22, 0.40, 0.58, 0.72, 1.0],
        );
    }
  }

  /// Color of the sun / moon / setting sun for whichever palette is active.
  static Color celestial() {
    switch (AppSettings.instance.palette) {
      case AppPalette.forestDark:
        return const Color(0xFFFFF176); // bright sun
      case AppPalette.midnight:
        return const Color(0xFFE3EEF7); // moon — cool white
      case AppPalette.twilight:
        return const Color(0xFFFFB870); // setting sun — warm
    }
  }

  /// Soft glow color used around the celestial body.
  static Color celestialGlow() {
    switch (AppSettings.instance.palette) {
      case AppPalette.forestDark:
        return const Color(0xFFFFEB3B);
      case AppPalette.midnight:
        return const Color(0xFFB3C9E0);
      case AppPalette.twilight:
        return const Color(0xFFFF8A65);
    }
  }

  /// Far hill color (back layer).
  static Color hillBack() {
    switch (AppSettings.instance.palette) {
      case AppPalette.forestDark:
        return const Color(0xFF558B2F);
      case AppPalette.midnight:
        return const Color(0xFF132A1E);
      case AppPalette.twilight:
        return const Color(0xFF4A2C44);
    }
  }

  /// Mid hill color (front layer).
  static Color hillMid() {
    switch (AppSettings.instance.palette) {
      case AppPalette.forestDark:
        return const Color(0xFF388E3C);
      case AppPalette.midnight:
        return const Color(0xFF0F1F18);
      case AppPalette.twilight:
        return const Color(0xFF36202E);
    }
  }

  /// Foreground grass strip — the closer near ground.
  static Color groundClose() {
    switch (AppSettings.instance.palette) {
      case AppPalette.forestDark:
        return const Color(0xFF1B5E20);
      case AppPalette.midnight:
        return const Color(0xFF0A1A12);
      case AppPalette.twilight:
        return const Color(0xFF2A1820);
    }
  }

  /// A second-layer ground tint, lighter than [groundClose].
  static Color groundMid() {
    switch (AppSettings.instance.palette) {
      case AppPalette.forestDark:
        return const Color(0xFF2E7D32);
      case AppPalette.midnight:
        return const Color(0xFF14281C);
      case AppPalette.twilight:
        return const Color(0xFF3D2030);
    }
  }
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: AppColors.soilDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.forestGreen,
          secondary: AppColors.mossGreen,
          surface: AppColors.darkBark,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(
            AppColors.lightLeaf.withValues(alpha: 0.55),
          ),
          thickness: const WidgetStatePropertyAll(5),
          radius: const Radius.circular(8),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.stoneBeigeColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          headlineMedium: TextStyle(color: AppColors.stoneBeigeColor),
          bodyLarge: TextStyle(color: AppColors.stoneBeigeColor),
          bodyMedium: TextStyle(color: Color(0xFFAA9980)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkBark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.mossGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AppColors.mossGreen.withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.forestGreen, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.stoneBeigeColor),
          hintStyle: const TextStyle(color: Color(0xFF7A6A55)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBark,
          foregroundColor: AppColors.stoneBeigeColor,
          elevation: 0,
        ),
      );
}
