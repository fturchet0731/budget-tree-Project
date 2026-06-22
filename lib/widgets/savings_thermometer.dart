import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A classic glass thermometer that "fills" with [fill] (0..1) so users can
/// watch money accumulate toward a target. Purely presentational — the parent
/// passes an already-animated fill value (e.g. from the grow controller).
class SavingsThermometer extends StatelessWidget {
  final double fill;
  final Color color;
  final double width;
  final double height;

  const SavingsThermometer({
    super.key,
    required this.fill,
    required this.color,
    this.width = 46,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _ThermometerPainter(
            fill: fill.clamp(0.0, 1.0),
            color: color,
          ),
        ),
      ),
    );
  }
}

class _ThermometerPainter extends CustomPainter {
  final double fill;
  final Color color;
  _ThermometerPainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final tubeWidth = size.width * 0.42;
    final cx = size.width / 2;
    final bulbRadius = size.width * 0.46;
    final bulbCenter = Offset(cx, size.height - bulbRadius);
    final tubeTop = size.height * 0.06;
    final tubeBottom = bulbCenter.dy;

    final tubeRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - tubeWidth / 2, tubeTop, cx + tubeWidth / 2, tubeBottom),
      Radius.circular(tubeWidth / 2),
    );

    // Glass background.
    final glass = Paint()..color = AppColors.soilMid.withValues(alpha: 0.55);
    canvas.drawRRect(tubeRect, glass);
    canvas.drawCircle(bulbCenter, bulbRadius, glass);

    // Mercury fill: bulb is always full, the tube fills from bottom up.
    final mercury = Paint()..color = color;
    canvas.drawCircle(bulbCenter, bulbRadius * 0.82, mercury);

    final usableTop = tubeTop + tubeWidth * 0.5;
    final fillTopY = tubeBottom - (tubeBottom - usableTop) * fill;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx - tubeWidth * 0.32,
        fillTopY,
        cx + tubeWidth * 0.32,
        tubeBottom,
      ),
      Radius.circular(tubeWidth * 0.32),
    );
    canvas.drawRRect(fillRect, mercury);

    // Connect tube fill to the bulb so there's no gap.
    canvas.drawRect(
      Rect.fromLTRB(cx - tubeWidth * 0.32, tubeBottom - 2,
          cx + tubeWidth * 0.32, bulbCenter.dy),
      mercury,
    );

    // Tick marks at 25 / 50 / 75 / 100%.
    final tick = Paint()
      ..color = AppColors.stoneBeigeColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final p in [0.25, 0.5, 0.75, 1.0]) {
      final y = tubeBottom - (tubeBottom - usableTop) * p;
      final x0 = cx + tubeWidth / 2 + 2;
      canvas.drawLine(Offset(x0, y), Offset(x0 + size.width * 0.18, y), tick);
    }

    // Glass highlight for a little gloss.
    final gloss = Paint()..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - tubeWidth * 0.34, tubeTop + 4, tubeWidth * 0.18,
            (tubeBottom - tubeTop) * 0.55),
        const Radius.circular(4),
      ),
      gloss,
    );
  }

  @override
  bool shouldRepaint(_ThermometerPainter old) =>
      old.fill != fill || old.color != color;
}
