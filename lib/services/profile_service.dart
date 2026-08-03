import 'package:shared_preferences/shared_preferences.dart';
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

  /// Local marker recording which user id has finished onboarding (claimed a
  /// username). Lets the onboarding gate skip the network profile lookup on
  /// later launches, so a returning user can open the (offline-first) app
  /// without connectivity. See [hasOnboardedLocally] / [markOnboardedLocally].
  static const _onboardedKey = 'onboarded_user_id_v1';

  /// Username rules surfaced to the UI: 3–20 chars, letters/digits/underscore.
  static final RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  bool get isAvailable =>
      SupabaseConfig.isConfigured && AuthService.instance.isSignedIn;

  String? get _uid => AuthService.instance.userId;

  /// True when this exact signed-in user has already completed onboarding on
  /// this device. Cached locally so the onboarding gate doesn't have to hit the
  /// network on every launch (and so a returning user can open the app while
  /// offline). The stored id is compared to the current user so a different
  /// account on the same device is still gated.
  Future<bool> hasOnboardedLocally() async {
    if (!isAvailable) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_onboardedKey) == _uid;
  }

  /// Record that the current user finished onboarding (see [hasOnboardedLocally]).
  Future<void> markOnboardedLocally() async {
    if (_uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onboardedKey, _uid!);
  }

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
  ///
  /// Goes through a SECURITY DEFINER function rather than reading the table:
  /// this is a question *about* a row the caller deliberately cannot see, and a
  /// bare boolean answers it without revealing whose row it is.
  Future<bool> isUsernameAvailable(String username) async {
    if (!isAvailable || !usernamePattern.hasMatch(username)) return false;
    final free = await SupabaseConfig.client
        .rpc('username_available', params: {'candidate': username});
    return free == true;
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
      await markOnboardedLocally();
      return Profile.fromRow(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const UsernameTakenException();
      rethrow;
    }
  }

  /// Stamp "seen just now" on the signed-in user's profile so friends' strips
  /// can show an active dot. Throttled in memory (at most once every 2 minutes)
  /// and fire-and-forget safe: failures are swallowed, presence is best-effort.
  DateTime? _lastPresenceTouch;
  Future<void> touchPresence() async {
    if (!isAvailable) return;
    final now = DateTime.now();
    if (_lastPresenceTouch != null &&
        now.difference(_lastPresenceTouch!).inMinutes < 2) {
      return;
    }
    _lastPresenceTouch = now;
    try {
      await SupabaseConfig.client.from(_table).update({
        'last_seen_at': now.toUtc().toIso8601String(),
      }).eq('id', _uid!);
    } catch (_) {
      // Best-effort: a failed heartbeat never surfaces to the user.
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

  /// Update the user's profile picture (a small base64 JPEG resized on
  /// device; pass null to clear it).
  Future<void> setAvatar(String? avatarB64) async {
    if (!isAvailable) return;
    await SupabaseConfig.client.from(_table).update({
      'avatar_b64': avatarB64,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _uid!);
  }

  /// Update the user's profile bio (pass null/blank to clear it).
  Future<void> setBio(String? bio) async {
    if (!isAvailable) return;
    final trimmed = bio?.trim();
    await SupabaseConfig.client.from(_table).update({
      'bio': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
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

  /// Shortest query the search will act on. One letter would page most of the
  /// user table, so the server enforces this too and the client mirrors it to
  /// avoid a pointless round trip.
  static const minSearchLength = 2;

  /// Search other users by (partial) username, excluding self.
  ///
  /// Strangers' rows aren't readable directly, so this goes through a
  /// SECURITY DEFINER function that caps the result set and returns only the
  /// columns a search row renders — no bio, status mode or pinned goal.
  /// Empty when the query is too short or the social layer is unavailable.
  Future<List<Profile>> searchByUsername(String query) async {
    final q = query.trim();
    if (!isAvailable || q.length < minSearchLength) return const [];
    final rows = await SupabaseConfig.client
        .rpc('search_profiles', params: {'q': q}) as List<dynamic>;
    return rows
        .map<Profile>((r) => Profile.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
