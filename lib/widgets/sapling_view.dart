import 'package:flutter/material.dart';
import '../theme/leaf_palette.dart';
import 'pixel_tree_engine.dart';

/// Renders a growing goal tree whose stage is driven by [progress] (0..1),
/// mapped to the pixel engine's continuous growth scalar `g = 1 + progress*6`
/// (stage 1 Seed to stage 7 Mature). The engine morphs fluidly between stages,
/// so a deposit that nudges [progress] upward reads as the tree growing rather
/// than snapping.
///
/// The painter draws on a fixed design grid and the view scales that drawing to
/// fit whatever box it is given, centered. Because the pixels are vector rects,
/// the [FittedBox] scales them crisply (no resampling), matching the handoff's
/// nearest-neighbour intent.
class SaplingView extends StatelessWidget {
  // 36x44 grid at 6px cells. Kept close to the previous 220x260 design box so
  // every call site lays out unchanged.
  static const double _cell = 6.0;
  static const int _cols = 36;
  static const int _rows = 44;
  static const _designSize = Size(_cols * _cell, _rows * _cell);

  final double progress;
  final Size size;
  final bool showGround;
  final LeafPalette leafPalette;

  const SaplingView({
    super.key,
    required this.progress,
    this.size = _designSize,
    this.showGround = true,
    this.leafPalette = LeafPalette.defaultGreen,
  });

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(
      size: _designSize,
      painter: SaplingPainter(
        progress: progress.clamp(0.0, 1.0),
        showGround: showGround,
        leafPalette: leafPalette,
      ),
    );
    final fitted = FittedBox(
      fit: BoxFit.contain,
      child: SizedBox.fromSize(size: _designSize, child: painter),
    );
    // Size.infinite means "fill whatever the parent gives us".
    if (!size.isFinite) return Center(child: fitted);
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Center(child: fitted),
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
    final surface = PixelSurface(canvas, SaplingView._cell);
    void put(int x, int y, Color c) => surface.put(x, y, c);

    final cols = SaplingView._cols;
    final rows = SaplingView._rows;
    final cx = cols / 2;
    final gy = (rows - 5).toDouble();
    // Matches the reference's (h-5)/30 normalisation so the tree fills the box.
    final s = (rows - 5) / 30;

    if (showGround) {
      PixelTree.mound(
          put, cx, gy, cols * 0.32, 2, PixelTree.ramp(PixelTree.soilBase));
    }

    // Category tint drives the whole canopy through the engine's HSL ramp.
    final tint = leafPalette.mid;
    final g = 1 + progress.clamp(0.0, 1.0) * 6; // 1..7
    PixelTree.goalTree(put, cx, gy, tint, g, s);
  }

  @override
  bool shouldRepaint(SaplingPainter old) =>
      old.progress != progress ||
      old.showGround != showGround ||
      old.leafPalette.mid != leafPalette.mid;
}
