import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_settings.dart';
import '../theme/app_tokens.dart';

/// Shows a full-screen celebration: a burst of falling confetti behind a
/// card announcing the milestone. Honors reduced-motion (confetti is skipped,
/// the card still appears). Use for goal completion, tier milestones, and
/// achievement unlocks so they all feel consistent.
Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.emoji_events,
  Color color = const Color(0xFFFFD54F),
  String buttonLabel = 'Celebrate',
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'celebration',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, _, _) => _CelebrationView(
      title: title,
      message: message,
      icon: icon,
      color: color,
      buttonLabel: buttonLabel,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = Curves.easeOutBack.transform(anim.value.clamp(0.0, 1.0));
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(scale: 0.85 + 0.15 * curved, child: child),
      );
    },
  );
}

class _CelebrationView extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String buttonLabel;
  const _CelebrationView({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.buttonLabel,
  });

  @override
  State<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<_CelebrationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Confetto> _confetti;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _confetti = List.generate(70, (_) => _Confetto.random(rnd, widget.color));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (AppSettings.instance.motionFull) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (AppSettings.instance.motionFull)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) => CustomPaint(
                    painter: _ConfettiPainter(_confetti, _ctrl.value),
                  ),
                ),
              ),
            ),
          ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
            decoration: BoxDecoration(
              color: AppTokens.current.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.color.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.18),
                    border:
                        Border.all(color: widget.color.withValues(alpha: 0.6)),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 40),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.current.textPrimary,
                    fontSize: 23,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: AppTokens.current.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.current.accent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      widget.buttonLabel,
                      style: GoogleFonts.nunito(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Confetto {
  final double x; // 0..1 horizontal start
  final double delay; // 0..1 fraction of timeline
  final double speed;
  final double drift;
  final double size;
  final double rotSpeed;
  final Color color;

  _Confetto({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.rotSpeed,
    required this.color,
  });

  factory _Confetto.random(math.Random r, Color base) {
    final palette = [
      base,
      Conifer.c300,
      Conifer.c400,
      Conifer.c600,
      const Color(0xFFFFD54F),
      const Color(0xFFFFA463),
    ];
    return _Confetto(
      x: r.nextDouble(),
      delay: r.nextDouble() * 0.4,
      speed: 0.7 + r.nextDouble() * 0.6,
      drift: (r.nextDouble() - 0.5) * 0.3,
      size: 5 + r.nextDouble() * 7,
      rotSpeed: (r.nextDouble() - 0.5) * 12,
      color: palette[r.nextInt(palette.length)],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> confetti;
  final double t;
  _ConfettiPainter(this.confetti, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final c in confetti) {
      final local = ((t - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = (local * c.speed) * (size.height + 40) - 20;
      final x = (c.x + c.drift * local) * size.width;
      final fade = local > 0.85 ? (1 - (local - 0.85) / 0.15) : 1.0;
      paint.color = c.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rotSpeed * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: c.size, height: c.size * 0.6),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
