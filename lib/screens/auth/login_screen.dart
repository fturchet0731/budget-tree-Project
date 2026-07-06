import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/acorn_mascot.dart';
import '../../widgets/ui/app_buttons.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/entrance.dart';
import 'verify_email_screen.dart';

/// Whether [password] meets the account password policy: at least 8 characters
/// with at least one letter and one digit. Mirrors the Supabase auth config
/// (`minimum_password_length = 8`, `password_requirements = "letters_digits"`)
/// so the client rejects weak passwords before a round trip. Pure and
/// top-level so it can be unit-tested (see test/password_policy_test.dart).
bool isStrongPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Za-z]').hasMatch(password) &&
      RegExp(r'\d').hasMatch(password);
}

/// Email + password sign-in / sign-up on the neutral canvas: one white card
/// with Acorn greeting the user from a soft green circle. On success the
/// [AuthGate] swaps this out for the app automatically (it listens to
/// [AuthService]), so this screen only has to clear errors.
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

  late bool _isSignUp = widget.startInSignUp;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _openVerify() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(email: _email.text.trim()),
      ),
    );
    // Verifying the code signs the user in. When this screen was pushed on top
    // of the launch screen (guest upgrading to an account) the AuthGate can't
    // remove it for us, so pop it too rather than landing on a stale form.
    if (!mounted) return;
    if (AuthService.instance.isSignedIn && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
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
        // Username/profile setup happens after sign-in, in the OnboardingGate —
        // so signing up is just email + password here.
        hasSession = await auth.signUp(_email.text, _password.text);
        // If email confirmation is on, signUp succeeds but creates no session.
        // Send the user to enter the code we just emailed them; verifying it
        // creates the session and the AuthGate advances.
        if (!hasSession && mounted) {
          _openVerify();
          return;
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
      // An unverified account can't sign in — route them to verification
      // instead of dead-ending on the error.
      if (e.code == 'email_not_confirmed' && mounted) {
        _openVerify();
        return;
      }
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context).somethingWentWrong);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _messageBox({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    final t = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDims.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rInner),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(color: t.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: StaggeredColumn(
                children: [
                  Center(
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: t.accentTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: AcornMascot(size: 64, sway: true),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDims.s16),
                  Text(
                    'Budget Tree',
                    textAlign: TextAlign.center,
                    style: text.headlineLarge,
                  ),
                  const SizedBox(height: AppDims.s4),
                  Text(
                    _isSignUp ? l.loginPlantForest : l.loginWelcomeBack,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppDims.s24),
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enabled: !_busy,
                            decoration: InputDecoration(
                              labelText: l.email,
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: t.textSecondary),
                            ),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return l.enterEmail;
                              if (!s.contains('@') || !s.contains('.')) {
                                return l.enterValidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDims.s16),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            enabled: !_busy,
                            decoration: InputDecoration(
                              labelText: l.password,
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: t.textSecondary),
                            ),
                            validator: (v) {
                              // Mirror the server policy (min 8, letters +
                              // digits) so users get an instant message
                              // instead of a generic auth error. Only enforced
                              // on sign-up; sign in accepts whatever the
                              // account already has.
                              if (!_isSignUp) return null;
                              if (!isStrongPassword(v ?? '')) {
                                return l.passwordTooShort;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (_notice != null) ...[
                            const SizedBox(height: AppDims.s16),
                            _messageBox(
                              message: _notice!,
                              icon: Icons.mark_email_read_outlined,
                              color: t.accentStrong,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: AppDims.s16),
                            _messageBox(
                              message: _error!,
                              icon: Icons.error_outline,
                              color: t.danger,
                            ),
                          ],
                          const SizedBox(height: AppDims.s24),
                          _busy
                              ? const SizedBox(
                                  height: 54,
                                  child: Center(
                                    child: SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                )
                              : AppPrimaryButton(
                                  label:
                                      _isSignUp ? l.createAccount : l.signIn,
                                  onPressed: _submit,
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDims.s8),
                  Center(
                    child: AppTextButton(
                      label: _isSignUp ? l.haveAccountSignIn : l.newHereCreate,
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _isSignUp = !_isSignUp;
                                _error = null;
                                _notice = null;
                              }),
                    ),
                  ),
                  // Only at the gate root: let a new user in without an
                  // account so they meet the app before committing. When
                  // this screen is pushed over the launch screen the user
                  // is already a guest, so the shortcut would be noise.
                  if (!Navigator.of(context).canPop())
                    Center(
                      child: AppTextButton(
                        icon: Icons.park_outlined,
                        label: l.loginExploreFirst,
                        onPressed: _busy
                            ? null
                            : () => AuthService.instance.enterGuestMode(),
                      ),
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
