import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../l10n/goal_labels.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../services/category_repository.dart';
import '../services/comparison_service.dart';
import '../services/goal_repository.dart';
import '../services/streak_service.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/achievements_sheet.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/category_picker.dart';
import '../widgets/info_button.dart';
import '../widgets/sapling_view.dart';
import '../widgets/ui/pressable.dart';
import '../tutorial/tutorial_content.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = [];
  List<TreeCategory> _categories = [];
  String? _filterCategoryId;
  bool _completedOnly = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final g = await GoalRepository.loadAll();
    final c = await CategoryRepository.loadAll();
    if (mounted) {
      setState(() {
        _goals = g;
        _categories = c;
        _loading = false;
      });
    }
  }

  Map<String, TreeCategory> get _categoriesById => {
    for (final c in _categories) c.id: c,
  };

  List<Goal> get _filteredGoals {
    return _goals.where((g) {
      if (_filterCategoryId != null && g.categoryId != _filterCategoryId) {
        return false;
      }
      if (_completedOnly && !g.isCompleted) return false;
      return true;
    }).toList();
  }

  int get _completedCount => _goals.where((g) => g.isCompleted).length;

  Future<void> _createGoal() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _openGoal(Goal goal) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGoal,
        backgroundColor: AppTokens.current.accent,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          l.plantAGoal,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
                              color: AppTokens.current.cardBorder,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColors.stoneBeigeColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.groveTitle,
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                color: AppColors.stoneBeigeColor,
                                fontSize: 26,
                              ),
                            ),
                            Text(
                              _loading
                                  ? l.loadingEllipsis
                                  : l.goalsGrowing(_goals.length),
                              style: GoogleFonts.nunito(
                                color: AppColors.mossGreen,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showAchievementsSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFD54F,
                            ).withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Color(0xFFBA8514),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const SectionInfoButton(section: TutorialSection.goals),
                    ],
                  ),
                ),
                if (!_loading && _goals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _GroveStatsBar(goals: _goals),
                  ),
                const SizedBox(height: 12),
                if (!_loading && _completedCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        selected: _completedOnly,
                        onSelected: (v) => setState(() => _completedOnly = v),
                        showCheckmark: false,
                        avatar: Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: _completedOnly
                              ? const Color(0xFF5C4407)
                              : const Color(0xFFBA8514),
                        ),
                        label: Text(l.completedFilter(_completedCount)),
                        labelStyle: GoogleFonts.nunito(
                          color: _completedOnly
                              ? const Color(0xFF5C4407)
                              : AppColors.stoneBeigeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                        backgroundColor: AppTokens.current.canvasSoft,
                        selectedColor: const Color(0xFFFFE082),
                        side: BorderSide(color: AppTokens.current.cardBorder),
                      ),
                    ),
                  ),
                if (!_loading && _goals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: CategoryPicker(
                        selectedCategoryId: _filterCategoryId,
                        showAllOption: true,
                        onChanged: (id) async {
                          setState(() => _filterCategoryId = id);
                          final cats = await CategoryRepository.loadAll();
                          if (mounted) setState(() => _categories = cats);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _goals.isEmpty
                      ? _EmptyGrove(onPlant: _createGoal)
                      : _filteredGoals.isEmpty
                      ? _NoGoalsInCategory(
                          onClear: () => setState(() {
                            _filterCategoryId = null;
                            _completedOnly = false;
                          }),
                        )
                      : RefreshIndicator(
                          color: AppTokens.current.accent,
                          onRefresh: _load,
                          child: AppScrollbar(
                            builder: (controller) => GridView.builder(
                              controller: controller,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                100,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.78,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                              itemCount: _filteredGoals.length,
                              itemBuilder: (ctx, i) {
                                final goal = _filteredGoals[i];
                                return _GoalCard(
                                  goal: goal,
                                  category: _categoriesById[goal.categoryId],
                                  onTap: () => _openGoal(goal),
                                );
                              },
                            ),
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
// Streak + month-over-month comparison banner
// ──────────────────────────────────────────────

class _GroveStatsBar extends StatelessWidget {
  final List<Goal> goals;
  const _GroveStatsBar({required this.goals});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final streak = StreakService.weeklyStreak(goals);
    final month = ComparisonService.monthOverMonth(goals);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTokens.current.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTokens.current.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Icon(
            streak.hasStreak
                ? Icons.local_fire_department
                : Icons.local_fire_department_outlined,
            color: streak.hasStreak
                ? (streak.atRisk
                      ? const Color(0xFFFFB74D)
                      : const Color(0xFFFF7043))
                : AppColors.mossGreen.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  streak.hasStreak
                      ? l.savingStreakWeeks(streak.currentWeeks)
                      : l.startSavingStreak,
                  style: GoogleFonts.nunito(
                    color: AppColors.stoneBeigeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  streak.hasStreak
                      ? (streak.atRisk
                            ? l.streakAtRisk
                            : l.streakBest(streak.bestWeeks))
                      : l.depositEachWeek,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _MonthComparisonChip(month: month),
        ],
      ),
    );
  }
}

class _MonthComparisonChip extends StatelessWidget {
  final PeriodComparison month;
  const _MonthComparisonChip({required this.month});

  @override
  Widget build(BuildContext context) {
    if (!month.hasActivity) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final pct = month.percentChange;
    final String text;
    final IconData icon;
    final Color color;
    if (pct == null) {
      // First month with savings — no prior baseline.
      text = l.monthThisAmount('\$${month.current.toStringAsFixed(0)}');
      icon = Icons.savings_outlined;
      color = AppTokens.current.accentStrong;
    } else if (pct >= 0) {
      text = l.monthVsLastUp(pct.round());
      icon = Icons.trending_up;
      color = AppTokens.current.accentStrong;
    } else {
      text = l.monthVsLastDown(pct.round());
      icon = Icons.trending_down;
      color = const Color(0xFFCC8A2E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.nunito(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Goal card with mini sapling
// ──────────────────────────────────────────────

class _GoalCard extends StatefulWidget {
  final Goal goal;
  final TreeCategory? category;
  final VoidCallback onTap;
  const _GoalCard({
    required this.goal,
    required this.category,
    required this.onTap,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    // Durable completion — a goal that has ever reached its target stays golden
    // (a trophy), even if money was later withdrawn below the line.
    final complete = goal.isCompleted;
    const gold = Color(0xFFBA8514);
    final palette = widget.category != null
        ? LeafPalette.fromAccent(Color(widget.category!.colorValue))
        : LeafPalette.defaultGreen;

    return PressableScale(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: complete
                ? const Color(0xFFE3B93F)
                : t.cardBorder,
            width: complete ? 1.6 : 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sapling on its tinted square — the visual centerpiece.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: complete
                      ? const Color(0xFFFBF3DC)
                      : t.accentTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Transform.scale(
                          scale: goal.isUncapped ? goal.tierScale : 1.0,
                          child: SaplingView(
                            progress: goal.progress,
                            size: Size.infinite,
                            leafPalette: palette,
                          ),
                        ),
                      ),
                    ),
                    if (complete)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(Icons.emoji_events,
                            size: 16, color: gold),
                      ),
                    if (widget.category != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(widget.category!.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  GoalIcons.forKey(goal.iconKey),
                  size: 13,
                  color: t.textSecondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${goal.currentAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    color: complete ? gold : t.accentStrong,
                    fontSize: 14,
                  ),
                ),
                Text(
                  goal.isUncapped
                      ? 'T${goal.tier}'
                      : '/ \$${goal.targetAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.nunito(
                    color: t.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        goal.isUncapped ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 6,
                backgroundColor: t.accentSoft,
                valueColor: AlwaysStoppedAnimation(
                  complete ? const Color(0xFFE3B93F) : t.accent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              complete
                  ? (goal.isComplete ? l.goalReached : l.completedCheck)
                  : goal.isUncapped
                      ? goal.localizedTierName(l)
                      : '${(goal.progress * 100).toStringAsFixed(0)}% · ${goal.localizedStageName(l)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: complete ? gold : t.textSecondary,
                fontSize: 10,
                fontWeight: complete ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Empty grove
// ──────────────────────────────────────────────

class _EmptyGrove extends StatelessWidget {
  final VoidCallback onPlant;
  const _EmptyGrove({required this.onPlant});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.spa_outlined,
              color: AppTokens.current.accent,
              size: 72,
            ),
            const SizedBox(height: 22),
            Text(
              l.noSaplingsTitle,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                color: AppColors.stoneBeigeColor,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l.noSaplingsBody,
              style: GoogleFonts.nunito(
                color: AppColors.mossGreen,
                fontSize: 14,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onPlant,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                l.plantFirstSapling,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoGoalsInCategory extends StatelessWidget {
  final VoidCallback onClear;
  const _NoGoalsInCategory({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              color: AppTokens.current.accent,
              size: 56,
            ),
            const SizedBox(height: 18),
            Text(
              l.noSaplingsCategoryTitle,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                color: AppColors.stoneBeigeColor,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.noSaplingsCategoryBody,
              style: GoogleFonts.nunito(
                color: AppColors.mossGreen,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onClear,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 11,
                ),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
              label: Text(
                l.showAll,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
