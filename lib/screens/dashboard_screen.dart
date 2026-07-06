import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_shadows.dart';
import '../theme/app_tokens.dart';
import '../tutorial/tutorial_tour.dart';
import '../widgets/pulse_strip.dart';
import '../widgets/reflection_card.dart';
import '../widgets/ui/app_buttons.dart';
import '../widgets/ui/entrance.dart';
import '../widgets/ui/pressable.dart';
import 'auth/login_screen.dart';
import 'createbudget_screen.dart';
import 'forest_screen.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';
import 'social_drawer.dart';

class DashboardScreen extends StatefulWidget {
  /// First launch only: play the guided tour once this menu appears, so Acorn
  /// greets the user at the four-leaf area before handing them the Create flow,
  /// and every section pops back here.
  final bool runTour;
  const DashboardScreen({super.key, this.runTour = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pulseKey = GlobalKey<PulseStripState>();

  @override
  void initState() {
    super.initState();
    if (widget.runTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runTour());
    }
  }

  /// Plays the guided tour over the four-leaf menu on first launch, then marks
  /// it seen so it never auto-plays again.
  Future<void> _runTour() async {
    if (!mounted) return;
    await GuidedTour.start(context);
    await AppSettings.instance.setTutorialSeen(true);
  }

  Future<void> _navigate(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    // Anything the user did in there may change what the pulse strip says.
    _pulseKey.currentState?.refresh();
  }

  /// Opens the Create flow. When a tree is actually planted the flow pops back
  /// here with `true`, so we land on the four-leaf menu and announce the new
  /// tree growing in the forest.
  Future<void> _openCreate() async {
    final planted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateBudgetScreen()),
    );
    if (!mounted) return;
    _pulseKey.currentState?.refresh();
    if (planted == true) {
      // Peak-motivation moment for a guest: their tree is in the ground, so
      // offer (once) to keep it safe with an account instead of the snackbar.
      if (await AuthService.instance.shouldOfferAccountUpgrade()) {
        await AuthService.instance.markAccountUpgradeOffered();
        if (mounted) await _offerAccountUpgrade();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.park, color: Conifer.c300, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(AppLocalizations.of(context).newTreeInForest),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Bottom sheet celebrating a guest's first planted tree and inviting them
  /// to create an account so the forest is backed up. Shown at most once.
  Future<void> _offerAccountUpgrade() async {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTokens.current.accentTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.park, color: Conifer.c500, size: 36),
              ),
              const SizedBox(height: AppDims.s12),
              Text(
                l.guestUpgradeTitle,
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
              const SizedBox(height: AppDims.s8),
              Text(
                l.guestUpgradeBody,
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
              const SizedBox(height: AppDims.s20),
              AppPrimaryButton(
                label: l.createAccount,
                icon: Icons.cloud_done_outlined,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(startInSignUp: true),
                    ),
                  );
                },
              ),
              Center(
                child: AppTextButton(
                  label: l.guestUpgradeLater,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      key: _scaffoldKey,
      // Friends live in a swipe-in sidebar (swipe from the right edge or tap
      // the handle) rather than a separate screen — keeps the app shallow.
      endDrawer: Drawer(
        backgroundColor: Colors.transparent,
        width: MediaQuery.of(context).size.width * 0.86,
        child: SocialDrawer(
          onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Entrance(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Budget Tree', style: text.headlineLarge),
                        const SizedBox(height: 2),
                        Text(l.dashboardChooseBranch, style: text.bodyMedium),
                      ],
                    ),
                  ),
                ),
                PulseStrip(key: _pulseKey, onPlantTree: _openCreate),
                const ReflectionBanner(),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _MenuGrid(
                          onTapCreate: _openCreate,
                          onTapModify: () =>
                              _navigate(context, const ForestScreen()),
                          onTapGoals: () =>
                              _navigate(context, const GoalsScreen()),
                          onTapSettings: () =>
                              _navigate(context, const SettingsScreen()),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppTextButton(
                      icon: Icons.arrow_downward,
                      label: l.dashboardBackToGround,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right-edge handle hinting the swipe-in Social sidebar.
          Positioned.fill(
            child: Align(
              alignment: const Alignment(1.0, -0.05),
              child: _SocialHandle(
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Social sidebar handle (swipe hint)
// ──────────────────────────────────────────────

class _SocialHandle extends StatefulWidget {
  final VoidCallback onTap;
  const _SocialHandle({required this.onTap});

  @override
  State<_SocialHandle> createState() => _SocialHandleState();
}

class _SocialHandleState extends State<_SocialHandle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (AppSettings.instance.motionFull) _bob.repeat();
    AppSettings.instance.addListener(_onSettings);
  }

  void _onSettings() {
    if (!mounted) return;
    final motion = AppSettings.instance.motionFull;
    if (motion && !_bob.isAnimating) {
      _bob.repeat();
    } else if (!motion && _bob.isAnimating) {
      _bob.stop();
    }
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(math.sin(_bob.value * math.pi * 2) * 2, 0),
        child: child,
      ),
      child: PressableScale(
        onTap: widget.onTap,
        child: Container(
          width: 26,
          height: 92,
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(14)),
            boxShadow: AppShadows.pill,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left, color: t.onAccent, size: 18),
              const SizedBox(height: 6),
              Icon(Icons.people_alt_rounded, color: t.onAccent, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 2×2 menu grid — white cards with flat spot illustrations
// ──────────────────────────────────────────────

class _MenuGrid extends StatelessWidget {
  final VoidCallback onTapCreate;
  final VoidCallback onTapModify;
  final VoidCallback onTapGoals;
  final VoidCallback onTapSettings;

  const _MenuGrid({
    required this.onTapCreate,
    required this.onTapModify,
    required this.onTapGoals,
    required this.onTapSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final tiles = [
      (
        l.dashboardCreate,
        l.dashboardCreateSub,
        _TileArt.sprout,
        t.accentTint,
        onTapCreate,
      ),
      (
        l.dashboardModify,
        l.dashboardModifySub,
        _TileArt.forest,
        t.brightness == Brightness.light
            ? Conifer.c100
            : const Color(0xFF2A3618),
        onTapModify,
      ),
      (
        l.dashboardGoals,
        l.dashboardGoalsSub,
        _TileArt.target,
        t.skyTint,
        onTapGoals,
      ),
      (
        l.dashboardSettings,
        l.dashboardSettingsSub,
        _TileArt.tune,
        t.soilTint,
        onTapSettings,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: AppDims.s16),
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) const SizedBox(width: AppDims.s16),
                Expanded(
                  child: Entrance(
                    delay: Duration(milliseconds: 70 * (row * 2 + col)),
                    child: _MenuTile(
                      label: tiles[row * 2 + col].$1,
                      sublabel: tiles[row * 2 + col].$2,
                      art: tiles[row * 2 + col].$3,
                      tint: tiles[row * 2 + col].$4,
                      onTap: tiles[row * 2 + col].$5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final _TileArt art;
  final Color tint;
  final VoidCallback onTap;

  const _MenuTile({
    required this.label,
    required this.sublabel,
    required this.art,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDims.s12),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppDims.rCard),
          border: Border.all(color: t.cardBorder),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.9,
              child: Container(
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(AppDims.rInner),
                ),
                child: CustomPaint(painter: _TileArtPainter(art)),
              ),
            ),
            const SizedBox(height: AppDims.s12),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

enum _TileArt { sprout, forest, target, tune }

/// Tiny flat spot illustrations for the menu tiles, drawn in the conifer
/// ramp so each tinted square carries the app's color.
class _TileArtPainter extends CustomPainter {
  final _TileArt art;
  const _TileArtPainter(this.art);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    switch (art) {
      case _TileArt.sprout:
        // Soil mound + stem + two leaves.
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, h * 0.88), width: w * 0.36, height: h * 0.14),
          Paint()..color = const Color(0xFF8A6B4F),
        );
        final stem = Paint()
          ..color = Conifer.c600
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
            Offset(cx, h * 0.85), Offset(cx, h * 0.38), stem);
        final leaf = Paint()..color = Conifer.c400;
        canvas.save();
        canvas.translate(cx, h * 0.48);
        canvas.rotate(-0.7);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(-w * 0.09, 0), width: w * 0.20, height: h * 0.16),
            leaf);
        canvas.restore();
        canvas.save();
        canvas.translate(cx, h * 0.40);
        canvas.rotate(0.7);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(w * 0.09, 0), width: w * 0.20, height: h * 0.16),
            Paint()..color = Conifer.c500);
        canvas.restore();
        break;

      case _TileArt.forest:
        // Three flat trees at staggered depths.
        void tree(double x, double s, Color crown) {
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset(x, h * 0.72 * s + h * (1 - s) * 0.72),
                width: w * 0.035 * s,
                height: h * 0.28 * s),
            Paint()..color = const Color(0xFF8A6B4F),
          );
          canvas.drawCircle(
              Offset(x, h * 0.45 * s + h * (1 - s) * 0.60), w * 0.13 * s,
              Paint()..color = crown);
        }

        tree(cx - w * 0.24, 0.8, Conifer.c600);
        tree(cx + w * 0.24, 0.85, Conifer.c500);
        tree(cx, 1.0, Conifer.c400);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, h * 0.90), width: w * 0.75, height: h * 0.10),
          Paint()..color = Conifer.c300.withValues(alpha: 0.6),
        );
        break;

      case _TileArt.target:
        // A sapling reaching for a golden ring (the goal).
        canvas.drawCircle(
          Offset(cx + w * 0.16, h * 0.30),
          w * 0.10,
          Paint()
            ..color = const Color(0xFFD4A843)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        final stem = Paint()
          ..color = Conifer.c600
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final path = Path()
          ..moveTo(cx - w * 0.10, h * 0.86)
          ..quadraticBezierTo(
              cx - w * 0.06, h * 0.55, cx + w * 0.08, h * 0.42);
        canvas.drawPath(path, stem);
        canvas.drawCircle(Offset(cx + w * 0.08, h * 0.42), w * 0.055,
            Paint()..color = Conifer.c400);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - w * 0.10, h * 0.88),
              width: w * 0.26,
              height: h * 0.10),
          Paint()..color = Conifer.c200,
        );
        break;

      case _TileArt.tune:
        // Three flat slider tracks with knobs.
        final track = Paint()
          ..color = Conifer.c200
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final knob = Paint()..color = Conifer.c500;
        final xs = [0.30, 0.62, 0.44];
        for (var i = 0; i < 3; i++) {
          final y = h * (0.28 + i * 0.22);
          canvas.drawLine(
              Offset(w * 0.22, y), Offset(w * 0.78, y), track);
          canvas.drawCircle(Offset(w * (0.22 + 0.56 * xs[i] / 0.78), y),
              w * 0.035, knob);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_TileArtPainter old) => old.art != art;
}
