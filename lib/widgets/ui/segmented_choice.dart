import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_settings.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_tokens.dart';
import 'pressable.dart';

/// Pill segmented control with a sliding thumb. Replaces the old chip rows
/// (theme/text-size pickers, cadence and frequency chips).
class SegmentedChoice<T> extends StatelessWidget {
  final T current;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const SegmentedChoice({
    super.key,
    required this.current,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final index = options.indexWhere((o) => o.$1 == current);
    final m = AppSettings.instance.motionMultiplier;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.canvasSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segW = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: (250 * m).round()),
                curve: Curves.easeOutCubic,
                left: segW * (index < 0 ? 0 : index),
                top: 0,
                bottom: 0,
                width: segW,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: AppShadows.pill,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (value, label) in options)
                    Expanded(
                      child: PressableScale(
                        haptic: value != current,
                        onTap: () => onChanged(value),
                        child: Center(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: value == current
                                  ? t.textPrimary
                                  : t.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
