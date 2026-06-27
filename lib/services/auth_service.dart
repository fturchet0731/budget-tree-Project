import 'dart:async';
import 'package:flutter/foundation.dart';
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

  bool get isConfigured => SupabaseConfig.isConfigured;

  User? get currentUser =>
      isConfigured ? SupabaseConfig.client.auth.currentUser : null;

  String? get userId => currentUser?.id;
  bool get isSignedIn => currentUser != null;

  /// Begin listening to auth changes. Call once at boot, after
  /// [SupabaseConfig.init]. On every signed-in event we kick off a background
  /// sync; on sign-out we drop the local caches so the next user starts clean.
  void start() {
    if (!isConfigured) return;
    _sub ??= SupabaseConfig.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          if (isSignedIn) {
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

  /// Sign in with email + password. Throws [AuthException] on bad credentials.
  Future<void> signIn(String email, String password) async {
    await SupabaseConfig.client.auth
        .signInWithPassword(email: email.trim(), password: password);
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
