import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../services/app_settings.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import 'scenery.dart';
import 'static_tree_view.dart';

/// Swipeable carousel of saved budget trees. Tapping a tree shows an
/// expanded info sheet (the same content as the grid's expanded view) with
/// a "View Full Tree" button that fires [onTapTree].
class ImmersiveForestView extends StatefulWidget {
  final List<BudgetModel> budgets;
  final Map<String, TreeCategory> categoriesById;
  final void Function(BudgetModel) onTapTree;
  final void Function(BudgetModel) onEdit;
  final void Function(BudgetModel) onDelete;

  const ImmersiveForestView({
    super.key,
    required this.budgets,
    required this.categoriesById,
    required this.onTapTree,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ImmersiveForestView> createState() => _ImmersiveForestViewState();
}

class _ImmersiveForestViewState extends State<ImmersiveForestView> {
  late final PageController _controller;
  double _page = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.84, initialPage: 0);
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LeafPalette _paletteFor(BudgetModel b) {
    final id = b.categoryId;
    if (id == null) return LeafPalette.defaultGreen;
    final cat = widget.categoriesById[id];
    if (cat == null) return LeafPalette.defaultGreen;
    return LeafPalette.fromAccent(Color(cat.colorValue));
  }

  TreeCategory? _categoryFor(BudgetModel b) {
    final id = b.categoryId;
    if (id == null) return null;
    return widget.categoriesById[id];
  }

  void _showInfoSheet(BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _BudgetInfoSheet(
        budget: budget,
        category: _categoryFor(budget),
        onView: () {
          Navigator.pop(ctx);
          widget.onTapTree(budget);
        },
        onEdit: () {
          Navigator.pop(ctx);
          widget.onEdit(budget);
        },
        onDelete: () {
          Navigator.pop(ctx);
          widget.onDelete(budget);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // One horizon for the whole scene, so the background band, the distant
      // trees and the budget tree in front all stand on the same ground rather
      // than on tiers at different elevations.
      //
      // The budget tree defines it and the background follows, not the other
      // way round: the tree's box is whatever is left once the plaque and
      // footer have their room, and the painter draws its ground at a fixed
      // fraction of that box. Deriving the horizon from the same numbers means
      // the two can't drift apart the way two independent fractions did.
      final h = constraints.maxHeight;
      final treeBoxHeight =
          (h - _kStageTop - _kStageBottom - _kPlaqueRoom).clamp(120.0, h);
      final groundY = _kStageTop + treeBoxHeight * _kTreeGroundFraction;

      return Stack(
      children: [
        // Continuous sky/forest background
        Positioned.fill(
          child: CustomPaint(
            painter: _ImmersiveBgPainter(parallax: _page, groundY: groundY),
          ),
        ),
        // Trees carousel — sized to leave room for footer dots + caption.
        Padding(
          padding: const EdgeInsets.only(
            top: _kStageTop,
            bottom: _kStageBottom,
          ),
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.budgets.length,
            itemBuilder: (ctx, i) {
              final budget = widget.budgets[i];
              final delta = (i - _page).abs().clamp(0.0, 1.0);
              final scale = 1.0 - delta * 0.10;
              final opacity = 1.0 - delta * 0.40;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 80),
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: _TreeStage(
                    budget: budget,
                    category: _categoryFor(budget),
                    leafPalette: _paletteFor(budget),
                    treeBoxHeight: treeBoxHeight,
                    onTapTree: () => _showInfoSheet(budget),
                  ),
                ),
              );
            },
          ),
        ),
        // Footer: dots + caption
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.budgets.length, (i) {
                  final isActive = (i - _page).abs() < 0.5;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.lightLeaf
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTokens.current.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTokens.current.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe,
                        color: AppTokens.current.textSecondary, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).swipeToWalk,
                      style: GoogleFonts.nunito(
                          color: AppTokens.current.textSecondary,
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
    });
  }
}

/// Padding around the tree carousel (the footer dots and caption live in the
/// bottom band).
const double _kStageTop = 40;
const double _kStageBottom = 110;

/// Vertical room kept below the tree for its name plaque.
const double _kPlaqueRoom = 132;

/// Where [StaticBudgetTreeView] draws its own ground inside whatever box it is
/// given. Sizing the box by this is what lands the tree on the shared horizon.
const double _kTreeGroundFraction = 0.78;

// ──────────────────────────────────────────────
// One tree page — tree (fixed height so it stands on the shared horizon)
// plus a centred name plaque below it
// ──────────────────────────────────────────────

class _TreeStage extends StatelessWidget {
  final BudgetModel budget;
  final TreeCategory? category;
  final LeafPalette leafPalette;
  final VoidCallback onTapTree;

  /// Chosen by the parent so the tree's own ground line lands exactly on the
  /// scene's horizon.
  final double treeBoxHeight;

