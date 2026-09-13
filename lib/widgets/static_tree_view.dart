import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import 'pixel_tree_engine.dart';

/// Static (non-animated) version of the budget tree — used in the immersive
/// forest carousel to render a finished tree at full size, now in the pixel-art
/// style ported from the design handoff.
///
/// The tree's shape (one branch per expense category, fanned so their labels do
/// not collide) is unchanged; only the drawing is pixelated. The branch layout
/// and the reported [leafHits] are the same geometry the vector version used, so
/// tap targets and the label-spacing guarantees still hold.
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
    // Kept at 0.78 of the box: the immersive scene derives its horizon from
    // this exact fraction (see forest_ground_test).
    final groundY = h * 0.78;
    // A shorter trunk than before, so the tree reads compact rather than tall.
    final trunkTopY = h * 0.36;
    final cx = w / 2;

    // A cell size that gives a chunky-but-legible pixel grid at any box size.
    final cell = math.max(1.5, h / 60);
    final surface = PixelSurface(canvas, cell);
    void put(int x, int y, Color c) => surface.put(x, y, c);
    double gx(double d) => d / cell;

    final bark = PixelTree.ramp(PixelTree.barkBase);
    final leaf = PixelTree.ramp(leafPalette.mid);

    _drawGround(put, gx, cx, groundY, w);

    // Trunk (full widths, converted from the old half-width design).
    PixelTree.trunk(put, gx(cx), gx(trunkTopY), gx(groundY),
        gx(18 * scale), gx(44 * scale), bark);

    _drawCrown(put, gx, cx, trunkTopY, leaf);

    if (budget.expenses.isNotEmpty) {
      _drawBranches(canvas, put, gx, cell, cx, groundY, trunkTopY, bark, leaf);
    }
  }

  void _drawGround(
      PutPixel put, double Function(double) gx, double cx, double groundY,
      double w) {
    PixelTree.mound(put, gx(cx), gx(groundY), gx(w * 0.34), gx(w * 0.05),
        PixelTree.ramp(PixelTree.soilBase));
  }

  void _drawCrown(PutPixel put, double Function(double) gx, double cx,
      double trunkTopY, PixelRamp leaf) {
    final cy = trunkTopY - 8 * scale;
    // The same eleven-cluster crown, drawn as one metaball canopy so it reads
    // as a single shaded mass rather than stacked circles.
    final clusters = <(double, double, double)>[
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
    final blobs = [
      for (final (lx, ly, lr) in clusters)
        CanopyBlob(gx(lx), gx(ly), gx(lr * scale * 0.42))
    ];
    PixelTree.canopy(put, blobs, leaf, budget.id.hashCode & 0x7fffffff);
  }

  void _drawBranches(
    Canvas canvas,
    PutPixel put,
    double Function(double) gx,
    double cell,
    double cx,
    double groundY,
    double trunkTopY,
    PixelRamp bark,
    PixelRamp leaf,
  ) {
    final cats = budget.expenses;
    final count = cats.length;

    // Branches alternate sides, so each side gets roughly half of them.
    final leftCount = (count / 2).ceil();
    final rightCount = count ~/ 2;

    for (int i = 0; i < count; i++) {
      final cat = cats[i];
      final pct = budget.percentageFor(cat);
      final tPos = 0.20 + (i / (count > 1 ? count - 1 : 1)) * 0.68;
      final attachY = trunkTopY + (groundY - trunkTopY) * tPos;
      final goLeft = i.isEven;

      // Fan the branches (unchanged geometry): high branches lift toward the
      // crown, low ones reach flatter and further, so leaf labels never stack.
      final sideIndex = i ~/ 2;
      final sideCount = goLeft ? leftCount : rightCount;
      final t = sideCount > 1 ? sideIndex / (sideCount - 1) : 0.35;
      final elevation = (0.44 - t * 0.26) * math.pi;
      final angle = goLeft ? math.pi - elevation : elevation;

      final reach = 1.0 + t * 0.34;
      final maxLen = (74 + pct * 110) * scale * reach;
      final endX = cx + math.cos(angle) * maxLen;
      final endY = attachY - math.sin(angle) * maxLen;

      // Thicker, less tapered limbs so branches read as real branches, not
      // twigs.
      final startW = ((16.0 + pct * 22) * scale).clamp(14.0, 40.0);
      final endW = (startW * 0.5).clamp(7.0, 18.0);

      PixelTree.limb(put, gx(cx), gx(attachY), gx(endX), gx(endY),
          gx(startW), gx(endW), bark);

      // Leaf blob at the branch tip, larger to match the fuller branches.
      final r = (20 + pct * 14) * scale;
      PixelTree.canopy(
        put,
        [
          CanopyBlob(gx(endX), gx(endY), gx(r), k: 0.95),
          CanopyBlob(gx(endX - (goLeft ? r * 0.5 : -r * 0.5)),
              gx(endY + r * 0.35), gx(r * 0.6)),
        ],
        leaf,
        (cat.name.hashCode + i * 17) & 0x7fffffff,
      );

      _label(canvas, endX, endY, cat, scale);
      leafHits?.add(TreeLeafHit(
        rect:
            Rect.fromCenter(center: Offset(endX, endY), width: 90, height: 90),
        category: cat,
      ));
    }
  }

  void _label(
      Canvas canvas, double x, double y, ExpenseCategory cat, double s) {
    final iconData = CategoryIcons.forKey(cat.emoji);
    final iconTp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          fontSize: 13 * s,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black54, offset: Offset(0.5, 1), blurRadius: 3),
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
            Shadow(color: Colors.black54, offset: Offset(0.5, 1), blurRadius: 3),
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
      old.leafPalette.mid != leafPalette.mid;
}
