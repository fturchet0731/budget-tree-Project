import 'package:flutter/material.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../pixel/pixel.dart';

/// The primary CTA: green pixel box, Silkscreen caps, hard depress on press.
///
/// The API is unchanged from the rounded version so existing call sites
/// inherit the pixel chrome for free. Material [icon]s still render (the
/// authored 16x16 sprites are used directly via [PixelButton] where the design
/// calls for them).
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) => _PixelLabelButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
        tone: PixelTone.accent,
        fontSize: 11,
      );
}

/// Quiet companion to the primary button: parchment fill, ink label.
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) => _PixelLabelButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
        tone: PixelTone.neutral,
        fontSize: 10,
      );
}

/// Shared body for the two filled buttons — a [PixelBox] that carries an
/// optional Material icon plus a Silkscreen label.
class _PixelLabelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final PixelTone tone;
  final double fontSize;

  const _PixelLabelButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.expand,
    required this.tone,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final enabled = onPressed != null;
    final ink = enabled ? tone.ink(t) : t.textTertiary;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: PixelBox(
        onTap: onPressed,
        semanticLabel: label,
        fill: enabled ? tone.fill(t) : t.canvasSoft,
        border: tone.border(t),
        shadow: tone.shadow(t),
        drop: AppDims.dropButton,
        height: 48,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: ink),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTheme.label(fontSize, ink, spacing: 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bare text button for tertiary actions — underlined Silkscreen, no box.
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final fg = onPressed != null ? t.accentStrong : t.textTertiary;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: AppTheme.label(10, fg, spacing: 1.0)),
            ],
          ),
        ),
      ),
    );
  }
}
