import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

/// Root decision point: rebuilds on auth changes and shows either the login
/// screen or the normal app. When Supabase isn't configured (no dart-defines)
/// we skip auth entirely and run in local-only mode, so the app still works
/// before the backend is set up.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    if (!auth.isConfigured) return const HomeScreen();

    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        if (!auth.isSignedIn) {
          // "Explore first": a guest uses the app local-only, exactly like the
          // unconfigured mode. Their launch screen shows Sign In / Register,
          // and signing up later migrates their local data to the account.
          if (auth.isGuest) return const HomeScreen();
          return const LoginScreen();
        }
        // A signed-in user still has to finish onboarding (claim a username)
        // before reaching the app. Keyed by user id so switching accounts
        // re-runs the check.
        return OnboardingGate(key: ValueKey(auth.userId));
      },
    );
  }
}

/// Sits between "signed in" and [HomeScreen]: every account must have a profile
/// (username) before using the app, regardless of whether they want friends.
/// Resolves the user's profile once; if they have none they're sent through
/// [OnboardingScreen], otherwise straight into the app.
///
/// Offline-first: once a user has onboarded on this device we remember it
/// locally ([ProfileService.hasOnboardedLocally]) and skip the network lookup,
/// so a returning user can open the app without connectivity.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

enum _GateState { loading, onboarding, ready, error }

class _OnboardingGateState extends State<OnboardingGate> {
  _GateState _state = _GateState.loading;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    setState(() => _state = _GateState.loading);
    // Fast path: already onboarded on this device — no network needed.
    if (await ProfileService.instance.hasOnboardedLocally()) {
      if (mounted) setState(() => _state = _GateState.ready);
      return;
    }
    try {
      final profile = await ProfileService.instance.myProfile();
      if (!mounted) return;
      if (profile != null) {
        // Legacy account that already has a username — remember it so the next
        // launch takes the fast path.
        await ProfileService.instance.markOnboardedLocally();
        if (mounted) setState(() => _state = _GateState.ready);
      } else {
        setState(() => _state = _GateState.onboarding);
      }
    } catch (_) {
      // Couldn't reach Supabase (offline, or the social migration isn't applied
      // yet). Don't guess — let the user retry rather than locking them out or
      // forcing a duplicate username claim.
      if (mounted) setState(() => _state = _GateState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.ready:
        return const HomeScreen();
      case _GateState.onboarding:
        return OnboardingScreen(onComplete: _resolve);
      case _GateState.error:
        return _GateError(onRetry: _resolve);
      case _GateState.loading:
        return const _GateLoading();
    }
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.lightLeaf),
        ),
      ),
    );
  }
}

class _GateError extends StatelessWidget {
  const _GateError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off,
                      color: AppColors.mossGreen, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l.gateErrorTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.stoneBeigeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.gateErrorBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mossGreen),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(l.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
