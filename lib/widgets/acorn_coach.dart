import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../tutorial/tutorial_content.dart';
import '../tutorial/tutorial_overlay.dart' show TapContinueHint;
import 'acorn_mascot.dart';

/// An in-screen Acorn coach that lives *on* a real screen and explains the
/// step the user is currently on, while leaving them free to actually do it.
///
/// It's compact, collapsible, and **draggable** — the user can grab Acorn and
/// move his tip anywhere on the screen so it never sits over the field they're
/// filling in. Read the tip, tap "Got it" to shrink him into a corner pill, do
/// the task, then tap him again to re-read. Dragging the tip off the left or
/// right edge tucks Acorn away entirely, leaving a little edge handle; tap or
/// swipe that handle inward to bring him back. When the host changes [lessonKey]
/// (e.g. the user advances to the next form step), the coach automatically
/// re-opens with the new [lines].
///
/// Host it in a [Positioned.fill] (or any box that fills the area you want it
/// to roam): the coach itself fills that box and only the floating panel is
/// hit-testable, so taps elsewhere fall through to the screen beneath.
class AcornCoach extends StatefulWidget {
  /// Identifies the current lesson. When it changes, the coach re-opens at
  /// the first line with the new [lines].
  final Object lessonKey;
  final List<TutorialStep> lines;

  /// Where the panel first appears before the user drags it.
  final Alignment initialAlignment;

  /// The widgets Acorn can point at, keyed by [TutorialStep.highlightId].
  /// While a line with a highlight id is on screen, the coach draws a pulsing
  /// ring around the matching widget so the user knows what he's talking
  /// about. Ids without a live widget (e.g. scrolled away) are just skipped.
  final Map<String, GlobalKey>? targets;

  const AcornCoach({
    super.key,
    required this.lessonKey,
    required this.lines,
    this.initialAlignment = const Alignment(-0.85, 0.62),
    this.targets,
  });

  @override
  State<AcornCoach> createState() => _AcornCoachState();
}

