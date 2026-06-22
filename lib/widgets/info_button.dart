import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../tutorial/tutorial_content.dart';
import '../tutorial/tutorial_overlay.dart';

/// A small circular "info" button that replays the acorn's guide for one
/// [TutorialSection]. Drop it into a screen's header so users can ask the
/// acorn to explain that section again at any time.
class SectionInfoButton extends StatelessWidget {
  final TutorialSection section;
  final double size;

  const SectionInfoButton({
    super.key,
    required this.section,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'How this works',
      child: GestureDetector(
        onTap: () => TutorialPlayer.playSection(context, section),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.mossGreen.withValues(alpha: 0.35)),
          ),
          child: const Icon(Icons.help_outline,
              color: AppColors.stoneBeigeColor, size: 20),
        ),
      ),
    );
  }
}
