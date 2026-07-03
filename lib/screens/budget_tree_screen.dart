import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../services/achievement_service.dart';
import '../services/app_settings.dart';
import '../services/budget_repository.dart';
import '../services/category_repository.dart';
import '../services/goal_repository.dart';
import '../services/notification_scheduler.dart';
import '../services/pay_scheduler.dart';
import '../services/sound_service.dart';
import '../services/suggestion_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/achievements_sheet.dart';
import '../widgets/acorn_coach.dart';
import '../widgets/category_picker.dart';
import '../widgets/scenery.dart';
import '../widgets/tree_drawing.dart';
import '../tutorial/tutorial_content.dart';

class BudgetTreeScreen extends StatefulWidget {
  final BudgetModel budget;

  /// When true, Acorn nudges the user to save the freshly grown tree.
  final bool tutorial;
  const BudgetTreeScreen({
    super.key,
    required this.budget,
    this.tutorial = false,
  });

  @override
  State<BudgetTreeScreen> createState() => _BudgetTreeScreenState();
}

class _BudgetTreeScreenState extends State<BudgetTreeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _growAnimation;

  // Populated each paint frame — leaf tap hit areas
  final List<_LeafHit> _leafHits = [];

  TreeCategory? _category;
  LeafPalette _leafPalette = LeafPalette.defaultGreen;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _growAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _controller.forward();
    });
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    if (widget.budget.categoryId == null) return;
    final all = await CategoryRepository.loadAll();
    final cat = all.cast<TreeCategory?>().firstWhere(
      (c) => c?.id == widget.budget.categoryId,
      orElse: () => null,
    );
    if (mounted && cat != null) {
      setState(() {
        _category = cat;
        _leafPalette = LeafPalette.fromAccent(Color(cat.colorValue));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Tap handling ──────────────────────────────
  void _onTapTree(TapUpDetails details) {
    final pos = details.localPosition;
    for (final hit in _leafHits) {
      if (hit.rect.contains(pos)) {
        _showLeafDetail(hit.category);
        return;
      }
    }
  }

  void _showLeafDetail(ExpenseCategory cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LeafDetailSheet(
        budget: widget.budget,
        category: cat,
        onChanged: () => setState(() {}),
      ),
    );
  }

  // ── Run pay cycle ─────────────────────────────
  Future<void> _runPayCycle() async {
    final result = await PayScheduler.runUpdate(widget.budget);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final nextWhen = _formatNextPay(result.nextPayDate);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF122B0F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              result.hadActivity
                  ? Icons.water_drop_outlined
                  : Icons.schedule_outlined,
              color: AppColors.lightLeaf,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.hadActivity
                    ? l.payProcessed(
                        result.periodsProcessed,
                        '\$${result.totalDeposited.toStringAsFixed(2)}',
                        result.updatedGoals.length,
                        nextWhen,
                      )
                    : l.noPayPeriods(nextWhen),
                style: GoogleFonts.nunito(
                  color: AppColors.stoneBeigeColor,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
    if (mounted) setState(() {}); // refresh next-pay countdown
    // Auto-deposits may have grown goals enough to earn badges.
    if (result.hadActivity) {
      final earned = await AchievementService.evaluateAndUnlock();
      if (mounted && earned.isNotEmpty) {
        await presentNewAchievements(context, earned);
      }
    }
  }

  String _formatNextPay(DateTime dt) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) return l.todayShort;
    if (diff.inDays == 0) return l.todayShort;
    if (diff.inDays == 1) return l.timeTomorrow;
    if (diff.inDays < 7) return l.timeInDays(diff.inDays);
    return l.onDate('${dt.month}/${dt.day}');
  }

  // ── Save budget dialog ────────────────────────
  void _showSaveDialog() {
    final l = AppLocalizations.of(context);
    String? chosenCategoryId = widget.budget.categoryId;
    bool autoLink = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (sbCtx, setSBState) => AlertDialog(
          backgroundColor: const Color(0xFF122B0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.park, color: AppColors.lightLeaf, size: 22),
              const SizedBox(width: 10),
              Text(
                l.saveBudgetTreeQuestion,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.saveBudgetTreeBody(widget.budget.budgetName),
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.groupOptionalUpper,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen.withValues(alpha: 0.75),
                    fontSize: 10.5,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                CategoryPicker(
                  selectedCategoryId: chosenCategoryId,
                  onChanged: (id) => setSBState(() => chosenCategoryId = id),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setSBState(() => autoLink = !autoLink),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.soilMid,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.mossGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: autoLink
                                ? AppColors.lightLeaf
                                : Colors.transparent,
                            border: Border.all(
                              color: autoLink
                                  ? AppColors.lightLeaf
                                  : AppColors.mossGreen.withValues(alpha: 0.6),
                              width: 1.6,
                            ),
                          ),
                          child: autoLink
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.autoLinkBranches,
                                style: GoogleFonts.nunito(
                                  color: AppColors.stoneBeigeColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.autoLinkBranchesDesc,
                                style: GoogleFonts.nunito(
                                  color: AppColors.mossGreen,
                                  fontSize: 11,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l.cancel,
                style: GoogleFonts.nunito(color: AppColors.mossGreen),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                // Capture before stamping savedAt: a never-saved budget is a
                // brand-new tree being planted (vs. updating one from the forest).
                final wasNew = widget.budget.savedAt == null;
                widget.budget.categoryId = chosenCategoryId;
                widget.budget.savedAt = DateTime.now();
                int autoLinkedCount = 0;
                if (autoLink) {
                  autoLinkedCount = await PayScheduler.autoLinkByName(
                    widget.budget,
                  );
                }
                await BudgetRepository.saveNew(widget.budget);
                SoundService.treePlanted();
                await AchievementService.evaluateAndUnlock();
                await NotificationScheduler.checkBudget(widget.budget);
                if (!mounted) return;
                if (wasNew) {
                  // A freshly planted tree: hand a "planted" signal back up the
                  // create flow so it lands on the four-leaf menu and announces
                  // the new tree there, instead of dropping a snackbar on a
                  // screen we're about to leave.
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (mounted) Navigator.of(context).pop(true);
                  });
                  return;
                }
                if (autoLinkedCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF122B0F),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: Text(
                        l.autoLinkedSnack(autoLinkedCount),
                        style: GoogleFonts.nunito(
                          color: AppColors.stoneBeigeColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF122B0F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        const Icon(
                          Icons.park,
                          color: AppColors.lightLeaf,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l.treePlantedSnack,
                          style: GoogleFonts.nunito(
                            color: AppColors.stoneBeigeColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
                });
              },
              child: Text(
                l.save,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the allocation-advice sheet: explained suggestions for adding,
  /// pruning, or trimming branches based on the current budget.
  void _showSuggestions() {
    final l = AppLocalizations.of(context);
    final suggestions = SuggestionService.forBudget(widget.budget, l);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D2010),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mossGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFFFFD54F), size: 20),
                const SizedBox(width: 8),
                Text(
                  l.gardenersTips,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    color: AppColors.stoneBeigeColor,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.gardenersTipsSub,
              style: GoogleFonts.nunito(
                color: AppColors.mossGreen,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: suggestions
                      .map((s) => _SuggestionTile(suggestion: s))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: AnimatedBuilder(
        animation: _growAnimation,
        builder: (ctx, child) {
          final show = _growAnimation.value > 0.85;
          final hasSchedule =
              widget.budget.payFrequency != null &&
              widget.budget.firstPayDate != null;
          return AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: show
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.budget.savedAt != null && hasSchedule)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FloatingActionButton.extended(
                            heroTag: 'processPay',
                            onPressed: _runPayCycle,
                            backgroundColor: AppColors.riverBlue,
                            elevation: 5,
                            icon: const Icon(
                              Icons.event_available,
                              color: Colors.white,
                            ),
                            label: Text(
                              l.processPay,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      FloatingActionButton.extended(
                        heroTag: 'saveTree',
                        onPressed: widget.budget.savedAt == null
                            ? _showSaveDialog
                            : _showSaveDialog,
                        backgroundColor: AppColors.forestGreen,
                        elevation: 6,
                        icon: const Icon(Icons.save_alt, color: Colors.white),
                        label: Text(
                          widget.budget.savedAt == null
                              ? l.saveMyTree
                              : l.updateTree,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
      body: Stack(
        children: [
          // ── Palette-aware sky gradient ────────
          Container(decoration: BoxDecoration(gradient: AppPalettes.sky())),
          // ── Static background scene ───────────
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _TreeSceneBackground(),
          ),
          // ── Animated growing tree ─────────────
          // NOTE: _leafHits.clear() is inside _GrowingTreePainter.paint()
          // so leafHits always reflects what was last painted, even after
          // the animation completes and the builder doesn't clear them.
          AnimatedBuilder(
            animation: _growAnimation,
            builder: (ctx, child) {
              return GestureDetector(
                onTapUp: _onTapTree,
                child: CustomPaint(
                  size: Size(size.width, size.height),
                  painter: _GrowingTreePainter(
                    budget: widget.budget,
                    progress: _growAnimation.value,
                    leafHits: _leafHits,
                    leafPalette: _leafPalette,
                    totalIncomeLabel: l.totalIncome,
                    rootLabel: widget.budget.remaining < 0
                        ? l.overBudgetAmount(
                            '\$${(-widget.budget.remaining).toStringAsFixed(2)}',
                          )
                        : l.unallocatedAmount(
                            '\$${widget.budget.remaining.toStringAsFixed(2)}',
                          ),
                  ),
                ),
              );
            },
          ),
          // ── Header bar ───────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.budget.budgetName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 20,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      offset: const Offset(1, 2),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(
                                    _category!.colorValue,
                                  ).withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _category!.name.toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 9,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Income: \$${widget.budget.totalIncome.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                        _ClockAndNextPay(budget: widget.budget),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSuggestions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Tap hint ─────────────────────────
          AnimatedBuilder(
            animation: _growAnimation,
            builder: (ctx, child) {
              final show =
                  _growAnimation.value > 0.72 && _growAnimation.value < 0.95;
              return AnimatedOpacity(
                opacity: show ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Align(
                  alignment: const Alignment(0, 0.3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          l.tapALeaf,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // ── Acorn save-prompt coach (tutorial only) ──
          // Fills the screen so the user can drag Acorn's tip anywhere.
          if (widget.tutorial)
            Positioned.fill(
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _growAnimation,
                  builder: (ctx, _) => _growAnimation.value > 0.85
                      ? AcornCoach(
                          lessonKey: 'save',
                          lines: saveTreeSteps(l),
                          initialAlignment: const Alignment(0, -0.8),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Hit record for leaf tapping
// ──────────────────────────────────────────────

class _LeafHit {
  final Rect rect;
  final ExpenseCategory category;
  const _LeafHit({required this.rect, required this.category});
}

// ──────────────────────────────────────────────
// Static background: sun, clouds, birds, ground
// ──────────────────────────────────────────────

class _TreeSceneBackground extends CustomPainter {
  final AppPalette palette;
  _TreeSceneBackground() : palette = AppSettings.instance.palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawSun(canvas, Offset(w * 0.84, h * 0.075), 30);
    _drawClouds(canvas, w, h);
    _drawBirds(canvas, w, h);
    _drawTreeLine(canvas, w, h);
    _drawGround(canvas, w, h);
  }

  /// Faint distant trees along the horizon, behind the rolling ground —
  /// gives the growing tree the same sense of depth as the other scenes.
  void _drawTreeLine(Canvas canvas, double w, double h) {
    final groundY = h * 0.74;
    final c = AppPalettes.groundClose().withValues(alpha: 0.55);
    for (int i = 0; i < 7; i++) {
      final x = (i + 0.5) / 7 * w;
      // Keep the center clear so the budget tree owns the stage.
      if ((x - w / 2).abs() < w * 0.16) continue;
      Scenery.paintTreeSilhouette(
        canvas,
        Offset(x, groundY + 4),
        40 + ((i * 9) % 4) * 7,
        c,
        seed: i + 5,
      );
    }
  }

  void _drawSun(Canvas canvas, Offset c, double r) {
    final isMidnight = AppSettings.instance.palette == AppPalette.midnight;
    final glow = AppPalettes.celestialGlow();
    final core = AppPalettes.celestial();

    // Glow
    canvas.drawCircle(
      c,
      r * 4.5,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: 0.32), Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: r * 4.5)),
    );
    // Rays (skipped for moon — moons don't have rays)
    if (!isMidnight) {
      final rayPaint = Paint()
        ..color = glow.withValues(alpha: 0.30)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        canvas.drawLine(
          Offset(
            c.dx + math.cos(angle) * r * 1.5,
            c.dy + math.sin(angle) * r * 1.5,
          ),
          Offset(
            c.dx + math.cos(angle) * r * 3.2,
            c.dy + math.sin(angle) * r * 3.2,
          ),
          rayPaint,
        );
      }
    }
    // Core disc
    canvas.drawCircle(c, r, Paint()..color = core);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = glow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Shine spot
    canvas.drawCircle(
      Offset(c.dx - r * 0.30, c.dy - r * 0.30),
      r * 0.32,
      Paint()..color = Colors.white.withValues(alpha: 0.40),
    );
    // Moon crescent shading
    if (isMidnight) {
      canvas.drawCircle(
        Offset(c.dx + r * 0.30, c.dy - r * 0.05),
        r * 0.95,
        Paint()..color = const Color(0xFF030814).withValues(alpha: 0.55),
      );
    }
  }

  void _drawClouds(Canvas canvas, double w, double h) {
    _cloud(canvas, Offset(w * 0.13, h * 0.085), 1.0);
    _cloud(canvas, Offset(w * 0.57, h * 0.055), 0.72);
    _cloud(canvas, Offset(w * 0.35, h * 0.135), 0.52);
  }

  void _cloud(Canvas canvas, Offset c, double s) {
    final r = 22.0 * s;

    // Shadow underside
    final shadowPaint = Paint()
      ..color = const Color(0xFFB0C4DE).withValues(alpha: 0.30);
    for (final (dx, dy, dr) in [
      (0.0, r * 0.30, 1.0),
      (r * 1.05, r * 0.45, 0.80),
      (-r * 0.95, r * 0.50, 0.68),
    ]) {
      canvas.drawCircle(
        Offset(c.dx + dx, c.dy + dy),
        r * dr * 0.5,
        shadowPaint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(c.dx - r * 1.35, c.dy + r * 0.25, r * 2.7, r * 0.4),
      shadowPaint,
    );

    // Main cloud body
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (final (dx, dy, dr) in [
      (0.0, 0.0, 1.0),
      (r * 1.05, r * 0.20, 0.80),
      (-r * 0.95, r * 0.28, 0.68),
      (r * 0.35, -r * 0.46, 0.88),
      (-r * 0.35, -r * 0.36, 0.65),
    ]) {
      canvas.drawCircle(Offset(c.dx + dx, c.dy + dy), r * dr, p);
    }
    canvas.drawRect(Rect.fromLTWH(c.dx - r * 1.35, c.dy, r * 2.7, r * 0.5), p);

    // Highlight on top
    canvas.drawCircle(
      Offset(c.dx - r * 0.2, c.dy - r * 0.3),
      r * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _drawBirds(Canvas canvas, double w, double h) {
    final isMidnight = palette == AppPalette.midnight;
    final p = Paint()
      ..color = (isMidnight ? Colors.white : const Color(0xFF1A237E))
          .withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final (bx, by, bs) in [
      (w * 0.20, h * 0.17, 7.0),
      (w * 0.26, h * 0.145, 5.5),
      (w * 0.50, h * 0.10, 8.0),
      (w * 0.56, h * 0.085, 6.2),
      (w * 0.63, h * 0.125, 5.0),
    ]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(bx - bs, by), width: bs * 2, height: bs),
        math.pi,
        math.pi,
        false,
        p,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(bx + bs, by), width: bs * 2, height: bs),
        math.pi,
        math.pi,
        false,
        p,
      );
    }
  }

  void _drawGround(Canvas canvas, double w, double h) {
    final groundY = h * 0.74;

    // Soil base (darkest, right at trunk bottom)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, groundY + 4),
        width: 100,
        height: 14,
      ),
      Paint()..color = const Color(0xFF1A0C06).withValues(alpha: 0.55),
    );

    // Rolling ground layers — palette aware
    canvas.drawPath(
      Path()
        ..moveTo(0, groundY)
        ..quadraticBezierTo(w * 0.30, groundY - 10, w * 0.60, groundY)
        ..quadraticBezierTo(w * 0.82, groundY + 6, w, groundY - 2)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = AppPalettes.groundClose(),
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, groundY + 8)
        ..quadraticBezierTo(w * 0.40, groundY + 3, w * 0.70, groundY + 8)
        ..quadraticBezierTo(w * 0.88, groundY + 11, w, groundY + 5)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = AppPalettes.groundMid(),
    );

    // Horizon edge lighter strip
    canvas.drawPath(
      Path()
        ..moveTo(0, groundY - 1)
        ..quadraticBezierTo(w * 0.30, groundY - 11, w * 0.60, groundY - 1)
        ..quadraticBezierTo(w * 0.82, groundY + 5, w, groundY - 3)
        ..lineTo(w, groundY + 4)
        ..lineTo(0, groundY + 4)
        ..close(),
      Paint()..color = AppPalettes.hillMid().withValues(alpha: 0.55),
    );

    // Grass blades
    final bladePaint = Paint()
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final rng = math.Random(21);
    for (int i = 0; i < 48; i++) {
      final x = rng.nextDouble() * w;
      final baseY = groundY + (x / w) * 6;
      final blH = 9 + rng.nextDouble() * 19;
      final lean = (rng.nextDouble() - 0.5) * 13;
      bladePaint.color = Color.fromRGBO(
        (18 + (rng.nextDouble() * 28)).round(),
        (96 + (rng.nextDouble() * 62)).round(),
        (18 + (rng.nextDouble() * 28)).round(),
        1,
      );
      canvas.drawLine(
        Offset(x, baseY),
        Offset(x + lean, baseY - blH),
        bladePaint,
      );
    }

    // Wildflowers: petaled blooms, not plain dots.
    final fColors = [
      const Color(0xFFFFEE58),
      Colors.white,
      const Color(0xFFFF8A65),
      const Color(0xFFCE93D8),
      const Color(0xFFFFB74D),
    ];
    for (int i = 0; i < 18; i++) {
      final x = 15.0 + rng.nextDouble() * (w - 30);
      if ((x - w / 2).abs() < 44) continue;
      final y = groundY + 2 + rng.nextDouble() * h * 0.07;
      Scenery.paintFlower(
        canvas,
        Offset(x, y),
        3.0 + rng.nextDouble() * 1.6,
        fColors[i % fColors.length],
        center: i % 2 == 0 ? const Color(0xFFFFEE58) : const Color(0xFFF9A825),
      );
    }
  }

  @override
  bool shouldRepaint(_TreeSceneBackground old) => old.palette != palette;
}

// ──────────────────────────────────────────────
// Animated growing tree painter
// ──────────────────────────────────────────────

class _GrowingTreePainter extends CustomPainter {
  final BudgetModel budget;
  final double progress;
  final List<_LeafHit> leafHits;
  final LeafPalette leafPalette;
  final String totalIncomeLabel;
  final String rootLabel;

  const _GrowingTreePainter({
    required this.budget,
    required this.progress,
    required this.leafHits,
    required this.leafPalette,
    required this.totalIncomeLabel,
    required this.rootLabel,
  });

  double get trunkProg => (progress / 0.30).clamp(0.0, 1.0);
  double get branchProg => ((progress - 0.30) / 0.30).clamp(0.0, 1.0);
  double get crownProg => ((progress - 0.52) / 0.24).clamp(0.0, 1.0);
  double get leafProg => ((progress - 0.68) / 0.20).clamp(0.0, 1.0);
  double get incomeProg => ((progress - 0.82) / 0.14).clamp(0.0, 1.0);
  double get fallProg => ((progress - 0.90) / 0.10).clamp(0.0, 1.0);

  static const double _groundY = 0.74;
  static const double _trunkTopFrac = 0.22;

  @override
  void paint(Canvas canvas, Size size) {
    // Clear hit list at start of every paint call so hits always
    // reflect what's visible, even after animation completes.
    leafHits.clear();

    final w = size.width;
    final h = size.height;
    final groundY = h * _groundY;
    final trunkTopY = h * _trunkTopFrac;
    final cx = w / 2;

    if (trunkProg > 0) _drawTrunk(canvas, cx, groundY, trunkTopY);
    if (crownProg > 0) _drawCrown(canvas, cx, trunkTopY, w);
    if (branchProg > 0 && budget.expenses.isNotEmpty) {
      _drawBranches(canvas, w, h, cx, groundY, trunkTopY);
    }
    if (fallProg > 0 && budget.remaining > 0) {
      _drawFallenLeaves(canvas, w, groundY);
    }
    if (fallProg > 0) _drawRootLabel(canvas, cx, groundY);
  }

  // ── Trunk ─────────────────────────────────────
  void _drawTrunk(Canvas canvas, double cx, double groundY, double trunkTopY) {
    final currentTop = groundY - (groundY - trunkTopY) * trunkProg;
    TreeDrawing.paintTrunk(
      canvas,
      base: Offset(cx, groundY),
      height: groundY - currentTop,
      baseHalfWidth: 22,
      topHalfWidth: 9,
      seed: budget.id.hashCode,
      drawKnot: trunkProg > 0.6,
      drawRoots: trunkProg > 0.8,
    );
  }

  // ── Crown (canopy) with income ─────────────────
  void _drawCrown(Canvas canvas, double cx, double trunkTopY, double w) {
    if (crownProg <= 0) return;

    final cy = trunkTopY - 8;

    // Shadow ellipse under crown
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 8, trunkTopY + 8),
        width: 150 * crownProg,
        height: 22 * crownProg,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.13 * crownProg)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Organic foliage clusters — back to front, animated outward from
    // the trunk top during the grow phase.
    final lp = leafPalette;
    final seedBase = budget.id.hashCode;
    final clusters = [
      (cx - 50, cy + 28, 50.0),
      (cx + 46, cy + 22, 48.0),
      (cx - 22, cy - 8, 60.0),
      (cx + 18, cy - 16, 56.0),
      (cx - 8, cy + 8, 64.0),
      (cx + 6, cy - 4, 60.0),
      (cx - 36, cy - 32, 38.0),
      (cx + 34, cy - 28, 36.0),
      (cx, cy - 48, 46.0),
      (cx - 8, cy - 68, 30.0),
      (cx + 10, cy - 62, 28.0),
    ];

    for (int i = 0; i < clusters.length; i++) {
      final (lx, ly, lr) = clusters[i];
      final animX = cx + (lx - cx) * crownProg;
      final animY = cy + (ly - cy) * crownProg;
      TreeDrawing.paintCluster(
        canvas,
        Offset(animX, animY),
        lr * crownProg,
        lp,
        seed: seedBase + i * 19,
      );
    }

    // Leaf-fringe accents at the front-facing clusters
    if (crownProg > 0.7) {
      for (int i = 0; i < 3; i++) {
        final (lx, ly, lr) = clusters[4 + i * 2];
        TreeDrawing.paintLeafFringe(
          canvas,
          Offset(lx, ly),
          lr * crownProg,
          lp,
          seed: seedBase + 800 + i,
          leafCount: 6,
          leafSize: 8,
        );
      }
    }

    // Income text in crown center
    if (incomeProg > 0) {
      final textAlpha = incomeProg.clamp(0.0, 1.0);

      final labelTp = TextPainter(
        text: TextSpan(
          text: totalIncomeLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: textAlpha * 0.78),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(
        canvas,
        Offset(cx - labelTp.width / 2, cy - labelTp.height - 6),
      );

      final amountTp = TextPainter(
        text: TextSpan(
          text: '\$${budget.totalIncome.toStringAsFixed(0)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: textAlpha),
            fontSize: 23 * (0.55 + 0.45 * incomeProg),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: textAlpha * 0.45),
                offset: const Offset(1, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      amountTp.paint(canvas, Offset(cx - amountTp.width / 2, cy + 2));
    }
  }

  // ── Branches with named leaf buttons ──────────
  void _drawBranches(
    Canvas canvas,
    double w,
    double h,
    double cx,
    double groundY,
    double trunkTopY,
  ) {
    final cats = budget.expenses;
    final count = cats.length;

    for (int i = 0; i < count; i++) {
      final bStart = i / count;
      final bEnd = (i + 1) / count;
      final localProg = ((branchProg - bStart) / (bEnd - bStart)).clamp(
        0.0,
        1.0,
      );
      if (localProg <= 0) continue;

      final cat = cats[i];
      final pct = budget.percentageFor(cat);

      final tPos = 0.28 + (i / (count > 1 ? count - 1 : 1)) * 0.57;
      final attachY = trunkTopY + (groundY - trunkTopY) * tPos;

      final goLeft = i.isEven;
      final angle = goLeft ? math.pi * 0.65 : math.pi * 0.35;

      final maxLen = 62 + pct * 130;
      final branchLen = maxLen * localProg;

      final endX = cx + math.cos(angle) * branchLen;
      final endY = attachY - math.sin(angle) * branchLen;

      final startW = (7.0 + pct * 14).clamp(7.0, 21.0);
      final endW = (startW * 0.28).clamp(2.0, 6.0);

      // Curved tapered branch with bark highlight (organic, not a straight stick)
      TreeDrawing.paintBranch(
        canvas,
        Offset(cx, attachY),
        Offset(endX, endY),
        startW: startW,
        endW: endW,
        bowFactor: 0.08,
      );

      // Named leaf at branch tip
      if (leafProg > 0) {
        _drawNamedLeaf(
          canvas,
          tipX: endX,
          tipY: endY,
          goLeft: goLeft,
          cat: cat,
          prog: leafProg,
        );
        leafHits.add(
          _LeafHit(
            rect: Rect.fromCenter(
              center: Offset(endX, endY),
              width: 88,
              height: 88,
            ),
            category: cat,
          ),
        );
      }
    }
  }

  // ── Single named leaf at branch tip ───────────
  void _drawNamedLeaf(
    Canvas canvas, {
    required double tipX,
    required double tipY,
    required bool goLeft,
    required ExpenseCategory cat,
    required double prog,
  }) {
    const leafW = 30.0;
    const leafH = 50.0;

    final leafAngle = goLeft ? -math.pi / 4 : math.pi / 4;

    canvas.save();
    canvas.translate(tipX, tipY);
    canvas.rotate(leafAngle);
    canvas.scale(prog);

    // Drop shadow
    canvas.drawPath(
      Path()
        ..moveTo(1.5, -leafH + 2)
        ..cubicTo(
          leafW * 0.95 + 1.5,
          -leafH * 0.25 + 2,
          leafW * 0.95 + 1.5,
          leafH * 0.55 + 2,
          1.5,
          leafH * 0.22 + 2,
        )
        ..cubicTo(
          -leafW * 0.95 + 1.5,
          leafH * 0.55 + 2,
          -leafW * 0.95 + 1.5,
          -leafH * 0.25 + 2,
          1.5,
          -leafH + 2,
        )
        ..close(),
      Paint()..color = Colors.black.withValues(alpha: 0.20),
    );

    // Leaf body — rich gradient
    final leafPath = Path()
      ..moveTo(0, -leafH)
      ..cubicTo(
        leafW * 0.95,
        -leafH * 0.25,
        leafW * 0.95,
        leafH * 0.55,
        0,
        leafH * 0.22,
      )
      ..cubicTo(
        -leafW * 0.95,
        leafH * 0.55,
        -leafW * 0.95,
        -leafH * 0.25,
        0,
        -leafH,
      )
      ..close();

    final lp = leafPalette;
    canvas.drawPath(
      leafPath,
      Paint()
        ..shader = LinearGradient(
          colors: [lp.light, lp.mid, lp.dark],
          stops: const [0.0, 0.45, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(-leafW, -leafH, leafW * 2, leafH * 1.3)),
    );

    // Outline
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = lp.outline
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );

    // Central vein
    canvas.drawLine(
      Offset(0, -leafH * 0.85),
      Offset(0, leafH * 0.18),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Side veins
    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final vy = -leafH * 0.75 + leafH * 1.2 * t;
      final vx = leafW * 0.55 * (1 - t * 0.3);
      final sidePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, vy), Offset(vx, vy + 6), sidePaint);
      canvas.drawLine(Offset(0, vy), Offset(-vx, vy + 6), sidePaint);
    }

    // Sunlit highlight oval (upper portion)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-leafW * 0.22, -leafH * 0.42),
        width: leafW * 0.45,
        height: leafH * 0.30,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    canvas.restore();

    // Label (drawn in screen space, unrotated): icon glyph + category name
    if (prog > 0.55) {
      final textAlpha = ((prog - 0.55) / 0.45).clamp(0.0, 1.0);
      final iconData = CategoryIcons.forKey(cat.emoji);
      final labelColor = Colors.white.withValues(alpha: textAlpha);
      final shadowStyle = Shadow(
        color: Colors.black.withValues(alpha: textAlpha * 0.55),
        offset: const Offset(0.5, 1),
        blurRadius: 3,
      );

      final iconTp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontFamily: iconData.fontFamily,
            fontSize: 13,
            color: labelColor,
            shadows: [shadowStyle],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final nameTp = TextPainter(
        text: TextSpan(
          text: cat.name,
          style: TextStyle(
            color: labelColor,
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
            shadows: [shadowStyle],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 64);

      final totalH = iconTp.height + 2 + nameTp.height;
      final topY = tipY - totalH / 2 - 2;
      iconTp.paint(canvas, Offset(tipX - iconTp.width / 2, topY));
      nameTp.paint(
        canvas,
        Offset(tipX - nameTp.width / 2, topY + iconTp.height + 2),
      );
    }
  }

  // ── Fallen leaves for unallocated money ───────
  void _drawFallenLeaves(Canvas canvas, double w, double groundY) {
    final rng = math.Random(99);
    final ratio = (budget.remaining / budget.totalIncome).clamp(0.0, 1.0);
    final leafCount = (ratio * 22).round().clamp(1, 22);

    final colors = [
      AppColors.leafYellow,
      AppColors.leafOrange,
      const Color(0xFFFFCC80),
    ];

    for (int i = 0; i < leafCount; i++) {
      if (i / leafCount > fallProg) break;
      final x = w * 0.12 + rng.nextDouble() * w * 0.76;
      final y = groundY - 2 - rng.nextDouble() * 14;
      final angle = rng.nextDouble() * math.pi * 2;
      final sz = 7 + rng.nextDouble() * 9;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      // Leaf shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(1, 1),
          width: sz * 1.6,
          height: sz * 0.6,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );

      final path = Path()
        ..moveTo(0, -sz)
        ..cubicTo(sz, -sz * 0.3, sz, sz * 0.7, 0, sz)
        ..cubicTo(-sz, sz * 0.7, -sz, -sz * 0.3, 0, -sz)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: 0.90)
          ..style = PaintingStyle.fill,
      );

      // Leaf vein
      canvas.drawLine(
        Offset(0, -sz * 0.7),
        Offset(0, sz * 0.6),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..strokeWidth = 0.7
          ..style = PaintingStyle.stroke,
      );

      canvas.restore();
    }
  }

  // ── Unallocated label at tree roots ───────────
  void _drawRootLabel(Canvas canvas, double cx, double groundY) {
    final alpha = fallProg.clamp(0.0, 1.0);
    if (alpha <= 0) return;

    final isOver = budget.remaining < 0;
    final text = rootLabel;
    final labelIcon = isOver ? Icons.warning : Icons.eco;
    final labelColor = (isOver ? AppColors.dangerRed : AppColors.leafYellow)
        .withValues(alpha: alpha);
    final shadow = Shadow(
      color: Colors.black.withValues(alpha: alpha * 0.6),
      offset: const Offset(0, 1),
      blurRadius: 4,
    );

    final iconTp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(labelIcon.codePoint),
        style: TextStyle(
          fontFamily: labelIcon.fontFamily,
          fontSize: 13,
          color: labelColor,
          shadows: [shadow],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          shadows: [shadow],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final totalW = iconTp.width + 5 + tp.width;
    final pillRect = Rect.fromCenter(
      center: Offset(cx, groundY + 22),
      width: totalW + 24,
      height: tp.height + 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(14)),
      Paint()..color = Colors.black.withValues(alpha: alpha * 0.32),
    );

    final startX = cx - totalW / 2;
    final baseY = groundY + 16;
    iconTp.paint(
      canvas,
      Offset(startX, baseY + (tp.height - iconTp.height) / 2),
    );
    tp.paint(canvas, Offset(startX + iconTp.width + 5, baseY));
  }

  @override
  bool shouldRepaint(_GrowingTreePainter old) =>
      old.progress != progress ||
      old.totalIncomeLabel != totalIncomeLabel ||
      old.rootLabel != rootLabel;
}

// ──────────────────────────────────────────────
// Leaf detail bottom sheet — branch info + link goals
// ──────────────────────────────────────────────

class _LeafDetailSheet extends StatefulWidget {
  final BudgetModel budget;
  final ExpenseCategory category;
  final VoidCallback onChanged;
  const _LeafDetailSheet({
    required this.budget,
    required this.category,
    required this.onChanged,
  });

  @override
  State<_LeafDetailSheet> createState() => _LeafDetailSheetState();
}

class _LeafDetailSheetState extends State<_LeafDetailSheet> {
  List<Goal> _allGoals = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final g = await GoalRepository.loadAll();
    if (mounted) {
      setState(() {
        _allGoals = g;
        _loaded = true;
      });
    }
  }

  Future<void> _toggleLink(Goal goal) async {
    final list = widget.category.linkedGoalIds;
    setState(() {
      if (list.contains(goal.id)) {
        list.remove(goal.id);
      } else {
        list.add(goal.id);
      }
    });
    // If this budget is already saved, persist back so links survive.
    if (widget.budget.savedAt != null) {
      await BudgetRepository.update(widget.budget);
    }
    widget.onChanged();
  }

  void _openLinkPicker() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0E2110),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mossGreen.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l.linkBranchToGoals,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: AppColors.stoneBeigeColor,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.selectGoalsBranch(widget.category.name),
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_allGoals.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.soilMid,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.mossGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.spa_outlined,
                            color: AppColors.lightLeaf,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l.noGoalsPlanted,
                            style: GoogleFonts.nunito(
                              color: AppColors.stoneBeigeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.createGoalComeBack,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: AppColors.mossGreen,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allGoals.length,
                        itemBuilder: (lc, i) {
                          final g = _allGoals[i];
                          final isLinked = widget.category.linkedGoalIds
                              .contains(g.id);
                          return _GoalLinkTile(
                            goal: g,
                            linked: isLinked,
                            onTap: () async {
                              await _toggleLink(g);
                              setSheetState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l.done,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cat = widget.category;
    final pct = (widget.budget.percentageFor(cat) * 100).toStringAsFixed(1);
    final linkedGoals = _allGoals
        .where((g) => cat.linkedGoalIds.contains(g.id))
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppPalettes.deepForest().colors.last,
            const Color(0xFF050805),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: AppColors.mossGreen.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.forestGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    CategoryIcons.forKey(cat.emoji),
                    size: 30,
                    color: AppColors.lightLeaf,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w600,
                          color: AppColors.stoneBeigeColor,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        l.percentOfIncome(pct),
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Allocated card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkBark.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.forestGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.allocated,
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '\$${cat.allocated.toStringAsFixed(2)}',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightLeaf,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: widget.budget.percentageFor(cat),
                      minHeight: 12,
                      backgroundColor: AppColors.soilMid,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.lightLeaf,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$0',
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        l.ofIncome(
                          '\$${widget.budget.totalIncome.toStringAsFixed(2)}',
                        ),
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Linked goals section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color: AppColors.mossGreen.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.linkedGoalsUpper,
                      style: GoogleFonts.nunito(
                        color: AppColors.mossGreen.withValues(alpha: 0.85),
                        fontSize: 11,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _loaded ? _openLinkPicker : null,
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.lightLeaf,
                    size: 16,
                  ),
                  label: Text(
                    l.linkEllipsis,
                    style: GoogleFonts.nunito(
                      color: AppColors.lightLeaf,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.lightLeaf,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (linkedGoals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.soilMid.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.mossGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  l.notFundingGoals,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: linkedGoals
                    .map(
                      (g) => _LinkedGoalChip(
                        goal: g,
                        onRemove: () => _toggleLink(g),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinkedGoalChip extends StatelessWidget {
  final Goal goal;
  final VoidCallback onRemove;
  const _LinkedGoalChip({required this.goal, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.forestGreen.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightLeaf.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            GoalIcons.forKey(goal.iconKey),
            color: AppColors.lightLeaf,
            size: 14,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              goal.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: AppColors.stoneBeigeColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(goal.progress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.nunito(
              color: AppColors.lightLeaf,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            iconSize: 13,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
              maxHeight: 20,
            ),
            onPressed: onRemove,
            icon: Icon(
              Icons.close,
              color: AppColors.mossGreen.withValues(alpha: 0.65),
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalLinkTile extends StatelessWidget {
  final Goal goal;
  final bool linked;
  final VoidCallback onTap;
  const _GoalLinkTile({
    required this.goal,
    required this.linked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                GoalIcons.forKey(goal.iconKey),
                color: AppColors.lightLeaf,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: AppColors.stoneBeigeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${goal.currentAmount.toStringAsFixed(0)} of \$${goal.targetAmount.toStringAsFixed(0)} · ${(goal.progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: linked ? AppColors.lightLeaf : Colors.transparent,
                border: Border.all(
                  color: linked
                      ? AppColors.lightLeaf
                      : AppColors.mossGreen.withValues(alpha: 0.55),
                  width: 1.6,
                ),
              ),
              child: linked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Live local-time clock + next-pay-date line in the budget tree header.
// The clock ticks every 30s and uses DateTime.now() which respects the
// device's timezone — no network call needed for an accurate local clock.
// ──────────────────────────────────────────────

class _ClockAndNextPay extends StatefulWidget {
  final BudgetModel budget;
  const _ClockAndNextPay({required this.budget});

  @override
  State<_ClockAndNextPay> createState() => _ClockAndNextPayState();
}

class _ClockAndNextPayState extends State<_ClockAndNextPay> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _localTime {
    final h = _now.hour;
    final m = _now.minute;
    // Show timezone offset (e.g. UTC-5)
    final off = _now.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final hh = off.inHours.abs().toString().padLeft(2, '0');
    final mm = (off.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final zone = mm == '00' ? 'UTC$sign$hh' : 'UTC$sign$hh:$mm';
    return '${_two(h)}:${_two(m)} · $zone';
  }

  String? _nextPayLabel(AppLocalizations l) {
    final next = PayScheduler.nextPayDate(widget.budget, _now);
    if (next == null) return null;
    final diff = next.difference(_now);
    if (diff.isNegative) return l.timeNow;
    if (diff.inDays == 0) {
      return l.timeToday('${_two(next.hour)}:${_two(next.minute)}');
    }
    if (diff.inDays == 1) return l.timeTomorrow;
    if (diff.inDays < 7) return l.timeInDays(diff.inDays);
    return '${next.month}/${next.day}/${next.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nextPay = _nextPayLabel(l);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 11, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            _localTime,
            style: GoogleFonts.nunito(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
            ),
          ),
          if (nextPay != null) ...[
            const SizedBox(width: 10),
            const Icon(Icons.event, size: 11, color: Colors.white70),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l.nextPayLine(nextPay),
                style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Allocation suggestion tile (Gardener's Tips sheet)
// ──────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final BudgetSuggestion suggestion;
  const _SuggestionTile({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final color = suggestion.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(suggestion.icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: GoogleFonts.nunito(
                    color: AppColors.stoneBeigeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  suggestion.reason,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
