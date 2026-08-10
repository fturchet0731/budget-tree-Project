import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/rhythm.dart';
import '../l10n/app_localizations.dart';
import '../l10n/rhythm_labels.dart';
import '../widgets/rhythm_picker.dart';
import '../l10n/preset_labels.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../services/budget_repository.dart';
import '../services/category_repository.dart';
import '../services/leftover_to_goal.dart';
import '../theme/app_dims.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/category_icons.dart';
import '../widgets/category_picker.dart';
import '../widgets/immersive_forest_view.dart';
import '../widgets/info_button.dart';
import '../widgets/pixel/pixel.dart';
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

  Future<void> _allocateLeftover(BudgetModel budget) async {
    final changed = await routeLeftoverToGoal(context, budget);
    if (changed && mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.allocationsReady)),
      );
      _load();
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
                PixelHeader(
                  title: l.yourForest,
                  strapline: _loading
                      ? l.loadingEllipsis
                      : l.budgetTreesPlanted(_budgets.length),
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_budgets.isNotEmpty)
                        _ViewModeToggle(
                          mode: _mode,
                          onChange: (m) => setState(() => _mode = m),
                        ),
                      const SizedBox(width: 6),
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
                                          onAllocateLeftover: () =>
                                              _allocateLeftover(budget),
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
  final VoidCallback onAllocateLeftover;

  const _BudgetCard({
    required this.budget,
    required this.category,
    required this.isExpanded,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    required this.onAllocateLeftover,
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTokens.current.card,
          border: Border.all(
            color: isExpanded
                ? AppTokens.current.accent
                : AppTokens.current.cardBorder,
            width: AppDims.borderThick,
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
                  // Tree portrait: one of the four chunky budget-tree sprites,
                  // picked by how full the tree is. The real per-branch tree
                  // (with tappable leaves) still lives on the detail screen.
                  PixelBox(
                    width: 86,
                    height: 86,
                    fill: AppTokens.current.accentTint,
                    borderWidth: AppDims.borderThin,
                    drop: 0,
                    alignment: Alignment.bottomCenter,
                    child: PixelSprite(
                      asset: PixelIcons.budgetTree(
                        branches: budget.expenses.length,
                        filled: allocPct.toDouble(),
                      ),
                      size: 82,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            Icon(Icons.account_balance_wallet_outlined,
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
                              Icon(Icons.warning_amber_rounded,
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
                    child: Icon(Icons.keyboard_arrow_down,
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
                                final perCycle =
                                    cat.allocatedPerCycle(budget.payFrequency);
                                final pct = budget.totalIncome > 0
                                    ? (perCycle / budget.totalIncome).clamp(0.0, 1.0)
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
                                                  '\$${perCycle.toStringAsFixed(2)}',
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
                                                valueColor: AlwaysStoppedAnimation(
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
                        if (budget.remaining > 0.5)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      AppTokens.current.accentStrong,
                                  side: BorderSide(
                                      color: AppTokens.current.accentStrong
                                          .withValues(alpha: 0.55)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(11)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 11),
                                ),
                                icon: const Icon(Icons.spa, size: 15),
                                label: Text(
                                  '${AppLocalizations.of(context).growAGoalWithIt} · \$${budget.remaining.toStringAsFixed(0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: onAllocateLeftover,
                              ),
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
            Icon(Icons.filter_alt_off_outlined,
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
            Icon(Icons.park, color: AppColors.forestGreen, size: 72),
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
  // Each branch's charge rhythm, editable alongside its amount.
  late List<Rhythm?> _expFreqs;
  // Editable copy of the roots feeding this tree: name + amount + rhythm.
  late List<(TextEditingController, TextEditingController, Rhythm?)>
      _incomes;
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
    _expFreqs = widget.budget.expenses.map((e) => e.frequency).toList();
    _incomes = widget.budget.incomeSources
        .map((inc) => (
              TextEditingController(text: inc.name),
              TextEditingController(text: inc.amount.toStringAsFixed(2)),
              inc.frequency,
            ))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _amountCtrls) {
      c.dispose();
    }
    for (final (n, a, _) in _incomes) {
      n.dispose();
      a.dispose();
    }
    super.dispose();
  }

  /// What each cycle the edited amounts convert to (a monthly rent edited in
  /// a weekly budget counts its per-cycle share), so the summary row always
  /// compares like-for-like against the per-cycle income.
  double _perCycle(double amount, Rhythm? freq) {
    final cycle = widget.budget.payFrequency;
    if (freq == null || cycle == null || freq == cycle) return amount;
    return amount * freq.periodsPerMonth / cycle.periodsPerMonth;
  }

  double get _allocatedNow {
    var sum = 0.0;
    for (var i = 0; i < _amountCtrls.length; i++) {
      sum += _perCycle(
          double.tryParse(_amountCtrls[i].text) ?? 0.0, _expFreqs[i]);
    }
    return sum;
  }

  List<IncomeSource> get _editedIncomes => [
        for (final (n, a, f) in _incomes)
          if (n.text.trim().isNotEmpty && (double.tryParse(a.text) ?? 0) > 0)
            IncomeSource(
              name: n.text.trim(),
              amount: double.tryParse(a.text) ?? 0,
              frequency: f,
            ),
      ];

  double get _incomeNow {
    final cycle = widget.budget.payFrequency;
    return _editedIncomes.fold(0.0, (s, e) => s + e.amountPerCycle(cycle));
  }

  void _addIncomeRow() {
    setState(() {
      _incomes.add((
        TextEditingController(),
        TextEditingController(),
        widget.budget.payFrequency,
      ));
    });
  }

  void _removeIncomeRow(int i) {
    final (n, a, _) = _incomes[i];
    setState(() => _incomes.removeAt(i));
    n.dispose();
    a.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final updated = BudgetModel(
      budgetName: _nameCtrl.text.trim().isEmpty
          ? widget.budget.budgetName
          : _nameCtrl.text.trim(),
      incomeSources: _editedIncomes,
      expenses: widget.budget.expenses.asMap().entries.map((entry) {
        final cat = entry.value;
        final amount =
            double.tryParse(_amountCtrls[entry.key].text) ?? cat.allocated;
        return ExpenseCategory(
            name: cat.name,
            allocated: amount,
            emoji: cat.emoji,
            linkedGoalIds: List<String>.from(cat.linkedGoalIds),
            frequency: _expFreqs[entry.key]);
      }).toList(),
      age: widget.budget.age,
      location: widget.budget.location,
      id: widget.budget.id,
      savedAt: widget.budget.savedAt,
      categoryId: _categoryId,
      // Keep the pay engine's state: cycle, first pay date, and the point it
      // has already processed up to must survive an edit.
      payFrequency: widget.budget.payFrequency,
      firstPayDate: widget.budget.firstPayDate,
      lastProcessedAt: widget.budget.lastProcessedAt,
    );
    await widget.onSaved(updated);
  }

  Widget _incomeRow(int i, AppLocalizations l) {
    final (nameCtrl, amountCtrl, freq) = _incomes[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: nameCtrl,
              style: TextStyle(color: AppColors.stoneBeigeColor, fontSize: 13),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.sourceName,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 86,
            child: TextField(
              controller: amountCtrl,
              style: TextStyle(color: AppColors.forestGreen, fontSize: 13),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                prefixText: '\$ ',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<Rhythm?>(
            tooltip: l.incomeArrives,
            initialValue: freq ?? widget.budget.payFrequency,
            onSelected: (f) async {
              // A null selection is the "Custom" entry: open the interval
              // picker rather than setting a preset.
              final chosen = f ??
                  await showRhythmDialog(
                    context,
                    freq ?? widget.budget.payFrequency ?? Rhythm.monthly,
                  );
              if (chosen == null || !mounted) return;
              setState(() => _incomes[i] = (nameCtrl, amountCtrl, chosen));
            },
            itemBuilder: (ctx) => [
              for (final f in Rhythm.presets)
                PopupMenuItem(value: f, child: Text(f.localizedLabel(l))),
              if (freq != null && freq.isCustom)
                PopupMenuItem(value: freq, child: Text(freq.localizedLabel(l))),
              PopupMenuItem(value: null, child: Text(l.rhythmCustom)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Icon(Icons.event_repeat_outlined,
                  size: 18, color: AppColors.mossGreen),
            ),
          ),
          GestureDetector(
            onTap: () => _removeIncomeRow(i),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close,
                  size: 16,
                  color: AppColors.stoneBeigeColor.withValues(alpha: 0.45)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final totalIncome = _incomeNow;
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
            style: TextStyle(color: AppColors.stoneBeigeColor),
            decoration: InputDecoration(
              labelText: l.budgetName,
              prefixIcon: Icon(Icons.park, color: AppColors.mossGreen),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.rootsFeedingTree.toUpperCase(),
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen.withValues(alpha: 0.75),
                      fontSize: 10.5,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _incomes.length; i++) _incomeRow(i, l),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addIncomeRow,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l.incomeAddAnother),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.branchesReachingOut.toUpperCase(),
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen.withValues(alpha: 0.75),
                      fontSize: 10.5,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.budget.expenses.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final freq = _expFreqs[i];
                  final cycle = widget.budget.payFrequency;
                  final differs =
                      freq != null && cycle != null && freq != cycle;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
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
                                style: TextStyle(
                                    color: AppColors.forestGreen, fontSize: 14),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'))
                                ],
                                onChanged: (_) => setState(() {}),
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  prefixText: '\$  ',
                                  prefixStyle:
                                      TextStyle(color: AppColors.mossGreen),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 10),
                                ),
                              ),
                            ),
                            // Same rhythm picker the income rows carry: how
                            // often this bill is charged.
                            PopupMenuButton<Rhythm?>(
                              tooltip: l.expenseCharged,
                              initialValue: freq ?? cycle,
                              onSelected: (f) async {
                                // Null is the "Custom" entry.
                                final chosen = f ??
                                    await showRhythmDialog(
                                        context, freq ?? cycle ?? Rhythm.monthly);
                                if (chosen == null || !mounted) return;
                                setState(() => _expFreqs[i] = chosen);
                              },
                              itemBuilder: (ctx) => [
                                for (final f in Rhythm.presets)
                                  PopupMenuItem(
                                      value: f,
                                      child: Text(f.localizedLabel(l))),
                                if (freq != null && freq.isCustom)
                                  PopupMenuItem(
                                      value: freq,
                                      child: Text(freq.localizedLabel(l))),
                                PopupMenuItem(
                                    value: null, child: Text(l.rhythmCustom)),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 6),
                                child: Icon(Icons.event_repeat_outlined,
                                    size: 18, color: AppColors.mossGreen),
                              ),
                            ),
                          ],
                        ),
                        if (differs)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, right: 26),
                            child: Text(
                              l.approxEachCycle(
                                '\$${_perCycle(double.tryParse(_amountCtrls[i].text) ?? 0.0, freq).toStringAsFixed(0)}',
                              ),
                              style: GoogleFonts.nunito(
                                  color: AppColors.mossGreen, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                ],
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

