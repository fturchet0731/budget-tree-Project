import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
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
          child: sharedGoals.isEmpty
              ? Center(
                  child: Text(
                    '${profile.label} hasn\'t shared any goals yet.',
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
                  itemCount: sharedGoals.length,
                  itemBuilder: (_, i) => _FriendGoalCard(goal: sharedGoals[i]),
                ),
        ),
      ),
    );
  }
}

class _FriendGoalCard extends StatelessWidget {
  const _FriendGoalCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).round();
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.mossGreen.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
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
            goal.isUncapped ? goal.tierName : '$pct% there',
            style: const TextStyle(color: AppColors.mossGreen, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
