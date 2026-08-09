import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dart port of the design handoff's `tree_engine.js` — the procedural pixel
/// engine behind the budget tree and goal sapling makeover.
///
/// Everything draws onto a coarse integer grid through a [PutPixel] callback;
/// the surface it draws to decides how big each grid cell is on screen. Scaling
/// happens by drawing bigger cells, never by resampling an image, so the pixel
/// art stays crisp at any size (the Flutter equivalent of the handoff's
/// `imageSmoothingEnabled = false`).
///
/// The math is a faithful port: `n2` value noise, the four-step HSL [ramp], the
/// metaball [canopy] shading, and the trunk/limb/mound/sparkle/seedling/goal
/// primitives all mirror the reference so the look matches. A single scalar
/// drives each tree (`g` 1..7 for goals, progress for budgets), so any
/// in-between state renders and tweens continuously.
typedef PutPixel = void Function(int x, int y, Color color);

/// A four-step colour ramp derived from one base colour: highlight, mid (the
/// base itself), low and dark. The canopy picks a step per pixel from a soft
/// normal plus value-noise, giving the blocky-but-shaded look.
class PixelRamp {
  final Color hi;
  final Color mid;
  final Color lo;
  final Color dk;
  const PixelRamp(this.hi, this.mid, this.lo, this.dk);
}

/// A grid-drawing surface: turns integer cell coordinates into filled rects of
/// side [cell] on the real canvas, offset by [origin]. Cells tile without gaps
/// (each spans floor(n*cell)..ceil((n+1)*cell)) and are drawn with anti-alias
/// off so edges stay hard.
class PixelSurface {
  final Canvas canvas;
  final double cell;
  final Offset origin;
  final Paint _paint = Paint()..isAntiAlias = false;

  PixelSurface(this.canvas, this.cell, {this.origin = Offset.zero});

  /// Grid columns/rows spanning a device width/height.
  int cols(double width) => (width / cell).ceil();
  int rows(double height) => (height / cell).ceil();

  /// Convert a device length to grid units.
  double g(double deviceLength) => deviceLength / cell;

  void put(int x, int y, Color color) {
    final left = origin.dx + (x * cell).floorToDouble();
    final top = origin.dy + (y * cell).floorToDouble();
    final right = origin.dx + ((x + 1) * cell).ceilToDouble();
    final bottom = origin.dy + ((y + 1) * cell).ceilToDouble();
    _paint.color = color;
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), _paint);
  }
}

/// One canopy blob: centre [x],[y] and radius [r] in grid units, squashed
/// vertically by [k] (1 = round).
class CanopyBlob {
  final double x;
  final double y;
  final double r;
  final double k;
  const CanopyBlob(this.x, this.y, this.r, {this.k = 1.0});
}

/// The stateless procedural engine. All coordinates are in grid units.
class PixelTree {
  PixelTree._();

  static const Color barkBase = Color(0xFF9A7248);
  static const Color barkThick = Color(0xFF8A6440);
  static const Color soilBase = Color(0xFF7D5F3C);
  static const Color defaultLeaf = Color(0xFF7FC23A);
  static const Color sparkleGold = Color(0xFFF2D36B);

  // ── colour helpers ────────────────────────────────────────────────

