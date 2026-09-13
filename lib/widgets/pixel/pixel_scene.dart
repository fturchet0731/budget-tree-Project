import 'package:flutter/material.dart';

import '../../theme/app_dims.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'pixel_button.dart';
import 'pixel_sprite.dart';

/// The diegetic hero band: a flat sky panel, a repeating ground tile along the
/// bottom, and a subject (a tree or sapling) standing on it.
///
/// Every "place" screen in the pixel skin opens with one of these — the hub,
/// a profile, a budget tree, a goal — so the app reads as a world you walk
/// around rather than a stack of forms. Overlays (back button, level badge,
/// a name plate) are positioned on top of the scene, not above it, which is
/// what makes the header feel like scenery instead of chrome.
class PixelScene extends StatelessWidget {
  final double height;

  /// The tree/sapling standing on the ground line.
  final Widget subject;

  /// Horizontal placement of [subject]: -1 left, 0 centre, 1 right.
  final double subjectX;

  /// Sky fill. Defaults to the pale green wash the handoff uses indoors; pass
  /// a blue for outdoor scenes.
  final Color? sky;

  /// Height of the soil strip at the bottom.
  final double groundHeight;

  final VoidCallback? onBack;
  final String? backLabel;

  /// Small overlay pinned to the top-right (typically a level badge).
  final Widget? topRight;

  /// Overlay pinned above the ground on the right (typically a name plate).
  final Widget? bottomRight;

  /// Overlay pinned above the ground on the left.
  final Widget? bottomLeft;

  /// Show Acorn idling on the right of the scene.
  final bool showAcorn;

  const PixelScene({
    super.key,
    required this.subject,
    this.height = 212,
    this.subjectX = 0,
    this.sky,
    this.groundHeight = 44,
    this.onBack,
    this.backLabel,
    this.topRight,
    this.bottomRight,
    this.bottomLeft,
    this.showAcorn = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    // The sky deliberately bleeds up behind the status bar — that's what makes
    // the scene read as scenery rather than a header. The *controls* must not,
    // so the band grows by the inset and everything pinned to its top is
    // pushed below the clock, wifi, and battery. Handling it here fixes every
    // scene screen at once; those screens must NOT wrap this in a SafeArea, or
    // the sky would stop short of the top edge.
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: height + topInset,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sky ?? Conifer.c50,
                  border: Border(
                    bottom: BorderSide(
                      color: t.cardBorder,
                      width: AppDims.borderThick,
                    ),
                  ),
                ),
              ),
            ),
            // Soil strip along the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PixelGround(height: groundHeight),
            ),
            // The subject stands on the ground line.
            Positioned(
              left: 0,
              right: 0,
              bottom: groundHeight * 0.32,
              child: Align(alignment: Alignment(subjectX, 0), child: subject),
            ),
            if (showAcorn)
              Positioned(
                right: 14,
                bottom: groundHeight + 8,
                child: const PixelSpriteSheet(
                  asset: PixelIcons.acorn,
                  size: 52,
                  frames: 2,
                  period: Duration(milliseconds: 3400),
                ),
              ),
            if (bottomLeft != null)
              Positioned(
                left: 14,
                bottom: groundHeight + 8,
                child: bottomLeft!,
              ),
            if (bottomRight != null)
              Positioned(
                right: 14,
                bottom: groundHeight + 8,
                child: bottomRight!,
              ),
            if (onBack != null)
              Positioned(
                top: 12 + topInset,
                left: 12,
                child: PixelIconButton(
                  icon: PixelIcons.back,
                  onPressed: onBack,
                  semanticLabel: backLabel,
                ),
              ),
            if (topRight != null)
              Positioned(top: 12 + topInset, right: 12, child: topRight!),
          ],
        ),
      ),
    );
  }
}

/// `LABEL ────────` — the rule-and-caption divider the handoff uses to open a
/// section on the profile and hub.
class PixelSectionRule extends StatelessWidget {
  final String label;

  /// Optional right-aligned counter, e.g. `6/18`.
  final String? trailing;

  const PixelSectionRule({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.label(9, t.textSecondary, spacing: 1.5),
        ),
        const SizedBox(width: AppDims.s8),
        Expanded(child: Container(height: 3, color: t.track)),
        if (trailing != null) ...[
          const SizedBox(width: AppDims.s8),
          Text(trailing!, style: AppTheme.label(9, t.textSecondary)),
        ],
      ],
    );
  }
}
