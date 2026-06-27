import 'goal_model.dart';
import 'profile_model.dart';

/// The state of a friend relationship row in the `friendships` table. A single
/// directed row (requester -> addressee) models the whole relationship.
enum FriendshipStatus { pending, accepted }

class Friendship {
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;

  const Friendship({
    required this.requesterId,
    required this.addresseeId,
    required this.status,
  });

  factory Friendship.fromRow(Map<String, dynamic> r) => Friendship(
        requesterId: r['requester'] as String,
        addresseeId: r['addressee'] as String,
        status: (r['status'] as String?) == 'accepted'
            ? FriendshipStatus.accepted
            : FriendshipStatus.pending,
      );

  /// The other user's id relative to [me].
  String otherId(String me) => requesterId == me ? addresseeId : requesterId;
}

/// A row in the friends list: a friend's profile, the goals they've shared with
/// us, and the single status emoji computed from those goals via the friend's
/// own [Profile.statusMode]. Assembled by `FriendsService`.
class FriendSummary {
  final Profile profile;
  final List<Goal> sharedGoals;
  final String statusEmoji;

  const FriendSummary({
    required this.profile,
    required this.sharedGoals,
    required this.statusEmoji,
  });
}
