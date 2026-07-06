import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_shadows.dart';
import '../theme/app_tokens.dart';

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
    final t = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.canvasSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, l.profile, SocialTab.profile),
          _segment(context, l.friends, SocialTab.friends),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, SocialTab tab) {
    final t = AppTokens.of(context);
    final selected = active == tab;
    return GestureDetector(
      onTap: () => onSelect(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? t.card : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? AppShadows.pill : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? t.textPrimary : t.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
