import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/app_settings.dart';

/// Fade + slide-up entrance played once on first build — the app-wide
/// arrival micro-animation. With reduced motion the child appears instantly.
class Entrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slide;

  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.slide = 16,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _anim;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    final m = AppSettings.instance.motionMultiplier;
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration * m,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (m == 0) {
      _ctrl.value = 1;
    } else if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, widget.slide * (1 - _anim.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// A column whose children enter one after another with a short stagger.
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration interval;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.interval = const Duration(milliseconds: 60),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          Entrance(delay: interval * i, child: children[i]),
      ],
    );
  }
}
