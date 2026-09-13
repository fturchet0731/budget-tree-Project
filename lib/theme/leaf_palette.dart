import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Four-stop colour ramp used by every leaf/crown drawing in the app.
/// Derived from a single accent colour so that user-chosen category colours
/// (e.g. blue "Trips", red "Emergency") tint every tree in that category
/// without breaking the natural-leaf gradient.
class LeafPalette {
  final Color light;
  final Color mid;
  final Color dark;
  final Color outline;

  const LeafPalette({
    required this.light,
    required this.mid,
    required this.dark,
    required this.outline,
  });

  /// Derive a leaf palette from an accent colour by walking the HSL lightness.
  factory LeafPalette.fromAccent(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    // Boost saturation slightly so very pale accents still read as a leaf.
    final sat = (hsl.saturation + 0.10).clamp(0.30, 0.90);

    Color shift(double lightness) => HSLColor.fromAHSL(
          1.0,
          hsl.hue,
          sat,
          lightness.clamp(0.05, 0.90),
        ).toColor();

    return LeafPalette(
      light: shift(hsl.lightness + 0.18),
      mid: shift(hsl.lightness),
      dark: shift(hsl.lightness - 0.18),
      outline: shift(hsl.lightness - 0.35),
    );
  }

  /// The default conifer-green palette used when no category is selected.
  static const defaultGreen = LeafPalette(
    light: Conifer.c300,
    mid: Conifer.c500,
    dark: Conifer.c700,
    outline: Conifer.c800,
  );

  /// Where a fully wilted canopy lands: dry amber and bark brown rather than a
  /// grey wash, so an unhealthy tree still reads as a plant and not a bug.
  static const _wilted = LeafPalette(
    light: Color(0xFFC9A227),
    mid: Color(0xFFA6762A),
    dark: Color(0xFF7A5326),
    outline: Color(0xFF4E351A),
  );

  /// This palette drained toward [_wilted] as [health] falls from 1 to 0.
  ///
  /// Every leaf and crown drawing in the app already reads its colour from a
  /// [LeafPalette] and nothing else, so shifting these four stops is the whole
  /// of "the tree looks less healthy" as far as colour goes. Health below 1
  /// never fully reaches the wilted end: even a neglected tree keeps a trace of
  /// green, because the point is that it can come back.
  LeafPalette withHealth(double health) {
    final t = (1 - health.clamp(0.0, 1.0)) * 0.85;
    if (t <= 0) return this;
    Color drain(Color from, Color to) => Color.lerp(from, to, t)!;
    return LeafPalette(
      light: drain(light, _wilted.light),
      mid: drain(mid, _wilted.mid),
      dark: drain(dark, _wilted.dark),
      outline: drain(outline, _wilted.outline),
    );
  }
}