  const _TreeStage({
    required this.budget,
    required this.category,
    required this.leafPalette,
    required this.treeBoxHeight,
    required this.onTapTree,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = budget.remaining < 0;
    return GestureDetector(
      onTap: onTapTree,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Fixed height rather than Expanded: the painter's ground sits at a
            // fraction of its box, so only a known box height puts it on the
            // scene's horizon.
            SizedBox(
              height: treeBoxHeight,
              child: StaticBudgetTreeView(
                budget: budget,
                scale: 0.7,
                leafPalette: leafPalette,
              ),
            ),
            // Centred plaque
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTokens.current.card,
                      AppTokens.current.card,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AppTokens.current.cardBorder),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (category != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color(category!.colorValue)
                                .withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Color(category!.colorValue)
                                    .withValues(alpha: 0.70)),
                          ),
                          child: Text(
                            category!.name.toUpperCase(),
                            style: GoogleFonts.nunito(
                              color: Color(category!.colorValue),
                              fontSize: 9.5,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      budget.budgetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w600,
                          color: AppColors.stoneBeigeColor,
                          fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            color: AppColors.lightLeaf, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '\$${budget.totalIncome.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                              color: AppColors.lightLeaf,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          isOver
                              ? Icons.warning_amber_rounded
                              : Icons.eco,
                          color: isOver
                              ? AppColors.dangerRed
                              : AppColors.mossGreen,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOver
                              ? '\$${(-budget.remaining).toStringAsFixed(2)} over'
                              : '\$${budget.remaining.toStringAsFixed(2)} left',
                          style: GoogleFonts.nunito(
                            color: isOver
                                ? AppColors.dangerRed
                                : AppColors.mossGreen,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context).tapForDetails,
                      style: GoogleFonts.nunito(
                        color: AppColors.mossGreen.withValues(alpha: 0.7),
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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
// Expanded info sheet shown on tap (immersive)
// ──────────────────────────────────────────────

class _BudgetInfoSheet extends StatelessWidget {
  final BudgetModel budget;
  final TreeCategory? category;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetInfoSheet({
    required this.budget,
    required this.category,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = budget.remaining < 0;
    final allocPct = budget.totalIncome > 0
        ? (budget.totalAllocated / budget.totalIncome).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2110),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.mossGreen.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Color(category!.colorValue)
                                  .withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Color(category!.colorValue)
                                      .withValues(alpha: 0.70)),
                            ),
                            child: Text(
                              category!.name.toUpperCase(),
                              style: GoogleFonts.nunito(
                                color: Color(category!.colorValue),
                                fontSize: 9.5,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        budget.budgetName,
                        style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w600,
                            color: AppColors.stoneBeigeColor,
                            fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${budget.expenses.length} expenses · ${budget.incomeSources.length} sources',
                        style: GoogleFonts.nunito(
                            color: AppColors.mossGreen, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${budget.totalIncome.toStringAsFixed(0)}',
                  style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightLeaf,
                      fontSize: 26),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: allocPct,
                minHeight: 8,
                backgroundColor: AppColors.soilMid,
                valueColor: AlwaysStoppedAnimation(
                  isOver
                      ? AppColors.dangerRed
                      : allocPct > 0.85
                          ? AppColors.warningAmber
                          : AppColors.lightLeaf,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isOver
                  ? '\$${(-budget.remaining).toStringAsFixed(2)} over budget'
                  : '\$${budget.remaining.toStringAsFixed(2)} remaining',
              style: GoogleFonts.nunito(
                color: isOver ? AppColors.dangerRed : AppColors.mossGreen,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context).expenseBreakdownUpper,
                style: GoogleFonts.nunito(
                  color: AppColors.mossGreen.withValues(alpha: 0.75),
                  fontSize: 10.5,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            ...budget.expenses.map((cat) {
              final perCycle = cat.allocatedPerCycle(budget.payFrequency);
              final pct = budget.totalIncome > 0
                  ? (perCycle / budget.totalIncome).clamp(0.0, 1.0)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(CategoryIcons.forKey(cat.emoji),
                        color: AppColors.lightLeaf, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cat.name,
                                  style: GoogleFonts.nunito(
                                      color: AppColors.stoneBeigeColor,
                                      fontSize: 12.5)),
                              Text(
                                '\$${perCycle.toStringAsFixed(2)}',
                                style: GoogleFonts.nunito(
                                    color: AppColors.lightLeaf,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 5,
                              backgroundColor: AppColors.soilMid,
                              valueColor: AlwaysStoppedAnimation(
                                  AppColors.lightLeaf),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 3,
                ),
                icon: const Icon(Icons.park, color: Colors.white),
                label: Text(AppLocalizations.of(context).viewFullTree,
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: Text(AppLocalizations.of(context).edit,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.riverBlue,
                      side: BorderSide(
                          color: AppColors.riverBlue
                              .withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 15),
                    label: Text(AppLocalizations.of(context).delete,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerRed,
                      side: BorderSide(
                          color: AppColors.dangerRed
                              .withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Continuous palette-aware background: sky + sun/moon + parallax
// ──────────────────────────────────────────────

class _ImmersiveBgPainter extends CustomPainter {
  final double parallax;

  /// The scene's horizon, shared with the budget tree in front so the ground
  /// reads as one continuous field.
  final double groundY;
  final AppPalette palette;

  _ImmersiveBgPainter({required this.parallax, required this.groundY})
      : palette = AppSettings.instance.palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTokens.current.skyTint, AppTokens.current.canvas],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    if (palette == AppPalette.dark) {
      _drawStars(canvas, w, h);
    }

    final celestial = Offset(w * 0.84, h * 0.10);
    canvas.drawCircle(
      celestial,
      120,
      Paint()
        ..shader = RadialGradient(colors: [
          (AppSettings.instance.isDark
                  ? const Color(0xFFB3C9E0)
                  : const Color(0xFFFFE082))
              .withValues(alpha: 0.32),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: celestial, radius: 120)),
    );
    canvas.drawCircle(
        celestial,
        28,
        Paint()
          ..color = AppSettings.instance.isDark
              ? const Color(0xFFE3EEF7)
              : const Color(0xFFFFD54F));
    if (palette == AppPalette.dark) {
      canvas.drawCircle(
        Offset(celestial.dx + 8, celestial.dy - 2),
        26,
        Paint()..color = const Color(0xFF030814).withValues(alpha: 0.55),
      );
    }

    final rng = math.Random(11);
    final cloudAlpha = palette == AppPalette.dark ? 0.42 : 0.88;
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: cloudAlpha);
    for (int i = 0; i < 5; i++) {
      final cx = ((i * 0.22 + 0.05) * w * 2 - parallax * 30) % (w * 1.2);
      final cy = h * (0.07 + (i % 3) * 0.03);
      _cloud(canvas, Offset(cx, cy), 0.7 + rng.nextDouble() * 0.4, cloudPaint);
    }

    // Distant trees stand ON the horizon, not on a lower tier of their own,
    // so they share the ground the budget tree is planted in.
    final offset = parallax * 18;
    for (int i = 0; i < 14; i++) {
      final tx = ((i / 13) * w * 1.2 - offset) % (w + 40);
      _silhouette(canvas, tx, groundY);
    }

    canvas.drawPath(
      Path()
        ..moveTo(0, groundY)
        ..quadraticBezierTo(w * 0.3, groundY - 10, w * 0.6, groundY)
        ..quadraticBezierTo(w * 0.85, groundY + 4, w, groundY - 4)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = _sceneGroundClose(),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, groundY + 10)
        ..quadraticBezierTo(w * 0.4, groundY + 5, w * 0.7, groundY + 10)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = _sceneGroundMid(),
    );

    final blade = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    final grassRng = math.Random(99);
    for (int i = 0; i < 70; i++) {
      final x = grassRng.nextDouble() * w;
      final baseY = groundY + (x / w) * 5;
      final blH = 10 + grassRng.nextDouble() * 18;
      final lean = (grassRng.nextDouble() - 0.5) * 12;
      blade.color = Color.fromRGBO(
        (18 + (grassRng.nextDouble() * 28)).round(),
        (96 + (grassRng.nextDouble() * 62)).round(),
        (18 + (grassRng.nextDouble() * 28)).round(),
        1,
      );
      canvas.drawLine(
          Offset(x, baseY), Offset(x + lean, baseY - blH), blade);
    }
  }

  void _drawStars(Canvas canvas, double w, double h) {
    final rng = math.Random(73);
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * 0.55;
      final r = 0.4 + rng.nextDouble() * 1.5;
      paint.color = Colors.white
          .withValues(alpha: 0.35 + rng.nextDouble() * 0.55);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _cloud(Canvas canvas, Offset c, double s, Paint p) {
    final r = 22.0 * s;
    for (final (dx, dy, dr) in [
      (0.0, 0.0, 1.0),
      (r * 1.05, r * 0.2, 0.80),
      (-r * 0.95, r * 0.3, 0.68),
      (r * 0.35, -r * 0.48, 0.88),
      (-r * 0.35, -r * 0.38, 0.65),
    ]) {
      canvas.drawCircle(Offset(c.dx + dx, c.dy + dy), r * dr, p);
    }
    canvas.drawRect(
        Rect.fromLTWH(c.dx - r * 1.35, c.dy, r * 2.7, r * 0.5), p);
  }

  void _silhouette(Canvas canvas, double tx, double groundY) {
    // Planted a few pixels into the horizon rather than floating above it: the
    // ground band is painted afterwards and its top edge undulates by about
    // 10px, so a small bite keeps every trunk met by ground instead of leaving
    // gaps under the ones sitting on a rise.
    Scenery.paintTreeSilhouette(
      canvas,
      Offset(tx, groundY + 4),
      52,
      _sceneGroundClose().withValues(alpha: 0.7),
      seed: (tx * 3).round(),
    );
  }

  @override
  bool shouldRepaint(_ImmersiveBgPainter old) =>
      old.parallax != parallax ||
      old.palette != palette ||
      old.groundY != groundY;
}

/// Flat scenery colors for the outdoor illustration scenes, theme-aware.
Color _sceneGroundClose() => AppSettings.instance.isDark
    ? const Color(0xFF2A3618)
    : Conifer.c400;
Color _sceneGroundMid() => AppSettings.instance.isDark
    ? const Color(0xFF243014)
    : Conifer.c300;
