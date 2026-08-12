import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/pixel/pixel.dart';
import '../widgets/status_tree_view.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';

/// The title screen.
///
/// A 16-bit save-file front end: layered sky, a drifting cloud, a repeating
/// ground tile, the **Ancient** status tree centre stage as the brand mark
/// (the same art as the launcher icon), Acorn bobbing beside it, and the
/// wordmark over a big green PRESS START. Start hands off to the dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// The launch hero always shows the Ancient prestige tree as the brand mark,
  /// independent of the account's real status.
  static const _heroSpriteKey = 'ancient';

  /// Acorn's idle bob and the drifting cloud share one clock.
  late final AnimationController _idle;

  // First launch: the dashboard runs the guided tour once we arrive there, so
  // Acorn greets the user at the four-leaf menu and every section pops back to
  // it. Captured when Start is pressed, consumed by the dashboard route.
  bool _runTour = false;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (AppSettings.instance.motionFull) _idle.repeat();
    AppSettings.instance.addListener(_onSettings);
  }

  void _onSettings() {
    if (!mounted) return;
    final motion = AppSettings.instance.motionFull;
    if (motion && !_idle.isAnimating) {
      _idle.repeat();
    } else if (!motion && _idle.isAnimating) {
      _idle.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _idle.dispose();
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

  /// Save-file controls, reactive to [AuthService]. In local-only mode
  /// (no backend configured) accounts don't exist, so we hide them entirely.
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
                style: AppTheme.label(9, t.textTertiary, spacing: 0.8),
              ),
              const SizedBox(height: AppDims.s4),
              _TitleTextButton(label: l.signOut, onTap: _signOut),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TitleTextButton(label: l.signIn, onTap: () => _openLogin()),
            const SizedBox(width: AppDims.s16),
            _TitleTextButton(
              label: l.register,
              onTap: () => _openLogin(signUp: true),
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
    final size = MediaQuery.of(context).size;
    final sceneH = math.min(size.height * 0.48, 420.0);
    final treeSize = math.min(sceneH * 0.62, 230.0);

    return Scaffold(
      body: Column(
        children: [
          // ── The scene: sky, cloud, ground, tree, Acorn ──
          SizedBox(
            height: sceneH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _SkyBackdrop(),
                AnimatedBuilder(
                  animation: _idle,
                  builder: (context, _) {
                    final w = size.width;
                    return Positioned(
                      top: sceneH * 0.12,
                      left: -130 + (w + 260) * _idle.value,
                      child: const Opacity(
                        opacity: 0.85,
                        child: PixelSprite(
                          asset: PixelIcons.cloud,
                          width: 120,
                          height: 60,
                        ),
                      ),
                    );
                  },
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: PixelGround(height: 62),
                ),
                // The tree, planted: its base sinks into the grass band rather
                // than resting on top of it, so it reads as rooted in the
                // ground rather than standing on it.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 46,
                  child: Center(
                    child: StatusTreeView(
                      spriteKey: _heroSpriteKey,
                      size: treeSize,
                    ),
                  ),
                ),
                // Acorn floats in the sky beside the canopy, drifting up and
                // down on a slow sine rather than sitting on the ground.
                Positioned(
                  right: size.width * 0.14,
                  bottom: sceneH * 0.46,
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (context, child) {
                      final float = AppSettings.instance.motionFull
                          ? math.sin(_idle.value * math.pi * 2) * 9
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, float),
                        child: child,
                      );
                    },
                    child: const PixelSpriteSheet(
                      asset: PixelIcons.acorn,
                      size: 52,
                      frames: 2,
                      period: Duration(milliseconds: 3400),
                    ),
                  ),
                ),
                // Hard ink line closing the scene off from the menu below.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(height: 3, color: t.cardBorder),
                ),
              ],
            ),
          ),

          // ── Wordmark + save-file menu ──
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: AppDims.pagePad,
                child: Column(
                  children: [
                    const SizedBox(height: AppDims.s20),
                    Text(
                      'BUDGET TREE',
                      textAlign: TextAlign.center,
                      style: AppTheme.display(
                        math.min(size.width * 0.115, 44),
                        t.textPrimary,
                        spacing: 1,
                      ).copyWith(
                        shadows: [
                          Shadow(
                            color: t.card,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDims.s4),
                    Text(
                      l.homeSlogan.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTheme.label(9, t.textTertiary, spacing: 1.5),
                    ),
                    const Spacer(),
                    PixelButton(
                      label: l.startButton.toUpperCase(),
                      icon: PixelIcons.sprout,
                      onPressed: _start,
                      fontSize: 13,
                    ),
                    const SizedBox(height: AppDims.s12),
                    _accountControls(),
                    const SizedBox(height: AppDims.s12),
                    Text(
                      'DEVELOPED BY FABIAN TURCHETTI',
                      style: AppTheme.label(9, t.textTertiary, spacing: 1.2),
                    ),
                    const SizedBox(height: AppDims.s12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banded sky wash — three flat steps rather than a smooth gradient, so it
/// keeps the limited-palette feel.
class _SkyBackdrop extends StatelessWidget {
  const _SkyBackdrop();

  @override
  Widget build(BuildContext context) {
    final dark = AppTokens.of(context).brightness == Brightness.dark;
    final bands = dark
        ? const [Color(0xFF1D2A38), Color(0xFF243444), Color(0xFF2B3D50)]
        : const [Color(0xFFBFE3F2), Color(0xFFD3ECF7), Color(0xFFE6F5FB)];
    return Column(
      children: [
        Expanded(flex: 44, child: Container(color: bands[0])),
        Expanded(flex: 28, child: Container(color: bands[1])),
        Expanded(flex: 28, child: Container(color: bands[2])),
      ],
    );
  }
}

/// Underlined Silkscreen text action for the title screen's save-file row.
class _TitleTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TitleTextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            label.toUpperCase(),
            style: AppTheme.label(10, t.accentStrong, spacing: 1.0),
          ),
        ),
      ),
    );
  }
}
