import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/leaf_palette.dart';

/// Renders a growing sapling whose visual stage is driven by [progress] (0..1).
/// The painter smoothly interpolates between stages so adding money
/// produces a continuous growth effect rather than discrete jumps.
class SaplingView extends StatelessWidget {
  final double progress;
  final Size size;
  final bool showGround;
  final LeafPalette leafPalette;

  const SaplingView({
    super.key,
    required this.progress,
    this.size = const Size(220, 260),
    this.showGround = true,
    this.leafPalette = LeafPalette.defaultGreen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: SaplingPainter(
          progress: progress.clamp(0.0, 1.0),
          showGround: showGround,
          leafPalette: leafPalette,
        ),
      ),
    );
  }
}

class SaplingPainter extends CustomPainter {
  final double progress;
  final bool showGround;
  final LeafPalette leafPalette;

  const SaplingPainter({
    required this.progress,
    required this.showGround,
    this.leafPalette = LeafPalette.defaultGreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final groundY = h * 0.86;

    if (showGround) _drawSoil(canvas, cx, groundY, w);

    // Stage 0 — seed always shown
    _drawSeed(canvas, cx, groundY, progress);

    if (progress > 0.04) {
      _drawSprout(canvas, cx, groundY, progress);
    }
    if (progress > 0.22) {
      _drawSapling(canvas, cx, groundY, progress);
    }
    if (progress > 0.48) {
      _drawYoungTree(canvas, cx, groundY, progress);
    }
    if (progress > 0.72) {
      _drawMatureCrown(canvas, cx, groundY, progress);
    }
    if (progress >= 0.999) {
      _drawCompleteSparkles(canvas, cx, groundY);
    }
  }

  // ── Soil patch + tiny pebbles ────────────────────────
  /// Wider, more substantial ground patch — three soil layers with
  /// scattered pebbles and a generous grass fringe so the sapling
  /// reads as planted in real earth rather than floating on a dot.
  void _drawSoil(Canvas canvas, double cx, double groundY, double w) {
    // Flat modern mound: two warm-brown ovals, no texture or shadows.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY + 8), width: 200, height: 30),
      Paint()..color = const Color(0xFF8A6B4F),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY + 4), width: 150, height: 18),
      Paint()..color = const Color(0xFFA98A68),
    );

    // A few flat grass blades framing the mound.
    final rng = math.Random(31);
    final bladePaint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 10; i++) {
      final x = cx + (rng.nextDouble() - 0.5) * 190;
      if ((x - cx).abs() < 30) continue; // leave room near the seed
      final bh = 7 + rng.nextDouble() * 9;
      final lean = (rng.nextDouble() - 0.5) * 6;
      bladePaint.color =
          i.isEven ? leafPalette.mid : leafPalette.light;
      canvas.drawLine(
          Offset(x, groundY + 1), Offset(x + lean, groundY - bh), bladePaint);
    }

    // Two tiny flat flowers for life.
    for (final side in [-1.0, 1.0]) {
      final x = cx + side * (55 + rng.nextDouble() * 30);
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x, groundY - 6),
        Paint()
          ..color = leafPalette.dark
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        Offset(x, groundY - 8),
        2.6,
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
  }

  // ── Always-visible seed at the surface ───────────────
  void _drawSeed(Canvas canvas, double cx, double groundY, double p) {
    // If a stem exists (p > 0.04), bury the seed
    final visibleAlpha = (1 - (p / 0.10)).clamp(0.0, 1.0);
    if (visibleAlpha <= 0) return;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY - 2), width: 7, height: 5),
      Paint()
        ..color = const Color(0xFF6D4C41).withValues(alpha: visibleAlpha),
    );
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx - 1, groundY - 3), width: 5, height: 3),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFA1887F).withValues(alpha: visibleAlpha)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }

  // ── Sprout: tiny stem + 2 cotyledon leaves ───────────
  void _drawSprout(Canvas canvas, double cx, double groundY, double p) {
    // p in 0.04..1.0
    final localProg = ((p - 0.04) / 0.20).clamp(0.0, 1.0);
    final stemH = 24 * localProg;
    final stemY = groundY - stemH;

    canvas.drawLine(
      Offset(cx, groundY),
      Offset(cx, stemY),
      Paint()
        ..color = const Color(0xFF388E3C)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Two cotyledon leaves
    if (localProg > 0.25) {
      final leafProg = ((localProg - 0.25) / 0.75).clamp(0.0, 1.0);
      _cotyledon(canvas, Offset(cx, stemY), leafProg, isLeft: true);
      _cotyledon(canvas, Offset(cx, stemY), leafProg, isLeft: false);
    }
  }

  void _cotyledon(Canvas canvas, Offset stemTop, double prog,
      {required bool isLeft}) {
    final dir = isLeft ? -1.0 : 1.0;
    canvas.save();
    canvas.translate(stemTop.dx, stemTop.dy);
    canvas.rotate(dir * math.pi / 5);
    canvas.scale(prog);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(dir * 12, -6, dir * 14, -2)
      ..quadraticBezierTo(dir * 12, 4, 0, 0)
      ..close();
    final lp = leafPalette;
    canvas.drawPath(path, Paint()..color = lp.mid);
    canvas.drawPath(
      path,
      Paint()
        ..color = lp.outline
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  // ── Sapling: a real little tree with ~4 leaves ───────
  void _drawSapling(Canvas canvas, double cx, double groundY, double p) {
    final localProg = ((p - 0.22) / 0.28).clamp(0.0, 1.0);
    final stemH = 28 + 28 * localProg;
    final stemTopY = groundY - stemH;

    // Slim trunk
    final trunkPath = Path()
      ..moveTo(cx - 2.2, groundY)
      ..quadraticBezierTo(cx - 2.0, (groundY + stemTopY) / 2,
          cx - 1.2, stemTopY)
      ..lineTo(cx + 1.2, stemTopY)
      ..quadraticBezierTo(cx + 2.0, (groundY + stemTopY) / 2,
          cx + 2.2, groundY)
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = const Color(0xFF8A6B4F));

    // 4 small leaves on alternating sides
    final leafCount = 4;
    for (int i = 0; i < leafCount; i++) {
      final t = i / (leafCount - 1);
      final attachY = stemTopY + (groundY - stemTopY) * t * 0.7;
      final isLeft = i.isEven;
      final leafReveal = (localProg - i * 0.1).clamp(0.0, 1.0);
      if (leafReveal <= 0) continue;
      _smallLeaf(canvas, Offset(cx, attachY), leafReveal, isLeft: isLeft);
    }
  }

  void _smallLeaf(Canvas canvas, Offset attach, double prog,
      {required bool isLeft}) {
    final dir = isLeft ? -1.0 : 1.0;
    canvas.save();
    canvas.translate(attach.dx, attach.dy);
    canvas.rotate(dir * math.pi / 3.5);
    canvas.scale(prog);
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(dir * 8, -3, dir * 14, 2, dir * 12, 6)
      ..cubicTo(dir * 6, 4, dir * 2, 4, 0, 0)
      ..close();
    final lp = leafPalette;
    canvas.drawPath(path, Paint()..color = lp.mid);
    canvas.drawPath(
      path,
      Paint()
        ..color = lp.outline
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      const Offset(0, 0),
      Offset(dir * 10, 3),
      Paint()
        ..color = lp.outline.withValues(alpha: 0.5)
        ..strokeWidth = 0.6,
    );
    canvas.restore();
  }

  // ── Young tree: thicker trunk + small leafy clusters ─
  void _drawYoungTree(Canvas canvas, double cx, double groundY, double p) {
    final localProg = ((p - 0.48) / 0.24).clamp(0.0, 1.0);
    final stemH = 56 + 36 * localProg;
    final stemTopY = groundY - stemH;
    final trunkW = 3.0 + 2.5 * localProg;

    final trunkPath = Path()
      ..moveTo(cx - trunkW, groundY)
      ..quadraticBezierTo(cx - trunkW * 0.9, (groundY + stemTopY) / 2,
          cx - trunkW * 0.5, stemTopY)
      ..lineTo(cx + trunkW * 0.5, stemTopY)
      ..quadraticBezierTo(cx + trunkW * 0.9, (groundY + stemTopY) / 2,
          cx + trunkW, groundY)
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = const Color(0xFF8A6B4F));

    // Two small leafy clusters at the upper trunk
    if (localProg > 0.15) {
      final cReveal = ((localProg - 0.15) / 0.85).clamp(0.0, 1.0);
      _leafCluster(canvas, Offset(cx - 10, stemTopY + 4), 10 * cReveal);
      _leafCluster(canvas, Offset(cx + 10, stemTopY + 2), 10 * cReveal);
      _leafCluster(canvas, Offset(cx, stemTopY - 6), 14 * cReveal);
    }
  }

  void _leafCluster(Canvas canvas, Offset c, double r) {
    if (r <= 0) return;
    final lp = leafPalette;
    canvas.drawCircle(c, r, Paint()..color = lp.dark);
    canvas.drawCircle(
      Offset(c.dx - r * 0.3, c.dy - r * 0.3),
      r * 0.5,
      Paint()..color = lp.light,
    );
    canvas.drawCircle(
      Offset(c.dx + r * 0.3, c.dy + r * 0.2),
      r * 0.45,
      Paint()..color = lp.mid,
    );
  }

  // ── Mature crown — full canopy growing from saplings ─
  void _drawMatureCrown(Canvas canvas, double cx, double groundY, double p) {
    final localProg = ((p - 0.72) / 0.28).clamp(0.0, 1.0);
    final cy = groundY - 92 - 12 * localProg;

    final lp = leafPalette;
    final layers = [
      (cx - 24, cy + 12, 24.0, lp.outline),
      (cx + 22, cy + 10, 22.0, lp.outline),
      (cx - 8, cy - 4, 30.0, lp.dark),
      (cx + 6, cy - 8, 28.0, lp.dark),
      (cx - 2, cy + 4, 34.0, lp.mid),
      (cx, cy - 22, 22.0, lp.mid),
      (cx - 14, cy - 30, 16.0, lp.light),
      (cx + 13, cy - 28, 14.0, lp.light),
    ];

    for (final (lx, ly, lr, lc) in layers) {
      final animX = cx + (lx - cx) * localProg;
      final animY = cy + (ly - cy) * localProg;
      canvas.drawCircle(
          Offset(animX, animY), lr * localProg, Paint()..color = lc);
    }

    // Sun highlight
    canvas.drawCircle(
      Offset(cx - 16, cy - 20),
      9 * localProg,
      Paint()..color = Colors.white.withValues(alpha: 0.10 * localProg),
    );
  }

  // ── Sparkles when 100% complete ──────────────────────
  void _drawCompleteSparkles(Canvas canvas, double cx, double groundY) {
    final rng = math.Random(7);
    for (int i = 0; i < 14; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final r = 50 + rng.nextDouble() * 60;
      final pt = Offset(
        cx + math.cos(ang) * r,
        groundY - 110 + math.sin(ang) * r,
      );
      final sz = 1.5 + rng.nextDouble() * 2.0;
      _sparkle(canvas, pt, sz);
    }
  }

  void _sparkle(Canvas canvas, Offset c, double sz) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(c.dx - sz, c.dy), Offset(c.dx + sz, c.dy), paint);
    canvas.drawLine(
        Offset(c.dx, c.dy - sz), Offset(c.dx, c.dy + sz), paint);
    canvas.drawCircle(
        c, sz * 0.4, Paint()..color = const Color(0xFFFFF59D));
  }

  @override
  bool shouldRepaint(SaplingPainter old) =>
      old.progress != progress ||
      old.showGround != showGround ||
      old.leafPalette != leafPalette;
}
