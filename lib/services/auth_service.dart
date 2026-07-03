import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'sync_engine.dart';

/// App-wide authentication state, modelled on the [AppSettings] singleton
/// pattern: a [ChangeNotifier] exposed as [AuthService.instance] that the UI
/// listens to (see `AuthGate`). Thinly wraps Supabase's auth client.
///
/// When Supabase isn't configured (no dart-defines), [isConfigured] is false
/// and the app should bypass the login gate and run in local-only mode.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  StreamSubscription<AuthState>? _sub;

  static const _guestKey = 'guest_mode_v1';
  bool _guest = false;

  bool get isConfigured => SupabaseConfig.isConfigured;

  /// True when the user chose "explore first" on the login screen and hasn't
  /// signed in yet. The app runs local-only (same as unconfigured mode); their
  /// data migrates up automatically if they create an account later, because
  /// [SyncEngine.onSignedIn] pushes all local rows on every sign-in.
  bool get isGuest => _guest && !isSignedIn;

  /// Let the user into the app without an account. Persisted so the next
  /// launch skips the login gate too.
  Future<void> enterGuestMode() async {
    _guest = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
  }

  Future<void> _clearGuestMode() async {
    if (!_guest) return;
    _guest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
  }

  static const _guestPromptKey = 'guest_account_prompt_shown_v1';

  /// Whether to invite this guest to create an account right now. True exactly
  /// once, at the peak-motivation moment the dashboard picks (first tree
  /// planted); after that the launch screen's Register button is the only
  /// nudge, so guests never feel nagged.
  Future<bool> shouldOfferAccountUpgrade() async {
    if (!isGuest) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_guestPromptKey) ?? false);
  }

  Future<void> markAccountUpgradeOffered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestPromptKey, true);
  }

  User? get currentUser =>
      isConfigured ? SupabaseConfig.client.auth.currentUser : null;

  String? get userId => currentUser?.id;
  bool get isSignedIn => currentUser != null;

  /// Whether the signed-in user has confirmed their email address. With email
  /// confirmation enabled a verified user always has [User.emailConfirmedAt].
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  /// Begin listening to auth changes. Call once at boot, after
  /// [SupabaseConfig.init]. On every signed-in event we kick off a background
  /// sync; on sign-out we drop the local caches so the next user starts clean.
  /// Also restores the persisted guest flag so a returning guest skips the
  /// login gate (await this before [runApp] so the gate opens correctly).
  Future<void> start() async {
    if (!isConfigured) return;
    final prefs = await SharedPreferences.getInstance();
    _guest = prefs.getBool(_guestKey) ?? false;
    _sub ??= SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          if (isSignedIn) {
            // Guest days are over: they have an account now, so the login
            // gate should own the signed-out state again.
            unawaited(_clearGuestMode());
            // Don't block the auth callback on network work.
            unawaited(SyncEngine.onSignedIn());
          }
          break;
        case AuthChangeEvent.signedOut:
          unawaited(SyncEngine.clearLocalCaches());
          break;
        default:
          break;
      }
      notifyListeners();
    });
  }

  /// Create a new account. Throws [AuthException] on failure (caller surfaces
  /// the message). With "Confirm email" disabled in the dashboard, this also
  /// signs the user in immediately and returns true. If email confirmation is
  /// enabled, no session is created (returns false) and the caller should tell
  /// the user to check their inbox rather than silently doing nothing.
  Future<bool> signUp(String email, String password) async {
    final res = await SupabaseConfig.client.auth
        .signUp(email: email.trim(), password: password);
    return res.session != null;
  }

  /// Sign in with email + password. Throws [AuthException] on bad credentials
  /// (including `email_not_confirmed` when the user hasn't verified yet, which
  /// the login screen catches to route them to the verification screen).
  Future<void> signIn(String email, String password) async {
    await SupabaseConfig.client.auth
        .signInWithPassword(email: email.trim(), password: password);
  }

  /// Verify the 6-digit code emailed after sign-up. On success Supabase creates
  /// a session and the auth listener advances the gate. Throws [AuthException]
  /// on a wrong or expired code.
  Future<void> verifyEmailOtp(String email, String token) async {
    await SupabaseConfig.client.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: token.trim(),
    );
  }

  /// Resend the sign-up confirmation code to [email]. Throws [AuthException]
  /// (e.g. rate limited) so the caller can surface the message.
  Future<void> resendSignupOtp(String email) async {
    await SupabaseConfig.client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
