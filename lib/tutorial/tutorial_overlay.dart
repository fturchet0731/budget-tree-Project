import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../theme/app_dims.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/pixel/pixel.dart';
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
      cancelLabel: l.tourClose,
    );
  }
}

/// How a tutorial dialog ended.
///
/// The two exits are deliberately distinct: **cancelling** ends the whole tour,
/// while **skipping a section** only drops the current one and carries on. They
/// get their own buttons so the user never has to guess which one they're
/// pressing (the single overloaded "Skip" used to mean either, depending on
/// where in the tour it appeared).
enum TutorialOutcome {
  /// Read to the end.
  completed,

  /// "Skip this section" — move on to the next part of the tour.
  skippedSection,

  /// "Cancel tour" — stop the walkthrough entirely.
  cancelledTour,
}

/// Shows the acorn overlay as a modal dialog over the current screen.
///
/// Set [allowSkipSection] for tour dialogs, which get the blue "skip this
/// section" control beside the speech bubble. One-off explainers (the info
/// buttons) leave it off: there's no section to skip, only the popup to close.
Future<TutorialOutcome> showTutorialDialog(
  BuildContext context, {
  required List<TutorialStep> steps,
  String? sectionTitle,
  String lastStepHint = 'Tap to continue',
  String cancelLabel = 'Cancel tour',
  String skipSectionLabel = 'Skip this section',
  bool allowSkipSection = false,
  bool redCancel = false,
}) async {
  final outcome = await showGeneralDialog<TutorialOutcome>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Tutorial',
    barrierColor: Colors.transparent, // the overlay paints its own scrim
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, _) => TutorialOverlay(
      steps: steps,
      sectionTitle: sectionTitle,
      lastStepHint: lastStepHint,
      cancelLabel: cancelLabel,
      skipSectionLabel: skipSectionLabel,
      allowSkipSection: allowSkipSection,
      redCancel: redCancel,
      onCancelTour: () =>
          Navigator.of(ctx).pop(TutorialOutcome.cancelledTour),
      onSkipSection: () =>
          Navigator.of(ctx).pop(TutorialOutcome.skippedSection),
      onComplete: () => Navigator.of(ctx).pop(TutorialOutcome.completed),
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  );
  return outcome ?? TutorialOutcome.completed;
}

/// The acorn-and-speech-bubble layer. It paints its own dimming scrim so it
/// can sit on top of a real screen (the guided tour) just as happily as
/// inside a transparent dialog (the info buttons). It never navigates on its
/// own — the host decides what [onSkip] / [onComplete] do.
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final String? sectionTitle;
  final String lastStepHint;
  final String cancelLabel;
  final String skipSectionLabel;

  /// Whether to offer the blue "skip this section" control by the bubble.
  final bool allowSkipSection;

  /// Red styling for the top-right exit. On for the guided tour, where it
  /// abandons the whole walkthrough; off for one-off explainers, where the
  /// button is just a neutral close.
  final bool redCancel;

  /// User pressed the red cancel button: end the whole tour.
  final VoidCallback onCancelTour;

  /// User pressed "skip this section": drop this part, keep the tour going.
  final VoidCallback onSkipSection;

  /// User tapped past the final line.
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onCancelTour,
    required this.onSkipSection,
    required this.onComplete,
    this.sectionTitle,
    this.lastStepHint = 'Tap to continue',
    this.cancelLabel = 'Cancel tour',
    this.skipSectionLabel = 'Skip this section',
    this.allowSkipSection = false,
    this.redCancel = false,
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

    final speakerLabel = widget.sectionTitle == null
        ? _step.speaker
        : '${_step.speaker} • ${widget.sectionTitle}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: Container(
        // Self-painted scrim so the screen behind reads as "dimmed".
        color: Colors.black.withValues(alpha: 0.5),
        // A transparent Material provides a real DefaultTextStyle for the
        // overlay. Without it, Text mounted in the Overlay merges onto
        // Flutter's error-fallback style and every line gets the yellow
        // double underline.
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
          child: Stack(
            children: [
              // ── Cancel the whole tour, top-right. Red so it reads as the
              // hard exit and is impossible to miss. ──
              Positioned(
                top: 8,
                right: 12,
                child: _TourButton(
                  label: widget.cancelLabel,
                  icon: Icons.close,
                  color: widget.redCancel
                      ? AppTokens.current.danger
                      : Colors.black.withValues(alpha: 0.55),
                  onTap: widget.onCancelTour,
                ),
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
                          hint: _isLast
                              ? widget.lastStepHint
                              : AppLocalizations.of(context).tourTapContinue,
                          progress: '${_index + 1} / ${widget.steps.length}',
                        );
                      },
                    ),
                    // ── Skip just this section, right under the bubble where
                    // the user is already reading. Blue so it reads as "move
                    // along", not "quit". ──
                    if (widget.allowSkipSection) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _TourButton(
                          label: widget.skipSectionLabel,
                          icon: Icons.skip_next,
                          color: AppColors.riverBlue,
                          onTap: widget.onSkipSection,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
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
    final t = AppTokens.of(context);
    // Acorn's dialogue is a dark NPC panel, the same one the dashboard quest
    // card and the hub's reflection use — the tutorial should look like the
    // character talking to you, not like a help tooltip pasted over the game.
    return PixelBox(
      fill: t.panelDark,
      border: t.panelDarkBorder,
      drop: AppDims.dropButton,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcornPortrait(size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        speaker.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.label(9, Conifer.c300, spacing: 1.0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      progress,
                      style: AppTheme.label(9, t.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Text(
                    text,
                    style: AppTheme.display(
                      15,
                      t.panelDarkText,
                      weight: FontWeight.w400,
                    ).copyWith(height: 1.35),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: showContinue ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: TapContinueHint(hint: hint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "tap to continue" affordance: hint text + blinking chevron. Shared by
/// every Acorn dialogue surface (the full-screen overlay and the in-screen
/// [AcornCoach] tips) so advancing always looks the same.
class TapContinueHint extends StatelessWidget {
  final String hint;
  final double fontSize;
  const TapContinueHint({super.key, required this.hint, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hint,
          style: GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(width: 4),
        _BlinkingChevron(size: fontSize + 6),
      ],
    );
  }
}

class _BlinkingChevron extends StatefulWidget {
  final double size;
  const _BlinkingChevron({this.size = 18});
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
          size: widget.size, color: AppColors.forestGreen),
    );
  }
}

/// A solid, high-contrast pill for the overlay's two exits. Filled rather than
/// translucent so both read clearly against whatever screen is dimmed behind
/// them, and colour-coded: red cancels the tour, blue skips a section.
class _TourButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TourButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // The overlay advances on tap anywhere, so swallow this one.
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
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
            const SizedBox(width: 5),
            Icon(icon, color: Colors.white, size: 15),
          ],
        ),
      ),
    );
  }
}
