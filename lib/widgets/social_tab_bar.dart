import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// The two faces of the dashboard's social sidebar.
enum SocialTab { profile, friends }

/// A small segmented control that flips the social sidebar between the user's
/// own profile and their friends list. Lives in each screen's app bar so the
/// toggle is always visible whichever tab is showing.
class SocialTabBar extends StatelessWidget {
  const SocialTabBar({super.key, required this.active, required this.onSelect});

  final SocialTab active;
  final ValueChanged<SocialTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.mossGreen.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(l.profile, SocialTab.profile),
          _segment(l.friends, SocialTab.friends),
        ],
      ),
    );
  }

  Widget _segment(String label, SocialTab tab) {
    final selected = active == tab;
    return GestureDetector(
      onTap: () => onSelect(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.forestGreen.withValues(alpha: 0.55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.lightLeaf
                : AppColors.mossGreen.withValues(alpha: 0.85),
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
