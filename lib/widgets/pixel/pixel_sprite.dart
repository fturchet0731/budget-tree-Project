import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/app_settings.dart';

/// Asset paths for the authored pixel art in `assets/ui/`.
///
/// All icons are square sheets drawn at 16x16 intent; render them through
/// [PixelSprite] so they scale nearest-neighbour.
class PixelIcons {
  PixelIcons._();
  static const _u = 'assets/ui/';

  static const plus = '${_u}icon_plus.png';
  static const forest = '${_u}icon_forest.png';
  static const star = '${_u}icon_star.png';
  static const drop = '${_u}icon_drop.png';
  static const heart = '${_u}icon_heart.png';
  static const coin = '${_u}icon_coin.png';
  static const chat = '${_u}icon_chat.png';
  static const scroll = '${_u}icon_scroll.png';
  static const gear = '${_u}icon_gear.png';
  static const sprout = '${_u}icon_sprout.png';
  static const back = '${_u}icon_back.png';
  static const check = '${_u}icon_check.png';
  static const flame = '${_u}icon_flame.png';
  static const pencil = '${_u}icon_pencil.png';
  static const lock = '${_u}icon_lock.png';

  static const acorn = '${_u}acorn.png'; // 2-frame idle/blink sheet
  static const acornHead = '${_u}acorn_head.png'; // portrait
  static const cloud = '${_u}cloud.png';
  static const groundTile = '${_u}tile_ground.png';

  /// Chunky budget-tree sprites, by forest fullness.
  static const treeSparse = '${_u}tree_sparse.png';
  static const treeHealthy = '${_u}tree_healthy.png';
  static const treeFull = '${_u}tree_full.png';
  static const treeFruiting = '${_u}tree_fruiting.png';

  /// Picks a budget-tree sprite from how much of the income is allocated and
  /// how many branches the tree carries.
  static String budgetTree({required int branches, required double filled}) {
    if (branches >= 6 && filled >= 0.85) return treeFruiting;
    if (branches >= 4 || filled >= 0.6) return treeFull;
    if (branches >= 2 || filled >= 0.3) return treeHealthy;
    return treeSparse;
  }
}

/// A single pixel-art image drawn with nearest-neighbour filtering.
///
/// Never use a plain `Image.asset` for this art: the default bilinear filter
/// blurs the pixel grid the moment it is scaled, which is exactly what the
/// 16-bit look must avoid.
class PixelSprite extends StatelessWidget {
  final String asset;
  final double? size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? tint;

  const PixelSprite({
    super.key,
    required this.asset,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width ?? size,
      height: height ?? size,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcIn,
      // A missing sprite degrades to empty space rather than a red error box.
      errorBuilder: (_, _, _) =>
          SizedBox(width: width ?? size, height: height ?? size),
    );
  }
}

/// Steps a horizontal sprite sheet on a hard cut — the same mechanic
/// [StatusTreeView] uses for the status trees.
///
/// [frames] cells are laid out left to right in one row. Each instance starts
/// at a random phase so a row of them never animates in unison, and the clock
/// is gated on reduced motion.
class PixelSpriteSheet extends StatefulWidget {
  final String asset;
  final int frames;
  final double size;
  final Duration period;

  /// Freeze on this frame instead of animating (used by static gallery cells).
  final int? staticFrame;

  const PixelSpriteSheet({
    super.key,
    required this.asset,
    required this.size,
    this.frames = 4,
    this.period = const Duration(milliseconds: 1600),
    this.staticFrame,
  });

  @override
  State<PixelSpriteSheet> createState() => _PixelSpriteSheetState();
}

class _PixelSpriteSheetState extends State<PixelSpriteSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final int _phase;

  @override
  void initState() {
    super.initState();
    _phase = math.Random().nextInt(widget.frames);
    _c = AnimationController(vsync: this, duration: widget.period);
    if (widget.staticFrame == null && AppSettings.instance.motionFull) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final frame = widget.staticFrame ??
            (((_c.value * widget.frames).floor() + _phase) % widget.frames);
        return ClipRect(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: OverflowBox(
              maxWidth: widget.size * widget.frames,
              alignment: Alignment(
                widget.frames == 1
                    ? 0
                    : -1 + 2 * (frame / (widget.frames - 1)),
                0,
              ),
              child: PixelSprite(
                asset: widget.asset,
                width: widget.size * widget.frames,
                height: widget.size,
                fit: BoxFit.fill,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The repeating grass-over-soil strip that seats every outdoor scene.
class PixelGround extends StatelessWidget {
  final double height;
  const PixelGround({super.key, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.asset(
        PixelIcons.groundTile,
        repeat: ImageRepeat.repeatX,
        alignment: Alignment.topLeft,
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
        fit: BoxFit.none,
        scale: 128 / height,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
