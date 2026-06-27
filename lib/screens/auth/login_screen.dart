import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

/// Email + password sign-in / sign-up, themed to match the forest aesthetic.
/// On success the [AuthGate] swaps this out for the app automatically (it
/// listens to [AuthService]), so this screen only has to clear errors.
class LoginScreen extends StatefulWidget {
  /// When opened from the launch screen's "Register" button we want the
  /// sign-up form up front; the [AuthGate] root opens in sign-in mode.
  const LoginScreen({super.key, this.startInSignUp = false});

  final bool startInSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();

  late bool _isSignUp = widget.startInSignUp;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final auth = AuthService.instance;
      bool hasSession = true;
      if (_isSignUp) {
        // Reserve the username before creating the account so we don't end up
        // with a signed-in user who couldn't claim their handle. The unique
        // constraint is still the real guard (claimUsername below).
        final username = _username.text.trim();
        if (!await ProfileService.instance.isUsernameAvailable(username)) {
          setState(() => _error = 'That username is taken. Try another.');
          return;
        }
        hasSession = await auth.signUp(_email.text, _password.text);
        if (hasSession) {
          try {
            await ProfileService.instance.claimUsername(username);
          } on UsernameTakenException {
            // Lost a race for the name; the dashboard will re-prompt on first
            // Friends open. Let the sign-in proceed rather than blocking.
          }
        }
        // If email confirmation is on, signUp succeeds but creates no session,
        // so AuthGate won't advance — tell the user to confirm their email
        // instead of leaving them on a screen that appears to do nothing.
        if (!hasSession && mounted) {
          setState(() {
            _isSignUp = false;
            _notice = 'Account created. Check your email to confirm, '
                'then sign in.';
          });
        }
      } else {
        await auth.signIn(_email.text, _password.text);
      }
      // When this screen is the AuthGate root it gets swapped out automatically
      // on the auth state change. When it was pushed on top of the launch
      // screen, pop it ourselves so the user lands back in the app.
      if (hasSession && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.park_rounded,
                          color: AppColors.lightLeaf, size: 72),
                      const SizedBox(height: 16),
                      Text(
                        'Budget Tree',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.stoneBeigeColor,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSignUp
                            ? 'Plant your forest in the cloud'
                            : 'Welcome back to your grove',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enabled: !_busy,
                        style: const TextStyle(
                            color: AppColors.stoneBeigeColor),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppColors.mossGreen),
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Enter your email';
                          if (!s.contains('@') || !s.contains('.')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      if (_isSignUp) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _username,
                          autocorrect: false,
                          enableSuggestions: false,
                          enabled: !_busy,
                          style: const TextStyle(
                              color: AppColors.stoneBeigeColor),
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            helperText:
                                'How friends find you — 3-20 letters, '
                                'numbers or _',
                            helperStyle: TextStyle(color: AppColors.mossGreen),
                            prefixIcon: Icon(Icons.alternate_email,
                                color: AppColors.mossGreen),
                          ),
                          validator: (v) {
                            if (!_isSignUp) return null;
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return 'Choose a username';
                            if (!ProfileService.usernamePattern.hasMatch(s)) {
                              return '3-20 letters, numbers or underscore';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        enabled: !_busy,
                        style: const TextStyle(
                            color: AppColors.stoneBeigeColor),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppColors.mossGreen),
                        ),
                        validator: (v) {
                          if ((v ?? '').length < 6) {
                            return 'At least 6 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_notice != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.mossGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.mossGreen
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mark_email_read_outlined,
                                  color: AppColors.lightLeaf, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _notice!,
                                  style: GoogleFonts.nunito(
                                      color: AppColors.stoneBeigeColor,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.dangerRed
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.dangerRed, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.nunito(
                                      color: AppColors.stoneBeigeColor,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isSignUp ? 'Create account' : 'Sign in',
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _error = null;
                                  _notice = null;
                                }),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign in'
                              : "New here? Create an account",
                          style: GoogleFonts.nunito(
                              color: AppColors.lightLeaf, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
