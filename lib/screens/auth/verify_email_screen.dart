import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Shown right after sign-up (or when signing in with an unconfirmed email).
/// The user types the 6-digit code Supabase emailed them; on success a session
/// is created and the [AuthGate] swaps this out for the app, so we just pop
/// ourselves to reveal it.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AuthService.instance.verifyEmailOtp(widget.email, _code.text);
      // Session created — the AuthGate root has already rebuilt into the app
      // beneath us, so just step off this pushed screen.
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error =
            e.message.isNotEmpty ? e.message : AppLocalizations.of(context).verifyBadCode);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).somethingWentWrong);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AuthService.instance.resendSignupOtp(widget.email);
      if (mounted) {
        setState(() => _notice = AppLocalizations.of(context).codeResent);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).somethingWentWrong);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                      ),
                      child: const Center(
                        child: AcornMascot(
                          size: 64,
                          speaking: false,
                          expression: AcornExpression.happy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDims.s16),
                  Text(
                    l.verifyTitle,
                    textAlign: TextAlign.center,
                    style: text.headlineMedium,
                  ),
                  const SizedBox(height: AppDims.s8),
                  Text(
                    l.verifyBody(widget.email),
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
                            controller: _code,
                            enabled: !_busy,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.nunito(
                              color: t.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                            decoration: InputDecoration(
                              labelText: l.verifyCodeLabel,
                              counterText: '',
                              prefixIcon: Icon(Icons.pin_outlined,
                                  color: t.textSecondary),
                            ),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.length < 6) return l.enterCode;
                              return null;
                            },
                            onFieldSubmitted: (_) => _verify(),
                          ),
                          if (_notice != null) ...[
                            const SizedBox(height: AppDims.s16),
                            _Banner(
                              icon: Icons.mark_email_read_outlined,
                              color: t.accentStrong,
                              text: _notice!,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: AppDims.s16),
                            _Banner(
                              icon: Icons.error_outline,
                              color: t.danger,
                              text: _error!,
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
                                  label: l.verifyButton,
                                  onPressed: _verify,
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDims.s8),
                  Center(
                    child: AppTextButton(
                      label: l.resendCode,
                      onPressed: _busy ? null : _resend,
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

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
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
              text,
              style: GoogleFonts.nunito(color: t.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
