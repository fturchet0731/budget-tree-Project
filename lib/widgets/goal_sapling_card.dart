import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/goal_labels.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';
import '../theme/leaf_palette.dart';
import 'sapling_view.dart';

/// A single goal drawn as a sapling in a profile / garden grid: the sapling, the
/// goal name, and its progress (or tier name for uncapped goals). Completed
/// goals read golden. Shared by the user's own profile and a friend's profile
/// view, so both grids look identical.
class GoalSaplingCard extends StatelessWidget {
  const GoalSaplingCard({super.key, required this.goal});

  final Goal goal;

  static const _gold = Color(0xFFFFD54F);

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed
              ? _gold.withValues(alpha: 0.85)
              : AppColors.mossGreen.withValues(alpha: 0.3),
          width: completed ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: Center(
              // FittedBox scales the fixed-size sapling down to whatever space
              // the grid cell allows, so the tree never overflows the card.
              child: FittedBox(
                fit: BoxFit.contain,
                child: SaplingView(
                  progress: goal.progress,
                  size: const Size(120, 150),
                  leafPalette: leafPalette,
                ),
              ),
            ),
          ),
          Text(
            goal.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
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
