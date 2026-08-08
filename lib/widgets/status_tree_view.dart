import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/app_settings.dart';

/// The user's consistency, drawn as one of the sixteen pixel-art status trees.
///
/// Deliberately its own widget rather than a `health` flag on a budget tree: a
/// budget tree means "here is your allocation" and must never be recoloured by
/// behaviour. This tree means one thing only — how consistently you have been
/// checking in, and (in the prestige tiers) for how long.
///
/// Each sprite in `assets/status_trees/<key>.png` is a horizontal sheet of four
/// frames. The frames bake in a gentle canopy sway, so animating is just
/// stepping through them on a hard cut (no interpolation) at ~1.5s per loop.
/// Instances start at a random phase so a row of trees never sways in unison,
/// and the whole thing is gated on reduced motion. Wrapped in a
/// [RepaintBoundary]; it lays out identically with motion off.
class StatusTreeView extends StatefulWidget {
  /// One of the sixteen tier names, e.g. `radiant` or `gilded`. Matches
  /// `TreeHealth.spriteKey` and a file under `assets/status_trees/`.
  final String spriteKey;
  final double size;

  const StatusTreeView({
    super.key,
    required this.spriteKey,
    this.size = 160,
  });

  @override
  State<StatusTreeView> createState() => _StatusTreeViewState();
}

class _StatusTreeViewState extends State<StatusTreeView>
    with SingleTickerProviderStateMixin {
  /// Decoded sheets are shared across every instance — sixteen small images at
  /// most, and a tree shows up in several places at once.
  static final Map<String, ui.Image> _cache = {};

  static const _frames = 4;
  static const _loop = Duration(milliseconds: 1500);

  late final AnimationController _clock;
  late final double _phase; // 0..1, this instance's offset into the loop.
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _phase = math.Random().nextDouble();
    _clock = AnimationController(vsync: this, duration: _loop);
    _load();
    _syncClock();
  }

  @override
  void didUpdateWidget(covariant StatusTreeView old) {
    super.didUpdateWidget(old);
    if (old.spriteKey != widget.spriteKey) _load();
    _syncClock();
  }

  Future<void> _load() async {
    final key = widget.spriteKey;
    final cached = _cache[key];
    if (cached != null) {
      if (_image != cached && mounted) setState(() => _image = cached);
      return;
    }
    try {
      final data = await rootBundle.load('assets/status_trees/$key.png');
      final image = await decodeImageFromList(data.buffer.asUint8List());
      _cache[key] = image;
      if (!mounted) return;
      // A late-arriving load for a key we've since moved off must not clobber
      // the current one.
      if (widget.spriteKey == key) setState(() => _image = image);
    } catch (_) {
      // A missing sprite degrades to an empty box rather than crashing.
    }
  }

  void _syncClock() {
    if (AppSettings.instance.motionFull) {
      if (!_clock.isAnimating) _clock.repeat();
    } else if (_clock.isAnimating) {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: image == null
            ? null
            : AnimatedBuilder(
                animation: _clock,
                builder: (context, _) {
                  final phased = (_clock.value + _phase) % 1.0;
                  final frame = (phased * _frames).floor() % _frames;
                  return CustomPaint(
                    painter: _SpritePainter(image: image, frame: frame),
                  );
                },
              ),
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frame;

  const _SpritePainter({required this.image, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final frameW = image.width / _StatusTreeViewState._frames;
    final frameH = image.height.toDouble();
    final src = Rect.fromLTWH(frame * frameW, 0, frameW, frameH);
    final dst = Offset.zero & size;
    // Nearest-neighbour keeps the pixel art crisp instead of smearing it when
    // scaled up.
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.image != image || old.frame != frame;
}
