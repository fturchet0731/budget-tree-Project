import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../services/category_repository.dart';
import '../services/comparison_service.dart';
import '../services/goal_repository.dart';
import '../services/streak_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/achievements_sheet.dart';
import '../widgets/category_picker.dart';
import '../widgets/info_button.dart';
import '../widgets/sapling_view.dart';
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

  Map<String, TreeCategory> get _categoriesById =>
      {for (final c in _categories) c.id: c};

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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGoal,
        backgroundColor: AppColors.forestGreen,
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Plant a Goal',
          style: GoogleFonts.nunito(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
          ),
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _GroveBgPainter(),
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
                                color: AppColors.mossGreen
                                    .withValues(alpha: 0.35)),
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
                              'The Grove',
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
                                  : '${_goals.length} goal${_goals.length == 1 ? '' : 's'} ${_goals.length == 1 ? "is" : "are"} growing',
                              style: GoogleFonts.nunito(
                                  color: AppColors.mossGreen, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showAchievementsSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F)
                                .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFFFD54F)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.emoji_events,
                              color: Color(0xFFFFD54F), size: 20),
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
                        onSelected: (v) =>
                            setState(() => _completedOnly = v),
                        showCheckmark: false,
                        avatar: Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: _completedOnly
                              ? const Color(0xFF2E1F00)
                              : const Color(0xFFFFD54F),
                        ),
                        label: Text('Completed · $_completedCount'),
                        labelStyle: GoogleFonts.nunito(
                          color: _completedOnly
                              ? const Color(0xFF2E1F00)
                              : AppColors.stoneBeigeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                        backgroundColor: Colors.black.withValues(alpha: 0.22),
                        selectedColor: const Color(0xFFFFD54F),
                        side: BorderSide(
                            color: const Color(0xFFFFD54F)
                                .withValues(alpha: 0.55)),
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
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.lightLeaf))
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
                              color: AppColors.lightLeaf,
                              onRefresh: _load,
                              child: GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 100),
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
    final streak = StreakService.weeklyStreak(goals);
    final month = ComparisonService.monthOverMonth(goals);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.mossGreen.withValues(alpha: 0.22)),
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
                      ? '${streak.currentWeeks}-week saving streak'
                      : 'Start a saving streak',
                  style: GoogleFonts.nunito(
                    color: AppColors.stoneBeigeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  streak.hasStreak
                      ? (streak.atRisk
                          ? 'Add to a goal this week to keep it alive'
                          : 'Best: ${streak.bestWeeks} week${streak.bestWeeks == 1 ? '' : 's'} · nice work!')
                      : 'Deposit each week to grow a streak',
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
    final pct = month.percentChange;
    final String text;
    final IconData icon;
    final Color color;
    if (pct == null) {
      // First month with savings — no prior baseline.
      text = '\$${month.current.toStringAsFixed(0)} this month';
      icon = Icons.savings_outlined;
      color = AppColors.lightLeaf;
    } else if (pct >= 0) {
      text = '+${pct.round()}% vs last month';
      icon = Icons.trending_up;
      color = const Color(0xFF8BC34A);
    } else {
      text = '${pct.round()}% vs last month';
      icon = Icons.trending_down;
      color = const Color(0xFFFFB74D);
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    // Durable completion — a goal that has ever reached its target stays golden
    // (a trophy), even if money was later withdrawn below the line.
    final complete = goal.isCompleted;
    // Card uses the same gradient as the sky+ground palette so it never
    // clashes when the user changes the global theme.
    final skyGradient = AppPalettes.sky();
    final cardColors = [
      skyGradient.colors[2].withValues(alpha: 0.85),
      skyGradient.colors[4].withValues(alpha: 0.85),
      AppPalettes.groundMid().withValues(alpha: 0.95),
    ];
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: cardColors,
              stops: const [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: complete
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.85)
                  : AppColors.forestGreen.withValues(alpha: 0.40),
              width: complete ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              if (complete)
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.20),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                // Sapling — the visual centerpiece. Uncapped goals are
                // scaled per tier so a Tier 6 sapling looks substantially
                // larger than a Tier 1.
                Positioned.fill(
                  child: Transform.scale(
                    scale: goal.isUncapped ? goal.tierScale : 1.0,
                    child: SaplingView(
                      progress: goal.progress,
                      size: Size.infinite,
                      leafPalette: widget.category != null
                          ? LeafPalette.fromAccent(
                              Color(widget.category!.colorValue))
                          : LeafPalette.defaultGreen,
                    ),
                  ),
                ),
                // Top overlay — icon + name
                Positioned(
                  top: 8,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          GoalIcons.forKey(goal.iconKey),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                offset: Offset(0.5, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (complete)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F)
                                .withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFFFD54F)
                                    .withValues(alpha: 0.85)),
                          ),
                          child: const Icon(Icons.emoji_events,
                              size: 12, color: Color(0xFFFFD54F)),
                        ),
                      if (widget.category != null)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: Color(widget.category!.colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 1.4),
                            boxShadow: [
                              BoxShadow(
                                color: Color(widget.category!.colorValue)
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Bottom overlay — progress + amounts
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 9,
                  child: Container(
                    padding:
                        const EdgeInsets.fromLTRB(10, 8, 10, 9),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.46),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${goal.currentAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                color: complete
                                    ? const Color(0xFFFFD54F)
                                    : Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              goal.isUncapped
                                  ? 'T${goal.tier}'
                                  : '/ \$${goal.targetAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.nunito(
                                color: Colors.white
                                    .withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: goal.isUncapped
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            valueColor: AlwaysStoppedAnimation(
                              complete
                                  ? const Color(0xFFFFD54F)
                                  : AppColors.lightLeaf,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          complete
                              ? (goal.isComplete ? 'Goal reached!' : 'Completed ✓')
                              : goal.isUncapped
                                  ? goal.tierName
                                  : '${(goal.progress * 100).toStringAsFixed(0)}% · ${goal.stageName}',
                          style: GoogleFonts.nunito(
                            color: complete
                                ? const Color(0xFFFFD54F)
                                : Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: complete
                                ? FontWeight.bold
                                : FontWeight.normal,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_outlined,
                color: AppColors.lightLeaf, size: 72),
            const SizedBox(height: 22),
            Text(
              'No saplings yet',
              style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Plant a goal sapling and watch it grow as you save toward it.',
              style: GoogleFonts.nunito(
                  color: AppColors.mossGreen, fontSize: 14, height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onPlant,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Plant Your First Sapling',
                style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
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
              'No saplings in this category yet',
              style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Plant a goal in this category or clear the filter to see all saplings.',
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
// Grove background — soft glow + ground
// ──────────────────────────────────────────────

class _GroveBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft sun glow upper-right
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.10),
      130,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFEE58).withValues(alpha: 0.18),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(
            center: Offset(w * 0.82, h * 0.10), radius: 130)),
    );

    // Distant silhouetted trees row
    final rng = math.Random(13);
    for (int i = 0; i < 12; i++) {
      final tx = (i / 11) * w + rng.nextDouble() * 22;
      final ty = h * (0.36 + rng.nextDouble() * 0.08);
      final op = 0.18 + rng.nextDouble() * 0.18;
      _silhouette(canvas, tx, ty, op);
    }
  }

  void _silhouette(Canvas canvas, double tx, double ty, double op) {
    final c = const Color(0xFF0A1E0A).withValues(alpha: op);
    canvas.drawCircle(Offset(tx, ty), 22, Paint()..color = c);
    canvas.drawCircle(
        Offset(tx - 12, ty + 8), 16, Paint()..color = c);
    canvas.drawCircle(
        Offset(tx + 11, ty + 6), 14, Paint()..color = c);
    canvas.drawRect(
      Rect.fromLTWH(tx - 3, ty + 16, 6, 16),
      Paint()..color = c,
    );
  }

  @override
  bool shouldRepaint(_GroveBgPainter old) => false;
}
