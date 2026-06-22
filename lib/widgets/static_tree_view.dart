import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import 'tree_drawing.dart';

/// Static (non-animated) version of the budget tree painter — used in the
/// immersive forest carousel to render a finished tree at full size.
class StaticBudgetTreeView extends StatelessWidget {
  final BudgetModel budget;
  final double scale;
  final List<TreeLeafHit>? leafHits;
  final LeafPalette leafPalette;

  const StaticBudgetTreeView({
    super.key,
    required this.budget,
    this.scale = 1.0,
    this.leafHits,
    this.leafPalette = LeafPalette.defaultGreen,
  });

  @override
  Widget build(BuildContext context) {
    // CustomPaint with no child renders at Size.zero. Force it to expand
    // into the parent constraints so trees actually show in PageView pages.
    return CustomPaint(
      size: Size.infinite,
      painter: _StaticTreePainter(
        budget: budget,
        scale: scale,
        leafHits: leafHits,
        leafPalette: leafPalette,
      ),
    );
  }
}

class TreeLeafHit {
  final Rect rect;
  final ExpenseCategory category;
  TreeLeafHit({required this.rect, required this.category});
}

class _StaticTreePainter extends CustomPainter {
  final BudgetModel budget;
  final double scale;
  final List<TreeLeafHit>? leafHits;
  final LeafPalette leafPalette;

  _StaticTreePainter({
    required this.budget,
    required this.scale,
    required this.leafPalette,
    this.leafHits,
  });

  @override
  void paint(Canvas canvas, Size size) {
    leafHits?.clear();
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.78;
    final trunkTopY = h * 0.30;
    final cx = w / 2;

    _drawGround(canvas, w, h, groundY);
    _drawTrunk(canvas, cx, groundY, trunkTopY);
    _drawCrown(canvas, cx, trunkTopY);
    if (budget.expenses.isNotEmpty) {
      _drawBranches(canvas, cx, groundY, trunkTopY);
    }
  }

  void _drawGround(Canvas canvas, double w, double h, double groundY) {
    // Far ground arc that rises behind the trunk so the tree never looks like
    // it's floating mid-air. Drawn first so trunk + roots sit on top.
    final back = Path()
      ..moveTo(0, groundY + 4)
      ..quadraticBezierTo(w * 0.30, groundY - 6, w * 0.62, groundY + 2)
      ..quadraticBezierTo(w * 0.85, groundY + 8, w, groundY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = AppPalettes.groundClose());

    final front = Path()
      ..moveTo(0, groundY + 14)
      ..quadraticBezierTo(w * 0.4, groundY + 9, w * 0.7, groundY + 14)
      ..quadraticBezierTo(w * 0.9, groundY + 16, w, groundY + 12)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = AppPalettes.groundMid());

