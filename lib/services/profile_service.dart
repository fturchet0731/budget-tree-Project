import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Thrown when the requested username is already taken (case-insensitively).
class UsernameTakenException implements Exception {
  const UsernameTakenException();
  @override
  String toString() => 'That username is already taken.';
}

/// Reads/writes the signed-in user's public [Profile] and searches other users
/// by username. Unlike the four data repositories this is **not** offline-first
/// — the social layer needs a live session, so every method short-circuits when
/// Supabase is unconfigured or the user is signed out (see [isAvailable]).
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _table = 'profiles';

  /// Username rules surfaced to the UI: 3–20 chars, letters/digits/underscore.
  static final RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  bool get isAvailable =>
      SupabaseConfig.isConfigured && AuthService.instance.isSignedIn;

  String? get _uid => AuthService.instance.userId;

  /// The signed-in user's profile, or null if they haven't claimed one yet.
  Future<Profile?> myProfile() async {
    if (!isAvailable) return null;
    final row = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('id', _uid!)
        .maybeSingle();
    return row == null ? null : Profile.fromRow(row);
  }

  /// True if [username] is well-formed and not already claimed by someone else.
  Future<bool> isUsernameAvailable(String username) async {
    if (!isAvailable || !usernamePattern.hasMatch(username)) return false;
    final row = await SupabaseConfig.client
        .from(_table)
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return row == null || row['id'] == _uid;
  }

  /// Claim [username] for the signed-in user (insert their profile row).
  /// Throws [UsernameTakenException] on a unique-constraint clash.
  Future<Profile> claimUsername(String username, {String? displayName}) async {
    final profile = Profile(
      id: _uid!,
      username: username,
      displayName: displayName,
    );
    try {
      final row = await SupabaseConfig.client
          .from(_table)
          .insert(profile.toRow())
          .select()
          .single();
      return Profile.fromRow(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const UsernameTakenException();
      rethrow;
    }
  }

  /// Update how this user's status emoji is computed.
  Future<void> setStatusMode(FriendStatusMode mode, {String? goalId}) async {
    if (!isAvailable) return;
    await SupabaseConfig.client.from(_table).update({
      'status_mode': mode.wire,
      'status_goal_id': mode == FriendStatusMode.goal ? goalId : null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _uid!);
  }

  /// Fetch a single profile by user id (used to resolve friends/requests).
  Future<Profile?> byId(String userId) async {
    if (!isAvailable) return null;
    final row = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromRow(row);
  }

  /// Search other users by (partial) username, excluding self. Empty when the
  /// query is blank or the social layer is unavailable.
  Future<List<Profile>> searchByUsername(String query) async {
    final q = query.trim();
    if (!isAvailable || q.isEmpty) return const [];
    final rows = await SupabaseConfig.client
        .from(_table)
        .select()
        .ilike('username', '%$q%')
        .neq('id', _uid!)
        .limit(20);
    return rows.map<Profile>((r) => Profile.fromRow(r)).toList();
  }
}
