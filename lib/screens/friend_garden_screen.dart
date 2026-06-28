import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/goal_model.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';
import '../widgets/goal_sapling_card.dart';

/// Read-only view of a friend's profile: their name + bio, and the goals they
/// shared drawn as saplings in a grid. The goals are fetched by
/// `FriendsService.friendSharedGoals` (RLS guarantees only shared ones reach
/// us), so this screen just paints what it's handed.
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
    final l = AppLocalizations.of(context);
    final bio = profile.bio?.trim();
    final hasBio = bio != null && bio.isNotEmpty;
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
          child: CustomScrollView(
            slivers: [
              if (hasBio)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      bio,
                      style: const TextStyle(
                          color: AppColors.stoneBeigeColor,
                          fontSize: 14,
                          height: 1.4),
                    ),
                  ),
                ),
              if (sharedGoals.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l.noSharedGoalsYet(profile.label),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.mossGreen),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => GoalSaplingCard(goal: sharedGoals[i]),
                      childCount: sharedGoals.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