    // Grass blades near the trunk for a soft horizon
    final rng = math.Random(31);
    final blade = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (int i = 0; i < 36; i++) {
      final x = rng.nextDouble() * w;
      final baseY = groundY + 2 + (x / w) * 4;
      final blH = 6 + rng.nextDouble() * 14;
      final lean = (rng.nextDouble() - 0.5) * 10;
      blade.color = Color.fromRGBO(
        (24 + (rng.nextDouble() * 28)).round(),
        (84 + (rng.nextDouble() * 62)).round(),
        (24 + (rng.nextDouble() * 28)).round(),
        0.85,
      );
      canvas.drawLine(
          Offset(x, baseY), Offset(x + lean, baseY - blH), blade);
    }
  }

  void _drawTrunk(
      Canvas canvas, double cx, double groundY, double trunkTopY) {
    TreeDrawing.paintTrunk(
      canvas,
      base: Offset(cx, groundY),
      height: groundY - trunkTopY,
      baseHalfWidth: 22 * scale,
      topHalfWidth: 9 * scale,
      seed: budget.id.hashCode,
    );
  }

  void _drawCrown(Canvas canvas, double cx, double trunkTopY) {
    final cy = trunkTopY - 8 * scale;
    final lp = leafPalette;
    final seedBase = budget.id.hashCode;

    // Soft shadow below the canopy
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + 8, trunkTopY + 8),
          width: 150 * scale,
          height: 22 * scale),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Organic foliage clusters from back to front
    final clusters = [
      (cx - 50, cy + 28, 50.0),
      (cx + 46, cy + 22, 48.0),
      (cx - 22, cy - 8, 60.0),
      (cx + 18, cy - 16, 56.0),
      (cx - 8, cy + 8, 64.0),
      (cx + 6, cy - 4, 60.0),
      (cx - 36, cy - 32, 38.0),
      (cx + 34, cy - 28, 36.0),
      (cx, cy - 48, 46.0),
      (cx - 8, cy - 68, 30.0),
      (cx + 10, cy - 62, 28.0),
    ];

    for (int i = 0; i < clusters.length; i++) {
      final (lx, ly, lr) = clusters[i];
      TreeDrawing.paintCluster(
        canvas,
        Offset(lx, ly),
        lr * scale,
        lp,
        seed: seedBase + i * 17,
      );
    }

    // Leaf fringe on the front-facing top clusters
    for (final (lx, ly, lr, seed) in [
      (cx - 8.0, cy + 8.0, 64.0, seedBase + 401),
      (cx, cy - 48.0, 46.0, seedBase + 402),
    ]) {
      TreeDrawing.paintLeafFringe(
        canvas,
        Offset(lx, ly),
        lr * scale,
        lp,
        seed: seed,
        leafCount: 6,
        leafSize: 8 * scale,
      );
    }
  }

  void _drawBranches(
      Canvas canvas, double cx, double groundY, double trunkTopY) {
    final cats = budget.expenses;
    final count = cats.length;
    for (int i = 0; i < count; i++) {
      final cat = cats[i];
      final pct = budget.percentageFor(cat);
      final tPos = 0.28 + (i / (count > 1 ? count - 1 : 1)) * 0.57;
      final attachY = trunkTopY + (groundY - trunkTopY) * tPos;
      final goLeft = i.isEven;
      final angle = goLeft ? math.pi * 0.65 : math.pi * 0.35;
      final maxLen = (62 + pct * 130) * scale;
      final endX = cx + math.cos(angle) * maxLen;
      final endY = attachY - math.sin(angle) * maxLen;

      final startW = ((7.0 + pct * 14) * scale).clamp(7.0, 21.0);
      final endW = (startW * 0.28).clamp(2.0, 6.0);
      TreeDrawing.paintBranch(
        canvas,
        Offset(cx, attachY),
        Offset(endX, endY),
        startW: startW,
        endW: endW,
        bowFactor: 0.08,
      );

      _leaf(canvas, endX, endY, goLeft, cat, scale);
      leafHits?.add(TreeLeafHit(
        rect: Rect.fromCenter(
            center: Offset(endX, endY), width: 90, height: 90),
        category: cat,
      ));
    }
  }

  void _leaf(Canvas canvas, double x, double y, bool goLeft,
      ExpenseCategory cat, double s) {
    final leafW = 30.0 * s;
    final leafH = 50.0 * s;
    final angle = goLeft ? -math.pi / 4 : math.pi / 4;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -leafH)
      ..cubicTo(leafW * 0.95, -leafH * 0.25, leafW * 0.95, leafH * 0.55, 0,
          leafH * 0.22)
      ..cubicTo(-leafW * 0.95, leafH * 0.55, -leafW * 0.95, -leafH * 0.25, 0,
          -leafH)
      ..close();
    final lp = leafPalette;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [lp.light, lp.mid, lp.dark],
          stops: const [0.0, 0.45, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
            Rect.fromLTWH(-leafW, -leafH, leafW * 2, leafH * 1.3)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lp.outline
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    // Central vein
    canvas.drawLine(
      Offset(0, -leafH * 0.85),
      Offset(0, leafH * 0.18),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = 1.0,
    );
    canvas.restore();

    // Icon + name label
    final iconData = CategoryIcons.forKey(cat.emoji);
    final iconTp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          fontSize: 13 * s,
          color: Colors.white,
          shadows: const [
            Shadow(
                color: Colors.black54,
                offset: Offset(0.5, 1),
                blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final nameTp = TextPainter(
      text: TextSpan(
        text: cat.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.5 * s,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
                color: Colors.black54,
                offset: Offset(0.5, 1),
                blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 64 * s);
    final totalH = iconTp.height + 2 + nameTp.height;
    final topY = y - totalH / 2 - 2;
    iconTp.paint(canvas, Offset(x - iconTp.width / 2, topY));
    nameTp.paint(
        canvas, Offset(x - nameTp.width / 2, topY + iconTp.height + 2));
  }

  @override
  bool shouldRepaint(_StaticTreePainter old) =>
      old.budget != budget ||
      old.scale != scale ||
      old.leafPalette != leafPalette;
}
