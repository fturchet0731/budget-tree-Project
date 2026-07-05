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
}
