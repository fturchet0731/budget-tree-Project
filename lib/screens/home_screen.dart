import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_tokens.dart';
import '../widgets/acorn_mascot.dart';
import '../widgets/ui/app_buttons.dart';
import '../widgets/ui/entrance.dart';
import '../widgets/ui/illustration_card.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';

/// Launch screen of the redesign: a calm neutral canvas with one hero
/// illustration card where a flat budget tree grows in and Acorn watches
/// from the grass. Start hands off to the dashboard with a quick fade.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // One-shot grow of the hero tree on arrival.
  late final AnimationController _grow;
  // Gentle idle sway of the canopy, gated by the Motion setting.
  late final AnimationController _sway;

  // First launch: the dashboard runs the guided tour once we arrive there, so
  // Acorn greets the user at the four-leaf menu and every section pops back to
  // it. Captured when Start is pressed, consumed by the dashboard route.
  bool _runTour = false;

  @override
  void initState() {
    super.initState();
    final m = AppSettings.instance.motionMultiplier;
    _grow = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (900 * m).round()),
    )..forward();
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    if (AppSettings.instance.motionFull) _sway.repeat();
    AppSettings.instance.addListener(_onSettings);
  }

  void _onSettings() {
    if (!mounted) return;
    final motion = AppSettings.instance.motionFull;
    if (motion && !_sway.isAnimating) {
      _sway.repeat();
    } else if (!motion && _sway.isAnimating) {
      _sway.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _grow.dispose();
    _sway.dispose();
    super.dispose();
  }

  void _start() {
    // First time the user presses Start, the acorn walks them through the
    // whole app. The dashboard runs the tour on arrival so Acorn shows the
    // four-leaf menu first and each section pops back to it.
    _runTour = !AppSettings.instance.tutorialSeen;
    Navigator.of(context).push(_dashboardRoute(runTour: _runTour)).then((_) {
      if (!mounted) return;
      _runTour = false;
      // Replay the hero grow when the user comes back to the launch screen.
      _grow.forward(from: 0);
      setState(() {});
    });
  }

  Route _dashboardRoute({bool runTour = false}) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, a, _) => DashboardScreen(runTour: runTour),
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
        child: child,
      ),
    );
  }

  void _openLogin({bool signUp = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(startInSignUp: signUp)),
    );
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).signedOut),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// The launch-screen account controls, reactive to [AuthService]. In
  /// local-only mode (no backend configured) accounts don't exist, so we hide
  /// them entirely; otherwise we show Sign In / Register when signed out and a
  /// Sign Out button when signed in.
  Widget _accountControls() {
    final auth = AuthService.instance;
    if (!auth.isConfigured) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        final l = AppLocalizations.of(context);
        final t = AppTokens.of(context);
        if (auth.isSignedIn) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                auth.currentUser?.email ?? '',
                style: GoogleFonts.nunito(
                  color: t.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              AppTextButton(label: l.signOut, onPressed: _signOut),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTextButton(label: l.signIn, onPressed: () => _openLogin()),
            const SizedBox(width: 8),
            AppTextButton(
              label: l.register,
              onPressed: () => _openLogin(signUp: true),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final heroH = math.min(
      MediaQuery.of(context).size.height * 0.40,
      420.0,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppDims.pagePad,
          child: Column(
            children: [
              const Spacer(flex: 2),
              Entrance(
                child: IllustrationCard(
                  height: heroH,
                  padding: EdgeInsets.zero,
                  illustration: AnimatedBuilder(
                    animation: Listenable.merge([_grow, _sway]),
                    builder: (context, _) => CustomPaint(
                      painter: _HeroTreePainter(
                        grow: Curves.easeOutCubic.transform(
                          AppSettings.instance.motionMultiplier == 0
                              ? 1.0
                              : _grow.value,
                        ),
                        sway: AppSettings.instance.motionFull
                            ? math.sin(_sway.value * math.pi * 2)
                            : 0,
                        dark: t.brightness == Brightness.dark,
                      ),
                      child: const Align(
                        alignment: Alignment(0.78, 1.0),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: AcornMascot(size: 64, sway: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s32),
              Entrance(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  'Budget Tree',
                  textAlign: TextAlign.center,
                  style: text.displayLarge,
                ),
              ),
              const SizedBox(height: AppDims.s8),
              Entrance(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  l.homeSlogan,
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: t.textSecondary),
                ),
              ),
              const Spacer(flex: 2),
              Entrance(
                delay: const Duration(milliseconds: 240),
                child: AppPrimaryButton(
                  label: l.startButton,
                  icon: Icons.play_arrow_rounded,
                  onPressed: _start,
                ),
              ),
              const SizedBox(height: AppDims.s8),
              Entrance(
                delay: const Duration(milliseconds: 300),
                child: _accountControls(),
              ),
              const SizedBox(height: AppDims.s12),
              Text(
                'Developed by Fabian Turchetti',
                style: GoogleFonts.nunito(
                  color: t.textTertiary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppDims.s12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat, modern hero tree: a warm trunk, bold overlapping conifer foliage
/// discs, a soft ground band, and a few floating leaves. [grow] 0..1 raises
/// the trunk then pops the canopy; [sway] adds a gentle idle lean.
class _HeroTreePainter extends CustomPainter {
  final double grow;
  final double sway;
  final bool dark;

  _HeroTreePainter({
    required this.grow,
    required this.sway,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final groundY = h * 0.86;

    // Ground: a wide flat mound.
    final ground = Paint()
      ..color = dark ? const Color(0xFF243014) : Conifer.c200;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + h * 0.10),
        width: w * 0.92,
        height: h * 0.26,
      ),
      ground,
    );

    // Trunk grows first (0 → 0.45 of the timeline).
    final trunkT = (grow / 0.45).clamp(0.0, 1.0);
    final trunkH = h * 0.42 * trunkT;
    final trunkW = w * 0.075;
    final trunkTop = groundY - trunkH;
    final lean = sway * w * 0.004;
    final trunk = Paint()..color = const Color(0xFF8A6B4F);
    final trunkPath = Path()
      ..moveTo(cx - trunkW * 0.62, groundY)
      ..quadraticBezierTo(
        cx - trunkW * 0.40, groundY - trunkH * 0.55,
        cx - trunkW * 0.34 + lean, trunkTop,
      )
      ..lineTo(cx + trunkW * 0.34 + lean, trunkTop)
      ..quadraticBezierTo(
        cx + trunkW * 0.40, groundY - trunkH * 0.55,
        cx + trunkW * 0.62, groundY,
      )
      ..close();
    canvas.drawPath(trunkPath, trunk);
    // One branch on each side.
    if (trunkT > 0.6) {
      final branch = Paint()
        ..color = const Color(0xFF8A6B4F)
        ..strokeWidth = trunkW * 0.34
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final bt = ((trunkT - 0.6) / 0.4).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(cx, groundY - trunkH * 0.55),
        Offset(cx - w * 0.10 * bt, groundY - trunkH * 0.78 * bt - trunkH * 0.1),
        branch,
      );
      canvas.drawLine(
        Offset(cx, groundY - trunkH * 0.42),
        Offset(cx + w * 0.09 * bt, groundY - trunkH * 0.62 * bt - trunkH * 0.1),
        branch,
      );
    }

    // Canopy pops after the trunk (0.35 → 1.0), back-eased.
    final canopyT = ((grow - 0.35) / 0.65).clamp(0.0, 1.0);
    final pop = Curves.easeOutBack.transform(canopyT);
    if (pop > 0.01) {
      final cy = trunkTop - h * 0.02;
      final r = w * 0.16 * pop;
      final swayX = sway * w * 0.008;

      void disc(double dx, double dy, double scale, Color color) {
        canvas.drawCircle(
          Offset(cx + dx * w + swayX * (1 + dy.abs() * 2), cy + dy * h),
          r * scale,
          Paint()..color = color,
        );
      }

      // Back to front: deep, mid, light discs make one bold flat canopy.
      disc(-0.13, -0.02, 0.92, Conifer.c600);
      disc(0.13, -0.02, 0.92, Conifer.c600);
      disc(-0.07, -0.09, 1.0, Conifer.c500);
      disc(0.08, -0.08, 1.0, Conifer.c500);
      disc(0.0, -0.15, 1.08, Conifer.c400);
      disc(-0.02, -0.05, 0.7, Conifer.c300);
    }

    // A few floating leaves drift beside the tree once it's grown.
    if (canopyT > 0.7) {
      final leafPaint = Paint()..color = Conifer.c400;
      final fade = ((canopyT - 0.7) / 0.3).clamp(0.0, 1.0);
      leafPaint.color = leafPaint.color.withValues(alpha: fade);
      void leaf(double x, double y, double s, double angle) {
        canvas.save();
        canvas.translate(x * w + sway * 6, y * h + sway * 3);
        canvas.rotate(angle + sway * 0.15);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 8 * s),
          leafPaint,
        );
        canvas.restore();
      }

      leaf(0.16, 0.30, 1.0, 0.5);
      leaf(0.82, 0.22, 0.8, -0.4);
      leaf(0.75, 0.48, 0.7, 0.9);
      leaf(0.22, 0.55, 0.8, -0.8);
    }
  }

  @override
  bool shouldRepaint(_HeroTreePainter old) =>
      old.grow != grow || old.sway != sway || old.dark != dark;
}
