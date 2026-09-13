import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'pixel_button.dart' show PixelTone;

/// A hard-edged progress meter: a parchment track with a 2px ink outline and a
/// striped fill. The stripes are what keep it reading as 16-bit rather than as
/// a flat modern bar.
class PixelBar extends StatelessWidget {
  /// 0..1. Values above 1 are clamped — pass [over] to colour an overflow.
  final double value;
  final double height;
  final PixelTone tone;

  /// Draw the fill in the danger colour (over budget).
  final bool over;

  /// Optional plan marker drawn as a vertical tick at this 0..1 position —
  /// used by the hub's plan-vs-reality bars.
  final double? planTick;

  const PixelBar({
    super.key,
    required this.value,
    this.height = 13,
    this.tone = PixelTone.accent,
    this.over = false,
    this.planTick,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final (hi, mid) = switch (over ? null : tone) {
      PixelTone.gold => (t.goldHi, t.gold),
      PixelTone.water => (t.water, t.waterShadow),
      PixelTone.neutral => (t.textTertiary, t.textSecondary),
      PixelTone.dark => (t.textSecondary, t.textPrimary),
      PixelTone.accent => (Conifer.c400, Conifer.c500),
      null => (t.danger, const Color(0xFF9E332E)),
    };

    return Container(
      height: height,
      // width is load-bearing: the Stack below sizes to its only non-positioned
      // child, which is the *fill*. Without this the whole bar collapses to the
      // width of its own fill wherever the parent doesn't constrain it (a
      // Column with crossAxisAlignment.start, say) — so an empty bar rendered
      // as nothing at all instead of an empty track.
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.track,
        border: Border.all(color: t.cardBorder, width: 2),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth * value.clamp(0.0, 1.0);
          return Stack(
            children: [
              SizedBox(
                width: w,
                height: double.infinity,
                child: CustomPaint(painter: _StripePainter(hi, mid)),
              ),
              if (planTick != null)
                Positioned(
                  left: (c.maxWidth * planTick!.clamp(0.0, 1.0) - 1)
                      .clamp(0.0, c.maxWidth - 2),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: t.textPrimary),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// `repeating-linear-gradient(90deg, hi 0 5px, mid 5px 7px)` — drawn directly
/// so the stripe pitch stays in device-independent pixels at any bar width.
class _StripePainter extends CustomPainter {
  final Color hi;
  final Color mid;
  const _StripePainter(this.hi, this.mid);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = hi);
    final p = Paint()..color = mid;
    for (double x = 5; x < size.width; x += 7) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 2.0.clamp(0, size.width - x), size.height),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.hi != hi || old.mid != mid;
}
