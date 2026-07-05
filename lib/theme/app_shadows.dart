import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Reusable shadow recipes, tuned per theme: soft ambient lift on the light
/// canvas, deeper contact shadows in dark mode.
class AppShadows {
  AppShadows._();

  static bool get _dark => AppTokens.current.brightness == Brightness.dark;

  /// Standard card lift — a diffuse ambient shadow plus a tight contact
  /// shadow, kept subtle so white cards float gently on the canvas.
  static List<BoxShadow> get card => _dark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ];

  /// Smaller variant for chips, small buttons, segmented-control thumbs.
  static List<BoxShadow> get pill => [
        BoxShadow(
          color: Colors.black.withValues(alpha: _dark ? 0.35 : 0.08),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  /// Soft glow around a featured / active surface (uses [accent]).
  static List<BoxShadow> accentGlow(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: _dark ? 0.40 : 0.25),
          blurRadius: 18,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: _dark ? 0.30 : 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}
