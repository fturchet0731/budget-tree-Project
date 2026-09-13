import 'package:flutter/widgets.dart';

/// Shared shape and spacing scale for the 16-bit pixel look.
///
/// **Every radius is 0.** Hard edges are the single rule that makes the app
/// read as a game; the `r*` names are kept so existing call sites keep
/// compiling, but they all resolve to square corners. Don't reintroduce a
/// rounded radius — use [PixelBox] and friends instead.
class AppDims {
  AppDims._();

  /// Cards and illustration containers.
  static const rCard = 0.0;

  /// Inputs and nested tiles.
  static const rInner = 0.0;

  /// Bottom sheet top corners.
  static const rSheet = 0.0;

  /// Buttons, chips, progress bars.
  static const rPill = 0.0;

  // ── Pixel chrome ──────────────────────────────────────────────
  /// Outline on cards, buttons, and panels.
  static const borderThick = 3.0;

  /// Outline on nested/inset boxes.
  static const borderThin = 2.0;

  /// Hard drop-shadow offset for cards (and how far they travel when pressed).
  static const dropCard = 5.0;

  /// Hard drop-shadow offset for buttons.
  static const dropButton = 4.0;

  /// Hard drop-shadow offset for small controls (icon buttons, chips).
  static const dropSmall = 3.0;

  /// Minimum tappable dimension — the handoff pins every control to 44px.
  static const tap = 44.0;

  // 4pt spacing scale.
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  /// Screen padding — the prototype uses a tight 14px gutter.
  static const pagePad = EdgeInsets.symmetric(horizontal: 14);
}
