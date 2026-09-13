import 'package:flutter/material.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../pixel/pixel.dart';

/// The standard surface of the pixel skin: a hard-edged parchment box with a
/// 3px ink outline and a solid offset drop shadow.
///
/// The constructor is unchanged from the previous rounded-card version, so
/// every existing call site keeps working and simply inherits the new chrome.
/// [showAccentStrip] is accepted for compatibility and renders nothing.
class AppCard extends StatelessWidget {
  final Widget child;
  final String? label;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? accent;
  final bool showAccentStrip;

  /// Makes the whole card tappable, with the pixel press-depress.
  final VoidCallback? onTap;

  /// Surface fill override — used for the gold "completed" card.
  final Color? fill;

  /// Outline override — used for the gold "completed" border.
  final Color? border;

  const AppCard({
    super.key,
    required this.child,
    this.label,
    this.icon,
    this.padding = const EdgeInsets.all(AppDims.s12),
    this.margin = EdgeInsets.zero,
    this.accent,
    this.showAccentStrip = true,
    this.onTap,
    this.fill,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final accentColor = accent ?? t.accentStrong;
    return PixelBox(
      margin: margin,
      padding: padding,
      onTap: onTap,
      fill: fill,
      border: border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: accentColor, size: 14),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label!.toUpperCase(),
                    style: AppTheme.label(9, accentColor, spacing: 1.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s8),
          ],
          child,
        ],
      ),
    );
  }
}
