import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/leaf_palette.dart';

/// Reusable building blocks for drawing organic, hand-painted-looking
/// trees. Every primitive accepts a [seed] so its random elements stay
/// stable across repaints (so the tree doesn't shimmer between frames).
class TreeDrawing {
  TreeDrawing._();

  // ──────────────────────────────────────────────
  // FOLIAGE CLUSTER
  // ──────────────────────────────────────────────

  /// Paint a single foliage cluster: irregular blob path + radial shading
  /// + subtle outline + sunlit highlight. Replaces the old "draw circle"
  /// approach with something that reads as a painted cluster of leaves.
  static void paintCluster(
    Canvas canvas,
    Offset center,
    double radius,
    LeafPalette palette, {
    required int seed,
    bool sunlitTop = true,
    double shadowAlpha = 0.18,
    bool drawOutline = true,
  }) {
    if (radius <= 0) return;
    final rng = math.Random(seed);
    final steps = 14;

    // Sample irregular points around the perimeter
    final pts = <Offset>[];
    for (int i = 0; i < steps; i++) {
      final angle = (i / steps) * 2 * math.pi - math.pi / 2;
      final variation = 0.86 + rng.nextDouble() * 0.28;
      pts.add(Offset(
        center.dx + math.cos(angle) * radius * variation,
        center.dy + math.sin(angle) * radius * variation,
      ));
    }

    // Build closed path with outward-biased quadratic curves
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < steps; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % steps];
      // Midpoint biased outward for a puffy curve
      final mx = (a.dx + b.dx) / 2;
      final my = (a.dy + b.dy) / 2;
      final outX = mx - center.dx;
      final outY = my - center.dy;
      final outLen = math.max(math.sqrt(outX * outX + outY * outY), 0.0001);
      final bias = radius * 0.12;
      final cx = mx + outX / outLen * bias;
      final cy = my + outY / outLen * bias;
      path.quadraticBezierTo(cx, cy, b.dx, b.dy);
    }
    path.close();

    // Soft drop shadow
    canvas.save();
    canvas.translate(2, 3);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: shadowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();

    // Base radial gradient: lit top-left → mid → shadow bottom-right
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [palette.light, palette.mid, palette.dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
            Rect.fromCircle(center: center, radius: radius * 1.2)),
    );

    if (drawOutline) {
      canvas.drawPath(
        path,
        Paint()
          ..color = palette.outline.withValues(alpha: 0.55)
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    // Soft sunlit highlight blob — adds dimensionality
    if (sunlitTop) {
      canvas.drawCircle(
        Offset(center.dx - radius * 0.30, center.dy - radius * 0.35),
        radius * 0.32,
        Paint()
          ..color = palette.light.withValues(alpha: 0.50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  /// Scatter small individual leaf silhouettes around a cluster's edge
  /// so the outline reads as a tuft of leaves rather than a single blob.
  static void paintLeafFringe(
    Canvas canvas,
    Offset center,
    double radius,
    LeafPalette palette, {
    required int seed,
    int leafCount = 6,
    double leafSize = 0,
  }) {
    if (radius <= 0) return;
    final rng = math.Random(seed);
    final size = leafSize > 0 ? leafSize : radius * 0.18;

    for (int i = 0; i < leafCount; i++) {
      final baseAngle = (i / leafCount) * 2 * math.pi - math.pi / 2;
      final angle = baseAngle + (rng.nextDouble() - 0.5) * 0.6;
      final r = radius * (0.94 + rng.nextDouble() * 0.12);
      final pos = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      _paintTeardropLeaf(
        canvas, pos, angle + math.pi / 2, palette, size,
        sunlit: angle < -0.4 || angle > 2 * math.pi - 0.4,
      );
    }
  }

  static void _paintTeardropLeaf(
    Canvas canvas,
    Offset center,
    double angle,
    LeafPalette palette,
    double size, {
    bool sunlit = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -size)
      ..cubicTo(
          size * 0.75, -size * 0.45, size * 0.75, size * 0.45, 0, size * 0.5)
      ..cubicTo(
          -size * 0.75, size * 0.45, -size * 0.75, -size * 0.45, 0, -size)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [sunlit ? palette.light : palette.mid, palette.dark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(-size, -size, size * 2, size * 1.5)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.outline.withValues(alpha: 0.6)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
    );
    // Central vein
    canvas.drawLine(
      Offset(0, -size * 0.85),
      Offset(0, size * 0.35),
      Paint()
        ..color = palette.light.withValues(alpha: 0.55)
        ..strokeWidth = 0.5,
    );
    canvas.restore();
  }

  // ──────────────────────────────────────────────
  // TAPERED BRANCH
  // ──────────────────────────────────────────────

  /// Paint a tapered branch from [start] to [end] with a subtle bow and
  /// a lighter highlight running along the sun-facing edge.
  static void paintBranch(
    Canvas canvas,
    Offset start,
    Offset end, {
    required double startW,
    required double endW,
    Color color = const Color(0xFF4E342E),
    Color highlight = const Color(0xFF8D6E63),
    double bowFactor = 0.06,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;

    final tx = dx / len;
    final ty = dy / len;
    final nx = -ty;
    final ny = tx;

    // Subtle outward bow so branches don't look like straight sticks
    final ctrl = Offset(
      start.dx + dx * 0.5 + nx * len * bowFactor,
      start.dy + dy * 0.5 + ny * len * bowFactor,
    );

    const samples = 16;
    final leftPts = <Offset>[];
    final rightPts = <Offset>[];

    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      // Quadratic bezier point
      final x = (1 - t) * (1 - t) * start.dx +
          2 * (1 - t) * t * ctrl.dx +
          t * t * end.dx;
      final y = (1 - t) * (1 - t) * start.dy +
          2 * (1 - t) * t * ctrl.dy +
          t * t * end.dy;
      // Tangent (derivative)
      final tdx = 2 * (1 - t) * (ctrl.dx - start.dx) +
          2 * t * (end.dx - ctrl.dx);
      final tdy = 2 * (1 - t) * (ctrl.dy - start.dy) +
          2 * t * (end.dy - ctrl.dy);
      final tlen = math.max(math.sqrt(tdx * tdx + tdy * tdy), 0.0001);
      final lnx = -tdy / tlen;
      final lny = tdx / tlen;
      final w = startW + (endW - startW) * t;
      leftPts.add(Offset(x + lnx * w / 2, y + lny * w / 2));
      rightPts.add(Offset(x - lnx * w / 2, y - lny * w / 2));
    }

    final ribbon = Path()..moveTo(leftPts.first.dx, leftPts.first.dy);
    for (final p in leftPts.skip(1)) {
      ribbon.lineTo(p.dx, p.dy);
    }
    for (final p in rightPts.reversed) {
      ribbon.lineTo(p.dx, p.dy);
    }
    ribbon.close();
    canvas.drawPath(ribbon, Paint()..color = color);

    // Subtle shadow line along the under edge
    final shadowEdge = Path()..moveTo(rightPts.first.dx, rightPts.first.dy);
    for (final p in rightPts.skip(1)) {
      shadowEdge.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      shadowEdge,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Bright highlight along the sun-lit edge
    final highlightEdge = Path()..moveTo(leftPts.first.dx, leftPts.first.dy);
    for (final p in leftPts.skip(1)) {
      highlightEdge.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      highlightEdge,
      Paint()
        ..color = highlight.withValues(alpha: 0.55)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  // ──────────────────────────────────────────────
  // OAK TRUNK
  // ──────────────────────────────────────────────

  /// Paint a realistic oak trunk with multi-stop bark gradient,
  /// vertical bark fissures, horizontal wrinkles, a knot, and a
  /// 5-lobed buttressed root flare. Slightly asymmetric for character.
  static void paintTrunk(
    Canvas canvas, {
    required Offset base,
    required double height,
    required double baseHalfWidth,
    required double topHalfWidth,
    int seed = 0,
    bool drawKnot = true,
    bool drawRoots = true,
  }) {
    final rng = math.Random(seed);
    final crook = (rng.nextDouble() - 0.5) * 6;
    final top = Offset(base.dx + crook, base.dy - height);

    // Slightly irregular mid points
    final lMid = Offset(
      base.dx - baseHalfWidth * 0.85 + (rng.nextDouble() - 0.5) * 3,
      base.dy - height * 0.4,
    );
    final rMid = Offset(
      base.dx + baseHalfWidth * 0.85 + (rng.nextDouble() - 0.5) * 3,
      base.dy - height * 0.4,
    );

    final trunkPath = Path()
      ..moveTo(base.dx - baseHalfWidth, base.dy)
      ..cubicTo(
        base.dx - baseHalfWidth * 0.95, base.dy - height * 0.15,
        lMid.dx, lMid.dy,
        top.dx - topHalfWidth, top.dy,
      )
      ..lineTo(top.dx + topHalfWidth, top.dy)
      ..cubicTo(
        rMid.dx, rMid.dy,
        base.dx + baseHalfWidth * 0.95, base.dy - height * 0.15,
        base.dx + baseHalfWidth, base.dy,
      )
      ..close();

    // Multi-stop bark gradient
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF1A0C06),
            Color(0xFF3E2723),
            Color(0xFF6D4C41),
            Color(0xFF9B7560),
            Color(0xFF6D4C41),
            Color(0xFF3E2723),
            Color(0xFF1A0C06),
          ],
          stops: [0.0, 0.15, 0.32, 0.5, 0.68, 0.85, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(
          Rect.fromLTWH(base.dx - baseHalfWidth, base.dy - height,
              baseHalfWidth * 2, height),
        ),
    );

    // Sunlit edge — soft warm overlay on the left side
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFE0B2).withValues(alpha: 0.18),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: const Alignment(-0.2, 0),
        ).createShader(
          Rect.fromLTWH(base.dx - baseHalfWidth, base.dy - height,
              baseHalfWidth * 2, height),
        ),
    );

    // Vertical bark fissures — short irregular strokes
    final fissure = Paint()
      ..color = const Color(0xFF120804).withValues(alpha: 0.50)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fissureCount = (height / 35).round().clamp(5, 12);
    for (int i = 0; i < fissureCount; i++) {
      final t = 0.08 + rng.nextDouble() * 0.84;
      final xJitter = (rng.nextDouble() - 0.5) * baseHalfWidth * 1.5;
      final y0 = base.dy - height * t;
      final segH = 14 + rng.nextDouble() * 28;
      final y1 = y0 - segH;
      final x = base.dx + xJitter;
      final wiggle = (rng.nextDouble() - 0.5) * 3;
      canvas.drawLine(Offset(x, y0), Offset(x + wiggle, y1), fissure);
    }

    // Horizontal wrinkles — softer
    final wrinkle = Paint()
      ..color = const Color(0xFF120804).withValues(alpha: 0.20)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    final wrinkleCount = (height / 32).round().clamp(3, 9);
    for (int i = 1; i <= wrinkleCount; i++) {
      final t = i / (wrinkleCount + 1);
      final y = base.dy - height * t;
      final hw = topHalfWidth + (baseHalfWidth - topHalfWidth) * (1 - t);
      final wiggleX = math.sin(t * math.pi * 4) * 1.8;
      canvas.drawLine(
        Offset(base.dx - hw * 0.8 + wiggleX, y),
        Offset(base.dx + hw * 0.8 + wiggleX, y),
        wrinkle,
      );
    }

    // Knot — small dark oval with a curved highlight
    if (drawKnot && height > 70) {
      final knotY = base.dy - height * (0.55 + rng.nextDouble() * 0.2);
      final knotSide = rng.nextBool() ? 1 : -1;
      final knotX = base.dx + knotSide * baseHalfWidth * 0.5;
      final knotW = baseHalfWidth * 0.35;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(knotX, knotY), width: knotW, height: knotW * 0.7),
        Paint()..color = const Color(0xFF120804),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(knotX, knotY),
            width: knotW * 0.65,
            height: knotW * 0.45),
        Paint()..color = const Color(0xFF3E2723),
      );
    }

    // Root flare — 5 organic lobes spread along the base
    if (drawRoots) {
      final rootDark = Paint()..color = const Color(0xFF3E2723);
      final rootMid = Paint()..color = const Color(0xFF5D4037);
      for (int i = 0; i < 5; i++) {
        final t = (i / 4.0) - 0.5; // -0.5..0.5
        final dx = t * baseHalfWidth * 4.2;
        final width = (1.0 - t.abs() * 0.55) * baseHalfWidth * 1.8;
        final h = width * 0.45;
        // Drop shadow
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(base.dx + dx + 1, base.dy + 4),
              width: width,
              height: h * 0.85),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(base.dx + dx, base.dy + 2),
              width: width,
              height: h),
          rootDark,
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(base.dx + dx - 1, base.dy - 1),
              width: width * 0.82,
              height: h * 0.8),
          rootMid,
        );
      }
    }
  }
}
