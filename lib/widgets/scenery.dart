import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared scene-drawing helpers for the painted backdrops. The screens used to
/// improvise silhouettes out of loose circles; these draw complete shapes —
/// trees with tapered trunks and scalloped crowns, hanging vines with leaves,
/// glowing fireflies — so every backdrop reads as a finished illustration.
/// All functions are deterministic (callers pass a seed where variety is
/// wanted) and paint with whatever color the caller hands in, so they follow
/// each screen's palette exactly like the ad-hoc shapes they replace.
class Scenery {
  Scenery._();

  /// A full tree silhouette standing on [base] (the trunk foot), [height]
  /// tall. The crown is a scalloped dome (not stacked circles) over a tapered
  /// trunk with a branch fork on each side. [seed] varies the scallop rhythm
  /// so a row of trees doesn't repeat. [aspect] is the crown width as a
  /// fraction of the height — leave null for a natural rounded tree, or pass
  /// something like 0.3 for the tall slender trees of a distant treeline.
  static void paintTreeSilhouette(
    Canvas canvas,
    Offset base,
    double height,
    Color color, {
    int seed = 0,
    double? aspect,
  }) {
    final rng = math.Random(seed);
    final paint = Paint()..color = color;

    final trunkH = height * 0.38;
    final crownH = height - trunkH * 0.55; // crown overlaps the trunk top
    final crownW = height * (aspect ?? (0.62 + rng.nextDouble() * 0.14));
    final crownCx = base.dx + (rng.nextDouble() - 0.5) * height * 0.06;
    final crownBottom = base.dy - trunkH;
    final crownTop = base.dy - height;

    // Trunk: tapered, with a slight lean.
    final lean = (rng.nextDouble() - 0.5) * height * 0.05;
    final trunk = Path()
      ..moveTo(base.dx - height * 0.045, base.dy)
      ..quadraticBezierTo(
        base.dx - height * 0.03 + lean * 0.5,
        base.dy - trunkH * 0.55,
        crownCx - height * 0.018 + lean,
        crownBottom - height * 0.05,
      )
      ..lineTo(crownCx + height * 0.018 + lean, crownBottom - height * 0.05)
      ..quadraticBezierTo(
        base.dx + height * 0.03 + lean * 0.5,
        base.dy - trunkH * 0.55,
        base.dx + height * 0.045,
        base.dy,
      )
      ..close();
    canvas.drawPath(trunk, paint);

    // Branch forks reaching into the crown.
    final branch = Paint()
      ..color = color
      ..strokeWidth = height * 0.02
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(base.dx + lean * 0.6, crownBottom + trunkH * 0.18),
      Offset(base.dx - crownW * 0.22, crownBottom - crownH * 0.18),
      branch,
    );
    canvas.drawLine(
      Offset(base.dx + lean * 0.6, crownBottom + trunkH * 0.1),
      Offset(base.dx + crownW * 0.2, crownBottom - crownH * 0.22),
      branch,
    );

