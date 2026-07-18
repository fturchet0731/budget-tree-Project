import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// The app's logo mark: the same flat hero tree that greets users on the
/// launch screen, drawn on the soft green [Conifer.c50] tint, but WITHOUT
/// Acorn. This is the source of truth for the launcher icon (rendered to a
/// PNG by `tool/gen_app_icon.dart`) and can be reused anywhere in-app that
/// wants the brand mark.
///
/// It is deliberately full-bleed (the tint fills the whole square) so it
/// looks right under any launcher's rounding/masking. Keep it static: no
/// animation, no sway, fully grown.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: const AppLogoPainter()),
    );
  }
}

/// Paints the logo square: tinted background, a warm trunk with two branches,
/// a bold flat conifer canopy, a soft ground mound, and a few drifting leaves.
/// Tuned to sit nicely centered in a square (unlike the landscape hero card).
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter();

  static const _trunk = Color(0xFF8A6B4F);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final groundY = h * 0.80;

    // Full-bleed tint so any launcher mask reveals brand colour, not white.
    canvas.drawRect(Offset.zero & size, Paint()..color = Conifer.c50);

    // Ground: a wide flat mound anchoring the tree.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + h * 0.14),
        width: w * 1.02,
        height: h * 0.30,
      ),
      Paint()..color = Conifer.c200,
    );

    // Trunk.
    final trunkH = h * 0.40;
    final trunkW = w * 0.085;
    final trunkTop = groundY - trunkH;
    final trunkPath = Path()
      ..moveTo(cx - trunkW * 0.62, groundY)
      ..quadraticBezierTo(
          cx - trunkW * 0.40, groundY - trunkH * 0.55, cx - trunkW * 0.34, trunkTop)
      ..lineTo(cx + trunkW * 0.34, trunkTop)
      ..quadraticBezierTo(
          cx + trunkW * 0.40, groundY - trunkH * 0.55, cx + trunkW * 0.62, groundY)
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = _trunk);

    // One branch on each side.
    final branch = Paint()
      ..color = _trunk
      ..strokeWidth = trunkW * 0.34
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx, groundY - trunkH * 0.55),
      Offset(cx - w * 0.10, groundY - trunkH * 0.88 - trunkH * 0.1),
      branch,
    );
    canvas.drawLine(
      Offset(cx, groundY - trunkH * 0.42),
      Offset(cx + w * 0.09, groundY - trunkH * 0.72 - trunkH * 0.1),
      branch,
    );

    // Canopy: back-to-front discs make one bold flat crown.
    final cy = trunkTop - h * 0.02;
    final r = w * 0.20;
    void disc(double dx, double dy, double scale, Color color) {
      canvas.drawCircle(
          Offset(cx + dx * w, cy + dy * h), r * scale, Paint()..color = color);
    }

    disc(-0.13, -0.02, 0.92, Conifer.c600);
    disc(0.13, -0.02, 0.92, Conifer.c600);
    disc(-0.07, -0.09, 1.0, Conifer.c500);
    disc(0.08, -0.08, 1.0, Conifer.c500);
    disc(0.0, -0.15, 1.08, Conifer.c400);
    disc(-0.02, -0.05, 0.7, Conifer.c300);

    // A few drifting leaves for character.
    final leafPaint = Paint()..color = Conifer.c400;
    void leaf(double x, double y, double s, double angle) {
      canvas.save();
      canvas.translate(x * w, y * h);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 22 * s, height: 13 * s),
        leafPaint,
      );
      canvas.restore();
    }

    leaf(0.17, 0.30, 1.0, 0.5);
    leaf(0.83, 0.23, 0.8, -0.4);
    leaf(0.78, 0.46, 0.7, 0.9);
    leaf(0.21, 0.52, 0.8, -0.8);
  }

  @override
  bool shouldRepaint(AppLogoPainter old) => false;
}
