import 'package:flutter/material.dart';

import '../../theme/app_dims.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'pixel_button.dart';
import 'pixel_sprite.dart';

/// The standard screen header: a square back button, a Pixelify title with a
/// Silkscreen strapline under it, and an optional trailing action.
///
/// Mirrors the handoff's header block, which every non-title screen shares.
/// Use it in place of an `AppBar` when a screen wants the strapline (the
/// AppBar theme already renders plain titles in the right type).
class PixelHeader extends StatelessWidget {
  final String title;

  /// Small caps line under the title, e.g. "4 TREES STANDING".
  final String? strapline;

  /// Defaults to popping the route; pass null to omit the back button.
  final VoidCallback? onBack;
  final bool showBack;

  /// Optional trailing control, usually a [PixelIconButton].
  final Widget? action;

  final EdgeInsetsGeometry padding;

  const PixelHeader({
    super.key,
    required this.title,
    this.strapline,
    this.onBack,
    this.showBack = true,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 10),
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack) ...[
            PixelIconButton(
              icon: PixelIcons.back,
              semanticLabel: MaterialLocalizations.of(context)
                  .backButtonTooltip,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: AppDims.s8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                if (strapline != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    strapline!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.label(9, t.textTertiary, spacing: 1.2),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppDims.s8),
            action!,
          ],
        ],
      ),
    );
  }
}
