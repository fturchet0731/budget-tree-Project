import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/app_settings.dart';

/// The faces our little guide can pull. The mouth/eye shape changes per
/// expression, which is what makes the acorn look like it's "speaking" as
/// the tutorial text types out (we flip between [talkOpen] / [talkWide]).
enum AcornExpression { idle, blink, happy, talkOpen, talkWide }

/// Acorn — the app's kawaii mascot, drawn entirely with a [CustomPainter]
/// (same approach as every other illustration in the app, so it sits
/// happily inside the forest theme and inherits no image assets).
///
/// * Pass [speaking] = true while dialogue is typing and the mouth animates
///   between two open shapes — its different "sprites" as it talks.
/// * When idle it sways gently and blinks now and then. The sway/blink are
///   gated behind the app's Motion setting so reduced-motion stays calm.
class AcornMascot extends StatefulWidget {
  final double size;

  /// Animate the mouth between talking sprites (use while text is typing).
  final bool speaking;

  /// Gentle idle bob + sway. Turn off where the acorn should sit perfectly
  /// still. Always also gated behind [AppSettings.motionFull].
  final bool sway;

  /// Force a particular face (overrides the automatic idle/blink/talk logic).
  final AcornExpression? expression;

  const AcornMascot({
    super.key,
    this.size = 120,
    this.speaking = false,
    this.sway = true,
    this.expression,
  });

  @override
  State<AcornMascot> createState() => _AcornMascotState();
}

class _AcornMascotState extends State<AcornMascot>
    with TickerProviderStateMixin {
  // Slow clock — drives the idle sway/bob and the once-per-cycle blink.
  late final AnimationController _idle;
  // Fast clock — flips the mouth between its two talking sprites.
  late final AnimationController _talk;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _talk = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _syncControllers();
    AppSettings.instance.addListener(_syncControllers);
  }

  @override
  void didUpdateWidget(AcornMascot old) {
    super.didUpdateWidget(old);
    if (old.speaking != widget.speaking || old.sway != widget.sway) {
      _syncControllers();
    }
  }

  /// Keep the two controllers running only when they're actually needed,
  /// respecting the reduced-motion setting for the idle flourishes.
  void _syncControllers() {
    if (!mounted) return;
    final motion = AppSettings.instance.motionFull;

    if (widget.speaking) {
      if (!_talk.isAnimating) _talk.repeat();
    } else {
      _talk.stop();
    }

    if (widget.sway && motion) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_syncControllers);
    _idle.dispose();
    _talk.dispose();
    super.dispose();
  }

  AcornExpression _currentExpression() {
    if (widget.expression != null) return widget.expression!;
    if (widget.speaking) {
      return _talk.value < 0.5
          ? AcornExpression.talkOpen
          : AcornExpression.talkWide;
    }
    // Brief blink near the end of each idle cycle.
    if (widget.sway && AppSettings.instance.motionFull && _idle.value > 0.93) {
      return AcornExpression.blink;
    }
    return AcornExpression.idle;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _talk]),
      builder: (context, _) {
        final swaying = widget.sway && AppSettings.instance.motionFull;
        final phase = _idle.value * math.pi * 2;
        final angle = swaying ? math.sin(phase) * 0.06 : 0.0;
        final bob = swaying ? math.sin(phase) * widget.size * 0.025 : 0.0;
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: angle,
            child: CustomPaint(
              // A touch wider than tall for a chunkier, friendlier acorn.
              size: Size(widget.size * 1.12, widget.size * 1.22),
              painter: _AcornPainter(_currentExpression()),
            ),
          ),
        );
      },
    );
  }
}

class _AcornPainter extends CustomPainter {
  final AcornExpression face;
  _AcornPainter(this.face);

