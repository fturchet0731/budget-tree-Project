import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import '../tutorial/tutorial_content.dart';
import 'acorn_mascot.dart';

/// An in-screen Acorn coach that lives *on* a real screen and explains the
/// step the user is currently on, while leaving them free to actually do it.
///
/// It's compact, collapsible, and **draggable** — the user can grab Acorn and
/// move his tip anywhere on the screen so it never sits over the field they're
/// filling in. Read the tip, tap "Got it" to shrink him into a corner pill, do
/// the task, then tap him again to re-read. When the host changes [lessonKey]
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

  const AcornCoach({
    super.key,
    required this.lessonKey,
    required this.lines,
    this.initialAlignment = const Alignment(-0.85, 0.62),
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
    // Keep the panel from being dragged off-screen.
    final maxX = (area.width - panel.width - m).clamp(m, double.infinity);
    final maxY = (area.height - panel.height - m).clamp(m, double.infinity);
    setState(() {
      _pos = Offset(next.dx.clamp(m, maxX), next.dy.clamp(m, maxY));
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
        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                onPanUpdate: (d) => _onDrag(d, area),
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

  Widget _buildCollapsed() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.barkBrown, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AcornMascot(size: 34, sway: true),
          const SizedBox(width: 6),
          Text(
            "Acorn's tip",
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDF6E3), Color(0xFFF3E6C8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.barkBrown, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
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
                      'Acorn',
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
                      color: const Color(0xFF3A2A18),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _typing
                        ? ''
                        : _isLast
                            ? 'Got it! ▸'
                            : 'Tap ▸',
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestGreen,
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
