import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/tree_health_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_tokens.dart';
import '../widgets/acorn_mascot.dart';
import '../widgets/status_tree_view.dart';
import '../widgets/ui/app_buttons.dart';
import '../widgets/ui/entrance.dart';
import '../widgets/ui/illustration_card.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';

/// Launch screen of the redesign: a calm neutral canvas with one hero
/// illustration card. The tree in it is the account's **status tree** — the
/// same living consistency tree the dashboard and Acorn's Hub show — so the
/// first thing the user sees on opening the app is where they stand right now,
/// with Acorn watching from the grass. Start hands off to the dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // The account's current status, replayed from the check-in ledger. Drives
  // which of the sixteen status trees the hero shows. Defaults to the neutral
  // fresh tier until the ledger loads (and for brand-new accounts).
  TreeHealth _health = TreeHealth.fresh;

  // First launch: the dashboard runs the guided tour once we arrive there, so
  // Acorn greets the user at the four-leaf menu and every section pops back to
  // it. Captured when Start is pressed, consumed by the dashboard route.
  bool _runTour = false;

  @override
  void initState() {
    super.initState();
    _loadHealth();
    AppSettings.instance.addListener(_onSettings);
  }

  Future<void> _loadHealth() async {
    final health = await TreeHealthService.current();
    if (!mounted) return;
    setState(() => _health = health);
  }

  void _onSettings() {
    if (!mounted) return;
    // Rebuild so theme / motion changes take effect (StatusTreeView re-syncs
    // its own animation on rebuild).
    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
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
      // The user may have answered a check-in in there, so refresh the tree.
      _loadHealth();
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
    final heroH = math.min(MediaQuery.of(context).size.height * 0.40, 420.0);
    final treeSize = math.min(heroH * 0.72, 300.0);

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
                  illustration: RepaintBoundary(
                    child: Stack(
                      children: [
                        // The account's living status tree, centred.
                        Center(
                          child: StatusTreeView(
                            spriteKey: _health.spriteKey,
                            size: treeSize,
                          ),
                        ),
                        // Acorn watches from the grass, bottom-right.
                        const Align(
                          alignment: Alignment(0.82, 0.96),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: AcornMascot(size: 60, sway: true),
                          ),
                        ),
                      ],
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
                style: GoogleFonts.nunito(color: t.textTertiary, fontSize: 11),
              ),
              const SizedBox(height: AppDims.s12),
            ],
          ),
        ),
      ),
    );
  }
}
