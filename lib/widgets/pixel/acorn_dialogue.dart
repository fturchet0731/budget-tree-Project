import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/app_settings.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'pixel_box.dart';
import 'pixel_button.dart';
import 'pixel_sprite.dart';

/// Reveals [text] one character at a time, RPG-style.
///
/// Respects reduced motion by showing the whole line immediately, and restarts
/// whenever the text changes so a new quest line types itself out.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration perChar;

  /// Draws a blinking underscore while typing.
  final bool cursor;

  const TypewriterText(
    this.text, {
    super.key,
    this.style,
    this.perChar = const Duration(milliseconds: 26),
    this.cursor = true,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(TypewriterText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _timer?.cancel();
    if (!AppSettings.instance.motionFull) {
      setState(() => _shown = widget.text.length);
      return;
    }
    setState(() => _shown = 0);
    _timer = Timer.periodic(widget.perChar, (t) {
      if (!mounted) return t.cancel();
      if (_shown >= widget.text.length) return t.cancel();
      setState(() => _shown++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typing = _shown < widget.text.length;
    return Text.rich(
      TextSpan(
        text: widget.text.substring(0, _shown),
        children: [
          if (widget.cursor && typing)
            TextSpan(text: '_', style: widget.style),
        ],
      ),
      style: widget.style,
    );
  }
}

/// Acorn's animated 2-frame idle portrait in a sunken frame.
class AcornPortrait extends StatelessWidget {
  final double size;

  /// Use the bigger drawn head instead of the 2-frame idle sheet.
  final bool head;

  const AcornPortrait({super.key, this.size = 42, this.head = false});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.panelDarkInset,
        border: Border.all(color: Pixel.nightBorder, width: 2),
      ),
      alignment: Alignment.center,
      child: head
          ? PixelSprite(asset: PixelIcons.acornHead, size: size - 8)
          : PixelSpriteSheet(
              asset: PixelIcons.acorn,
              size: size - 8,
              frames: 2,
              period: const Duration(milliseconds: 3400),
            ),
    );
  }
}

/// The dark NPC panel: Acorn's portrait, a Silkscreen speaker label, a
/// typewritten line, and an optional gold action.
///
/// Used for the dashboard quest card, wizard hints, and the hub's reflection
/// card — anywhere Acorn speaks in-world rather than through the tutorial
/// overlay.
class AcornDialogue extends StatelessWidget {
  /// Small caps label above the line, e.g. "ACORN · NEW QUEST".
  final String speaker;
  final String text;

  /// Optional gold call to action.
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  /// Shows a small dismiss cross in the panel's top-right. Acorn's nudges are
  /// suggestions, not obligations, so the player must be able to wave one away.
  final VoidCallback? onDismiss;

  /// Tooltip / semantic label for the dismiss control.
  final String? dismissLabel;

  const AcornDialogue({
    super.key,
    required this.speaker,
    required this.text,
    this.actionLabel,
    this.onAction,
    this.onTap,
    this.margin,
    this.onDismiss,
    this.dismissLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return PixelBox(
      onTap: onTap,
      margin: margin,
      fill: t.panelDark,
      border: t.panelDarkBorder,
      drop: AppDims.dropButton,
      padding: const EdgeInsets.all(9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AcornPortrait(),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        speaker,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.label(9, Conifer.c300, spacing: 1.0),
                      ),
                    ),
                    if (onDismiss != null)
                      Semantics(
                        button: true,
                        label: dismissLabel,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onDismiss,
                          child: Padding(
                            // Padding rather than a bigger glyph: keeps the
                            // 44px tap target without a heavy X in the corner.
                            padding: const EdgeInsets.only(
                                left: 12, bottom: 12, right: 2),
                            child: Icon(Icons.close,
                                size: 15, color: t.panelDarkText),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 36),
                  child: TypewriterText(
                    text,
                    style: AppTheme.display(14, t.panelDarkText,
                        weight: FontWeight.w400),
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PixelButton(
                      label: actionLabel!,
                      onPressed: onAction,
                      tone: PixelTone.gold,
                      expand: false,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
