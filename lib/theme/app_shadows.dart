import 'package:flutter/material.dart';

/// Reusable shadow + surface recipes for a consistent modern feel.
/// Use these on cards, buttons, and elevated UI surfaces.
class AppShadows {
  AppShadows._();

  /// Tight close shadow + diffuse far shadow — the standard recipe used
  /// throughout for a layered "lifted" feeling.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 30,
          spreadRadius: -2,
          offset: const Offset(0, 12),
        ),
      ];

  /// Smaller variant for chips, small buttons, etc.
  static List<BoxShadow> get pill => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];

  /// Soft glow around a featured / active surface (uses [accent]).
  static List<BoxShadow> accentGlow(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.45),
          blurRadius: 22,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];
}