class _AcornCoachState extends State<AcornCoach>
    with SingleTickerProviderStateMixin {
  final GlobalKey _panelKey = GlobalKey();
  late final AnimationController _type;
  late Animation<int> _chars;
  bool _expanded = true;
  int _index = 0;

  /// When true, Acorn has been swiped off-screen and only a small edge handle
  /// remains; [_hiddenOnRight] records which edge he tucked behind.
  bool _hidden = false;
  bool _hiddenOnRight = false;

  /// Top-left of the floating panel within the host box. Null until the first
  /// layout, when we seed it from [initialAlignment].
  Offset? _pos;

  TutorialStep get _line => widget.lines[_index];
  bool get _typing => _type.isAnimating;
  bool get _isLast => _index == widget.lines.length - 1;

  @override
  void initState() {
    super.initState();
    _type = AnimationController(vsync: this);
    _startLine();
  }

  @override
  void didUpdateWidget(AcornCoach old) {
    super.didUpdateWidget(old);
    if (old.lessonKey != widget.lessonKey) {
      // New step — re-open and start fresh (keep wherever it was dragged to).
      _index = 0;
      _expanded = true;
      // If Acorn was swiped away, bring him back so the new tip is seen. His
      // stored position is off-screen, so re-seed it to the default corner.
      if (_hidden) {
        _hidden = false;
        _pos = null;
      }
      _startLine();
    }
  }

  void _startLine() {
    final text = _line.text;
    final ms = AppSettings.instance.motionFull ? text.length * 26 : 0;
    _type.duration = Duration(milliseconds: ms);
    _chars = IntTween(begin: 0, end: text.length).animate(_type);
    _type
      ..reset()
      ..forward();
    if (mounted) setState(() {});
  }

  void _onTap() {
    if (!_expanded) {
      setState(() => _expanded = true);
      return;
    }
    if (_typing) {
      _type.value = 1.0; // reveal the rest now
      setState(() {});
      return;
    }
    if (_isLast) {
      setState(() => _expanded = false); // collapse to the corner pill
      return;
    }
    setState(() => _index++);
    _startLine();
  }

  Offset _seedPos(Size area, Size panel) {
    final ax = (widget.initialAlignment.x + 1) / 2;
    final ay = (widget.initialAlignment.y + 1) / 2;
    return Offset(
      (area.width - panel.width).clamp(0, double.infinity) * ax,
      (area.height - panel.height).clamp(0, double.infinity) * ay,
    );
  }

  void _onDrag(DragUpdateDetails d, Size area) {
    final panel = _panelKey.currentContext?.size ?? const Size(300, 150);
    final next = (_pos ?? Offset.zero) + d.delta;
    const m = 4.0;
    // Allow the panel to be pushed well past the left/right edges so the user
    // can swipe Acorn off-screen; only a sliver needs to stay grabbable. The
    // vertical axis stays inside the host box.
    final minX = -panel.width + 40;
    final maxX = area.width - 40;
    final maxY = (area.height - panel.height - m).clamp(m, double.infinity);
    setState(() {
      _pos = Offset(next.dx.clamp(minX, maxX), next.dy.clamp(m, maxY));
    });
  }

  /// On release, decide whether Acorn was flung far enough past an edge to be
  /// tucked away into a handle, or should snap back fully on-screen.
  void _onDragEnd(Size area) {
    final panel = _panelKey.currentContext?.size ?? const Size(300, 150);
    final pos = _pos ?? Offset.zero;
    final offLeft = -pos.dx; // how far the left edge is past the screen edge
    final offRight = (pos.dx + panel.width) - area.width;
    final threshold = panel.width * 0.4;
    if (offLeft > threshold) {
      setState(() {
        _hidden = true;
        _hiddenOnRight = false;
      });
    } else if (offRight > threshold) {
      setState(() {
        _hidden = true;
        _hiddenOnRight = true;
      });
    } else {
      // Snap back so no part is left hanging off an edge.
      const m = 4.0;
      final maxX = (area.width - panel.width - m).clamp(m, double.infinity);
      setState(() {
        _pos = Offset(pos.dx.clamp(m, maxX), pos.dy);
      });
    }
  }

  /// Bring Acorn back from his hidden edge, parked just inside that edge at the
  /// height the handle was resting at.
  void _restoreFromHidden(Size area) {
    final panel = _panelKey.currentContext?.size ?? const Size(300, 150);
    const m = 8.0;
    final maxX = (area.width - panel.width - m).clamp(m, double.infinity);
    final maxY = (area.height - panel.height - m).clamp(m, double.infinity);
    final y = (_pos?.dy ?? area.height * 0.5).clamp(m, maxY);
    setState(() {
      _hidden = false;
      _pos = Offset(_hiddenOnRight ? maxX : m, y.toDouble());
    });
  }

  @override
  void dispose() {
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final area = Size(c.maxWidth, c.maxHeight);
        final estimate =
            Size(area.width.clamp(0, 340).toDouble() - 24, 150);
        final pos = _pos ??= _seedPos(area, estimate);
        if (_hidden) return _buildHiddenHandle(area);
        final highlightKey = _line.highlightId == null
            ? null
            : widget.targets?[_line.highlightId];
        return Stack(
          children: [
            // Ring around whatever the current line is talking about.
            if (_expanded && highlightKey != null)
              Positioned.fill(
                child: TargetHighlightRing(targetKey: highlightKey),
              ),
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                onPanUpdate: (d) => _onDrag(d, area),
                onPanEnd: (_) => _onDragEnd(area),
                child: KeyedSubtree(
                  key: _panelKey,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topLeft,
                    child:
                        _expanded ? _buildExpanded() : _buildCollapsed(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The little tab that peeks from an edge once Acorn has been swiped away.
  /// Tapping it, or swiping it back inward, restores the coach.
  Widget _buildHiddenHandle(Size area) {
    const handleH = 88.0;
    final maxTop = (area.height - handleH - 8).clamp(8.0, double.infinity);
    final top = (_pos?.dy ?? area.height * 0.5).clamp(8.0, maxTop);
    return Stack(
      children: [
        Positioned(
          top: top.toDouble(),
          left: _hiddenOnRight ? null : 0,
          right: _hiddenOnRight ? 0 : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _restoreFromHidden(area),
            onHorizontalDragUpdate: (d) {
              // A nudge inward (away from the edge) brings Acorn back.
              final inward = _hiddenOnRight ? -d.delta.dx : d.delta.dx;
              if (inward > 6) _restoreFromHidden(area);
            },
            child: Container(
              width: 34,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.current.card,
                borderRadius: _hiddenOnRight
                    ? const BorderRadius.horizontal(left: Radius.circular(16))
                    : const BorderRadius.horizontal(right: Radius.circular(16)),
                border: Border.all(color: AppTokens.current.cardBorder),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AcornMascot(size: 26, sway: true),
                  const SizedBox(height: 4),
                  Icon(
                    _hiddenOnRight ? Icons.chevron_left : Icons.chevron_right,
                    size: 16,
                    color: AppColors.barkBrown,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsed() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: AppTokens.current.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTokens.current.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AcornMascot(size: 34, sway: true),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).coachAcornTip,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.barkBrown,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.unfold_more, size: 16, color: AppColors.barkBrown),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppTokens.current.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTokens.current.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AcornMascot(
            size: 58,
            speaking: _typing,
            sway: !_typing,
            expression: _typing ? null : _line.expression,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Drag affordance — the whole panel is draggable.
                    const Icon(Icons.drag_indicator,
                        size: 15, color: AppColors.barkBrown),
                    const SizedBox(width: 3),
                    Text(
                      _line.speaker,
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: AppColors.barkBrown,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_index + 1}/${widget.lines.length}',
                      style: GoogleFonts.nunito(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.barkBrown.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Minimise so the form underneath is fully usable.
                    GestureDetector(
                      onTap: () => setState(() => _expanded = false),
                      child: const Icon(Icons.remove_circle_outline,
                          size: 18, color: AppColors.barkBrown),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _chars,
                  builder: (context, _) => Text(
                    _line.text.substring(0, _chars.value),
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.current.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: _typing ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TapContinueHint(
                      hint: _isLast
                          ? AppLocalizations.of(context).coachGotIt
                          : AppLocalizations.of(context).tourTapContinue,
                      fontSize: 11.5,
                    ),
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

/// A pulsing ring drawn around the widget a [TutorialStep.highlightId] points
/// at, so the user can see exactly what Acorn is talking about. Hosted inside
/// the coach's stack (which fills the screen area); it ignores pointers so
/// the highlighted widget stays fully usable.
class TargetHighlightRing extends StatefulWidget {
  final GlobalKey targetKey;
  const TargetHighlightRing({super.key, required this.targetKey});

  @override
  State<TargetHighlightRing> createState() => _TargetHighlightRingState();
}

class _TargetHighlightRingState extends State<TargetHighlightRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // The controller both pulses the ring and keeps its position tracking the
    // target (which can move as the list scrolls). With reduced motion the
    // ring is drawn static; the ticker only re-syncs position.
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// The target's rect translated into this widget's coordinate space, or
  /// null when the target isn't laid out right now (e.g. scrolled away).
  Rect? _targetRect() {
    final targetBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    final myBox = context.findRenderObject() as RenderBox?;
    if (targetBox == null || myBox == null) return null;
    if (!targetBox.attached || !myBox.attached || !targetBox.hasSize) {
      return null;
    }
    final topLeft = myBox.globalToLocal(targetBox.localToGlobal(Offset.zero));
    return topLeft & targetBox.size;
  }

  @override
  Widget build(BuildContext context) {
    // The ring repaints a blurred shadow every frame while it pulses, over a
    // screen that is otherwise still — keep those repaints on their own layer.
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final rect = _targetRect();
            if (rect == null) return const SizedBox.shrink();
            final motion = AppSettings.instance.motionFull;
            final v = motion ? _pulse.value : 0.5;
            final ring = rect.inflate(4 + 4 * v);
            final t = AppTokens.current;
            return Stack(
              children: [
                Positioned.fromRect(
                  rect: ring,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: t.accentStrong.withValues(
                          alpha: 0.55 + 0.45 * v,
                        ),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: t.accent.withValues(alpha: 0.25 + 0.2 * v),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
