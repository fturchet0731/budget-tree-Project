import 'auth_service.dart';
import 'supabase_config.dart';

/// A goal's like tally plus whether the signed-in user is one of the likers.
class LikeSummary {
  final int count;
  final bool mine;
  const LikeSummary({required this.count, required this.mine});
}

/// Likes on friends' shared goals (the heart button). Online-only like the
/// rest of the social layer: every method no-ops when Supabase is
/// unconfigured or no one is signed in. RLS enforces the real rules server
/// side (only accepted friends can like, only shared goals, never your own).
class GoalLikesService {
  GoalLikesService._();
  static final GoalLikesService instance = GoalLikesService._();

  static const _table = 'goal_likes';

  bool get isAvailable =>
      SupabaseConfig.isConfigured && AuthService.instance.isSignedIn;

  String? get _uid => AuthService.instance.userId;

  /// Tally + my-like flag for one goal, in a single round trip.
  Future<LikeSummary> summary(String goalOwnerId, String goalId) async {
    if (!isAvailable) return const LikeSummary(count: 0, mine: false);
    final rows = await SupabaseConfig.client
        .from(_table)
        .select('liker')
        .eq('goal_owner', goalOwnerId)
        .eq('goal_id', goalId);
    return LikeSummary(
      count: rows.length,
      mine: rows.any((r) => r['liker'] == _uid),
    );
  }

  /// Like [goalId] (idempotent: an existing like is kept).
  Future<void> like(String goalOwnerId, String goalId) async {
    if (!isAvailable) return;
    await SupabaseConfig.client.from(_table).upsert({
      'goal_owner': goalOwnerId,
      'goal_id': goalId,
      'liker': _uid,
    });
  }

  /// Remove my like from [goalId].
  Future<void> unlike(String goalOwnerId, String goalId) async {
    if (!isAvailable) return;
    await SupabaseConfig.client
        .from(_table)
        .delete()
        .eq('goal_owner', goalOwnerId)
        .eq('goal_id', goalId)
        .eq('liker', _uid!);
  }
}
