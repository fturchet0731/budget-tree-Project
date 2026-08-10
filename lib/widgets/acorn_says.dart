import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Acorn saying something, outside the tutorial.
///
/// The tour's own bubble is private to `tutorial_overlay.dart` and carries tour
/// machinery (typewriter, step counter, skip buttons) that a reflection slide
/// has no use for. This is the same visual language with none of that, so the
/// hub and the story slides read as the same character speaking.
class AcornSays extends StatelessWidget {
  final String text;

  /// Optional heading above the line, e.g. the slide's topic.
  final String? title;

  /// Point the tail down at a mascot below, rather than up at one above.
  final bool tailDown;

  const AcornSays({
    super.key,
    required this.text,
    this.title,
    this.tailDown = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return CustomPaint(
      painter: _TailPainter(down: tailDown, tokens: t),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
        margin: EdgeInsets.only(
          top: tailDown ? 0 : 14,
          bottom: tailDown ? 14 : 0,
        ),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: t.cardBorder),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.eco, size: 14, color: AppColors.forestGreen),
                const SizedBox(width: 6),
                Text(
                  'Acorn',
                  style: GoogleFonts.pixelifySans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: t.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            if (title != null) ...[
              const SizedBox(height: 8),
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.nunito(
                color: t.textPrimary,
                fontSize: 15.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final bool down;
  final AppTokens tokens;
  const _TailPainter({required this.down, required this.tokens});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * 0.16;
    final edge = down ? size.height - 14 : 14.0;
    final tip = down ? edge + 16 : edge - 16;

    Path tri(double halfWidth, double from, double to, double skew) => Path()
      ..moveTo(x - halfWidth, from)
      ..lineTo(x + halfWidth, from)
      ..lineTo(x + skew, to)
      ..close();

    canvas.drawPath(
      tri(14, edge, tip, -4),
      Paint()..color = tokens.cardBorder,
    );
    canvas.drawPath(
      tri(9, down ? edge - 1 : edge + 1, down ? tip - 5 : tip + 5, -3),
      Paint()..color = tokens.card,
    );
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) =>
      old.down != down || old.tokens != tokens;
}
