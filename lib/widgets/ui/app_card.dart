import 'package:flutter/material.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_tokens.dart';

/// The standard surface of the redesign: a clean card with a soft ambient
/// shadow and a hairline border, sitting on the neutral canvas.
///
/// The constructor mirrors the retired BarkCard exactly so migrating a call
/// site is an import swap. [showAccentStrip] is accepted for compatibility
/// and renders nothing.
class AppCard extends StatelessWidget {
  final Widget child;
  final String? label;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? accent;
  final bool showAccentStrip;

  const AppCard({
    super.key,
    required this.child,
    this.label,
    this.icon,
    this.padding = const EdgeInsets.all(AppDims.s20),
    this.margin = EdgeInsets.zero,
    this.accent,
    this.showAccentStrip = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final accentColor = accent ?? t.accentStrong;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppDims.rCard),
        border: Border.all(color: t.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: accentColor, size: 15),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label!.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s12),
          ],
          child,
        ],
      ),
    );
  }
}
