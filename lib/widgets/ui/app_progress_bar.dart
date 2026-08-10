import 'package:flutter/material.dart';
import '../../services/app_settings.dart';
import '../../theme/app_tokens.dart';
import '../pixel/pixel.dart';

/// Progress meter — allocation, goal growth, survey position.
///
/// In the pixel skin this is a [PixelBar]: a parchment track with a 2px ink
/// outline and a striped fill. The eased fill animation is kept (it is what
/// makes a deposit feel like growth), but the shape is now square.
///
/// The API is unchanged. [color]/[gradient] are honoured loosely: a supplied
/// colour picks the closest pixel tone rather than flattening the stripes.
class AppProgressBar extends StatelessWidget {
  /// 0..1; values outside are clamped.
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final Gradient? gradient;

  /// Draw the fill in the danger tone (over budget).
  final bool over;

  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 13,
    this.color,
    this.trackColor,
    this.gradient,
    this.over = false,
  });

  /// Maps a legacy colour argument onto one of the pixel tones.
  PixelTone get _tone {
    final t = AppTokens.current;
    final c = color;
    if (c == null) return PixelTone.accent;
    if (c == t.gold || c == t.goldHi || c == t.warning) return PixelTone.gold;
    if (c == t.water || c == t.waterShadow) return PixelTone.water;
    return PixelTone.accent;
  }

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    final m = AppSettings.instance.motionMultiplier;
    final isOver = over || color == AppTokens.current.danger;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: Duration(milliseconds: (600 * m).round()),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => PixelBar(
        value: v,
        height: height,
        tone: _tone,
        over: isOver,
      ),
    );
  }
}