    // Crown: a dome whose sides descend in leafy scallops. Built as one path
    // so the silhouette is a single, deliberate shape.
    final crown = Path()..moveTo(crownCx - crownW * 0.5, crownBottom);
    // Left side up.
    _scallopedEdge(
      crown,
      from: Offset(crownCx - crownW * 0.5, crownBottom),
      to: Offset(crownCx - crownW * 0.16, crownTop + crownH * 0.06),
      bumps: 3,
      bulge: crownW * 0.09,
      rng: rng,
    );
    // Over the top.
    crown.quadraticBezierTo(
      crownCx,
      crownTop - crownH * 0.06,
      crownCx + crownW * 0.18,
      crownTop + crownH * 0.08,
    );
    // Right side down.
    _scallopedEdge(
      crown,
      from: Offset(crownCx + crownW * 0.18, crownTop + crownH * 0.08),
      to: Offset(crownCx + crownW * 0.5, crownBottom),
      bumps: 3,
      bulge: crownW * 0.09,
      rng: rng,
    );
    // Underside: gentle lobes back to the start.
    _scallopedEdge(
      crown,
      from: Offset(crownCx + crownW * 0.5, crownBottom),
      to: Offset(crownCx - crownW * 0.5, crownBottom),
      bumps: 4,
      bulge: crownH * 0.07,
      rng: rng,
    );
    crown.close();
    canvas.drawPath(crown, paint);
  }

  /// A curtain of foliage hanging from the top edge across [width], its lower
  /// edge dipping in leafy lobes down to at most [depth]. Drawn as one closed
  /// path; layer two or three with different colors/depths for a canopy.
  static Path canopyBand(
    double width,
    double depth, {
    int lobes = 6,
    int seed = 0,
  }) {
    final rng = math.Random(seed);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, depth * (0.45 + rng.nextDouble() * 0.3));
    var x = 0.0;
    final step = width / lobes;
    for (var i = 0; i < lobes; i++) {
      final nextX = x + step;
      final dipY = depth * (0.55 + rng.nextDouble() * 0.45);
      final riseY = depth * (0.25 + rng.nextDouble() * 0.3);
      // Each lobe: bulge down then tuck up, like overlapping leaf masses.
      path.quadraticBezierTo(x + step * 0.5, dipY, nextX, riseY);
      x = nextX;
    }
    path
      ..lineTo(width, 0)
      ..close();
    return path;
  }

  /// A vine hanging from [top], [length] long, swaying [sway] to the side,
  /// with paired leaves along it. Draws stem + leaves in [color].
  static void paintHangingVine(
    Canvas canvas,
    Offset top,
    double length,
    double sway,
    Color color, {
    int leaves = 5,
  }) {
    final stem = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(
        top.dx + sway,
        top.dy + length * 0.55,
        top.dx + sway * 0.4,
        top.dy + length,
      );
    canvas.drawPath(path, stem);

    // Leaves alternate sides along the stem.
    for (var i = 1; i <= leaves; i++) {
      final t = i / (leaves + 1);
      final pos = _quadPoint(
        top,
        Offset(top.dx + sway, top.dy + length * 0.55),
        Offset(top.dx + sway * 0.4, top.dy + length),
        t,
      );
      final side = i.isEven ? 1.0 : -1.0;
      final size = length * 0.085 * (1.15 - t * 0.5);
      paintLeaf(canvas, pos, size, side * (0.9 + t * 0.5), color);
    }
  }

  /// One complete leaf: pointed-oval blade with a center vein, rotated by
  /// [angle], tip [size] away from [base].
  static void paintLeaf(
    Canvas canvas,
    Offset base,
    double size,
    double angle,
    Color color,
  ) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final blade = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.55, -size * 0.42, size, 0)
      ..quadraticBezierTo(size * 0.55, size * 0.42, 0, 0)
      ..close();
    canvas.drawPath(blade, Paint()..color = color);
    canvas.drawLine(
      Offset.zero,
      Offset(size * 0.85, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 0.9,
    );
    canvas.restore();
  }

  /// A small wildflower: five petals radiating from a bright center, instead
  /// of the single colored dot the scenes used to scatter.
  static void paintFlower(
    Canvas canvas,
    Offset at,
    double radius,
    Color petal, {
    Color center = const Color(0xFFFFEE58),
  }) {
    final petalPaint = Paint()..color = petal;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5 - math.pi / 2;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(radius * 0.72, 0),
          width: radius * 1.15,
          height: radius * 0.72,
        ),
        petalPaint,
      );
      canvas.restore();
    }
    canvas.drawCircle(at, radius * 0.42, Paint()..color = center);
  }

  /// A glowing firefly: bright core over a soft radial halo.
  static void paintFirefly(
    Canvas canvas,
    Offset at,
    double radius,
    Color glow,
  ) {
    canvas.drawCircle(
      at,
      radius * 4,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: 0.35), Colors.transparent],
        ).createShader(Rect.fromCircle(center: at, radius: radius * 4)),
    );
    canvas.drawCircle(at, radius, Paint()..color = glow.withValues(alpha: 0.9));
  }

  /// A soft slanted light shaft from [top] widening as it falls [length].
  static void paintLightShaft(
    Canvas canvas,
    Offset top,
    double length,
    double slant,
    Color color,
  ) {
    final path = Path()
      ..moveTo(top.dx - 14, top.dy)
      ..lineTo(top.dx + 14, top.dy)
      ..lineTo(top.dx + slant + 52, top.dy + length)
      ..lineTo(top.dx + slant - 52, top.dy + length)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, Colors.transparent],
        ).createShader(path.getBounds())
        ..blendMode = BlendMode.plus,
    );
  }

  static void _scallopedEdge(
    Path path, {
    required Offset from,
    required Offset to,
    required int bumps,
    required double bulge,
    required math.Random rng,
  }) {
    var prev = from;
    for (var i = 1; i <= bumps; i++) {
      final t = i / bumps;
      final target = Offset(
        lerpDouble(from.dx, to.dx, t)!,
        lerpDouble(from.dy, to.dy, t)!,
      );
      // Bulge outward, perpendicular to the edge direction.
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      final nx = -dy / len;
      final ny = dx / len;
      final b = bulge * (0.8 + rng.nextDouble() * 0.5);
      path.quadraticBezierTo(
        (prev.dx + target.dx) / 2 + nx * b,
        (prev.dy + target.dy) / 2 + ny * b,
        target.dx,
        target.dy,
      );
      prev = target;
    }
  }

  static Offset _quadPoint(Offset p0, Offset c, Offset p1, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * c.dx + t * t * p1.dx,
      u * u * p0.dy + 2 * u * t * c.dy + t * t * p1.dy,
    );
  }
}
