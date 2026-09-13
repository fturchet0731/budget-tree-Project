import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tree_health_labels.dart';
import '../models/goal_model.dart';
import '../models/profile_model.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../services/tree_health_service.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/status_tree_view.dart';
import '../widgets/goal_sapling_card.dart';
import '../widgets/profile_avatar.dart';
import 'friend_chat_screen.dart';
import 'friend_goal_screen.dart';

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(profile: profile, size: 32),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                '${profile.label}  $statusEmoji',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        foregroundColor: AppColors.stoneBeigeColor,
        actions: [
          // Open the 1:1 chat with this friend.
          IconButton(
            tooltip: l.messageAction,
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendChatScreen(friend: profile),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: AppTokens.current.canvas,
        child: SafeArea(
          child: AppScrollbar(
            builder: (controller) => CustomScrollView(
              controller: controller,
              slivers: [
                // Their tree, in the same state they see it on their own
                // dashboard. Absent for a friend who has never answered a
                // check-in, rather than showing a bare trunk.
                if (profile.healthScore != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          StatusTreeView(
                            spriteKey: TreeHealthService
                                .tierFor(profile.healthScore!.toDouble())
                                .name,
                            size: 84,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TreeHealthService
                                      .tierFor(profile.healthScore!.toDouble())
                                      .label(l),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l.hubScoreSub(profile.healthScore!),
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (hasBio)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        bio,
                        style: TextStyle(
                          color: AppColors.stoneBeigeColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
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
                          style: TextStyle(color: AppColors.mossGreen),
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
                        (ctx, i) => GestureDetector(
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => FriendGoalScreen(
                                goal: sharedGoals[i],
                                ownerLabel: profile.label,
                                ownerId: profile.id,
                              ),
                            ),
                          ),
                          child: GoalSaplingCard(goal: sharedGoals[i]),
                        ),
                        childCount: sharedGoals.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
