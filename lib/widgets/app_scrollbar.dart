import 'package:flutter/material.dart';

/// Wraps a scrollable in an always-visible scrollbar so users can see at a
/// glance that a screen has more content below the fold. It owns the
/// [ScrollController] and hands it to [builder], which must pass it to the one
/// scroll view it builds (so the thumb tracks that view).
///
/// Usage:
/// ```dart
/// AppScrollbar(builder: (c) => ListView(controller: c, children: [...]))
/// ```
class AppScrollbar extends StatefulWidget {
  const AppScrollbar({super.key, required this.builder});

  final Widget Function(ScrollController controller) builder;

  @override
  State<AppScrollbar> createState() => _AppScrollbarState();
}

class _AppScrollbarState extends State<AppScrollbar> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      thickness: 5,
      radius: const Radius.circular(8),
      child: widget.builder(_controller),
    );
  }
}
