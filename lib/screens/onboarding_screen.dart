import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/acorn_mascot.dart';

/// Forced first-run onboarding for a signed-in user who hasn't claimed a
/// profile yet. Every account needs a username (it's how friends find them and
/// the key the social tables hang off), so this gates the app: the user can't
/// reach the home flow until they pick one. Reached only via the
/// [OnboardingGate]; on success it calls [onComplete] so the gate re-resolves
/// and shows the app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  /// Invoked after the username is claimed and saved to Supabase.
  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final username = _username.text.trim();
      final display = _displayName.text.trim();
      if (!await ProfileService.instance.isUsernameAvailable(username)) {
        if (mounted) {
          setState(() => _error = AppLocalizations.of(context).usernameTaken);
        }
        return;
      }
      await ProfileService.instance.claimUsername(
        username,
        displayName: display.isEmpty ? null : display,
      );
      await widget.onComplete();
    } on UsernameTakenException {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).usernameTaken);
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context).onboardingSaveError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// What Acorn says, reacting to the form state.
  String _acornLine(AppLocalizations l) {
    if (_busy) return l.onboardingAcornBusy;
    if (_error != null) return l.onboardingAcornError;
    return l.onboardingAcornWelcome;
  }

  AcornExpression get _acornFace =>
      _error != null ? AcornExpression.idle : AcornExpression.happy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                      AcornMascot(
                        size: 104,
                        speaking: !_busy,
                        expression: _acornFace,
                      ),
                      const SizedBox(height: 12),
                      _AcornBubble(text: _acornLine(l)),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _username,
                        autocorrect: false,
                        enableSuggestions: false,
                        enabled: !_busy,
                        textInputAction: TextInputAction.next,
                        style:
                            const TextStyle(color: AppColors.stoneBeigeColor),
                        decoration: InputDecoration(
                          labelText: l.username,
                          helperText: l.onboardingUsernameHelper,
                          helperStyle:
                              const TextStyle(color: AppColors.mossGreen),
                          prefixIcon: const Icon(Icons.alternate_email,
                              color: AppColors.mossGreen),
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return l.chooseUsername;
                          if (!ProfileService.usernamePattern.hasMatch(s)) {
                            return l.usernameRule;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _displayName,
                        enabled: !_busy,
                        textInputAction: TextInputAction.done,
                        style:
                            const TextStyle(color: AppColors.stoneBeigeColor),
                        decoration: InputDecoration(
                          labelText: l.onboardingDisplayNameLabel,
                          helperText: l.onboardingDisplayNameHelper,
                          helperStyle:
                              const TextStyle(color: AppColors.mossGreen),
                          prefixIcon: const Icon(Icons.badge_outlined,
                              color: AppColors.mossGreen),
                        ),
                        onFieldSubmitted: (_) => _claim(),
                      ),
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
                        onPressed: _busy ? null : _claim,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                l.onboardingEnterForest,
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold, fontSize: 16),
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

/// A small rounded speech bubble with a pointer up toward Acorn. Animates its
/// text so each new line from Acorn feels like he's talking.
class _AcornBubble extends StatelessWidget {
  const _AcornBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Little pointer triangle toward Acorn.
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 18,
            height: 9,
            color: Colors.black.withValues(alpha: 0.30),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.lightLeaf.withValues(alpha: 0.45)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              text,
              key: ValueKey(text),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.stoneBeigeColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width / 2, 0)
    ..lineTo(0, size.height)
    ..lineTo(size.width, size.height)
    ..close();

  @override
  bool shouldReclip(_TriangleClipper old) => false;
}
