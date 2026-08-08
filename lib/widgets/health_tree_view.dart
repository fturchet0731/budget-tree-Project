import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/tree_health_service.dart';
import '../theme/app_tokens.dart';
import '../theme/leaf_palette.dart';
import 'tree_drawing.dart';

/// The user's consistency, drawn as a tree.
///
/// Deliberately its own widget rather than a `health` flag on
/// [StaticBudgetTreeView]: a budget tree means "here is your allocation" and
/// must never be recoloured by behaviour, or the two signals blur into one.
/// This tree means one thing only — how consistently you have been checking in.
///
/// Health drives three things at once, because a single cue reads as a bug
/// rather than a state: the canopy thins (clusters drop away), the palette
/// drains toward dry amber, and at the top tier a soft halo appears behind the
/// crown. Wrapped in a [RepaintBoundary]; the halo's shimmer is gated on
/// reduced motion and the tree lays out identically with motion off.
class HealthTreeView extends StatefulWidget {
  /// 0 to 1. Usually [TreeHealth.fraction].
  final double health;
  final double size;

  /// Base palette before health drains it. Defaults to the app's conifer green.
  final LeafPalette palette;

  const HealthTreeView({
    super.key,
    required this.health,
    this.size = 160,
    this.palette = LeafPalette.defaultGreen,
  });

  @override
  State<HealthTreeView> createState() => _HealthTreeViewState();
}

class _HealthTreeViewState extends State<HealthTreeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  bool get _radiant =>
      TreeHealthService.tierFor(widget.health * 100) == TreeHealthTier.radiant;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _syncShimmer();
  }

  @override
  void didUpdateWidget(covariant HealthTreeView old) {
    super.didUpdateWidget(old);
    _syncShimmer();
  }

  /// The halo only breathes at the top tier, and only when motion is on.
  void _syncShimmer() {
    final wanted = _radiant && AppSettings.instance.motionFull;
    if (wanted && !_shimmer.isAnimating) {
      _shimmer.repeat(reverse: true);
    } else if (!wanted && _shimmer.isAnimating) {
      _shimmer
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) => CustomPaint(
            painter: HealthTreePainter(
              health: widget.health,
              palette: widget.palette,
              // Full glow when the shimmer is parked, so reduced motion still
              // sees a radiant tree rather than a dim one.
              glow: _radiant ? 0.75 + 0.25 * _shimmer.value : 0,
              tokens: AppTokens.current,
            ),
          ),
        ),
      ),
    );
  }
}

class HealthTreePainter extends CustomPainter {
  final double health;
  final LeafPalette palette;
  final double glow;
  final AppTokens tokens;

  const HealthTreePainter({
    required this.health,
    required this.palette,
    required this.glow,
    required this.tokens,
  });

  /// The crown, back to front. Trimming from the end thins the near and upper
  /// canopy first, which is where a viewer looks, so a wilting tree reads as
  /// sparse rather than merely smaller.
  static const _clusters = <({double dx, double dy, double r})>[
    (dx: -0.20, dy: -0.02, r: 0.20),
    (dx: 0.20, dy: -0.02, r: 0.20),
    (dx: 0.00, dy: -0.14, r: 0.23),
    (dx: -0.26, dy: -0.16, r: 0.16),
    (dx: 0.26, dy: -0.16, r: 0.16),
    (dx: -0.11, dy: -0.28, r: 0.17),
    (dx: 0.11, dy: -0.28, r: 0.17),
    (dx: 0.00, dy: -0.38, r: 0.14),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final h = health.clamp(0.0, 1.0);
    final w = size.width;
    final groundY = size.height * 0.86;
    final centre = w / 2;
    final leaves = palette.withHealth(h);

    _paintGround(canvas, size, groundY, h);

    if (glow > 0) {
      canvas.drawCircle(
        Offset(centre, groundY - size.height * 0.44),
        w * 0.40,
        Paint()..color = tokens.accent.withValues(alpha: 0.13 * glow),
      );
    }

    // A neglected tree is a smaller, thinner tree as well as a browner one.
    final trunkHeight = size.height * (0.30 + 0.10 * h);
    TreeDrawing.paintTrunk(
      canvas,
      base: Offset(centre, groundY),
      height: trunkHeight,
      baseHalfWidth: w * (0.045 + 0.020 * h),
      topHalfWidth: w * (0.020 + 0.010 * h),
      seed: 7,
    );

    final crownCentre = Offset(centre, groundY - trunkHeight - size.height * 0.04);

    // Keep at least two clusters: a bare trunk reads as "no data", and the
    // barren tier still has to look like a tree that could recover.
    final keep = math.max(2, (_clusters.length * (0.28 + 0.72 * h)).round());

    for (var i = 0; i < keep; i++) {
      final c = _clusters[i];
      TreeDrawing.paintCluster(
        canvas,
        Offset(crownCentre.dx + w * c.dx, crownCentre.dy + w * c.dy),
        w * c.r * (0.72 + 0.28 * h),
        leaves,
        seed: 31 + i * 17,
      );
    }

    // Fringe only on the two front clusters, thinning with health.
    final fringe = (6 * h).round();
    if (fringe > 0) {
      for (var i = 0; i < math.min(2, keep); i++) {
        final c = _clusters[i];
        TreeDrawing.paintLeafFringe(
          canvas,
          Offset(crownCentre.dx + w * c.dx, crownCentre.dy + w * c.dy),
          w * c.r * (0.72 + 0.28 * h),
          leaves,
          seed: 101 + i * 13,
          leafCount: fringe,
        );
      }
    }

    // Leaves the tree has dropped. The clearest read on "this went backwards",
    // and it only appears once health is genuinely low.
    if (h < 0.5) {
      _paintFallenLeaves(canvas, size, groundY, (1 - h * 2).clamp(0.0, 1.0),
          leaves);
    }
  }

  void _paintGround(Canvas canvas, Size size, double groundY, double h) {
    final grass = Color.lerp(
      const Color(0xFFB89B62),
      tokens.accentSoft,
      h,
    )!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.06,
          groundY,
          size.width * 0.88,
          size.height * 0.10,
        ),
        const Radius.circular(999),
      ),
      Paint()..color = grass,
    );
  }

  void _paintFallenLeaves(
    Canvas canvas,
    Size size,
    double groundY,
    double amount,
    LeafPalette leaves,
  ) {
    final rng = math.Random(5);
    final count = (5 * amount).round();
    final paint = Paint()..color = leaves.dark;
    for (var i = 0; i < count; i++) {
      final x = size.width * (0.16 + rng.nextDouble() * 0.68);
      final y = groundY + size.height * (0.012 + rng.nextDouble() * 0.05);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((rng.nextDouble() - 0.5) * 1.4);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.052,
          height: size.width * 0.026,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant HealthTreePainter old) =>
      old.health != health ||
      old.glow != glow ||
      old.tokens != tokens ||
      old.palette.mid != palette.mid;
}