  // Palette — warm acorn browns and a soft tan nut.
  static const _capDark = Color(0xFF6B4226);
  static const _capLight = Color(0xFF8A5A33);
  static const _nutDark = Color(0xFFB9803F);
  static const _nutLight = Color(0xFFE2A85C);
  static const _stem = Color(0xFF4E3320);
  static const _cheek = Color(0xFFE8836B);
  static const _eye = Color(0xFF3A2415);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft contact shadow under the acorn.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.97), width: w * 0.62, height: h * 0.07),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // Seam where the cap meets the nut. The nut rises a little above it with
    // broad shoulders, and the cap overlaps down past it — so there's no gap.
    final capBottom = h * 0.42;
    final nutRect = Rect.fromLTRB(w * 0.15, h * 0.33, w * 0.85, h * 0.92);

    // ── NUT BODY — broad rounded shoulders, tapering to a point at bottom ──
    final nut = Path()
      ..moveTo(nutRect.left, nutRect.top + nutRect.height * 0.16)
      ..quadraticBezierTo(nutRect.left, nutRect.top,
          nutRect.left + nutRect.width * 0.30, nutRect.top)
      ..lineTo(nutRect.right - nutRect.width * 0.30, nutRect.top)
      ..quadraticBezierTo(nutRect.right, nutRect.top,
          nutRect.right, nutRect.top + nutRect.height * 0.16)
      ..quadraticBezierTo(nutRect.right, nutRect.bottom - nutRect.height * 0.06,
          nutRect.center.dx, nutRect.bottom)
      ..quadraticBezierTo(nutRect.left, nutRect.bottom - nutRect.height * 0.06,
          nutRect.left, nutRect.top + nutRect.height * 0.16)
      ..close();
    // Flat modern fill: one warm tan, with a single flat highlight crescent
    // instead of a gradient.
    canvas.drawPath(nut, Paint()..color = _nutLight);
    canvas.save();
    canvas.clipPath(nut);
    canvas.drawOval(
      Rect.fromLTRB(w * 0.42, h * 0.40, w * 0.92, h * 0.95),
      Paint()..color = _nutDark.withValues(alpha: 0.35),
    );
    canvas.restore();

    // ── CAP — wide dome that sits down onto the nut, with a little stem ──
    final capRect = Rect.fromLTRB(w * 0.07, h * 0.05, w * 0.93, capBottom);
    final cap = Path()
      ..moveTo(capRect.left, capRect.bottom - capRect.height * 0.20)
      ..quadraticBezierTo(capRect.left, capRect.top,
          capRect.center.dx, capRect.top)
      ..quadraticBezierTo(capRect.right, capRect.top,
          capRect.right, capRect.bottom - capRect.height * 0.20)
      ..quadraticBezierTo(capRect.center.dx, capRect.bottom + capRect.height * 0.22,
          capRect.left, capRect.bottom - capRect.height * 0.20)
      ..close();
    // Flat cap in the lighter brown with a darker underside band.
    canvas.drawPath(cap, Paint()..color = _capLight);
    canvas.save();
    canvas.clipPath(cap);
    canvas.drawRect(
      Rect.fromLTRB(capRect.left, capRect.bottom - capRect.height * 0.34,
          capRect.right, capRect.bottom + capRect.height * 0.3),
      Paint()..color = _capDark.withValues(alpha: 0.55),
    );
    canvas.restore();

    // Cap cross-hatch texture (the classic acorn waffle pattern), kept quiet
    // so the cap still reads as one flat shape.
    canvas.save();
    canvas.clipPath(cap);
    final hatch = Paint()
      ..color = _capDark.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double x = capRect.left - capRect.height; x < capRect.right; x += w * 0.10) {
      canvas.drawLine(Offset(x, capRect.bottom), Offset(x + capRect.height, capRect.top), hatch);
      canvas.drawLine(Offset(x, capRect.top), Offset(x + capRect.height, capRect.bottom), hatch);
    }
    canvas.restore();

    // Stem nub on top.
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, capRect.top + h * 0.01),
          width: w * 0.10,
          height: h * 0.10),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(stemRect, Paint()..color = _stem);

    // ── FACE — sits on the upper nut ──
    final faceY = nutRect.top + nutRect.height * 0.40;
    final eyeDx = w * 0.15;
    final eyeR = w * 0.075;
    final leftEye = Offset(w * 0.5 - eyeDx, faceY);
    final rightEye = Offset(w * 0.5 + eyeDx, faceY);

    // Rosy cheeks.
    final cheekPaint = Paint()..color = _cheek.withValues(alpha: 0.55);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(leftEye.dx - eyeR * 0.7, faceY + eyeR * 1.5),
            width: eyeR * 1.7,
            height: eyeR * 1.1),
        cheekPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(rightEye.dx + eyeR * 0.7, faceY + eyeR * 1.5),
            width: eyeR * 1.7,
            height: eyeR * 1.1),
        cheekPaint);

    _drawEyes(canvas, leftEye, rightEye, eyeR);
    _drawMouth(canvas, Offset(w * 0.5, faceY + eyeR * 2.6), w);
  }

  void _drawEyes(Canvas canvas, Offset l, Offset r, double eyeR) {
    final eyePaint = Paint()..color = _eye;
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.9);

    if (face == AcornExpression.blink) {
      // Closed, content downward arcs.
      final p = Paint()
        ..color = _eye
        ..strokeWidth = eyeR * 0.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final c in [l, r]) {
        final path = Path()
          ..moveTo(c.dx - eyeR, c.dy)
          ..quadraticBezierTo(c.dx, c.dy + eyeR * 0.8, c.dx + eyeR, c.dy);
        canvas.drawPath(path, p);
      }
      return;
    }

    if (face == AcornExpression.happy) {
      // Upward ^ ^ happy arcs.
      final p = Paint()
        ..color = _eye
        ..strokeWidth = eyeR * 0.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final c in [l, r]) {
        final path = Path()
          ..moveTo(c.dx - eyeR, c.dy + eyeR * 0.4)
          ..quadraticBezierTo(c.dx, c.dy - eyeR * 0.7, c.dx + eyeR, c.dy + eyeR * 0.4);
        canvas.drawPath(path, p);
      }
      return;
    }

    // Open round eyes with a sparkle.
    for (final c in [l, r]) {
      canvas.drawCircle(c, eyeR, eyePaint);
      canvas.drawCircle(
          Offset(c.dx - eyeR * 0.3, c.dy - eyeR * 0.35), eyeR * 0.32, shine);
      canvas.drawCircle(
          Offset(c.dx + eyeR * 0.35, c.dy + eyeR * 0.3), eyeR * 0.15, shine);
    }
  }

  void _drawMouth(Canvas canvas, Offset c, double w) {
    final fill = Paint()..color = const Color(0xFF6E3B2A);
    final line = Paint()
      ..color = _eye
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (face) {
      case AcornExpression.talkOpen:
        canvas.drawOval(
            Rect.fromCenter(center: c, width: w * 0.13, height: w * 0.10), fill);
        break;
      case AcornExpression.talkWide:
        canvas.drawOval(
            Rect.fromCenter(center: c, width: w * 0.17, height: w * 0.17), fill);
        // little tongue
        canvas.drawArc(
            Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.03), width: w * 0.12, height: w * 0.10),
            0, math.pi, true,
            Paint()..color = _cheek.withValues(alpha: 0.8));
        break;
      case AcornExpression.happy:
        // Big open smile.
        final path = Path()
          ..moveTo(c.dx - w * 0.10, c.dy - w * 0.01)
          ..quadraticBezierTo(c.dx, c.dy + w * 0.11, c.dx + w * 0.10, c.dy - w * 0.01)
          ..close();
        canvas.drawPath(path, fill);
        break;
      case AcornExpression.idle:
      case AcornExpression.blink:
        // Gentle closed smile.
        final path = Path()
          ..moveTo(c.dx - w * 0.08, c.dy)
          ..quadraticBezierTo(c.dx, c.dy + w * 0.07, c.dx + w * 0.08, c.dy);
        canvas.drawPath(path, line);
        break;
    }
  }

  @override
  bool shouldRepaint(_AcornPainter old) => old.face != face;
}
