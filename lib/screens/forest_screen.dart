import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../services/budget_repository.dart';
import '../services/category_repository.dart';
import '../theme/app_theme.dart';
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
              color: selected
                  ? AppColors.forestGreen.withValues(alpha: 0.55)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 17,
              color: selected
                  ? AppColors.lightLeaf
                  : AppColors.mossGreen.withValues(alpha: 0.75),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: AppColors.mossGreen.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill(Icons.forest_outlined, ForestViewMode.immersive,
              'Walk through your forest'),
          pill(Icons.grid_view_rounded, ForestViewMode.grid, 'Grid list'),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2410),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove this tree?',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600,
              color: AppColors.stoneBeigeColor, fontSize: 20),
        ),
        content: Text(
          '"${budget.budgetName}" will be permanently removed from your forest.',
          style: GoogleFonts.nunito(color: AppColors.mossGreen, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.nunito(color: AppColors.mossGreen)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
          ),
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _ForestBgPainter(),
          ),
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
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.mossGreen.withValues(alpha: 0.35)),
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
                              'Your Forest',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                color: AppColors.stoneBeigeColor,
                                fontSize: 26,
                                shadows: const [
                                  Shadow(
                                      color: Colors.black54,
                                      offset: Offset(1, 2),
                                      blurRadius: 5)
                                ],
                              ),
                            ),
                            Text(
                              _loading
                                  ? 'Loading…'
                                  : '${_budgets.length} budget tree${_budgets.length == 1 ? '' : 's'} planted',
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
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.lightLeaf))
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF152B12).withValues(alpha: 0.97),
              const Color(0xFF0B1A09).withValues(alpha: 0.97),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isExpanded
                ? AppColors.lightLeaf.withValues(alpha: 0.55)
                : AppColors.forestGreen.withValues(alpha: 0.22),
            width: isExpanded ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            if (isExpanded)
              BoxShadow(
                color: AppColors.forestGreen.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
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
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF5B9BD5),
                          Color(0xFF7EC8E3),
                          Color(0xFF8DC06A),
                        ],
                        stops: [0.0, 0.58, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
                                color: AppColors.lightLeaf, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '\$${budget.totalIncome.toStringAsFixed(2)}',
                              style: GoogleFonts.nunito(
                                color: AppColors.lightLeaf,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${budget.expenses.length} expense${budget.expenses.length == 1 ? '' : 's'} · ${budget.incomeSources.length} source${budget.incomeSources.length == 1 ? '' : 's'}',
                          style: GoogleFonts.nunito(
                              color: AppColors.mossGreen, fontSize: 11),
                        ),
                        if (budget.savedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(budget.savedAt!),
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
                                      : AppColors.lightLeaf,
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
                                                        fontSize: 12)),
                                                Text(
                                                  '\$${cat.allocated.toStringAsFixed(2)}',
                                                  style: GoogleFonts.nunito(
                                                    color: AppColors.lightLeaf,
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
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                elevation: 3,
                              ),
                              icon: const Icon(Icons.park,
                                  size: 16, color: Colors.white),
                              label: Text('View Full Tree',
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
                                  label: Text('Edit',
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
                                  label: Text('Delete',
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
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
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2E1B0E), Color(0xFF7B5040), Color(0xFF2E1B0E)],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(cx - 7, trunkTopY, 14, groundY - trunkTopY)),
    );

    // Bark lines
    final barkLine = Paint()
      ..color = const Color(0xFF1A0C06).withValues(alpha: 0.35)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final y = trunkTopY + (groundY - trunkTopY) * t;
      final hw = 3.5 + (7 - 3.5) * t;
      canvas.drawLine(Offset(cx - hw * 0.8, y), Offset(cx + hw * 0.8, y), barkLine);
    }

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

    // Highlight on crown (top-left)
    canvas.drawCircle(
      Offset(cx - 14, crownY - 14),
      8,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Branches with tiny leaf clusters
    if (budget.expenses.isNotEmpty) {
      final count = budget.expenses.length.clamp(1, 5);
      final branchPaint = Paint()
        ..color = const Color(0xFF4E342E)
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
      Paint()..color = const Color(0xFF2E7D32),
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
                color: AppColors.lightLeaf, size: 56),
            const SizedBox(height: 18),
            Text(
              'No trees in this category yet',
              style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Either plant a new tree in this category or clear the filter to see everything.',
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
              label: Text('Show all',
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
            const Icon(Icons.park, color: AppColors.lightLeaf, size: 72),
            const SizedBox(height: 22),
            Text(
              'Your forest is empty',
              style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Plant your first budget tree by going back and creating a new budget.',
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
                'Go Plant a Tree',
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
    final totalIncome = widget.budget.totalIncome;
    final remaining = totalIncome - _allocatedNow;
    final isOver = remaining < 0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2010),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
            'Edit Budget',
            style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                color: AppColors.stoneBeigeColor,
                fontSize: 20),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.stoneBeigeColor),
            decoration: const InputDecoration(
              labelText: 'Budget name',
              prefixIcon: Icon(Icons.park, color: AppColors.mossGreen),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'CATEGORY',
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
                Text('Income: \$${totalIncome.toStringAsFixed(2)}',
                    style:
                        GoogleFonts.nunito(color: AppColors.mossGreen, fontSize: 12)),
                Text(
                  isOver
                      ? '⚠ Over: \$${(-remaining).toStringAsFixed(2)}'
                      : 'Left: \$${remaining.toStringAsFixed(2)}',
                  style: GoogleFonts.nunito(
                    color: isOver ? AppColors.dangerRed : AppColors.lightLeaf,
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
                            color: AppColors.lightLeaf, size: 20),
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
                                color: AppColors.lightLeaf, fontSize: 14),
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
                      'Save Changes',
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

// ──────────────────────────────────────────────
// Forest background painter
// ──────────────────────────────────────────────

class _ForestBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawDistantTrees(canvas, w, h);
    _drawGround(canvas, w, h);
    _drawMist(canvas, w, h);
  }

  void _drawDistantTrees(Canvas canvas, double w, double h) {
    final trees = [
      (w * 0.04, h * 0.44, 0.28),
      (w * 0.16, h * 0.38, 0.38),
      (w * 0.30, h * 0.41, 0.30),
      (w * 0.46, h * 0.36, 0.42),
      (w * 0.60, h * 0.40, 0.32),
      (w * 0.74, h * 0.37, 0.36),
      (w * 0.88, h * 0.42, 0.26),
      (w * 0.97, h * 0.45, 0.22),
    ];
    for (final (tx, ty, op) in trees) {
      _silhouetteTree(canvas, tx, ty, h, op);
    }
  }

  void _silhouetteTree(
      Canvas canvas, double tx, double ty, double h, double op) {
    final groundY = h * 0.80;
    final trunkH = groundY - ty;
    final scale = 0.6 + op * 0.9;

    final crownPaint = Paint()
      ..color = const Color(0xFF1A3A16).withValues(alpha: op * 0.85);
    final crownMid = Paint()
      ..color = const Color(0xFF243D1F).withValues(alpha: op * 0.60);

    canvas.drawCircle(Offset(tx, ty), 26 * scale, crownPaint);
    canvas.drawCircle(Offset(tx - 16 * scale, ty + 10 * scale), 19 * scale, crownPaint);
    canvas.drawCircle(Offset(tx + 15 * scale, ty + 8 * scale), 17 * scale, crownPaint);
    canvas.drawCircle(Offset(tx, ty - 20 * scale), 15 * scale, crownMid);

    final trunkPaint = Paint()
      ..color = const Color(0xFF100A05).withValues(alpha: op * 0.75);
    canvas.drawRect(
      Rect.fromLTWH(tx - 5 * scale, ty + 16 * scale, 10 * scale,
          trunkH - 16 * scale),
      trunkPaint,
    );
  }

  void _drawGround(Canvas canvas, double w, double h) {
    final groundY = h * 0.80;

    canvas.drawPath(
      Path()
        ..moveTo(0, groundY)
        ..quadraticBezierTo(w * 0.35, groundY - 14, w * 0.65, groundY - 3)
        ..quadraticBezierTo(w * 0.82, groundY + 4, w, groundY - 7)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFF080F07),
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, groundY + 12)
        ..quadraticBezierTo(w * 0.28, groundY + 5, w * 0.55, groundY + 14)
        ..quadraticBezierTo(w * 0.78, groundY + 10, w, groundY + 8)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFF0C1A0A),
    );

    // Grass blades
    final rng = math.Random(77);
    final blade = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 70; i++) {
      final x = rng.nextDouble() * w;
      final baseY = groundY + 10 + (x / w) * 14;
      final blH = 10 + rng.nextDouble() * 24;
      final lean = (rng.nextDouble() - 0.5) * 16;
      blade.color = Color.fromRGBO(
        (10 + (rng.nextDouble() * 18)).round(),
        (52 + (rng.nextDouble() * 44)).round(),
        (12 + (rng.nextDouble() * 18)).round(),
        0.65 + rng.nextDouble() * 0.35,
      );
      canvas.drawLine(
          Offset(x, baseY), Offset(x + lean, baseY - blH), blade);
    }
  }

  void _drawMist(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.28, w, h * 0.38),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0A1A08).withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, h * 0.28, w, h * 0.38)),
    );
  }

  @override
  bool shouldRepaint(_ForestBgPainter old) => false;
}
