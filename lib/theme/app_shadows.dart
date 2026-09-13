import 'package:flutter/material.dart';
import 'app_dims.dart';
import 'app_tokens.dart';

/// Hard offset drop shadows — the pixel skin's depth cue.
///
/// **No blur, no spread, y-offset only.** A blurred shadow immediately reads
/// as "modern app" again and breaks the 16-bit illusion, so every recipe here
/// is a solid rectangle sitting under the box. Pressing a control collapses
/// its shadow to zero and translates it down by the same amount (see
/// [PixelBox]/[PixelButton]) — that pairing is the "button depress".
class AppShadows {
  AppShadows._();

  static List<BoxShadow> _hard(Color color, double dy) => [
        BoxShadow(color: color, offset: Offset(0, dy)),
      ];

  /// Standard card lift.
  static List<BoxShadow> get card =>
      _hard(AppTokens.current.boxShadow, AppDims.dropCard);

  /// Smaller variant for chips, icon buttons, segmented-control thumbs.
  static List<BoxShadow> get pill =>
      _hard(AppTokens.current.boxShadow, AppDims.dropSmall);

  /// Shadow under a green primary button.
  static List<BoxShadow> get accentButton =>
      _hard(AppTokens.current.accentShadow, AppDims.dropButton);

  /// Shadow under a gold (streak / accept / completed) control.
  static List<BoxShadow> get goldButton =>
      _hard(AppTokens.current.goldShadow, AppDims.dropSmall);

  /// Shadow under a blue (water) control.
  static List<BoxShadow> get waterButton =>
      _hard(AppTokens.current.waterShadow, AppDims.dropCard);

  /// Kept for older call sites that asked for a highlight around an active
  /// surface. In the pixel skin there is no glow — it resolves to the plain
  /// hard card shadow so nothing blurs.
  static List<BoxShadow> accentGlow(Color accent) => card;
}
