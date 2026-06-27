import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../tutorial/tutorial_tour.dart';
import '../widgets/acorn_mascot.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';

/// Worm's-eye launch screen. You open at the base of a giant tree looking
/// straight up the tapering trunk; pressing Start fast-travels the camera
/// up the trunk into the dense canopy, then hands off to the dashboard
/// (the four-leaf menu). Recreated in Flutter from the Claude Design
/// "Budget Tree Launch" prototype, palette-aware across the app's three
/// themes, with the creator credit carried over from the old home screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Phase { ground, ascend, arrived }

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // One-shot launch drive (0 → 1 over ascentMs). Powers every parallax
  // translation, blur, and overlay fade.
  late final AnimationController _ascent;
  // Short looping controller for the whoosh: speed-line streaks + the
  // tumble of shaken-loose leaves. Only runs during the launch.
  late final AnimationController _fx;
  // Slow idle breeze for grass sway — gated by the Motion setting so the
  // ground state costs nothing on low-end phones when motion is off.
  late final AnimationController _breeze;
  // Gentle button pulse at rest.
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;
  // Entrance: title fades in, button drifts up.
  late final AnimationController _entry;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _buttonSlide;
  // Eased view of ascent — slow-in, fast middle, gentle arrival.
  late final Animation<double> _ascentAnim;
  // Slow leaf drift — long period so leaves fall gently. Decoupled from the
  // breeze so leaf speed is independent of grass sway speed.
  late final AnimationController _leafFall;
  // Slow horizontal cloud drift across the sky.
  late final AnimationController _clouds;

  _Phase _phase = _Phase.ground;

  static const _ascentMs = 1600;

  @override
  void initState() {
    super.initState();
    _ascent = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _ascentMs))
      ..addStatusListener(_onAscentStatus);
    _fx = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _breeze = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    _leafFall = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16000));
    _clouds = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 60000));
    if (AppSettings.instance.motionFull) {
      _breeze.repeat();
      _leafFall.repeat();
      _clouds.repeat();
    }
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _entry = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _entryFade = CurvedAnimation(
        parent: _entry, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entry,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
    _ascentAnim = CurvedAnimation(
      parent: _ascent,
      curve: Curves.easeInOutCubic,
    );
    _entry.forward();

    AppSettings.instance.addListener(_onSettings);
  }

  void _onSettings() {
    if (!mounted) return;
    final motion = AppSettings.instance.motionFull;
    if (motion && !_breeze.isAnimating) {
      _breeze.repeat();
      _leafFall.repeat();
      _clouds.repeat();
    } else if (!motion && _breeze.isAnimating && _phase == _Phase.ground) {
      _breeze.stop();
      _leafFall.stop();
      _clouds.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _ascent.dispose();
    _fx.dispose();
    _breeze.dispose();
    _leafFall.dispose();
    _clouds.dispose();
    _pulse.dispose();
    _entry.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_phase != _Phase.ground) return;
    // First time the user presses Start, the acorn walks them through the
    // whole app before we climb the tree. They can skip it; either way we
    // only auto-play it once.
    if (!AppSettings.instance.tutorialSeen) {
      await GuidedTour.start(context);
      await AppSettings.instance.setTutorialSeen(true);
      if (!mounted) return;
    }
    _beginAscent();
  }

  void _beginAscent() {
    if (_phase != _Phase.ground) return;
    setState(() => _phase = _Phase.ascend);
    // The whoosh needs motion even if idle motion is disabled.
    if (!_breeze.isAnimating) _breeze.repeat();
    _fx.repeat();
    _ascent.forward(from: 0);
  }

  void _onAscentStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _phase = _Phase.arrived);
      _fx.stop();
      // We've arrived deep in the leaves — hand off to the four-leaf menu.
      Navigator.of(context).push(_dashboardRoute()).then((_) {
        // Coming back from the dashboard resets us to the ground state.
        if (!mounted) return;
        _ascent.reset();
        setState(() => _phase = _Phase.ground);
      });
    }
  }

  Route _dashboardRoute() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, a, _) => const DashboardScreen(),
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeIn),
        child: child,
      ),
    );
  }

  void _openLogin({bool signUp = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(startInSignUp: signUp),
      ),
    );
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkBark,
        content: Text('Signed out 🌱',
            style: GoogleFonts.nunito(color: Colors.white)),
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
        if (auth.isSignedIn) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                auth.currentUser?.email ?? 'Signed in',
                style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _ghostButton('Sign Out', onTap: _signOut),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ghostButton('Sign In', onTap: () => _openLogin()),
            const SizedBox(width: 12),
            _solidButton('Register', onTap: () => _openLogin(signUp: true)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;
    final theme = _LaunchTheme.of(AppSettings.instance.palette);
    final motion = AppSettings.instance.motionFull;

    // World strip geometry — a long trunk that towers up into a canopy.
    final worldH = h * 3.1;
    final worldTravel = worldH - h * 1.15; // land deep inside the canopy
    final skyTravel = worldTravel * 0.34; // slow parallax
    final fgTravel = worldTravel * 1.30; // foreground flies away fast

    return Scaffold(
      backgroundColor: theme.skyBottom,
      body: AnimatedBuilder(
        animation: _ascentAnim,
        builder: (context, _) {
          final p = _ascentAnim.value;
          final moved = _phase != _Phase.ground;
          // Overlays bloom in over the back half of the ascent.
          final arriveT = ((p - 0.55) / 0.45).clamp(0.0, 1.0);
          final speedT = _phase == _Phase.ascend
              ? (1.0 - (p - 0.5).abs() * 2).clamp(0.0, 1.0)
              : 0.0;

          return Stack(
            children: [
              // ── SKY (slow parallax) ───────────────
              Transform.translate(
                offset: Offset(0, p * skyTravel),
                child: Container(
                  width: w,
                  height: h * 1.4,
                  decoration: BoxDecoration(gradient: AppPalettes.sky()),
                ),
              ),

              // ── CLOUDS drifting across the sky (slow parallax) ──
              Transform.translate(
                offset: Offset(0, p * skyTravel),
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _clouds,
                      builder: (_, a) => CustomPaint(
                        painter: _CloudPainter(t: _clouds.value, theme: theme),
                        size: Size(w, h * 1.4),
                      ),
                    ),
                  ),
                ),
              ),

              // ── SKY PARTICLES: fireflies / pollen (ground phase only) ──
              if (!moved)
                IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _breeze,
                      builder: (_, a) => CustomPaint(
                        painter: _ParticlePainter(
                            t: _breeze.value, theme: theme),
                        size: Size(w, h),
                      ),
                    ),
                  ),
                ),

              // ── WORLD: trunk + branches + canopy ──
              // Drawn in screen space with an internal scroll so the layer
              // stays screen-sized (no giant offscreen texture). Skia culls
              // the off-screen parts of the tall strip cheaply.
              _maybeBlur(
                enabled: motion && _phase == _Phase.ascend,
                sigma: speedT * 2.2,
                child: CustomPaint(
                  painter: _WorldPainter(
                    theme: theme,
                    worldH: worldH,
                    scroll: p * worldTravel,
                  ),
                  size: Size(w, h),
                ),
              ),

              // ── FOREGROUND: soil rim + dense grass ─
              Transform.translate(
                offset: Offset(0, p * fgTravel),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _breeze,
                    builder: (context, _) => CustomPaint(
                      painter: _ForegroundPainter(
                        theme: theme,
                        sway: motion
                            ? math.sin(_breeze.value * math.pi * 2)
                            : 0,
                      ),
                      size: Size(w, h),
                    ),
                  ),
                ),
              ),

              // ── IDLE LEAF FALL (gentle drift on title screen) ──
              if (!moved)
                IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _leafFall,
                      builder: (_, a) => CustomPaint(
                        painter: _IdleLeafPainter(
                            t: _leafFall.value, theme: theme),
                        size: Size(w, h),
                      ),
                    ),
                  ),
                ),

              // ── FALLING LEAVES (shaken loose) ─────
              if (moved)
                IgnorePointer(
                  child: Opacity(
                    opacity: 1.0,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _fx,
                        builder: (context, _) => CustomPaint(
                          painter: _LeafFallPainter(
                              t: _fx.value, theme: theme),
                          size: Size(w, h),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── SPEED LINES (whoosh) ──────────────
              if (speedT > 0.01)
                IgnorePointer(
                  child: Opacity(
                    opacity: speedT,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _fx,
                        builder: (context, _) => CustomPaint(
                          painter: _SpeedLinesPainter(_fx.value),
                          size: Size(w, h),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── CANOPY SHADE (tucked under branches) ─
              if (arriveT > 0.01)
                IgnorePointer(
                  child: Opacity(
                    opacity: arriveT,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -1.1),
                          radius: 1.1,
                          colors: [
                            theme.shade.withValues(alpha: 0.62),
                            theme.shade.withValues(alpha: 0.22),
                            theme.shade.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.45, 0.72],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── DAPPLED LIGHT through the leaves ──
              if (arriveT > 0.01)
                IgnorePointer(
                  child: Opacity(
                    opacity: arriveT * 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.45, -0.65),
                          radius: 0.9,
                          colors: [
                            theme.glow.withValues(alpha: 0.85),
                            theme.glow.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── OVERHEAD BRANCH FRINGE arching over us ─
              if (arriveT > 0.01)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: h * 0.22,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: arriveT,
                      child: CustomPaint(
                        painter: _OverheadFringePainter(theme),
                      ),
                    ),
                  ),
                ),

              // ── START UI (fades out on launch) ────
              IgnorePointer(
                ignoring: _phase != _Phase.ground,
                child: Opacity(
                  opacity: (1.0 - p * 1.6).clamp(0.0, 1.0),
                  child: _buildStartUi(theme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _maybeBlur({
    required bool enabled,
    required double sigma,
    required Widget child,
  }) {
    if (!enabled || sigma < 0.05) return child;
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }

  Widget _buildStartUi(_LaunchTheme theme) {
    return SafeArea(
      child: Stack(
        children: [
          // ── TITLE + BUTTONS — one centred group ──
          Align(
            alignment: const Alignment(0, -0.12),
            child: FadeTransition(
              opacity: _entryFade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Acorn mascot, swaying idly above the title.
                  const AcornMascot(size: 96, sway: true),
                  const SizedBox(height: 8),
                  Text(
                    'Budget Tree',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 46,
                      height: 1.0,
                      letterSpacing: 0.5,
                      shadows: [
                        const Shadow(
                            color: Color(0x30000000), offset: Offset(0, 3)),
                        Shadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            offset: const Offset(0, 8),
                            blurRadius: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Climb to grow your savings',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 17,
                      shadows: [
                        Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                  // Buttons sit directly beneath the title.
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: _buttonSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: _startButton(theme),
                        ),
                        const SizedBox(height: 14),
                        _accountControls(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Credit pinned to the bottom ──
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _entryFade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Developed by Fabian Turchetti',
                  style: GoogleFonts.nunito(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _startButton(_LaunchTheme theme) {
    return GestureDetector(
      onTap: _start,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        decoration: BoxDecoration(
          color: theme.button,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                offset: const Offset(0, 6)),
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 14)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play triangle
            CustomPaint(
              size: const Size(13, 16),
              painter: _PlayTrianglePainter(),
            ),
            const SizedBox(width: 12),
            Text(
              'Start',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghostButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _solidButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Text(label,
            style: GoogleFonts.nunito(
                color: const Color(0xFF2E7D39),
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Palette-aware colour set for the launch scene
// ──────────────────────────────────────────────

class _LaunchTheme {
  final Color leafBackstop;
  final Color leafDark;
  final Color leafMid;
  final Color leafLight;
  final Color branchA;
  final Color branchB;
  final Color trunkA;
  final Color trunkB;
  final Color trunkKnot;
  final List<Color> grass;
  final Color soilTop;
  final Color soilRim1;
  final Color soilRim2;
  final Color bushDark;
  final Color bushLight;
  final Color glow;
  final Color shade;
  final Color button;
  final Color skyBottom;
  final Color cloud;

  const _LaunchTheme({
    required this.leafBackstop,
    required this.leafDark,
    required this.leafMid,
    required this.leafLight,
    required this.branchA,
    required this.branchB,
    required this.trunkA,
    required this.trunkB,
    required this.trunkKnot,
    required this.grass,
    required this.soilTop,
    required this.soilRim1,
    required this.soilRim2,
    required this.bushDark,
    required this.bushLight,
    required this.glow,
    required this.shade,
    required this.button,
    required this.skyBottom,
    required this.cloud,
  });

  static _LaunchTheme of(AppPalette palette) {
    switch (palette) {
      case AppPalette.forestDark:
        return const _LaunchTheme(
          leafBackstop: Color(0xFF237A37),
          leafDark: Color(0xFF2A8640),
          leafMid: Color(0xFF46A851),
          leafLight: Color(0xFF82D873),
          branchA: Color(0xFF8A5530),
          branchB: Color(0xFF6A4126),
          trunkA: Color(0xFF9A6038),
          trunkB: Color(0xFF855230),
          trunkKnot: Color(0xFF5B3A22),
          grass: [Color(0xFF256B32), Color(0xFF2C7A3A), Color(0xFF338A40)],
          soilTop: Color(0xFF4F3018),
          soilRim1: Color(0xFF6E4429),
          soilRim2: Color(0xFF46290F),
          bushDark: Color(0xFF2C7338),
          bushLight: Color(0xFF368A44),
          glow: Color(0xFFFFF7D2),
          shade: Color(0xFF123418),
          button: Color(0xFF46B257),
          skyBottom: Color(0xFF7CB342),
          cloud: Color(0xFFF7FBFF),
        );
      case AppPalette.midnight:
        return const _LaunchTheme(
          leafBackstop: Color(0xFF10331F),
          leafDark: Color(0xFF154029),
          leafMid: Color(0xFF1F5436),
          leafLight: Color(0xFF356E48),
          branchA: Color(0xFF3A2A1C),
          branchB: Color(0xFF2A1E14),
          trunkA: Color(0xFF4A3424),
          trunkB: Color(0xFF38271A),
          trunkKnot: Color(0xFF241A10),
          grass: [Color(0xFF0A1A12), Color(0xFF12281C), Color(0xFF1A3A26)],
          soilTop: Color(0xFF1A0F08),
          soilRim1: Color(0xFF241608),
          soilRim2: Color(0xFF120A04),
          bushDark: Color(0xFF0F2A1C),
          bushLight: Color(0xFF184028),
          glow: Color(0xFFB3C9E0),
          shade: Color(0xFF05140C),
          button: Color(0xFF2B6E48),
          skyBottom: Color(0xFF12281C),
          cloud: Color(0xFF3A4A63),
        );
      case AppPalette.twilight:
        return const _LaunchTheme(
          leafBackstop: Color(0xFF2C3A1A),
          leafDark: Color(0xFF3A4A20),
          leafMid: Color(0xFF566B2A),
          leafLight: Color(0xFF8A9C44),
          branchA: Color(0xFF6B4A2A),
          branchB: Color(0xFF513620),
          trunkA: Color(0xFF7A552F),
          trunkB: Color(0xFF5E3F22),
          trunkKnot: Color(0xFF3E2818),
          grass: [Color(0xFF44521F), Color(0xFF55642A), Color(0xFF6B7A38)],
          soilTop: Color(0xFF2A1820),
          soilRim1: Color(0xFF4A2C30),
          soilRim2: Color(0xFF2A1820),
          bushDark: Color(0xFF3A4A20),
          bushLight: Color(0xFF566B2A),
          glow: Color(0xFFFFB870),
          shade: Color(0xFF1A0E14),
          button: Color(0xFFC56A4A),
          skyBottom: Color(0xFF3D3528),
          cloud: Color(0xFFF3D9C2),
        );
    }
  }
}

// ──────────────────────────────────────────────
// WORLD: tapering trunk, branches, dense canopy
// ──────────────────────────────────────────────

class _WorldPainter extends CustomPainter {
  final _LaunchTheme theme;
  final double worldH;
  final double scroll; // 0 at ground → worldTravel deep in the canopy
  _WorldPainter({
    required this.theme,
    required this.worldH,
    required this.scroll,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // strip-space y=0 is the canopy top, y=worldH is the trunk base which
    // sits at the visible bottom edge at rest. We anchor the strip bottom
    // to the screen bottom and add the scroll: as scroll grows the canopy
    // (top of the strip) travels down into view. Skia culls everything
    // outside the screen rect so the off-screen trunk costs nothing.
    final dy = (h - worldH) + scroll;
    canvas.save();
    canvas.translate(0, dy);

    final canopyBottom = worldH - h * 1.45;
    _paintCanopy(canvas, w, canopyBottom);      // canopy first
    _paintLowBranches(canvas, w, canopyBottom); // branches next — roots buried under trunk
    _paintTrunk(canvas, w, canopyBottom);        // trunk last — covers branch roots cleanly

    canvas.restore();
  }

  void _paintTrunk(Canvas canvas, double w, double canopyBottom) {
    final topY = canopyBottom;
    final botY = worldH;

    // Trapezoid: wide at base (worm's-eye), narrow where it meets the canopy.
    final path = Path()
      ..moveTo(w * 0.06, botY)
      ..lineTo(w * 0.94, botY)
      ..lineTo(w * 0.63, topY)
      ..lineTo(w * 0.37, topY)
      ..close();

    final trunkRect = Rect.fromLTRB(w * 0.06, topY, w * 0.94, botY);

    // Same 5-stop bark gradient as the dashboard's _BranchTrellisPainter trunk
    // — so the tree looks identical on both the launch screen and the menu.
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF1A0C06),
            Color(0xFF5D4037),
            Color(0xFF8D6E63),
            Color(0xFF5D4037),
            Color(0xFF1A0C06),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(trunkRect),
    );

    // Horizontal bark wrinkles — matching the dashboard trunk texture.
    canvas.save();
    canvas.clipPath(path);
    final trunkH = botY - topY;
    final bark = Paint()
      ..color = const Color(0xFF1A0C06).withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rng = math.Random(7);
    final rows = (trunkH / 46).round();
    for (int i = 1; i <= rows; i++) {
      final t = i / (rows + 1);
      final y = topY + trunkH * t + (rng.nextDouble() - 0.5) * 8;
      // Trunk half-width at this height (wide at base, narrow at canopy).
      final hw = (w * 0.44) * t + (w * 0.13) * (1 - t);
      canvas.drawLine(
          Offset(w * 0.5 - hw * 0.82, y), Offset(w * 0.5 + hw * 0.82, y), bark);
    }
    canvas.restore();

    // Knots with deep radial gradient.
    for (final (kx, ky, kw, kh) in [
      (w * 0.44, botY - 480, 50.0, 66.0),
      (w * 0.52, botY - 250, 38.0, 52.0),
      (w * 0.38, botY - 735, 32.0, 46.0),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(kx, ky), width: kw, height: kh),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(kx, ky - kh * 0.08), kw * 0.48,
            [const Color(0xFF1A0C06), const Color(0xFF5D4037)],
            [0.3, 1.0],
          ),
      );
    }
  }

  void _paintLowBranches(Canvas canvas, double w, double canopyBottom) {
    final base = worldH;
    final trunkSpan = worldH - canopyBottom;

    // Interpolate the trunk's left/right edges at any strip-y so branches
    // root precisely at the bark surface with no floating gap.
    double lx(double y) {
      final t = ((worldH - y) / trunkSpan).clamp(0.0, 1.0);
      return w * (0.06 + t * 0.31);
    }
    double rx(double y) {
      final t = ((worldH - y) / trunkSpan).clamp(0.0, 1.0);
      return w * (0.94 - t * 0.31);
    }

    // (startY, length, angleDeg, goLeft)
    final branches = <(double, double, double, bool)>[
      (base - 340,  220, -24, true),
      (base - 430,  228,  20, false),
      (base - 580,  185, -17, true),
      (base - 650,  190,  16, false),
      (base - 870,  155, -13, true),
      (base - 930,  158,  14, false),
    ];
    for (final (sy, len, deg, left) in branches) {
      // Root the branch INSIDE the trunk body (30px past the bark edge) so the
      // later-painted trunk covers the joint and the branch emerges seamlessly.
      final sx = left ? lx(sy) + 30 : rx(sy) - 30;
      final rad = deg * math.pi / 180;
      final dir = left ? -1 : 1;
      final ex = sx + dir * len * math.cos(rad);
      final ey = sy + len * math.sin(rad);
      _branch(canvas, Offset(sx, sy), Offset(ex, ey), 36);
      _clump(canvas, Offset(ex, ey), 92, seed: (sx + sy).toInt());
    }
  }

  /// Curved, tapering branch matching the dashboard tree's branch style:
  /// a quadratic bezier with an organic outward/downward droop, sampled into
  /// a ribbon that narrows from [w0] at the trunk to a fine tip.
  void _branch(Canvas canvas, Offset start, Offset end, double w0) {
    const w1 = 4.0;
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final outward = (end.dx - start.dx).sign;
    final ctrl = Offset(mid.dx + outward * 24, mid.dy + 18);

    const steps = 20;
    final left = <Offset>[];
    final right = <Offset>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final mt = 1 - t;
      final x = mt * mt * start.dx + 2 * mt * t * ctrl.dx + t * t * end.dx;
      final y = mt * mt * start.dy + 2 * mt * t * ctrl.dy + t * t * end.dy;
      final thick = w0 + (w1 - w0) * t;
      final dx = 2 * mt * (ctrl.dx - start.dx) + 2 * t * (end.dx - ctrl.dx);
      final dy = 2 * mt * (ctrl.dy - start.dy) + 2 * t * (end.dy - ctrl.dy);
      final dl = math.sqrt(dx * dx + dy * dy);
      if (dl == 0) continue;
      final nx = -dy / dl, ny = dx / dl;
      left.add(Offset(x + nx * thick / 2, y + ny * thick / 2));
      right.add(Offset(x - nx * thick / 2, y - ny * thick / 2));
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          start, end,
          [const Color(0xFF8D6E63), const Color(0xFF5D4037)],
        ),
    );
    // Subtle top highlight, same as the dashboard branches.
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _clump(Canvas canvas, Offset c, double r, {required int seed}) {
    final rng = math.Random(seed);
    final blobs = <(double, double, double, Color)>[
      (-r * 0.5, -r * 0.45, r * 0.95, theme.leafDark),
      (r * 0.05, -r * 0.3, r * 0.72, theme.leafMid),
      (-r * 0.42, -r * 0.05, r * 0.6, theme.leafMid),
      (-r * 0.26, -r * 0.36, r * 0.34, theme.leafLight),
    ];
    for (final (dx, dy, br, col) in blobs) {
      final jx = (rng.nextDouble() - 0.5) * 6;
      canvas.drawCircle(Offset(c.dx + dx + jx, c.dy + dy), br,
          Paint()..color = col);
    }
  }

  void _paintCanopy(Canvas canvas, double w, double canopyBottom) {
    // A solid leaf mass filling the top of the strip. We extend massBottom
    // past the trunk-top (canopyBottom) by 80px so the two pieces overlap —
    // eliminating the bare-sky gap that was visible mid-pan.
    const top = -160.0;
    final massBottom = canopyBottom + 80.0;
    canvas.drawRect(
      Rect.fromLTRB(-120, top, w + 120, massBottom),
      Paint()..color = theme.leafBackstop,
    );

    // Sun glow behind the canopy.
    final glowC = Offset(w * 0.42, massBottom * 0.28);
    canvas.drawCircle(
      glowC,
      massBottom * 0.5,
      Paint()
        ..shader = ui.Gradient.radial(
          glowC, massBottom * 0.5,
          [theme.glow.withValues(alpha: 0.85), theme.glow.withValues(alpha: 0)],
          [0.0, 0.62],
        ),
    );

    // Dense fill of leaf circles in a staggered grid.
    final rng = math.Random(7);
    final fills = [theme.leafBackstop, theme.leafDark, theme.leafMid];
    final cell = w * 0.30;
    for (double y = top + 60; y < massBottom; y += cell * 0.62) {
      int col = 0;
      for (double x = -40; x < w + 60; x += cell * 0.72) {
        final r = cell * (0.42 + rng.nextDouble() * 0.12);
        final jx = (rng.nextDouble() - 0.5) * 24;
        final jy = (rng.nextDouble() - 0.5) * 24;
        canvas.drawCircle(Offset(x + jx, y + jy), r,
            Paint()..color = fills[(col + (y ~/ cell).toInt()) % fills.length]);
        col++;
      }
    }

    // Branches weaving through the canopy.
    for (final (ax, ay, bx, by, ww) in [
      (w * 0.05, massBottom * 0.55, w * 0.55, massBottom * 0.42, 18.0),
      (w * 0.5, massBottom * 0.72, w * 0.98, massBottom * 0.6, 16.0),
      (w * 0.6, massBottom * 0.26, w * 0.9, massBottom * 0.12, 14.0),
    ]) {
      _branch(canvas, Offset(ax, ay), Offset(bx, by), ww);
    }

    // Foreground rustling clumps for depth and highlights.
    final clumps = <(double, double, double, int)>[
      (w * 0.5, massBottom * 0.42, 110, 1),
      (w * 0.28, massBottom * 0.5, 92, 2),
      (w * 0.74, massBottom * 0.46, 95, 3),
      (w * 0.4, massBottom * 0.22, 78, 4),
      (w * 0.66, massBottom * 0.26, 72, 5),
      (w * 0.5, massBottom * 0.66, 120, 6),
      (w * 0.24, massBottom * 0.68, 86, 7),
      (w * 0.78, massBottom * 0.64, 88, 8),
      (w * 0.5, massBottom * 0.84, 116, 9),
      (w * 0.18, massBottom * 0.34, 70, 10),
      (w * 0.84, massBottom * 0.36, 70, 11),
    ];
    for (final (cx, cy, r, seed) in clumps) {
      _clump(canvas, Offset(cx, cy), r.toDouble(), seed: seed);
    }
  }

  @override
  bool shouldRepaint(_WorldPainter old) =>
      old.theme != theme || old.worldH != worldH || old.scroll != scroll;
}

// ──────────────────────────────────────────────
// Blade cache — computed once per screen width
// ──────────────────────────────────────────────

class _BladeDatum {
  final double x, baseY, blH, width, leanFactor, phase;
  final Color col;
  const _BladeDatum(this.x, this.baseY, this.blH, this.width,
      this.leanFactor, this.phase, this.col);
}

class _BladeCache {
  static double? _w, _h;
  static List<_BladeDatum> row1 = [];
  static List<_BladeDatum> row2 = [];

  static void ensure(double w, double h, List<Color> grass) {
    if (_w == w && _h == h) return;
    _w = w;
    _h = h;
    final rng = math.Random(99);
    final count = (w / 7).floor();
    row1 = List.generate(count, (i) {
      final x = (i + 0.5) * (w / count) + (rng.nextDouble() - 0.5) * 4;
      final baseY = h - 90 + rng.nextDouble() * 14;
      final blH = 56 + rng.nextDouble() * 78;
      final phase = rng.nextDouble() * math.pi * 2;
      final leanFactor = (8 + rng.nextDouble() * 10) * 0.5;
      final width = 8.0 + rng.nextDouble() * 5;
      return _BladeDatum(x, baseY, blH, width, leanFactor, phase,
          grass[i % grass.length]);
    });
    row2 = List.generate(count, (i) {
      final x = i * (w / count) + (rng.nextDouble() - 0.5) * 5;
      final baseY = h - 78 + rng.nextDouble() * 10;
      final blH = 34 + rng.nextDouble() * 46;
      final phase = rng.nextDouble() * math.pi * 2;
      final leanFactor = (6 + rng.nextDouble() * 8) * 0.5;
      final width = 7.0 + rng.nextDouble() * 4;
      return _BladeDatum(x, baseY, blH, width, leanFactor, phase,
          grass[(i + 1) % grass.length]);
    });
  }
}

// ──────────────────────────────────────────────
// FOREGROUND: soil burrow rim + dense grass
// ──────────────────────────────────────────────

class _ForegroundPainter extends CustomPainter {
  final _LaunchTheme theme;
  final double sway; // -1..1
  _ForegroundPainter({required this.theme, required this.sway});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fgTop = h - 230; // foreground band height

    // Soil burrow rim — dark earthen arc across the bottom.
    canvas.drawRect(
      Rect.fromLTRB(0, h - 52, w, h),
      Paint()..color = theme.soilTop,
    );
    canvas.drawOval(
      Rect.fromLTRB(-30, h - 150, w + 30, h + 70),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h), w * 0.7,
          [theme.soilRim1, theme.soilRim2],
          [0.4, 1.0],
        ),
    );

    // Corner undergrowth bushes.
    for (final (cx, by, bw, bh, col) in [
      (-10.0, h - 120, 175.0, 118.0, theme.bushDark),
      (40.0, h - 140, 104.0, 84.0, theme.bushLight),
      (w + 10, h - 120, 175.0, 118.0, theme.bushDark),
      (w - 40, h - 140, 104.0, 84.0, theme.bushLight),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, by), width: bw, height: bh),
        Paint()..color = col,
      );
    }

    // Build blade layout once per screen width; only sway changes per frame.
    _BladeCache.ensure(w, h, theme.grass);
    for (final b in _BladeCache.row1) {
      final lean = b.leanFactor * math.sin(sway * math.pi + b.phase);
      final tipX = b.x + lean;
      final path = Path()
        ..moveTo(b.x - b.width / 2, b.baseY)
        ..quadraticBezierTo(
            b.x + lean * 0.4, b.baseY - b.blH * 0.55, tipX, b.baseY - b.blH)
        ..quadraticBezierTo(b.x + lean * 0.4 + b.width * 0.4,
            b.baseY - b.blH * 0.5, b.x + b.width / 2, b.baseY)
        ..close();
      canvas.drawPath(path, Paint()..color = b.col);
    }
    for (final b in _BladeCache.row2) {
      final lean = b.leanFactor * math.sin(sway * math.pi + b.phase);
      final tipX = b.x + lean;
      final path = Path()
        ..moveTo(b.x - b.width / 2, b.baseY)
        ..quadraticBezierTo(
            b.x + lean * 0.4, b.baseY - b.blH * 0.55, tipX, b.baseY - b.blH)
        ..quadraticBezierTo(b.x + lean * 0.4 + b.width * 0.4,
            b.baseY - b.blH * 0.5, b.x + b.width / 2, b.baseY)
        ..close();
      canvas.drawPath(path, Paint()..color = b.col);
    }

    // Wildflowers dotted along the grass.
    final flowerColors = [
      const Color(0xFFFFFFFF),
      const Color(0xFFF48FB1),
      const Color(0xFFC79BE8),
      const Color(0xFFFFD23F),
    ];
    for (final (fx, stemH, col) in [
      (w * 0.16, 40.0, flowerColors[0]),
      (w * 0.39, 34.0, flowerColors[1]),
      (w * 0.62, 42.0, flowerColors[2]),
      (w * 0.82, 32.0, flowerColors[0]),
      (w * 0.5, 38.0, flowerColors[1]),
    ]) {
      final baseY = h - 86;
      canvas.drawRect(
        Rect.fromLTWH(fx, baseY - stemH, 3, stemH),
        Paint()..color = const Color(0xFF3A8F47),
      );
      canvas.drawCircle(Offset(fx + 1.5, baseY - stemH), 9,
          Paint()..color = col);
      canvas.drawCircle(Offset(fx + 1.5, baseY - stemH), 3.5,
          Paint()..color = const Color(0xFFFFD23F));
    }

    // Two spotted mushrooms.
    _mushroom(canvas, Offset(w * 0.10, h - 88), 1.0, const Color(0xFFD65745));
    _mushroom(canvas, Offset(w * 0.88, h - 84), 0.8, const Color(0xFFE07A4D));

    // Pebbles.
    for (final (px, py, pw) in [
      (w * 0.3, h - 70, 30.0),
      (w * 0.56, h - 66, 24.0),
      (w * 0.7, h - 72, 34.0),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: pw, height: pw * 0.42),
        Paint()..color = const Color(0xFF9A958C),
      );
    }

    // Keep fgTop referenced (band anchor) without a lint warning.
    assert(fgTop <= h);
  }

  void _mushroom(Canvas canvas, Offset base, double s, Color cap) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx, base.dy - 18 * s, 10 * s, 18 * s),
        Radius.circular(4 * s),
      ),
      Paint()..color = const Color(0xFFF2E9D6),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(base.dx - 8 * s, base.dy - 30 * s, 30 * s, 19 * s),
        topLeft: Radius.circular(15 * s),
        topRight: Radius.circular(15 * s),
        bottomLeft: Radius.circular(5 * s),
        bottomRight: Radius.circular(5 * s),
      ),
      Paint()..color = cap,
    );
    canvas.drawCircle(
        Offset(base.dx - 1 * s, base.dy - 24 * s), 2.5 * s,
        Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(base.dx + 12 * s, base.dy - 27 * s), 3 * s,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ForegroundPainter old) =>
      old.theme != theme || old.sway != sway;
}

// ──────────────────────────────────────────────
// Falling leaves shaken loose during the launch
// ──────────────────────────────────────────────

class _LeafFallPainter extends CustomPainter {
  final double t; // 0..1 looping
  final _LaunchTheme theme;
  _LeafFallPainter({required this.t, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = math.Random(3);
    final colors = [theme.leafMid, theme.leafLight, theme.leafDark];
    for (int i = 0; i < 16; i++) {
      final lane = rng.nextDouble();
      final speed = 0.6 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble();
      final prog = (t * speed + phase) % 1.0;
      final x = lane * w + math.sin(prog * math.pi * 4 + i) * 18;
      final y = prog * (h + 80) - 40;
      final sz = 18.0 + rng.nextDouble() * 12;
      final rot = prog * math.pi * 4 + i;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      // Leaf: rounded-diamond petal shape.
      final path = Path()
        ..moveTo(0, -sz / 2)
        ..quadraticBezierTo(sz / 2, 0, 0, sz / 2)
        ..quadraticBezierTo(-sz / 2, 0, 0, -sz / 2)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i % colors.length]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LeafFallPainter old) => old.t != t;
}

// ──────────────────────────────────────────────
// Speed lines (whoosh) during the ascent
// ──────────────────────────────────────────────

class _SpeedLinesPainter extends CustomPainter {
  final double t; // 0..1 looping
  _SpeedLinesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = math.Random(5);
    for (int i = 0; i < 14; i++) {
      final x = rng.nextDouble() * w;
      final len = 60 + rng.nextDouble() * 80;
      final speed = 0.8 + rng.nextDouble() * 0.6;
      final phase = rng.nextDouble();
      final prog = (t * speed + phase) % 1.0;
      final y = prog * (h + len) - len;
      final alpha = (0.6 + rng.nextDouble() * 0.3);
      final paint = Paint()
        ..strokeWidth = 2 + rng.nextDouble() * 2
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(x, y),
          Offset(x, y + len),
          [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawLine(Offset(x, y), Offset(x, y + len), paint);
    }
  }

  @override
  bool shouldRepaint(_SpeedLinesPainter old) => old.t != t;
}

// ──────────────────────────────────────────────
// Overhead branch fringe arching over the arrival
// ──────────────────────────────────────────────

class _OverheadFringePainter extends CustomPainter {
  final _LaunchTheme theme;
  _OverheadFringePainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final dark = theme.shade;
    final blobs = <(double, double, double)>[
      (-10, 6, 75),
      (w * 0.25, -8, 85),
      (w * 0.5, 2, 75),
      (w * 0.75, -10, 86),
      (w + 10, 4, 78),
      (w * 0.15, 18, 60),
      (w * 0.68, 16, 60),
    ];
    for (final (x, y, r) in blobs) {
      canvas.drawCircle(
          Offset(x, y), r, Paint()..color = dark.withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(_OverheadFringePainter old) => false;
}

// Small play triangle for the Start button.
class _PlayTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────
// Idle leaf fall — gentle drift on the title screen
// ──────────────────────────────────────────────

class _IdleLeafPainter extends CustomPainter {
  final double t;
  final _LaunchTheme theme;
  _IdleLeafPainter({required this.t, required this.theme});

  static const _count = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = math.Random(42);
    final colors = [theme.leafMid, theme.leafLight, theme.leafDark];

    for (int i = 0; i < _count; i++) {
      // Uniformly pre-spread phases so leaves cover every screen height at
      // all times — no matter when the loop wraps, coverage is continuous.
      final basePhase = i / _count;
      final laneX = rng.nextDouble();
      // Uniform speed (exactly one fall per loop) keeps the wrap perfectly
      // seamless; the 16s controller period makes the fall slow and gentle.
      final swayAmp = 16.0 + rng.nextDouble() * 20;
      final sz = 16.0 + rng.nextDouble() * 14;

      final prog = (t + basePhase) % 1.0;
      final x = laneX * w + math.sin(prog * math.pi * 4 + i) * swayAmp;
      final y = prog * (h + 80) - 40;
      final rot = prog * math.pi * 2.5 + i;

      // sin(prog·π) = 0 at top and bottom, 1 at midfall.
      // The wrap (bottom→top teleport) happens while alpha≈0, so it is invisible.
      final alpha = math.sin(prog * math.pi).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final path = Path()
        ..moveTo(0, -sz / 2)
        ..quadraticBezierTo(sz / 2.2, 0, 0, sz / 2)
        ..quadraticBezierTo(-sz / 2.2, 0, 0, -sz / 2)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[i % 3].withValues(alpha: alpha * 0.85),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_IdleLeafPainter old) => old.t != t || old.theme != theme;
}

// ──────────────────────────────────────────────
// Sky particles — fireflies / drifting pollen
// ──────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double t;
  final _LaunchTheme theme;
  _ParticlePainter({required this.t, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = math.Random(17);
    for (int i = 0; i < 16; i++) {
      final bx = rng.nextDouble() * w;
      final byStart = rng.nextDouble() * h * 0.75;
      final speed = 0.04 + rng.nextDouble() * 0.06;
      final phase = rng.nextDouble();
      final prog = (t * speed + phase) % 1.0;
      final wobble = math.sin(prog * math.pi * 3 + i * 1.7) * 14;
      final x = bx + wobble;
      final y = byStart - prog * h * 0.35; // drift upward
      final alpha = math.sin(prog * math.pi).clamp(0.0, 1.0);
      final r = 1.5 + rng.nextDouble() * 2.0;
      // Soft outer glow
      canvas.drawCircle(
        Offset(x, y),
        r * 3,
        Paint()
          ..color = theme.glow.withValues(alpha: alpha * 0.18),
      );
      // Bright core
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = theme.glow.withValues(alpha: alpha * 0.80),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

// ──────────────────────────────────────────────
// Clouds — opaque puffs drifting across the sky
// ──────────────────────────────────────────────

class _CloudPainter extends CustomPainter {
  final double t; // 0..1 looping
  final _LaunchTheme theme;
  _CloudPainter({required this.t, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Cloud body colour tuned to the palette so it reads against each sky
    // (bright white by day, dim slate at night). Fully opaque.
    final cloudColor = theme.cloud;
    final shadow = Color.alphaBlend(
        Colors.black.withValues(alpha: 0.10), cloudColor);

    // (baseX 0..1, y, scale, speed) — speed varies so layers feel parallaxed.
    final clouds = <(double, double, double, double)>[
      (0.12, h * 0.10, 1.15, 1.0),
      (0.55, h * 0.06, 0.85, 1.35),
      (0.80, h * 0.18, 1.30, 0.75),
      (0.32, h * 0.24, 0.70, 1.60),
      (0.68, h * 0.30, 1.00, 1.10),
    ];

    for (final (bx, cy, scale, speed) in clouds) {
      // Wrap horizontally across a band wider than the screen.
      final span = w + 260;
      double cx = (bx * span + t * speed * span) % span - 130;
      _drawCloud(canvas, Offset(cx, cy), scale, cloudColor, shadow);
    }
  }

  void _drawCloud(
      Canvas canvas, Offset c, double s, Color body, Color shadow) {
    // Soft underside shadow, then overlapping opaque lobes.
    final lobes = <(double, double, double)>[
      (-58, 8, 34),
      (-26, -6, 44),
      (10, -14, 50),
      (44, -4, 42),
      (70, 10, 32),
      (8, 14, 46),
    ];
    final shadowPaint = Paint()..color = shadow;
    for (final (dx, dy, r) in lobes) {
      canvas.drawCircle(
          Offset(c.dx + dx * s, c.dy + (dy + 8) * s), r * s, shadowPaint);
    }
    final bodyPaint = Paint()..color = body;
    for (final (dx, dy, r) in lobes) {
      canvas.drawCircle(
          Offset(c.dx + dx * s, c.dy + dy * s), r * s, bodyPaint);
    }
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.t != t || old.theme != theme;
}
