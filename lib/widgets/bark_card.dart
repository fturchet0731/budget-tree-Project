import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// Wooden-bark panel used to group form sections. Has a soft forest-green
/// gradient, a slim vine-coloured accent strip along the top, optional
/// section label (with leaf icon), and the standard multi-layer shadow.
class BarkCard extends StatelessWidget {
  final Widget child;
  final String? label;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? accent;
  final bool showAccentStrip;

  const BarkCard({
    super.key,
    required this.child,
    this.label,
    this.icon,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
    this.margin = EdgeInsets.zero,
    this.accent,
    this.showAccentStrip = true,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? AppColors.lightLeaf;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A2912).withValues(alpha: 0.94),
            const Color(0xFF0D1808).withValues(alpha: 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.forestGreen.withValues(alpha: 0.32),
          width: 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top vine accent strip — fades from accent → transparent
            if (showAccentStrip)
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accentColor.withValues(alpha: 0.75),
                      accentColor,
                      accentColor.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
                  ),
                ),
              ),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) ...[
                    Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon,
                              color: accentColor, size: 14),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label!.toUpperCase(),
                          style: GoogleFonts.nunito(
                            color: accentColor,
                            fontSize: 10.5,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
