import 'package:flutter/material.dart';

import '../../services/app_settings.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_tokens.dart';

/// The one recipe that makes the app read as a 16-bit game: a hard-edged box
/// with a thick outline, **no border radius**, and a solid offset drop shadow
/// (no blur). Pressing it collapses the shadow and translates the box down by
/// the same distance — the "button depress".
///
/// Everything in the pixel skin is built from this: cards, buttons, panels,
/// icon boxes, inset wells. Use it instead of `Container` + `BoxDecoration`
/// so the chrome stays consistent.
///
/// The shadow is a `BoxShadow`, so it costs no layout space; a pressed box
/// travels into the gap the shadow occupied, exactly as the CSS prototype does.
class PixelBox extends StatefulWidget {
  final Widget? child;

  /// Surface fill. Defaults to the token card colour.
  final Color? fill;

  /// Outline colour. Defaults to the token card border (the ink outline).
  final Color? border;

  /// Outline width — 3 for cards/buttons, 2 for nested boxes.
  final double borderWidth;

  /// Drop-shadow colour. Defaults to the token box shadow.
  final Color? shadow;

  /// How far the shadow is offset, and how far the box travels when pressed.
  /// Pass 0 for a flat box (inset wells, list rows).
  final double drop;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  /// When set the box becomes tappable and gains the press animation.
  final VoidCallback? onTap;

  /// Optional semantic label for the tappable box.
  final String? semanticLabel;

  const PixelBox({
    super.key,
    this.child,
    this.fill,
    this.border,
    this.borderWidth = AppDims.borderThick,
    this.shadow,
    this.drop = AppDims.dropCard,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.onTap,
    this.semanticLabel,
  });

  @override
  State<PixelBox> createState() => _PixelBoxState();
}

class _PixelBoxState extends State<PixelBox> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final fill = widget.fill ?? t.card;
    final border = widget.border ?? t.cardBorder;
    final shadow = widget.shadow ?? t.boxShadow;
    final pressed = _down && widget.drop > 0;

    // Reduced motion still gets the state change (so a press is visible), it
    // just snaps rather than easing.
    final duration = AppSettings.instance.motionFull
        ? const Duration(milliseconds: 60)
        : Duration.zero;

    Widget box = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      alignment: widget.alignment,
      transform: Matrix4.translationValues(0, pressed ? widget.drop : 0, 0),
      decoration: BoxDecoration(
        color: fill,
        border: widget.borderWidth <= 0
            ? null
            : Border.all(color: border, width: widget.borderWidth),
        boxShadow: (widget.drop <= 0 || pressed)
            ? null
            : [BoxShadow(color: shadow, offset: Offset(0, widget.drop))],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      box = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: box,
      );
      if (widget.semanticLabel != null) {
        box = Semantics(button: true, label: widget.semanticLabel, child: box);
      }
    }

    if (widget.margin != null) {
      box = Padding(padding: widget.margin!, child: box);
    }
    return box;
  }
}
