import '../models/goal_model.dart';
import '../models/profile_model.dart';

/// Pure logic that turns a friend's shared goals into the single status emoji
/// shown next to their name. Kept here (not in a widget) alongside the other
/// retention/engagement utilities so it can be unit-tested in isolation.
///
/// The score is a 0..1 health value reduced from the friend's shared goals
/// according to *their own* [FriendStatusMode]; the emoji is a fixed ramp over
/// that score. A friend with no shared goals reads as [noGoalsEmoji].
class FriendStatus {
  FriendStatus._();

  /// Shown when a friend shares no goals (or the pinned goal is gone).
  static const String noGoalsEmoji = '😴';

  /// Ramp thresholds anchored on the two examples the product asked for:
  /// barely-funded goals → skull, ≥75% complete → sunglasses.
  static String emojiForScore(double score) {
    if (score >= 0.75) return '😎';
    if (score >= 0.50) return '🙂';
    if (score >= 0.25) return '😬';
    return '💀';
  }

  /// Reduce the friend's [sharedGoals] to a single 0..1 score using [mode].
  /// Returns null when there's nothing to score (no goals, or a `goal` mode
  /// whose pinned goal isn't among the shared set).
  static double? scoreFor(
    List<Goal> sharedGoals,
    FriendStatusMode mode, {
    String? goalId,
  }) {
    if (sharedGoals.isEmpty) return null;
    final progresses = sharedGoals.map((g) => g.progress).toList();
    switch (mode) {
      case FriendStatusMode.best:
        return progresses.reduce((a, b) => a > b ? a : b);
      case FriendStatusMode.worst:
        return progresses.reduce((a, b) => a < b ? a : b);
      case FriendStatusMode.average:
        return progresses.reduce((a, b) => a + b) / progresses.length;
      case FriendStatusMode.goal:
        for (final g in sharedGoals) {
          if (g.id == goalId) return g.progress;
        }
        return null; // pinned goal not shared / deleted
    }
  }

  /// The status emoji for a friend given their shared goals and chosen mode.
  static String emojiFor(
    List<Goal> sharedGoals,
    FriendStatusMode mode, {
    String? goalId,
  }) {
    final score = scoreFor(sharedGoals, mode, goalId: goalId);
    return score == null ? noGoalsEmoji : emojiForScore(score);
  }
}
