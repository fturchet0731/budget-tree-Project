import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';
import '../services/auth_service.dart';

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
        return auth.isSignedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
