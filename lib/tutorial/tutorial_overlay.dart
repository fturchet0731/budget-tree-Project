import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/acorn_mascot.dart';
import 'tutorial_content.dart';

/// Plays the acorn's guide for a single [TutorialSection] as a dismissible
/// dialog. Used by the per-section info buttons (replays just that part).
class TutorialPlayer {
  TutorialPlayer._();

  static Future<void> playSection(
      BuildContext context, TutorialSection section) {
    final l = AppLocalizations.of(context);
    return showTutorialDialog(
      context,
      steps: sectionSteps(section, l),
      sectionTitle: section.label(l),
      lastStepHint: l.tourTapFinish,
      skipLabel: l.tourSkip,
    );
  }
}

/// Shows the acorn overlay as a modal dialog over the current screen.
///
/// Returns `true` if the user pressed **Skip**, `false` if they read it to
/// the end. The guided tour uses the return value to know whether to keep
/// going or bail out.
Future<bool> showTutorialDialog(
  BuildContext context, {
  required List<TutorialStep> steps,
  String? sectionTitle,
  String lastStepHint = 'Tap to continue',
  String skipLabel = 'Skip',
}) async {
  final skipped = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Tutorial',
    barrierColor: Colors.transparent, // the overlay paints its own scrim
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, _) => TutorialOverlay(
      steps: steps,
      sectionTitle: sectionTitle,
      lastStepHint: lastStepHint,
      skipLabel: skipLabel,
      onSkip: () => Navigator.of(ctx).pop(true),
      onComplete: () => Navigator.of(ctx).pop(false),
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  );
  return skipped ?? false;
}

/// The acorn-and-speech-bubble layer. It paints its own dimming scrim so it
/// can sit on top of a real screen (the guided tour) just as happily as
/// inside a transparent dialog (the info buttons). It never navigates on its
/// own — the host decides what [onSkip] / [onComplete] do.
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final String? sectionTitle;
  final String lastStepHint;
  final String skipLabel;

  /// User pressed the skip button.
  final VoidCallback onSkip;

  /// User tapped past the final line.
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onSkip,
    required this.onComplete,
    this.sectionTitle,
    this.lastStepHint = 'Tap to continue',
    this.skipLabel = 'Skip',
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _type; // typewriter reveal
  late Animation<int> _chars;
  late final AnimationController _enter; // acorn + bubble pop-in
  int _index = 0;

  TutorialStep get _step => widget.steps[_index];
  bool get _typing => _type.isAnimating;
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _type = AnimationController(vsync: this);
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..forward();
    _startLine();
  }

  void _startLine() {
    final text = _step.text;
    // ~26ms per character feels like a chatty RPG; instant if motion is off.
    final ms = AppSettings.instance.motionFull ? text.length * 26 : 0;
    _type.duration = Duration(milliseconds: ms);
    _chars = IntTween(begin: 0, end: text.length).animate(_type);
    _type
      ..reset()
      ..forward();
    setState(() {});
  }

  void _advance() {
    if (_typing) {
      // First tap reveals the rest of the line instantly.
      _type.value = 1.0;
      setState(() {});
      return;
    }
    if (_isLast) {
      widget.onComplete();
      return;
    }
    setState(() => _index++);
    _startLine();
  }

  @override
  void dispose() {
    _type.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final acornSize = (media.size.width * 0.28).clamp(96.0, 150.0);

    final speakerLabel = widget.sectionTitle == null
        ? _step.speaker
        : '${_step.speaker} • ${widget.sectionTitle}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Container(
        // Self-painted scrim so the screen behind reads as "dimmed".
        color: Colors.black.withValues(alpha: 0.5),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Skip, top-right ──
              Positioned(
                top: 8,
                right: 12,
                child: _SkipButton(label: widget.skipLabel, onTap: widget.onSkip),
              ),

              // ── Acorn + speech bubble, anchored to the bottom ──
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _chars,
                      builder: (context, _) {
                        final full = _step.text;
                        final shown = full.substring(0, _chars.value);
                        return _SpeechBubble(
                          speaker: speakerLabel,
                          text: shown,
                          showContinue: !_typing,
                          hint: _isLast ? widget.lastStepHint : 'Tap to continue',
                          progress: '${_index + 1} / ${widget.steps.length}',
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Acorn peeks up from the bottom-left as the guide.
                    ScaleTransition(
                      scale: CurvedAnimation(
                          parent: _enter, curve: Curves.easeOutBack),
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: AcornMascot(
                          size: acornSize,
                          speaking: _typing,
                          sway: !_typing,
                          expression: _typing ? null : _step.expression,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// RPG-style speech bubble with a little tail
// ──────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String speaker;
  final String text;
  final bool showContinue;
  final String hint;
  final String progress;

  const _SpeechBubble({
    required this.speaker,
    required this.text,
    required this.showContinue,
    required this.hint,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTokens.current.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTokens.current.cardBorder),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker name plate.
            Row(
              children: [
                Icon(Icons.eco, size: 15, color: AppColors.forestGreen),
                const SizedBox(width: 6),
                Text(
                  speaker,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.barkBrown,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  progress,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.barkBrown.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Constrain so long lines don't crowd the tail/continue row.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Text(
                text,
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.current.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: showContinue ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hint,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const _BlinkingChevron(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small downward triangle tail beneath the bubble, pointing at the acorn.
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tailTop = size.height - 12;
    final x = size.width * 0.16;
    final path = Path()
      ..moveTo(x - 14, tailTop)
      ..lineTo(x + 14, tailTop)
      ..lineTo(x - 4, tailTop + 16)
      ..close();
    canvas.drawPath(path, Paint()..color = AppTokens.current.cardBorder);
    final inner = Path()
      ..moveTo(x - 9, tailTop - 1)
      ..lineTo(x + 9, tailTop - 1)
      ..lineTo(x - 3, tailTop + 11)
      ..close();
    canvas.drawPath(inner, Paint()..color = AppTokens.current.card);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => false;
}

class _BlinkingChevron extends StatefulWidget {
  const _BlinkingChevron();
  @override
  State<_BlinkingChevron> createState() => _BlinkingChevronState();
}

class _BlinkingChevronState extends State<_BlinkingChevron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    if (AppSettings.instance.motionFull) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
      child: Icon(Icons.play_arrow_rounded,
          size: 18, color: AppColors.forestGreen),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SkipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.close, color: Colors.white, size: 15),
          ],
        ),
      ),
    );
  }
}
