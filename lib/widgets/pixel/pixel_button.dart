import 'package:flutter/material.dart';

import '../../theme/app_dims.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'pixel_box.dart';
import 'pixel_sprite.dart';

/// The colour families a pixel control can wear. Each carries its own hard
/// shadow colour, matching the handoff's four button recipes.
enum PixelTone {
  /// Green — primary actions.
  accent,

  /// Gold — streaks, quests, "accept", completed.
  gold,

  /// Blue — goal watering.
  water,

  /// Parchment — secondary / neutral.
  neutral,

  /// Dark panel — Acorn / NPC surfaces.
  dark,
}

extension PixelToneColors on PixelTone {
  Color fill(AppTokens t) => switch (this) {
        PixelTone.accent => t.accent,
        PixelTone.gold => t.gold,
        PixelTone.water => t.water,
        PixelTone.neutral => t.card,
        PixelTone.dark => t.panelDark,
      };

  Color border(AppTokens t) => switch (this) {
        PixelTone.gold => t.goldHi,
        PixelTone.dark => t.panelDarkBorder,
        _ => t.cardBorder,
      };

  Color shadow(AppTokens t) => switch (this) {
        PixelTone.accent => t.accentShadow,
        PixelTone.gold => t.goldShadow,
        PixelTone.water => t.waterShadow,
        PixelTone.neutral => t.boxShadow,
        PixelTone.dark => t.boxShadow,
      };

  Color ink(AppTokens t) => switch (this) {
        PixelTone.accent => t.onAccent,
        PixelTone.gold => t.inkDeep,
        PixelTone.water => t.inkDeep,
        PixelTone.neutral => t.textPrimary,
        PixelTone.dark => t.panelDarkText,
      };
}

/// A chunky pixel button: Silkscreen caps on a hard-edged tone box that
/// depresses when tapped. Always at least [AppDims.tap] tall.
class PixelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PixelTone tone;

  /// Optional 16x16 sprite from `assets/ui/icon_*.png`, drawn before the label.
  final String? icon;

  /// Fill the available width (default) or hug the label.
  final bool expand;

  /// Label size in logical px — Silkscreen's floor is 9.
  final double fontSize;

  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = PixelTone.accent,
    this.icon,
    this.expand = true,
    this.fontSize = 11,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: AppDims.tap,
        alignment: Alignment.center,
        width: expand ? double.infinity : null,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              PixelSprite(asset: icon!, size: 16),
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

/// A square 44x44 icon button — back chevrons, "+" actions, edit pencils.
class PixelIconButton extends StatelessWidget {
  final String icon;
  final VoidCallback? onPressed;
  final PixelTone tone;
  final String? semanticLabel;
  final double size;
  final double iconSize;

  const PixelIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tone = PixelTone.neutral,
    this.semanticLabel,
    this.size = AppDims.tap,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return PixelBox(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      fill: tone.fill(t),
      border: tone.border(t),
      shadow: tone.shadow(t),
      drop: AppDims.dropSmall,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: PixelSprite(asset: icon, size: iconSize),
    );
  }
}
