/// How a user's single "status emoji" (shown next to their name in a friend's
/// list) is derived from their shared goals. Each user picks this for
/// *themselves* — it is published in their profile so friends compute the
/// emoji the way the owner intends.
///
/// - [best]    — use the most-complete shared goal (the default).
/// - [average] — blend the progress of all shared goals.
/// - [worst]   — use the least-funded shared goal.
/// - [goal]    — pin to one specific shared goal ([Profile.statusGoalId]).
enum FriendStatusMode { best, average, worst, goal }

extension FriendStatusModeWire on FriendStatusMode {
  /// Stored as a short string in the `profiles.status_mode` column.
  String get wire => name; // best | average | worst | goal

  static FriendStatusMode fromWire(String? s) {
    switch (s) {
      case 'average':
        return FriendStatusMode.average;
      case 'worst':
        return FriendStatusMode.worst;
      case 'goal':
        return FriendStatusMode.goal;
      case 'best':
      default:
        return FriendStatusMode.best;
    }
  }

  String get label {
    switch (this) {
      case FriendStatusMode.best:
        return 'Best goal';
      case FriendStatusMode.average:
        return 'Average of goals';
      case FriendStatusMode.worst:
        return 'Worst goal';
      case FriendStatusMode.goal:
        return 'A chosen goal';
    }
  }
}

/// A public-facing user profile backing the friends feature. Unlike the four
/// data models (which live whole inside a `data` jsonb column), profiles map
/// onto real `profiles` columns, so this (de)serializes column-by-column.
class Profile {
  final String id; // == auth.users.id
  final String username;
  final String? displayName;
  final FriendStatusMode statusMode;
  final String? statusGoalId;

  /// A completed goal the user pins to show off on their profile. Friends see
  /// it highlighted (golden "Featured") at the front of the user's garden. Null
  /// when nothing is featured. Only meaningful for goals the user has also
  /// shared, since friends can only read shared goals.
  final String? featuredGoalId;

  const Profile({
    required this.id,
    required this.username,
    this.displayName,
    this.statusMode = FriendStatusMode.best,
    this.statusGoalId,
    this.featuredGoalId,
  });

  /// Name to show in the UI — the display name if set, else the @username.
  String get label =>
      (displayName != null && displayName!.trim().isNotEmpty)
          ? displayName!
          : '@$username';

  factory Profile.fromRow(Map<String, dynamic> r) => Profile(
        id: r['id'] as String,
        username: r['username'] as String,
        displayName: r['display_name'] as String?,
        statusMode: FriendStatusModeWire.fromWire(r['status_mode'] as String?),
        statusGoalId: r['status_goal_id'] as String?,
        featuredGoalId: r['featured_goal_id'] as String?,
      );

  /// Columns to insert/update. `id` is set by the service from `auth.uid()`.
  Map<String, dynamic> toRow() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'status_mode': statusMode.wire,
        'status_goal_id': statusMode == FriendStatusMode.goal
            ? statusGoalId
            : null,
        'featured_goal_id': featuredGoalId,
      };
}
