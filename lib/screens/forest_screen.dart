import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../l10n/preset_labels.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../services/budget_repository.dart';
import '../services/category_repository.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/category_picker.dart';
import '../widgets/immersive_forest_view.dart';
import '../widgets/info_button.dart';
import '../tutorial/tutorial_content.dart';
import 'budget_tree_screen.dart';

enum ForestViewMode { immersive, grid }

class _ViewModeToggle extends StatelessWidget {
  final ForestViewMode mode;
  final ValueChanged<ForestViewMode> onChange;
  const _ViewModeToggle({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    Widget pill(IconData icon, ForestViewMode m, String tip) {
      final selected = mode == m;
      return Tooltip(
        message: tip,
        child: GestureDetector(
          onTap: () => onChange(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTokens.current.card : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: selected ? AppShadows.pill : null,
            ),
            child: Icon(
              icon,
              size: 17,
              color: selected
                  ? AppTokens.current.accentStrong
                  : AppTokens.current.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTokens.current.canvasSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTokens.current.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill(Icons.forest_outlined, ForestViewMode.immersive,
              AppLocalizations.of(context).walkThroughForest),
          pill(Icons.grid_view_rounded, ForestViewMode.grid,
              AppLocalizations.of(context).gridList),
        ],
      ),
    );
  }
}

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key});

  @override
  State<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends State<ForestScreen> {
  List<BudgetModel> _budgets = [];
  List<TreeCategory> _categories = [];
  String? _filterCategoryId;
  bool _loading = true;
  int? _expandedIndex;
  ForestViewMode _mode = ForestViewMode.immersive;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final budgets = await BudgetRepository.loadAll();
    final cats = await CategoryRepository.loadAll();
    if (mounted) {
      setState(() {
        _budgets = budgets;
        _categories = cats;
        _loading = false;
      });
    }
  }

  Map<String, TreeCategory> get _categoriesById =>
      {for (final c in _categories) c.id: c};

  List<BudgetModel> get _filteredBudgets {
    if (_filterCategoryId == null) return _budgets;
    return _budgets.where((b) => b.categoryId == _filterCategoryId).toList();
  }

  Future<void> _deleteBudget(BudgetModel budget) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.removeTreeTitle),
        content: Text(l.removeTreeBody(budget.budgetName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.current.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await BudgetRepository.delete(budget.id);
      if (mounted) {
        setState(() => _expandedIndex = null);
        _load();
      }
    }
  }

  void _editBudget(BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditSheet(
        budget: budget,
        onSaved: (updated) async {
          await BudgetRepository.update(updated);
          if (ctx.mounted) Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppTokens.current.canvasSoft,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTokens.current.cardBorder),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.stoneBeigeColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.yourForest,
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                color: AppColors.stoneBeigeColor,
                                fontSize: 26,
                              ),
                            ),
                            Text(
                              _loading
                                  ? l.loadingEllipsis
                                  : l.budgetTreesPlanted(_budgets.length),
                              style: GoogleFonts.nunito(
                                  color: AppColors.mossGreen, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (_budgets.isNotEmpty)
                        _ViewModeToggle(
                          mode: _mode,
                          onChange: (m) => setState(() => _mode = m),
                        ),
                      const SizedBox(width: 10),
                      const SectionInfoButton(
                          section: TutorialSection.forest),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_loading && _budgets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: CategoryPicker(
                        selectedCategoryId: _filterCategoryId,
                        showAllOption: true,
                        onChanged: (id) async {
                          setState(() => _filterCategoryId = id);
                          // New categories may have been created in the picker
                          final cats = await CategoryRepository.loadAll();
                          if (mounted) setState(() => _categories = cats);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _budgets.isEmpty
                          ? _EmptyForest(
                              onPlant: () => Navigator.pop(context))
                          : _filteredBudgets.isEmpty
                              ? _NoMatchInCategory(
                                  onClear: () => setState(
                                      () => _filterCategoryId = null),
                                )
                              : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              child: _mode == ForestViewMode.immersive
                                  ? ImmersiveForestView(
                                      key: const ValueKey('immersive'),
                                      budgets: _filteredBudgets,
                                      categoriesById: _categoriesById,
                                      onTapTree: (b) {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            transitionDuration:
                                                const Duration(milliseconds: 500),
                                            pageBuilder: (_, a, b2) =>
                                                BudgetTreeScreen(budget: b),
                                            transitionsBuilder:
                                                (_, a, b2, child) =>
                                                    FadeTransition(
                                                        opacity: a,
                                                        child: child),
                                          ),
                                        );
                                      },
                                      onEdit: _editBudget,
                                      onDelete: _deleteBudget,
                                    )
                                  : ListView.builder(
                                      key: const ValueKey('grid'),
                                      padding: const EdgeInsets.fromLTRB(
                                          18, 0, 18, 32),
                                      itemCount: _filteredBudgets.length,
                                      itemBuilder: (ctx, i) {
                                        final budget = _filteredBudgets[i];
                                        final isExpanded =
                                            _expandedIndex == i;
                                        return _BudgetCard(
                                          budget: budget,
                                          category: _categoriesById[
                                              budget.categoryId],
                                          isExpanded: isExpanded,
                                          onTap: () => setState(() =>
                                              _expandedIndex =
                                                  isExpanded ? null : i),
                                          onEdit: () => _editBudget(budget),
                                          onDelete: () =>
                                              _deleteBudget(budget),
                                          onView: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                transitionDuration:
                                                    const Duration(
                                                        milliseconds: 500),
                                                pageBuilder: (_, a, b2) =>
                                                    BudgetTreeScreen(
                                                        budget: budget),
                                                transitionsBuilder:
                                                    (_, a, b2, child) =>
                                                        FadeTransition(
                                                            opacity: a,
                                                            child: child),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
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

// ──────────────────────────────────────────────
// Budget card (collapsed + expanded)
// ──────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final TreeCategory? category;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _BudgetCard({
    required this.budget,
    required this.category,
    required this.isExpanded,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final allocPct = budget.totalIncome > 0
        ? (budget.totalAllocated / budget.totalIncome).clamp(0.0, 1.0)
        : 0.0;
    final isOver = budget.remaining < 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTokens.current.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isExpanded
                ? AppTokens.current.accentStrong
                : AppTokens.current.cardBorder,
            width: isExpanded ? 1.5 : 1.0,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            // ── Collapsed header row ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  // Mini tree preview
                  Container(
                    width: 92,
                    height: 116,
                    decoration: BoxDecoration(
                      color: AppTokens.current.accentTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CustomPaint(
                        painter: _MiniTreePainter(
                          budget: budget,
                          leafPalette: category != null
                              ? LeafPalette.fromAccent(
                                  Color(category!.colorValue))
                              : LeafPalette.defaultGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(category!.colorValue)
                                    .withValues(alpha: 0.30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Color(category!.colorValue)
                                        .withValues(alpha: 0.7)),
                              ),
                              child: Text(
                                category!.name.toUpperCase(),
                                style: GoogleFonts.nunito(
                                  color: Color(category!.colorValue),
                                  fontSize: 9,
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
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                color: AppColors.forestGreen, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '\$${budget.totalIncome.toStringAsFixed(2)}',
                              style: GoogleFonts.nunito(
                                color: AppColors.forestGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.budgetCardCounts(
                              budget.expenses.length, budget.incomeSources.length),
                          style: GoogleFonts.nunito(
                              color: AppColors.mossGreen, fontSize: 11),
                        ),
                        if (budget.savedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(budget.savedAt!, l),
                            style: GoogleFonts.nunito(
                              color: AppColors.mossGreen.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: allocPct,
                            minHeight: 7,
                            backgroundColor: AppColors.soilMid,
                            valueColor: AlwaysStoppedAnimation(
                              isOver
                                  ? AppColors.dangerRed
                                  : allocPct > 0.85
                                      ? AppColors.warningAmber
                                      : AppColors.forestGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isOver)
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.dangerRed, size: 11),
                            if (isOver) const SizedBox(width: 3),
                            Text(
                              isOver
                                  ? '\$${(-budget.remaining).toStringAsFixed(2)} over budget'
                                  : '\$${budget.remaining.toStringAsFixed(2)} remaining',
                              style: GoogleFonts.nunito(
                                color: isOver
                                    ? AppColors.dangerRed
                                    : AppColors.mossGreen,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.mossGreen, size: 22),
                  ),
                ],
              ),
            ),

            // ── Expanded details ──────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: AppColors.forestGreen.withValues(alpha: 0.25),
                          height: 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EXPENSE BREAKDOWN',
                                style: GoogleFonts.nunito(
                                  color: AppColors.mossGreen.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...budget.expenses.map((cat) {
                                final pct = budget.totalIncome > 0
                                    ? (cat.allocated / budget.totalIncome).clamp(0.0, 1.0)
                                    : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: Row(
                                    children: [
                                      Icon(CategoryIcons.forKey(cat.emoji),
                                          color: AppColors.forestGreen, size: 18),
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
                                                        fontSize: 12)),
                                                Text(
                                                  '\$${cat.allocated.toStringAsFixed(2)}',
                                                  style: GoogleFonts.nunito(
                                                    color: AppColors.forestGreen,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
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
                                                valueColor: const AlwaysStoppedAnimation(
                                                    AppColors.forestGreen),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                              ),
                              icon: const Icon(Icons.park,
                                  size: 16, color: Colors.white),
                              label: Text(AppLocalizations.of(context).viewFullTree,
                                  style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              onPressed: onView,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.riverBlue,
                                    side: BorderSide(
                                        color: AppColors.riverBlue.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(11)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 15),
                                  label: Text(AppLocalizations.of(context).edit,
                                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                  onPressed: onEdit,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.dangerRed,
                                    side: BorderSide(
                                        color: AppColors.dangerRed.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(11)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                  icon: const Icon(Icons.delete_outline, size: 15),
                                  label: Text(AppLocalizations.of(context).delete,
                                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                                  onPressed: onDelete,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt, AppLocalizations l) {
    final months = monthAbbrevs(l);
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ──────────────────────────────────────────────
// Mini tree CustomPainter for card preview
// ──────────────────────────────────────────────

class _MiniTreePainter extends CustomPainter {
  final BudgetModel budget;
  final LeafPalette leafPalette;
  const _MiniTreePainter({
    required this.budget,
    this.leafPalette = LeafPalette.defaultGreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final groundY = h * 0.86;
    final trunkTopY = h * 0.36;

    // Trunk
    final trunkPath = Path()
      ..moveTo(cx - 7, groundY)
      ..quadraticBezierTo(cx - 7, (groundY + trunkTopY) / 2, cx - 3.5, trunkTopY)
      ..lineTo(cx + 3.5, trunkTopY)
      ..quadraticBezierTo(cx + 7, (groundY + trunkTopY) / 2, cx + 7, groundY)
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = const Color(0xFF8A6B4F));

    // Crown blobs — palette-tinted
    final lp = leafPalette;
    final crownY = trunkTopY - 4;
    for (final (bx, by, br, bc) in <(double, double, double, Color)>[
      (cx - 15, crownY + 9, 16.0, lp.outline),
      (cx + 14, crownY + 7, 15.0, lp.dark),
      (cx - 5, crownY - 3, 20.0, lp.dark),
      (cx + 7, crownY - 7, 18.0, lp.mid),
      (cx, crownY + 5, 22.0, lp.mid),
      (cx - 2, crownY - 17, 14.0, lp.light),
      (cx - 18, crownY - 12, 11.0, lp.dark),
      (cx + 16, crownY - 14, 10.0, lp.mid),
    ]) {
      canvas.drawCircle(Offset(bx, by), br, Paint()..color = bc);
    }

    // Branches with tiny leaf clusters
    if (budget.expenses.isNotEmpty) {
      final count = budget.expenses.length.clamp(1, 5);
      final branchPaint = Paint()
        ..color = const Color(0xFF8A6B4F)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < count; i++) {
        final tPos = 0.28 + (i / (count > 1 ? count - 1 : 1)) * 0.58;
        final attachY = trunkTopY + (groundY - trunkTopY) * tPos;
        final goLeft = i.isEven;
        final endX = cx + (goLeft ? -24.0 : 24.0);
        final endY = attachY - 12;
        canvas.drawLine(Offset(cx, attachY), Offset(endX, endY), branchPaint);
        // Leaf cluster — palette-tinted
        canvas.drawCircle(
          Offset(endX, endY),
          6.5,
          Paint()..color = lp.mid,
        );
        canvas.drawCircle(
          Offset(endX, endY),
          6.5,
          Paint()
            ..color = lp.outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
    }

    // Ground strip
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY + 1), width: w * 0.75, height: 7),
      Paint()..color = Conifer.c300,
    );
  }

  @override
  bool shouldRepaint(_MiniTreePainter old) =>
      old.leafPalette != leafPalette;
}

class _NoMatchInCategory extends StatelessWidget {
  final VoidCallback onClear;
  const _NoMatchInCategory({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off_outlined,
                color: AppColors.forestGreen, size: 56),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context).noTreesCategoryTitle,
              style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).noTreesCategoryBody,
              style: GoogleFonts.nunito(
                  color: AppColors.mossGreen, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
              label: Text(AppLocalizations.of(context).showAll,
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Empty state
// ──────────────────────────────────────────────

class _EmptyForest extends StatelessWidget {
  final VoidCallback onPlant;
  const _EmptyForest({required this.onPlant});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.park, color: AppColors.forestGreen, size: 72),
            const SizedBox(height: 22),
            Text(
              AppLocalizations.of(context).forestEmptyTitle,
              style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).forestEmptyBody,
              style: GoogleFonts.nunito(
                  color: AppColors.mossGreen, fontSize: 14, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onPlant,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.park, color: Colors.white),
              label: Text(
                AppLocalizations.of(context).goPlantATree,
                style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Edit budget bottom sheet
// ──────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final BudgetModel budget;
  final Future<void> Function(BudgetModel) onSaved;

  const _EditSheet({required this.budget, required this.onSaved});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late TextEditingController _nameCtrl;
  late List<TextEditingController> _amountCtrls;
  String? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.budget.budgetName);
    _categoryId = widget.budget.categoryId;
    _amountCtrls = widget.budget.expenses
        .map((e) => TextEditingController(text: e.allocated.toStringAsFixed(2)))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _amountCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  double get _allocatedNow =>
      _amountCtrls.fold(0.0, (s, c) => s + (double.tryParse(c.text) ?? 0.0));

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final updated = BudgetModel(
      budgetName: _nameCtrl.text.trim().isEmpty
          ? widget.budget.budgetName
          : _nameCtrl.text.trim(),
      incomeSources: widget.budget.incomeSources,
      expenses: widget.budget.expenses.asMap().entries.map((entry) {
        final cat = entry.value;
        final amount =
            double.tryParse(_amountCtrls[entry.key].text) ?? cat.allocated;
        return ExpenseCategory(
            name: cat.name,
            allocated: amount,
            emoji: cat.emoji,
            linkedGoalIds: List<String>.from(cat.linkedGoalIds));
      }).toList(),
      age: widget.budget.age,
      location: widget.budget.location,
      id: widget.budget.id,
      savedAt: widget.budget.savedAt,
      categoryId: _categoryId,
    );
    await widget.onSaved(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final totalIncome = widget.budget.totalIncome;
    final remaining = totalIncome - _allocatedNow;
    final isOver = remaining < 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTokens.current.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
          22, 18, 22, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mossGreen.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l.editBudget,
            style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                color: AppColors.stoneBeigeColor,
                fontSize: 20),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.stoneBeigeColor),
            decoration: InputDecoration(
              labelText: l.budgetName,
              prefixIcon: const Icon(Icons.park, color: AppColors.mossGreen),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.categoryUpper,
              style: GoogleFonts.nunito(
                color: AppColors.mossGreen.withValues(alpha: 0.75),
                fontSize: 10.5,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          CategoryPicker(
            selectedCategoryId: _categoryId,
            onChanged: (id) => setState(() => _categoryId = id),
          ),
          const SizedBox(height: 16),
          // Budget summary row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.soilMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.incomeAmount('\$${totalIncome.toStringAsFixed(2)}'),
                    style:
                        GoogleFonts.nunito(color: AppColors.mossGreen, fontSize: 12)),
                Text(
                  isOver
                      ? l.overAmount('\$${(-remaining).toStringAsFixed(2)}')
                      : l.leftAmount('\$${remaining.toStringAsFixed(2)}'),
                  style: GoogleFonts.nunito(
                    color: isOver ? AppColors.dangerRed : AppColors.forestGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: widget.budget.expenses.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(CategoryIcons.forKey(cat.emoji),
                            color: AppColors.forestGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(cat.name,
                              style: GoogleFonts.nunito(
                                  color: AppColors.stoneBeigeColor,
                                  fontSize: 13)),
                        ),
                        SizedBox(
                          width: 94,
                          child: TextField(
                            controller: _amountCtrls[i],
                            style: const TextStyle(
                                color: AppColors.forestGreen, fontSize: 14),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'))
                            ],
                            onChanged: (_) => setState(() {}),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              prefixText: '\$  ',
                              prefixStyle:
                                  TextStyle(color: AppColors.mossGreen),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                elevation: 3,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      l.saveChanges,
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

