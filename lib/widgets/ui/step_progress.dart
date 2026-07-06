import 'package:flutter/material.dart';
import '../../services/app_settings.dart';
import '../../theme/app_tokens.dart';

/// Segmented pill progress bar for the wizards: one rounded segment per step,
/// filled through the current step, with an animated sweep on advance.
/// Replaces the old vine step indicator.
class StepProgress extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const StepProgress({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final m = AppSettings.instance.motionMultiplier;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: i <= currentStep ? 1.0 : 0.0),
                    duration: Duration(milliseconds: (350 * m).round()),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Color.lerp(t.accentSoft, t.accent, v),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            labels[currentStep.clamp(0, labels.length - 1)],
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: t.accentStrong,
                ),
          ),
        ],
      ),
    );
  }
}
