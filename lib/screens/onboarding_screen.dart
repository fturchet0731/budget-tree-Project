import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/profile_service.dart';
import '../theme/app_theme.dart';

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
        if (mounted) setState(() => _error = 'That username is taken. Try another.');
        return;
      }
      await ProfileService.instance.claimUsername(
        username,
        displayName: display.isEmpty ? null : display,
      );
      await widget.onComplete();
    } on UsernameTakenException {
      if (mounted) setState(() => _error = 'That username is taken. Try another.');
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Couldn\'t save your profile. Check your connection and try again.');
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
                      const Icon(Icons.eco_rounded,
                          color: AppColors.lightLeaf, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to your grove',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.stoneBeigeColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick a username to finish setting up your account. '
                        'It\'s how friends find you — but you can plant and grow '
                        'your forest whether or not you ever add any.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _username,
                        autocorrect: false,
                        enableSuggestions: false,
                        enabled: !_busy,
                        textInputAction: TextInputAction.next,
                        style:
                            const TextStyle(color: AppColors.stoneBeigeColor),
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          helperText: '3-20 letters, numbers or _',
                          helperStyle: TextStyle(color: AppColors.mossGreen),
                          prefixIcon: Icon(Icons.alternate_email,
                              color: AppColors.mossGreen),
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Choose a username';
                          if (!ProfileService.usernamePattern.hasMatch(s)) {
                            return '3-20 letters, numbers or underscore';
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
                        decoration: const InputDecoration(
                          labelText: 'Display name (optional)',
                          helperText: 'Shown to friends instead of @username',
                          helperStyle: TextStyle(color: AppColors.mossGreen),
                          prefixIcon: Icon(Icons.badge_outlined,
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
                                'Enter the forest',
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
