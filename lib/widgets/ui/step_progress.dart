import 'package:flutter/material.dart';
import '../../services/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Segmented pixel progress bar for the wizards: one hard-edged segment per
/// step, filled through the current step, with an animated sweep on advance.
///
/// Reads as a quest tracker — "STEP 2 OF 5" — rather than a web progress bar.
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
    final step = currentStep.clamp(0, labels.length - 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP ${step + 1} OF ${labels.length} · ${labels[step].toUpperCase()}',
            style: AppTheme.label(9, t.textTertiary, spacing: 1.2),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: i <= currentStep ? 1.0 : 0.0),
                    duration: Duration(milliseconds: (350 * m).round()),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color.lerp(t.track, t.accent, v),
                        border: Border.all(color: t.cardBorder, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
