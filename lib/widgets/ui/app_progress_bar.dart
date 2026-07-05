import 'package:flutter/material.dart';
import '../../services/app_settings.dart';
import '../../theme/app_tokens.dart';

/// Pill progress bar with an eased animated fill — the standard way progress
/// (allocation, goal growth, survey position) reads in the redesign.
class AppProgressBar extends StatelessWidget {
  /// 0..1; values outside are clamped.
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final Gradient? gradient;

  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color,
    this.trackColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final target = value.clamp(0.0, 1.0);
    final m = AppSettings.instance.motionMultiplier;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: Duration(milliseconds: (600 * m).round()),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Stack(
            children: [
              Container(color: trackColor ?? t.accentSoft),
              FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: gradient == null ? (color ?? t.accent) : null,
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
