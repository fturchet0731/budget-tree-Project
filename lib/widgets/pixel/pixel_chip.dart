import 'package:flutter/material.dart';

import '../../theme/app_dims.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'pixel_box.dart';

/// A selectable pixel chip — filter rows, cadence pickers, category pickers.
///
/// Selected reads as ink-filled (or accent-filled) with a hard outline;
/// unselected is parchment with a hairline. Always [AppDims.tap] tall so it
/// stays a legal touch target, per the handoff.
class PixelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Use the accent green for the selected fill instead of ink.
  final bool accentWhenSelected;

  const PixelChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.accentWhenSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final fill = selected
        ? (accentWhenSelected ? t.accent : t.textPrimary)
        : t.card;
    final ink = selected
        ? (accentWhenSelected ? t.onAccent : t.canvas)
        : t.textSecondary;
    final border = selected ? t.cardBorder : t.boxShadow;

    return PixelBox(
      onTap: onTap,
      semanticLabel: label,
      fill: fill,
      border: border,
      borderWidth: AppDims.borderThin,
      drop: 0,
      height: AppDims.tap,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.label(9, ink, spacing: 1.0),
      ),
    );
  }
}

/// A small non-interactive badge — cycle tags, "LV.12", "x4" counters.
class PixelBadge extends StatelessWidget {
  final String label;
  final Color? fill;
  final Color? ink;
  final double fontSize;

  const PixelBadge({
    super.key,
    required this.label,
    this.fill,
    this.ink,
    this.fontSize = 9,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: fill ?? t.accentSoft,
        border: Border.all(color: t.cardBorder, width: 2),
      ),
      child: Text(
        label,
        style: AppTheme.label(fontSize, ink ?? t.textPrimary, spacing: 0.8),
      ),
    );
  }
}
