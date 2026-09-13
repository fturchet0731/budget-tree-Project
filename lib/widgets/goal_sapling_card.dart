import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/goal_labels.dart';
import '../models/goal_model.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/leaf_palette.dart';
import 'sapling_view.dart';

/// A single goal drawn as a sapling in a profile / garden grid: the sapling, the
/// goal name, and its progress (or tier name for uncapped goals). Completed
/// goals read golden. Shared by the user's own profile and a friend's profile
/// view, so both grids look identical.
class GoalSaplingCard extends StatelessWidget {
  const GoalSaplingCard({super.key, required this.goal});

  final Goal goal;

  static const _gold = Color(0xFFBA8514);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pct = (goal.progress * 100).round();
    final completed = goal.isCompleted;
    // Render the sapling in the goal's own tree colour. This travels with the
    // goal (leafColorValue) so a friend sees the same colour the owner saved.
    final leafPalette = goal.leafColorValue != null
        ? LeafPalette.fromAccent(Color(goal.leafColorValue!))
        : LeafPalette.defaultGreen;
    final t = AppTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: completed ? const Color(0xFFE3B93F) : t.cardBorder,
          width: completed ? 1.6 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            // SaplingView scales its fixed design size down to whatever space
            // the grid cell allows, so the tree never overflows the card.
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SaplingView(
                progress: goal.progress,
                size: Size.infinite,
                leafPalette: leafPalette,
              ),
            ),
          ),
          Text(
            goal.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.stoneBeigeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            completed
                ? l.completedCheck
                : goal.isUncapped
                ? goal.localizedTierName(l)
                : l.percentThere(pct),
            style: TextStyle(
              color: completed ? _gold : AppColors.mossGreen,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
