import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/friendship_model.dart';
import '../models/goal_model.dart';
import '../models/profile_model.dart';
import 'auth_service.dart';
import 'friend_status.dart';
import 'supabase_config.dart';

/// Friend relationships and reading friends' shared goals. Like
/// [ProfileService] this is online-only: every method no-ops to an empty result
/// when Supabase is unconfigured or no one is signed in. Privacy is enforced by
/// RLS on the server — `friendSharedGoals` can only ever return goals the owner
/// marked shared *and* that belong to an accepted friend.
class FriendsService {
  FriendsService._();
  static final FriendsService instance = FriendsService._();

  static const _friendships = 'friendships';
  static const _goals = 'goals';

  bool get isAvailable =>
      SupabaseConfig.isConfigured && AuthService.instance.isSignedIn;

  String? get _uid => AuthService.instance.userId;

  // ------------------------------------------------------------- mutations

  /// Send a friend request to [targetUserId]. If they already requested *us*,
  /// this accepts their pending request instead of creating a duplicate.
  Future<void> sendRequest(String targetUserId) async {
    if (!isAvailable || targetUserId == _uid) return;

    // Did they already request us? Accept that rather than cross-requesting.
    final reverse = await SupabaseConfig.client
        .from(_friendships)
        .select('status')
        .eq('requester', targetUserId)
        .eq('addressee', _uid!)
        .maybeSingle();
    if (reverse != null) {
      await acceptRequest(targetUserId);
      return;
    }

    try {
      await SupabaseConfig.client.from(_friendships).insert({
        'requester': _uid,
        'addressee': targetUserId,
        'status': 'pending',
      });
    } on PostgrestException catch (e) {
      // 23505 = already requested; treat as idempotent success.
      if (e.code != '23505') rethrow;
    }
  }

  /// Accept the pending request sent by [requesterId].
  Future<void> acceptRequest(String requesterId) async {
    if (!isAvailable) return;
    await SupabaseConfig.client
        .from(_friendships)
        .update({'status': 'accepted'})
        .eq('requester', requesterId)
        .eq('addressee', _uid!);
  }

  /// Remove a friend, decline an incoming request, or cancel an outgoing one —
  /// all are just "delete the relationship row in whichever direction exists".
  Future<void> removeFriend(String otherUserId) async {
    if (!isAvailable) return;
    await SupabaseConfig.client.from(_friendships).delete().or(
          'and(requester.eq.$_uid,addressee.eq.$otherUserId),'
          'and(requester.eq.$otherUserId,addressee.eq.$_uid)',
        );
  }

  // --------------------------------------------------------------- queries

  Future<List<Friendship>> _rows() async {
    if (!isAvailable) return const [];
    final rows = await SupabaseConfig.client
        .from(_friendships)
        .select()
        .or('requester.eq.$_uid,addressee.eq.$_uid');
    return rows.map<Friendship>((r) => Friendship.fromRow(r)).toList();
  }

  /// Pending requests *received* by us (we are the addressee).
  Future<List<Profile>> incomingRequests() async {
    final me = _uid;
    final pending = (await _rows()).where((f) =>
        f.status == FriendshipStatus.pending && f.addresseeId == me);
    return _resolveProfiles(pending.map((f) => f.requesterId));
  }

  /// Accepted friends.
  Future<List<Profile>> friends() async {
    final me = _uid;
    if (me == null) return const [];
    final accepted = (await _rows())
        .where((f) => f.status == FriendshipStatus.accepted)
        .map((f) => f.otherId(me));
    return _resolveProfiles(accepted);
  }

  /// Accepted friends with their shared goals and computed status emoji —
  /// everything the friends list needs in one call.
  Future<List<FriendSummary>> friendSummaries() async {
    final profiles = await friends();
    final summaries = <FriendSummary>[];
    for (final p in profiles) {
      final goals = await friendSharedGoals(p.id);
      summaries.add(FriendSummary(
        profile: p,
        sharedGoals: goals,
        statusEmoji: FriendStatus.emojiFor(
          goals,
          p.statusMode,
          goalId: p.statusGoalId,
        ),
      ));
    }
    return summaries;
  }

  /// The goals [friendUserId] has shared with us. RLS guarantees we only ever
  /// receive rows the owner marked shared and only for an accepted friend.
  Future<List<Goal>> friendSharedGoals(String friendUserId) async {
    if (!isAvailable) return const [];
    final rows = await SupabaseConfig.client
        .from(_goals)
        .select('data')
        .eq('user_id', friendUserId);
    return rows
        .map<Goal>((r) => Goal.fromJson(r['data'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Profile>> _resolveProfiles(Iterable<String> ids) async {
    final list = ids.toList();
    if (!isAvailable || list.isEmpty) return const [];
    final rows = await SupabaseConfig.client
        .from('profiles')
        .select()
        .inFilter('id', list);
    return rows.map<Profile>((r) => Profile.fromRow(r)).toList();
  }
}
