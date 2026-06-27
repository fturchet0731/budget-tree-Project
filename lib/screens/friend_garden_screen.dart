import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/goal_model.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';
import '../widgets/sapling_view.dart';

/// Read-only view of a friend's shared goals, each drawn as a sapling. The
/// goals are fetched by `FriendsService.friendSharedGoals` (RLS guarantees only
/// shared ones reach us), so this screen just paints what it's handed.
class FriendGardenScreen extends StatelessWidget {
  const FriendGardenScreen({
    super.key,
    required this.profile,
    required this.statusEmoji,
    required this.sharedGoals,
  });

  final Profile profile;
  final String statusEmoji;
  final List<Goal> sharedGoals;

  /// Shared goals with the profile's featured goal (if shared) pulled to the
  /// front so it shows first.
  List<Goal> get _orderedGoals {
    final featured = profile.featuredGoalId;
    if (featured == null) return sharedGoals;
    final ordered = [...sharedGoals]
      ..sort((a, b) {
        if (a.id == featured) return -1;
        if (b.id == featured) return 1;
        return 0;
      });
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final goals = _orderedGoals;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('${profile.label}  $statusEmoji'),
        foregroundColor: AppColors.stoneBeigeColor,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
        child: SafeArea(
          child: goals.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)
                        .noSharedGoalsYet(profile.label),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mossGreen),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: goals.length,
                  itemBuilder: (_, i) => _FriendGoalCard(
                    goal: goals[i],
                    featured: goals[i].id == profile.featuredGoalId,
                  ),
                ),
        ),
      ),
    );
  }
}

class _FriendGoalCard extends StatelessWidget {
  const _FriendGoalCard({required this.goal, this.featured = false});
  final Goal goal;
  final bool featured;

  static const _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pct = (goal.progress * 100).round();
    final completed = goal.isCompleted;
    // Featured and completed goals both read golden; featured adds a ribbon.
    final golden = featured || completed;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: golden
              ? _gold.withValues(alpha: 0.85)
              : AppColors.mossGreen.withValues(alpha: 0.3),
          width: golden ? 2 : 1,
        ),
        boxShadow: featured
            ? [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          if (featured)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: _gold),
                const SizedBox(width: 4),
                Text(
                  l.featured,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          Expanded(
            child: Center(
              child: SaplingView(
                progress: goal.progress,
                size: const Size(120, 150),
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
                    ? goal.tierName
                    : l.percentThere(pct),
            style: TextStyle(
                color: completed ? _gold : AppColors.mossGreen, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
