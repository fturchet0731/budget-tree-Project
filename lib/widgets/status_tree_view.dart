import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
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
///
/// [leafTint] performs a **palette swap** on the foliage only (see
/// [_recolour]) so a goal's category colour carries onto its tree. The health
/// tree itself never passes a tint — its colour is the tier's meaning.
class StatusTreeView extends StatefulWidget {
  /// One of the sixteen tier names, e.g. `radiant` or `gilded`. Matches
  /// `TreeHealth.spriteKey` and a file under `assets/status_trees/`.
  final String spriteKey;
  final double size;

  /// Recolour the leaves to this hue, keeping the trunk and soil untouched.
  /// Null renders the sprite exactly as authored.
  final Color? leafTint;

  const StatusTreeView({
    super.key,
    required this.spriteKey,
    this.size = 160,
    this.leafTint,
  });

  @override
  State<StatusTreeView> createState() => _StatusTreeViewState();
}

class _StatusTreeViewState extends State<StatusTreeView>
    with SingleTickerProviderStateMixin {
  /// Decoded sheets are shared across every instance — sixteen small images at
  /// most (times however many category tints are in play), and a tree shows up
  /// in several places at once.
  static final Map<String, ui.Image> _cache = {};

  /// In-flight decodes, so N saplings of the same kind don't each recolour the
  /// same sheet on first build.
  static final Map<String, Future<ui.Image?>> _pending = {};

  static const _frames = 4;
  static const _loop = Duration(milliseconds: 1500);

  late final AnimationController _clock;
  late final double _phase; // 0..1, this instance's offset into the loop.
  ui.Image? _image;

  String get _cacheKey => widget.leafTint == null
      ? widget.spriteKey
      : '${widget.spriteKey}#${widget.leafTint!.toARGB32()}';

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
    if (old.spriteKey != widget.spriteKey || old.leafTint != widget.leafTint) {
      _load();
    }
    _syncClock();
  }

  Future<void> _load() async {
    final key = _cacheKey;
    final cached = _cache[key];
    if (cached != null) {
      if (_image != cached && mounted) setState(() => _image = cached);
      return;
    }
    final image = await (_pending[key] ??= _decode(key));
    if (image == null || !mounted) return;
    // A late-arriving load for a key we've since moved off must not clobber
    // the current one.
    if (_cacheKey == key) setState(() => _image = image);
  }

  Future<ui.Image?> _decode(String key) async {
    try {
      final data =
          await rootBundle.load('assets/status_trees/${widget.spriteKey}.png');
      var image = await decodeImageFromList(data.buffer.asUint8List());
      final tint = widget.leafTint;
      if (tint != null) image = await _recolour(image, tint);
      _cache[key] = image;
      return image;
    } catch (_) {
      // A missing sprite degrades to an empty box rather than crashing.
      return null;
    } finally {
      _pending.remove(key);
    }
  }

  /// Palette-swaps the foliage to [tint].
  ///
  /// Only pixels that read as leaves are touched: saturated hues in the green
  /// band. Trunk and soil are browns (hue well below the band) and the shaded
  /// outline is near-black (no saturation), so both survive untouched. Each
  /// leaf pixel keeps its **lightness**, which is what carries the sprite's
  /// four-step shading ladder — so the retinted tree still reads as the same
  /// drawing, just in another colour.
  static Future<ui.Image> _recolour(ui.Image src, Color tint) async {
    final bd = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) return src;
    final px = Uint8List.fromList(bd.buffer.asUint8List());
    final target = HSLColor.fromColor(tint);

    for (var i = 0; i < px.length; i += 4) {
      if (px[i + 3] == 0) continue; // transparent
      final hsl = HSLColor.fromColor(
        Color.fromARGB(255, px[i], px[i + 1], px[i + 2]),
      );
      // Greens and yellow-greens only, and only where there is real colour.
      if (hsl.saturation < 0.12) continue;
      if (hsl.hue < 55 || hsl.hue > 175) continue;
      final out = HSLColor.fromAHSL(
        1,
        target.hue,
        target.saturation.clamp(0.25, 1.0),
        hsl.lightness,
      ).toColor();
      px[i] = (out.r * 255).round();
      px[i + 1] = (out.g * 255).round();
      px[i + 2] = (out.b * 255).round();
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      px,
      src.width,
      src.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
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
