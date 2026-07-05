import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

/// Quiet uppercase section label used between card groups.
class SectionHeader extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(4, 20, 4, 8),
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: t.textSecondary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
