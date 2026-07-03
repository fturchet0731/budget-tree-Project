import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../tutorial/tutorial_tour.dart';
import '../widgets/pulse_strip.dart';
import '../widgets/reflection_card.dart';
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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pulseKey = GlobalKey<PulseStripState>();
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
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

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
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
          backgroundColor: const Color(0xFF122B0F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.park, color: AppColors.lightLeaf, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).newTreeInForest,
                  style: const TextStyle(
                    color: AppColors.stoneBeigeColor,
                    fontSize: 14,
                  ),
                ),
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF122B0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.park, color: AppColors.lightLeaf, size: 44),
              const SizedBox(height: 12),
              Text(
                l.guestUpgradeTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  color: AppColors.stoneBeigeColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.guestUpgradeBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.mossGreen,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(startInSignUp: true),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_done_outlined),
                label: Text(l.createAccount),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l.guestUpgradeLater,
                  style: GoogleFonts.nunito(color: AppColors.mossGreen),
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
          Container(
            decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
          ),
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            painter: _CanopyPainter(),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  'Budget Tree',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 28,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).dashboardChooseBranch,
                  style: TextStyle(
                    color: AppColors.mossGreen.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
                ),
                PulseStrip(key: _pulseKey, onPlantTree: _openCreate),
                const ReflectionBanner(),
                Expanded(
                  child: ScaleTransition(
                    scale: _entryAnimation,
                    child: FadeTransition(
                      opacity: _entryAnimation,
                      child: _LeafGrid(
                        onTapCreate: () => _openCreate(),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_downward,
                      color: AppColors.mossGreen,
                      size: 16,
                    ),
                    label: Text(
                      AppLocalizations.of(context).dashboardBackToGround,
                      style: const TextStyle(
                        color: AppColors.mossGreen,
                        letterSpacing: 1,
                      ),
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

class _SocialHandle extends StatelessWidget {
  final VoidCallback onTap;
  const _SocialHandle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 116,
        decoration: BoxDecoration(
          color: AppColors.forestGreen,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.55),
              blurRadius: 12,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
            const SizedBox(height: 6),
            RotatedBox(
              quarterTurns: 1,
              child: Text(
                AppLocalizations.of(context).social.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 4-Leaf grid layout
// ──────────────────────────────────────────────

class _LeafGrid extends StatelessWidget {
  final VoidCallback onTapCreate;
  final VoidCallback onTapModify;
  final VoidCallback onTapGoals;
  final VoidCallback onTapSettings;

  const _LeafGrid({
    required this.onTapCreate,
    required this.onTapModify,
    required this.onTapGoals,
    required this.onTapSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: AspectRatio(
          aspectRatio: 0.78,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Branch backdrop drawn behind the leaves so the leaves
              // appear to hang off real curving branches.
              const Positioned.fill(
                child: CustomPaint(painter: _BranchTrellisPainter()),
              ),
              // Leaves positioned around a central trunk
              LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;
                  const leafW = 0.44; // % of parent width
                  const leafH = 0.33;
                  return Stack(
                    children: [
                      _placeLeaf(
                        left: w * 0.04,
                        top: h * 0.11,
                        width: w * leafW,
                        height: h * leafH,
                        child: _LeafButton(
                          label: l.dashboardCreate,
                          sublabel: l.dashboardCreateSub,
                          icon: Icons.park,
                          color: AppColors.forestGreen,
                          rotation: -0.18,
                          onTap: onTapCreate,
                        ),
                      ),
                      _placeLeaf(
                        right: w * 0.04,
                        top: h * 0.11,
                        width: w * leafW,
                        height: h * leafH,
                        child: _LeafButton(
                          label: l.dashboardModify,
                          sublabel: l.dashboardModifySub,
                          icon: Icons.forest,
                          color: AppColors.mossGreen,
                          rotation: 0.18,
                          onTap: onTapModify,
                        ),
                      ),
                      _placeLeaf(
                        left: w * 0.04,
                        bottom: h * 0.11,
                        width: w * leafW,
                        height: h * leafH,
                        child: _LeafButton(
                          label: l.dashboardGoals,
                          sublabel: l.dashboardGoalsSub,
                          icon: Icons.flag_outlined,
                          color: AppColors.riverBlue,
                          rotation: -0.18,
                          onTap: onTapGoals,
                        ),
                      ),
                      _placeLeaf(
                        right: w * 0.04,
                        bottom: h * 0.11,
                        width: w * leafW,
                        height: h * leafH,
                        child: _LeafButton(
                          label: l.dashboardSettings,
                          sublabel: l.dashboardSettingsSub,
                          icon: Icons.tune,
                          color: AppColors.barkBrown,
                          rotation: 0.18,
                          onTap: onTapSettings,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeLeaf({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double width,
    required double height,
    required Widget child,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

// ──────────────────────────────────────────────
// Branch trellis behind the 4 leaves
// ──────────────────────────────────────────────

class _BranchTrellisPainter extends CustomPainter {
  const _BranchTrellisPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final groundY = h * 0.92;
    final trunkTopY = h * 0.10;

    // Trunk
    final trunkPath = Path()
      ..moveTo(cx - 14, groundY)
      ..quadraticBezierTo(cx - 11, (groundY + trunkTopY) / 2, cx - 6, trunkTopY)
      ..lineTo(cx + 6, trunkTopY)
      ..quadraticBezierTo(cx + 11, (groundY + trunkTopY) / 2, cx + 14, groundY)
      ..close();
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader =
            const LinearGradient(
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
            ).createShader(
              Rect.fromLTWH(cx - 14, trunkTopY, 28, groundY - trunkTopY),
            ),
    );

    // Horizontal bark wrinkles
    final bark = Paint()
      ..color = const Color(0xFF1A0C06).withValues(alpha: 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 8; i++) {
      final t = i / 9.0;
      final y = trunkTopY + (groundY - trunkTopY) * t;
      final hw = 6 + (14 - 6) * t;
      canvas.drawLine(Offset(cx - hw * 0.8, y), Offset(cx + hw * 0.8, y), bark);
    }

    // Root flare
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY + 3), width: 60, height: 12),
      Paint()..color = const Color(0xFF3E2723),
    );

    // Four branches reaching to the leaf positions
    // Each branch has a thick taper, drawn as a polygon for natural feel.
    final branchColor = const Color(0xFF5D4037);
    final highlight = Colors.white.withValues(alpha: 0.08);

    // Approximate target points for the four leaves (inside-edge of each)
    final tl = Offset(w * 0.26, h * 0.20);
    final tr = Offset(w * 0.74, h * 0.20);
    final bl = Offset(w * 0.26, h * 0.78);
    final br = Offset(w * 0.74, h * 0.78);

    // Branch attach points along the trunk
    final upperAttach = Offset(cx, trunkTopY + (groundY - trunkTopY) * 0.18);
    final lowerAttach = Offset(cx, trunkTopY + (groundY - trunkTopY) * 0.72);

    _drawCurvedBranch(canvas, upperAttach, tl, branchColor, highlight, 13);
    _drawCurvedBranch(canvas, upperAttach, tr, branchColor, highlight, 13);
    _drawCurvedBranch(canvas, lowerAttach, bl, branchColor, highlight, 14);
    _drawCurvedBranch(canvas, lowerAttach, br, branchColor, highlight, 14);
  }

  /// Draws a tapering branch from [start] to [end] using a quadratic curve.
  /// The branch is widest at [start] (thickness [w0]) and narrows to ~3px at end.
  void _drawCurvedBranch(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    Color highlight,
    double w0,
  ) {
    final w1 = 3.0;
    // Control point biased outward and slightly downward for organic droop
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final outward = (end.dx - start.dx).sign;
    final ctrl = Offset(mid.dx + outward * 18, mid.dy + 12);

    // Tapered ribbon: sample N points along the curve, offset normal to it.
    final steps = 18;
    final leftPoints = <Offset>[];
    final rightPoints = <Offset>[];
    Offset? prev;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      // quadratic bezier
      final x =
          (1 - t) * (1 - t) * start.dx +
          2 * (1 - t) * t * ctrl.dx +
          t * t * end.dx;
      final y =
          (1 - t) * (1 - t) * start.dy +
          2 * (1 - t) * t * ctrl.dy +
          t * t * end.dy;
      final pt = Offset(x, y);
      final thick = w0 + (w1 - w0) * t;

      // Normal direction (derivative of bezier)
      final dx =
          2 * (1 - t) * (ctrl.dx - start.dx) + 2 * t * (end.dx - ctrl.dx);
      final dy =
          2 * (1 - t) * (ctrl.dy - start.dy) + 2 * t * (end.dy - ctrl.dy);
      final len = math.sqrt(dx * dx + dy * dy);
      if (len == 0) continue;
      final nx = -dy / len;
      final ny = dx / len;

      leftPoints.add(Offset(pt.dx + nx * thick / 2, pt.dy + ny * thick / 2));
      rightPoints.add(Offset(pt.dx - nx * thick / 2, pt.dy - ny * thick / 2));
      prev = pt;
    }

    final path = Path()..moveTo(leftPoints.first.dx, leftPoints.first.dy);
    for (final p in leftPoints.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in rightPoints.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);

    // Highlight strip along the top edge (one-pixel offset along the left side)
    final hp = Path()..moveTo(leftPoints.first.dx, leftPoints.first.dy);
    for (final p in leftPoints.skip(1)) {
      hp.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      hp,
      Paint()
        ..color = highlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Small twig at the end for a natural finish
    if (prev != null) {
      canvas.drawCircle(end, w1 * 0.9, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_BranchTrellisPainter old) => false;
}

// ──────────────────────────────────────────────
// Single leaf-shaped button
// ──────────────────────────────────────────────

class _LeafButton extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final double rotation;
  final VoidCallback onTap;

  const _LeafButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.rotation,
    required this.onTap,
  });

  @override
  State<_LeafButton> createState() => _LeafButtonState();
}

class _LeafButtonState extends State<_LeafButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Transform.rotate(
          angle: widget.rotation,
          child: DecoratedBox(
            // Soft drop shadow follows the leaf's clipped shape.
            decoration: ShapeDecoration(
              shape: _LeafShapeBorder(),
              shadows: AppShadows.card,
            ),
            child: ClipPath(
              clipper: _LeafClipper(),
              child: Container(
                height: 145,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color.withValues(alpha: 0.9),
                      widget.color,
                      widget.color.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 145),
                      painter: _LeafVeinPainter(widget.color),
                    ),
                    Center(
                      child: Padding(
                        // Keep longer translations (FR/ES) off the leaf's curved
                        // edges so nothing looks crammed against the clip.
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.icon,
                              color: Colors.white.withValues(alpha: 0.92),
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.sublabel,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Leaf clip path
// ──────────────────────────────────────────────

class _LeafClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _leafPath(size);

  @override
  bool shouldReclip(_LeafClipper old) => false;
}

Path _leafPath(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w / 2, 0)
    ..cubicTo(w * 1.05, h * 0.1, w * 1.05, h * 0.85, w / 2, h)
    ..cubicTo(-w * 0.05, h * 0.85, -w * 0.05, h * 0.1, w / 2, 0)
    ..close();
}

/// ShapeBorder version of the leaf clip — lets `ShapeDecoration.shadows`
/// cast a drop shadow that follows the leaf outline.
class _LeafShapeBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _leafPath(rect.size).shift(rect.topLeft);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

// ──────────────────────────────────────────────
// Leaf vein decoration
// ──────────────────────────────────────────────

class _LeafVeinPainter extends CustomPainter {
  final Color leafColor;
  const _LeafVeinPainter(this.leafColor);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(w / 2, h * 0.05), Offset(w / 2, h * 0.92), paint);

    for (int i = 1; i <= 4; i++) {
      final t = i / 5.0;
      final y = h * (0.15 + t * 0.65);
      final xReach = w * (0.25 + t * 0.08);
      canvas.drawLine(Offset(w / 2, y), Offset(w / 2 - xReach, y + 15), paint);
      canvas.drawLine(Offset(w / 2, y), Offset(w / 2 + xReach, y + 15), paint);
    }
  }

  @override
  bool shouldRepaint(_LeafVeinPainter old) => false;
}

// ──────────────────────────────────────────────
// Decorative canopy background
// ──────────────────────────────────────────────

class _CanopyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * 0.6;
      final r = 20.0 + rng.nextDouble() * 30;
      final opacity = 0.04 + rng.nextDouble() * 0.06;
      paint.color = AppColors.leafGreen.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rng.nextDouble() * math.pi * 2);
      final path = Path()
        ..moveTo(0, -r)
        ..cubicTo(r, -r * 0.3, r, r * 0.8, 0, r)
        ..cubicTo(-r, r * 0.8, -r, -r * 0.3, 0, -r)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CanopyPainter old) => false;
}