  /// Value noise in 0..1, ported verbatim so canopies dither identically.
  static double n2(num x, num y, [num s = 0]) {
    final v = math.sin(x * 127.1 + y * 311.7 + s * 74.7) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// Four-step ramp from a base colour, matching `ramp()` in the handoff:
  /// hi = +19% L (+4 S), mid = base, lo = -13% L, dk = -25% L (-8 S).
  static PixelRamp ramp(Color base) {
    final hsl = HSLColor.fromColor(base);
    final h = hsl.hue;
    final s = hsl.saturation * 100;
    final l = hsl.lightness * 100;
    Color mk(double ss, double ll) => HSLColor.fromAHSL(
          1,
          h,
          (ss / 100).clamp(0.0, 1.0),
          (ll / 100).clamp(0.0, 1.0),
        ).toColor();
    return PixelRamp(
      mk(math.min(100, s + 4), math.min(90, l + 19)),
      base,
      mk(s, math.max(10, l - 13)),
      mk(math.max(0, s - 8), math.max(7, l - 25)),
    );
  }

  // ── primitives ────────────────────────────────────────────────────

  /// Metaball canopy: for each cell in the blobs' union, pick the nearest blob,
  /// drop cells outside a noisy rim, and shade by a soft normal plus noise.
  static void canopy(PutPixel put, List<CanopyBlob> blobs, PixelRamp pal,
      int seed) {
    if (blobs.isEmpty) return;
    var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
    for (final b in blobs) {
      final ry = b.r * b.k;
      x0 = math.min(x0, b.x - b.r - 1);
      x1 = math.max(x1, b.x + b.r + 1);
      y0 = math.min(y0, b.y - ry - 1);
      y1 = math.max(y1, b.y + ry + 1);
    }
    for (var y = y0.floor(); y <= y1.ceil(); y++) {
      for (var x = x0.floor(); x <= x1.ceil(); x++) {
        CanopyBlob? best;
        var bd = 1e9;
        for (final b in blobs) {
          final dx = (x + 0.5 - b.x) / b.r;
          final dy = (y + 0.5 - b.y) / (b.r * b.k);
          final d = math.sqrt(dx * dx + dy * dy);
          if (d < bd) {
            bd = d;
            best = b;
          }
        }
        if (best == null) continue;
        final j = (n2(x, y, seed) - 0.5) * 0.13;
        if (bd > 1 + j) continue;
        final nx = (x + 0.5 - best.x) / best.r;
        final ny = (y + 0.5 - best.y) / best.r;
        final lum =
            -(nx * 0.5 + ny * 0.82) + (n2(x * 1.7, y * 1.3, seed + 3) * 0.2 - 0.1);
        Color col;
        if (bd > 0.86) {
          col = pal.dk;
        } else if (lum > 0.36) {
          col = pal.hi;
        } else if (lum > -0.1) {
          col = pal.mid;
        } else {
          col = pal.lo;
        }
        put(x, y, col);
      }
    }
  }

  /// Tapering trunk from [top] to [bot] (grid rows), widening [wTop]->[wBot].
  static void trunk(PutPixel put, double cx, double top, double bot, double wTop,
      double wBot, PixelRamp pal) {
    final t0 = top.round();
    final b0 = bot.round();
    for (var y = t0; y <= b0; y++) {
      final t = (y - t0) / math.max(1, b0 - t0);
      final w = math.max(1, (wTop + (wBot - wTop) * t * t).round());
      final l = (cx - w / 2).round();
      final r = l + w - 1;
      for (var x = l; x <= r; x++) {
        var c = pal.mid;
        if (w > 2 && x == l) {
          c = pal.hi;
        } else if (w > 1 && x == r) {
          c = pal.dk;
        } else if (w > 3 && x == r - 1) {
          c = pal.lo;
        }
        put(x, y, c);
      }
    }
  }

  /// A branch limb from (x0,y0) to (x1,y1), tapering [w0]->[w1].
  static void limb(PutPixel put, double x0, double y0, double x1, double y1,
      double w0, double w1, PixelRamp pal) {
    final steps =
        (math.max((x1 - x0).abs(), (y1 - y0).abs()) * 2).round();
    for (var i = 0; i <= steps; i++) {
      final t = steps != 0 ? i / steps : 0.0;
      final x = (x0 + (x1 - x0) * t).round();
      final y = (y0 + (y1 - y0) * t).round();
      final w = math.max(1, (w0 + (w1 - w0) * t).round());
      for (var k = 0; k < w; k++) {
        put(x, y + k, k == 0 ? pal.hi : (k == w - 1 ? pal.dk : pal.mid));
      }
    }
  }

  /// A soil mound ellipse centred at (cx,cy) with radii (rx,ry).
  static void mound(
      PutPixel put, double cx, double cy, double rx, double ry, PixelRamp pal) {
    for (var y = -ry.round(); y <= ry.round(); y++) {
      for (var x = -rx.round(); x <= rx.round(); x++) {
        final d = (x / rx) * (x / rx) + (y / ry) * (y / ry);
        if (d > 1) continue;
        put(
          cx.round() + x,
          cy.round() + y,
          y < -ry * 0.2 ? pal.hi : (y > ry * 0.25 ? pal.dk : pal.mid),
        );
      }
    }
  }

  /// A ring of little plus-shaped sparkles around (cx,cy).
  static void sparkles(PutPixel put, double cx, double cy, double r, int n,
      Color col, int seed) {
    for (var i = 0; i < n; i++) {
      final a = n2(i, 3, seed) * math.pi * 2;
      final rr = r * (0.75 + n2(i, 9, seed + 1) * 0.55);
      final x = (cx + math.cos(a) * rr).round();
      final y = (cy + math.sin(a) * rr * 0.9).round();
      put(x, y, col);
      put(x + 1, y, col);
      put(x - 1, y, col);
      put(x, y + 1, col);
      put(x, y - 1, col);
    }
  }

  /// A just-planted seed with a tiny two-leaf sprout, tinted [tint].
  static void seedling(
      PutPixel put, double cx, double gy, Color tint, double s) {
    final seed = ramp(const Color(0xFF8A5A30));
    final st = ramp(const Color(0xFF6EA832));
    final leaf = ramp(tint);
    for (var y = -1; y <= 1; y++) {
      for (var x = -2; x <= 2; x++) {
        if (x * x + (y * 2) * (y * 2) > 5) continue;
        put(cx.round() + x, gy.round() + y, y < 0 ? seed.hi : seed.lo);
      }
    }
    final topY = (gy - (4 * s).round());
    for (var yy = gy - 1; yy >= topY; yy--) {
      put(cx.round(), yy.round(), yy % 2 != 0 ? st.hi : st.mid);
    }
    canopy(put, [CanopyBlob(cx - 2, topY, 2 * s, k: 0.7)], leaf, 2);
    canopy(put, [CanopyBlob(cx + 2, topY - 1, 2 * s, k: 0.7)], leaf, 3);
    put(cx.round(), (topY - 1).round(), leaf.hi);
  }

  // ── goal tree ─────────────────────────────────────────────────────

  /// The per-stage geometry table (stages 1..7). Blobs with r==0 are absent at
  /// that stage; interpolating toward a non-zero neighbour grows them in.
  static Map<int, _GoalSpec> get _goalSpec => {
        1: _GoalSpec(1, 1, 1, const [
          CanopyBlob(-3, -7, 0),
          CanopyBlob(3, -8, 0),
          CanopyBlob(0, -12, 0),
          CanopyBlob(-2, -24, 0),
          CanopyBlob(4, -23, 0),
        ]),
        2: _GoalSpec(6, 1, 2, const [
          CanopyBlob(-3, -7, 2.4, k: 0.8),
          CanopyBlob(3, -8, 2.4, k: 0.8),
          CanopyBlob(0, -12, 0),
          CanopyBlob(-2, -24, 0),
          CanopyBlob(4, -23, 0),
        ]),
        3: _GoalSpec(11, 1, 3, const [
          CanopyBlob(0, -14, 4.2),
          CanopyBlob(-4, -13, 0),
          CanopyBlob(4, -14, 0),
          CanopyBlob(-2, -24, 0),
          CanopyBlob(4, -23, 0),
        ]),
        4: _GoalSpec(13, 2, 4, const [
          CanopyBlob(0, -17, 5.6),
          CanopyBlob(-4, -14, 3.6),
          CanopyBlob(5, -15, 0),
          CanopyBlob(-1, -25, 0),
          CanopyBlob(4, -24, 0),
        ]),
        5: _GoalSpec(14, 2, 5, const [
          CanopyBlob(0, -19, 6.8),
          CanopyBlob(-5, -15, 4.4),
          CanopyBlob(5, -15, 4.2),
          CanopyBlob(-1, -26, 0),
          CanopyBlob(4, -25, 0),
        ]),
        6: _GoalSpec(15, 3, 6, const [
          CanopyBlob(0, -21, 8, k: 0.94),
          CanopyBlob(-6, -16, 5.4),
          CanopyBlob(6, -16, 5.2),
          CanopyBlob(0, -26, 5),
          CanopyBlob(4, -26, 0),
        ]),
        7: _GoalSpec(16, 3, 7, const [
          CanopyBlob(0, -22, 9.2, k: 0.94),
          CanopyBlob(-7, -17, 6.2),
          CanopyBlob(7, -17, 6),
          CanopyBlob(-2, -28, 5.6),
          CanopyBlob(4, -27, 4.8),
        ]),
      };

  /// Draw a goal tree at continuous growth [g] (1..7) with canopy colour [tint].
  /// Integer values are the canonical stage sprites; fractional values morph
  /// between them. [s] scales the whole tree.
  static void goalTree(
      PutPixel put, double cx, double gy, Color tint, double g, double s) {
    final bark = ramp(barkBase);
    final leaf = ramp(tint);
    double sc(double v) => v * s;

    final table = _goalSpec;
    final lo = g.floor().clamp(1, 6);
    final hi = lo + 1;
    final f = (g - lo).clamp(0.0, 1.0);
    final L = table[lo]!;
    final H = table[hi]!;
    double lp(double a, double b) => a + (b - a) * f;

    if (g < 3.2) seedling(put, cx, gy, tint, s * (0.7 + 0.1 * g));

    final top = lp(L.top, H.top);
    final w0 = lp(L.w0, H.w0);
    final w1 = lp(L.w1, H.w1);
    if (top > 2.5) {
      trunk(put, cx, gy - sc(top).round().toDouble(), gy - 1,
          math.max(1, sc(w0).round()).toDouble(),
          math.max(1, sc(w1).round()).toDouble(), bark);
    }

    final blobs = <CanopyBlob>[];
    for (var i = 0; i < L.blobs.length; i++) {
      final b = L.blobs[i];
      final c = H.blobs[i];
      final r = sc(lp(b.r, c.r));
      if (r <= 0.35) continue;
      blobs.add(CanopyBlob(
        cx + sc(lp(b.x, c.x)),
        gy + sc(lp(b.y, c.y)),
        r,
        k: lp(b.k, c.k),
      ));
    }
    if (blobs.isNotEmpty) canopy(put, blobs, leaf, 7);
    if (g > 6.6) sparkles(put, cx, gy - sc(22), sc(13), 7, sparkleGold, 11);
  }
}

class _GoalSpec {
  final double top;
  final double w0;
  final double w1;
  final List<CanopyBlob> blobs;
  const _GoalSpec(this.top, this.w0, this.w1, this.blobs);
}
