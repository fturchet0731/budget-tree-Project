import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Growth-stage step indicator: three icons (seed → sprout → tree)
/// connected by a vine that fills as the user advances through the
/// budget-creation flow. Replaces the plain "numbered circles" step bar.
class VineStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<VineStep> steps;
  final double height;

  const VineStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
    this.height = 84,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (ctx, c) {
        final w = c.maxWidth;
        // Centres of each step dot along the horizontal axis
        final positions = List<double>.generate(
          steps.length,
          (i) => 30 + (w - 60) * (i / (steps.length - 1)),
        );

        return Stack(
          children: [
            // Vine line behind everything
            Positioned.fill(
              child: CustomPaint(
                painter: _VinePainter(
                  positions: positions,
                  yCenter: height / 2 - 6,
                  currentStep: currentStep,
                  totalSteps: steps.length,
                ),
              ),
            ),
            // The step dots
            for (int i = 0; i < steps.length; i++)
              Positioned(
                left: positions[i] - 28,
                top: 0,
                width: 56,
                child: _StepDot(
                  step: steps[i],
                  state: i < currentStep
                      ? _DotState.done
                      : i == currentStep
                          ? _DotState.active
                          : _DotState.upcoming,
                ),
              ),
          ],
        );
      }),
    );
  }
}

class VineStep {
  final String label;
  final IconData icon;
  const VineStep({required this.label, required this.icon});
}

enum _DotState { upcoming, active, done }

class _StepDot extends StatelessWidget {
  final VineStep step;
  final _DotState state;
  const _StepDot({required this.step, required this.state});

  @override
  Widget build(BuildContext context) {
    final active = state == _DotState.active;
    final done = state == _DotState.done;
    final fillColor = done || active
        ? AppColors.forestGreen
        : AppColors.soilMid;
    final borderColor = active
        ? AppColors.lightLeaf
        : done
            ? AppColors.lightLeaf.withValues(alpha: 0.6)
            : AppColors.mossGreen.withValues(alpha: 0.4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: active ? 44 : 36,
          height: active ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                done || active
                    ? AppColors.forestGreen.withValues(alpha: 0.85)
                    : AppColors.soilMid,
                fillColor,
              ],
            ),
            border: Border.all(color: borderColor, width: active ? 2.2 : 1.4),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.lightLeaf.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : done
                    ? [
                        BoxShadow(
                          color: AppColors.forestGreen
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            done ? Icons.check : step.icon,
            size: active ? 22 : 18,
            color: done || active
                ? Colors.white
                : AppColors.mossGreen.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: GoogleFonts.nunito(
            color: active
                ? AppColors.stoneBeigeColor
                : done
                    ? AppColors.lightLeaf
                    : AppColors.mossGreen.withValues(alpha: 0.65),
            fontSize: active ? 12 : 11,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 0.4,
          ),
          child: Text(step.label, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _VinePainter extends CustomPainter {
  final List<double> positions;
  final double yCenter;
  final int currentStep;
  final int totalSteps;

  _VinePainter({
    required this.positions,
    required this.yCenter,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;
    // Background vine path connects all dots with gentle dips
    final bg = Path()..moveTo(positions.first, yCenter);
    for (int i = 1; i < positions.length; i++) {
      final mid = (positions[i - 1] + positions[i]) / 2;
      bg.quadraticBezierTo(mid, yCenter + 10, positions[i], yCenter);
    }
    canvas.drawPath(
      bg,
      Paint()
        ..color = AppColors.mossGreen.withValues(alpha: 0.30)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Filled portion up to the current step
    if (currentStep > 0) {
      final fill = Path()..moveTo(positions.first, yCenter);
      final endIdx = currentStep.clamp(0, positions.length - 1);
      for (int i = 1; i <= endIdx; i++) {
        final mid = (positions[i - 1] + positions[i]) / 2;
        fill.quadraticBezierTo(mid, yCenter + 10, positions[i], yCenter);
      }
      canvas.drawPath(
        fill,
        Paint()
          ..color = AppColors.lightLeaf
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );

      // Tiny leaf accents along the filled vine
      for (int i = 0; i < endIdx; i++) {
        final midX = (positions[i] + positions[i + 1]) / 2;
        _drawSmallLeaf(canvas, Offset(midX, yCenter + 4), 4.5);
      }
    }
  }

  void _drawSmallLeaf(Canvas canvas, Offset center, double size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.6);
    final path = Path()
      ..moveTo(0, -size)
      ..cubicTo(size * 0.7, -size * 0.4, size * 0.7, size * 0.4, 0, size * 0.5)
      ..cubicTo(-size * 0.7, size * 0.4, -size * 0.7, -size * 0.4, 0, -size)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = AppColors.lightLeaf,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.darkForestGreen
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VinePainter old) =>
      old.currentStep != currentStep ||
      old.positions != positions;
}
