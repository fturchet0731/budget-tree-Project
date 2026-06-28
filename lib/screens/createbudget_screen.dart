import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/pay_frequency.dart';
import '../l10n/app_localizations.dart';
import '../l10n/preset_labels.dart';
import '../models/ai_plan.dart';
import '../models/budget_model.dart';
import '../services/ai_coach_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../widgets/acorn_coach.dart';
import '../widgets/allocation_plan_card.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/bark_card.dart';
import '../widgets/info_button.dart';
import '../widgets/vine_step_indicator.dart';
import '../tutorial/tutorial_content.dart';
import 'budget_tree_screen.dart';

class CreateBudgetScreen extends StatefulWidget {
  /// When true, Acorn rides along and coaches each phase (used by the tour).
  final bool tutorial;
  const CreateBudgetScreen({super.key, this.tutorial = false});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  int _step = 0;

  // True once the user has settled allocations on the Plan step (by picking an
  // AI plan or entering amounts manually). Gates leaving the Plan step. Reset
  // whenever the expense set changes so stale allocations aren't carried over.
  bool _planSettled = false;

  // Step 1 – Income
  final List<IncomeSource> _incomeSources = [];
  final _incomeNameCtrl = TextEditingController();
  final _incomeAmountCtrl = TextEditingController();

  // Step 2 – Expenses
  final List<ExpenseCategory> _expenses = [];
  final _expNameCtrl = TextEditingController();
  final _expAmountCtrl = TextEditingController();
  String _selectedIconKey = 'other';

  // Step 3 – Budget name + pay schedule
  final _budgetNameCtrl = TextEditingController(text: 'My Budget');
  PayFrequency? _payFrequency;
  DateTime? _firstPayDate;

  // icon key + display name
  static const _presets = [
    ('home', 'Housing'),
    ('food', 'Food'),
    ('transport', 'Transport'),
    ('savings', 'Savings'),
    ('entertainment', 'Entertainment'),
    ('subscriptions', 'Subscriptions'),
    ('healthcare', 'Healthcare'),
    ('personal', 'Personal'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _incomeNameCtrl.dispose();
    _incomeAmountCtrl.dispose();
    _expNameCtrl.dispose();
    _expAmountCtrl.dispose();
    _budgetNameCtrl.dispose();
    super.dispose();
  }

  double get _totalIncome => _incomeSources.fold(0.0, (s, e) => s + e.amount);
  double get _totalAllocated => _expenses.fold(0.0, (s, e) => s + e.allocated);

  void _addIncome() {
    final name = _incomeNameCtrl.text.trim();
    final amount = double.tryParse(_incomeAmountCtrl.text) ?? 0;
    if (name.isEmpty || amount <= 0) return;
    setState(() {
      _incomeSources.add(IncomeSource(name: name, amount: amount));
      _incomeNameCtrl.clear();
      _incomeAmountCtrl.clear();
    });
  }

  void _addExpense() {
    final name = _expNameCtrl.text.trim();
    // Amount is optional now: the user declares the expense here and the AI plan
    // step (or manual entry there) decides how much to allocate.
    final amount = double.tryParse(_expAmountCtrl.text) ?? 0;
    if (name.isEmpty) return;
    setState(() {
      _expenses.add(
        ExpenseCategory(
          name: name,
          allocated: amount < 0 ? 0 : amount,
          emoji: _selectedIconKey,
        ),
      );
      _expNameCtrl.clear();
      _expAmountCtrl.clear();
      _planSettled = false; // expense set changed; re-settle on the Plan step
    });
  }

  void _removeExpense(int i) => setState(() {
    _expenses.removeAt(i);
    _planSettled = false;
  });

  /// Reorder the declared expenses on the Plan step. The list order *is* the
  /// importance ranking handed to the AI (top = most important). [newIndex] is
  /// already adjusted by `onReorderItem`, so no off-by-one correction is needed.
  void _reorderExpense(int oldIndex, int newIndex) => setState(() {
    final item = _expenses.removeAt(oldIndex);
    _expenses.insert(newIndex, item);
  });

  /// Apply a chosen AI plan: write each plan item's amount onto the matching
  /// expense (by name), leaving any leftover unallocated as savings headroom.
  void _applyPlan(AllocationPlan plan) => setState(() {
    for (final cat in _expenses) {
      final match = plan.items.cast<PlanItem?>().firstWhere(
        (it) => it!.name.toLowerCase().trim() == cat.name.toLowerCase().trim(),
        orElse: () => null,
      );
      if (match != null) cat.allocated = match.amount;
    }
    _planSettled = true;
  });

  /// Mark allocations settled after the user edits amounts manually.
  void _settleManual() => setState(() => _planSettled = true);

  Future<void> _plantTree() async {
    final model = BudgetModel(
      budgetName: _budgetNameCtrl.text.trim().isEmpty
          ? 'My Budget'
          : _budgetNameCtrl.text.trim(),
      incomeSources: _incomeSources,
      expenses: _expenses,
      payFrequency: _payFrequency,
      firstPayDate: _firstPayDate,
    );
    final planted = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, anim, secondaryAnim) =>
            BudgetTreeScreen(budget: model, tutorial: widget.tutorial),
        transitionsBuilder: (_, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    // The tree was saved into the forest. Close the create flow too, handing
    // the "planted" signal to whoever opened us (the dashboard announces the
    // new tree; the guided tour uses it to mark the step complete).
    if (planted == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final titles = [
      l.stepIncomeTitle,
      l.stepExpensesTitle,
      l.stepPlanTitle,
      l.stepNamePayTitle,
    ];
    final subtitles = [
      l.stepIncomeSub,
      l.stepExpensesSub,
      l.stepPlanSub,
      l.stepNamePaySub,
    ];
    final stepTitle = titles[_step];
    final stepSubtitle = subtitles[_step];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Atmospheric background — palette-driven so the Settings theme
          //    changes this screen's mood like every other surface ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _NatureBgPainter())),
          // ── Foreground content ───────────────────
          SafeArea(
            child: Column(
              children: [
                _CreateHeader(
                  step: _step,
                  title: stepTitle,
                  subtitle: stepSubtitle,
                  onBack: _step == 0
                      ? () => Navigator.pop(context)
                      : () => setState(() => _step--),
                ),
                VineStepIndicator(
                  currentStep: _step,
                  steps: [
                    VineStep(label: l.vineSeed, icon: Icons.eco),
                    VineStep(
                      label: l.vineBranches,
                      icon: Icons.account_tree_outlined,
                    ),
                    VineStep(label: l.vinePlan, icon: Icons.auto_awesome),
                    VineStep(label: l.vineRoots, icon: Icons.park_outlined),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(anim);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: _step == 0
                        ? _IncomeStep(
                            key: const ValueKey(0),
                            sources: _incomeSources,
                            nameCtrl: _incomeNameCtrl,
                            amountCtrl: _incomeAmountCtrl,
                            suggestions: incomeSuggestionKeys,
                            onAdd: _addIncome,
                            onRemove: (i) =>
                                setState(() => _incomeSources.removeAt(i)),
                          )
                        : _step == 1
                        ? _ExpenseStep(
                            key: const ValueKey(1),
                            expenses: _expenses,
                            nameCtrl: _expNameCtrl,
                            amountCtrl: _expAmountCtrl,
                            selectedIconKey: _selectedIconKey,
                            totalIncome: _totalIncome,
                            totalAllocated: _totalAllocated,
                            presets: _presets,
                            onAdd: _addExpense,
                            onRemove: _removeExpense,
                            onPresetTap: (name, iconKey) => setState(() {
                              _expNameCtrl.text = iconKey == 'other'
                                  ? ''
                                  : name;
                              _selectedIconKey = iconKey;
                            }),
                          )
                        : _step == 2
                        ? _PlanStep(
                            key: const ValueKey(2),
                            income: _totalIncome,
                            expenses: _expenses,
                            settled: _planSettled,
                            onReorder: _reorderExpense,
                            onApplyPlan: _applyPlan,
                            onSettleManual: _settleManual,
                          )
                        : _PersonalStep(
                            key: const ValueKey(3),
                            nameCtrl: _budgetNameCtrl,
                            payFrequency: _payFrequency,
                            firstPayDate: _firstPayDate,
                            onFrequencyChanged: (f) =>
                                setState(() => _payFrequency = f),
                            onFirstPayDateChanged: (d) =>
                                setState(() => _firstPayDate = d),
                          ),
                  ),
                ),
                _BottomBar(
                  step: _step,
                  lastStep: 3,
                  canAdvance: _step == 0
                      ? _incomeSources.isNotEmpty
                      : _step == 1
                      ? _expenses.isNotEmpty
                      : _step == 2
                      ? _planSettled
                      : true,
                  onNext: () {
                    if (_step < 3) {
                      setState(() => _step++);
                    } else {
                      _plantTree();
                    }
                  },
                ),
              ],
            ),
          ),
          // ── Acorn coach for the current phase (tutorial only) ──
          // Fills the screen so the user can drag Acorn's tip anywhere.
          if (widget.tutorial)
            Positioned.fill(
              child: SafeArea(
                child: AcornCoach(
                  lessonKey: _step,
                  lines: createStepSteps(_step, l),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Atmospheric background painter (sky → forest)
// ──────────────────────────────────────────────

class _NatureBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The base gradient is painted behind us from AppPalettes.deepForest();
    // here we only add the celestial glow + silhouettes so the whole scene
    // follows the active palette.

    // Soft celestial glow upper right, tinted to the active palette.
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.08),
      120,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppPalettes.celestialGlow().withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: Offset(w * 0.85, h * 0.08), radius: 120),
            ),
    );

    // Distant tree silhouettes near the bottom (fading into bg)
    final silhouette = const Color(0xFF050D04).withValues(alpha: 0.75);
    final treeY = h * 0.86;
    for (int i = 0; i < 12; i++) {
      final t = (i / 11);
      final x = t * w;
      // Three overlapping ovals per tree forming a simple silhouette
      final cR = 22.0 + ((i * 7) % 4) * 4;
      canvas.drawCircle(Offset(x, treeY - 6), cR, Paint()..color = silhouette);
      canvas.drawCircle(
        Offset(x - 14, treeY + 6),
        cR * 0.8,
        Paint()..color = silhouette,
      );
      canvas.drawCircle(
        Offset(x + 12, treeY + 6),
        cR * 0.7,
        Paint()..color = silhouette,
      );
      // Tiny trunk
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, treeY + 18), width: 5, height: 16),
        Paint()..color = silhouette,
      );
    }

    // Foreground vignette darkening the very bottom
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.8, w, h * 0.2),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xFF050905)],
        ).createShader(Rect.fromLTWH(0, h * 0.8, w, h * 0.2)),
    );
  }

  @override
  bool shouldRepaint(_NatureBgPainter old) => false;
}

// ──────────────────────────────────────────────
// Header bar — back button + step title plaque
// ──────────────────────────────────────────────

class _CreateHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  const _CreateHeader({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.mossGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                step == 0 ? Icons.arrow_back : Icons.chevron_left,
                color: AppColors.stoneBeigeColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(step),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: AppColors.stoneBeigeColor,
                      fontSize: 22,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionInfoButton(section: TutorialSection.create),
          const SizedBox(width: 10),
          // Decorative small leaf badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              '${step + 1}',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 1 – Income
// ──────────────────────────────────────────────

class _IncomeStep extends StatelessWidget {
  final List<IncomeSource> sources;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final List<String> suggestions;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _IncomeStep({
    super.key,
    required this.sources,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.suggestions,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = sources.fold(0.0, (s, e) => s + e.amount);
    return AppScrollbar(
      builder: (controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          // Quick-picks card
          BarkCard(
            label: l.quickPick,
            icon: Icons.bolt,
            accent: AppColors.riverBlue,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map(
                    (s) => GestureDetector(
                      onTap: () => nameCtrl.text = incomeSuggestionLabel(l, s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.riverBlue.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.riverBlue.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.water_drop_outlined,
                              size: 12,
                              color: AppColors.skyBlue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              incomeSuggestionLabel(l, s),
                              style: GoogleFonts.nunito(
                                color: AppColors.stoneBeigeColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          // Add a source card
          BarkCard(
            label: l.addASource,
            icon: Icons.add_circle_outline,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.stoneBeigeColor),
                    decoration: InputDecoration(
                      labelText: l.sourceName,
                      hintText: l.sourceNameHint,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: amountCtrl,
                    style: const TextStyle(color: AppColors.stoneBeigeColor),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l.amountDollar,
                      hintText: '0.00',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _AddButton(onTap: onAdd),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (sources.isNotEmpty)
            BarkCard(
              label: l.rootsFeedingTree,
              icon: Icons.water_drop,
              accent: AppColors.lightLeaf,
              child: Column(
                children: [
                  ...sources.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.riverBlue.withValues(
                                alpha: 0.18,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.water_drop_outlined,
                              color: AppColors.riverBlue,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.name,
                              style: GoogleFonts.nunito(
                                color: AppColors.stoneBeigeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '\$${s.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.nunito(
                              color: AppColors.lightLeaf,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.stoneBeigeColor.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            onPressed: () => onRemove(i),
                          ),
                        ],
                      ),
                    );
                  }),
                  Divider(
                    color: AppColors.mossGreen.withValues(alpha: 0.3),
                    height: 22,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.totalMonthlyIncome,
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightLeaf,
                          fontSize: 20,
                        ),
                      ),
                    ],
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
// Step 2 – Expenses
// ──────────────────────────────────────────────

class _ExpenseStep extends StatelessWidget {
  final List<ExpenseCategory> expenses;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final String selectedIconKey;
  final double totalIncome;
  final double totalAllocated;
  final List<(String, String)> presets;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(String name, String iconKey) onPresetTap;

  const _ExpenseStep({
    super.key,
    required this.expenses,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.selectedIconKey,
    required this.totalIncome,
    required this.totalAllocated,
    required this.presets,
    required this.onAdd,
    required this.onRemove,
    required this.onPresetTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final remaining = totalIncome - totalAllocated;
    final overBudget = remaining < 0;

    return AppScrollbar(
      builder: (controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          // Budget meter
          BarkCard(
            label: l.canopyMeter,
            icon: Icons.donut_large,
            accent: overBudget ? AppColors.dangerRed : AppColors.lightLeaf,
            child: Column(
              children: [
                _BudgetBar(
                  totalIncome: totalIncome,
                  totalAllocated: totalAllocated,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.allocatedAmount(
                        '\$${totalAllocated.toStringAsFixed(2)}',
                      ),
                      style: GoogleFonts.nunito(
                        color: AppColors.stoneBeigeColor,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      overBudget
                          ? l.overByAmount(
                              '\$${(-remaining).toStringAsFixed(2)}',
                            )
                          : l.remainingAmount(
                              '\$${remaining.toStringAsFixed(2)}',
                            ),
                      style: GoogleFonts.nunito(
                        color: overBudget
                            ? AppColors.dangerRed
                            : AppColors.lightLeaf,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Presets card
          BarkCard(
            label: l.pickABranch,
            icon: Icons.account_tree_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((p) {
                final iconKey = p.$1;
                final name = expensePresetLabel(l, iconKey);
                final isSelected = selectedIconKey == iconKey;
                return GestureDetector(
                  onTap: () => onPresetTap(name, iconKey),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.forestGreen.withValues(alpha: 0.45)
                          : AppColors.soilMid,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.lightLeaf
                            : AppColors.mossGreen.withValues(alpha: 0.4),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.lightLeaf.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CategoryIcons.forKey(iconKey),
                          size: 15,
                          color: isSelected
                              ? AppColors.lightLeaf
                              : AppColors.mossGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: GoogleFonts.nunito(
                            color: isSelected
                                ? AppColors.lightLeaf
                                : AppColors.stoneBeigeColor,
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          // Add a branch card
          BarkCard(
            label: l.addABranch,
            icon: Icons.add_circle_outline,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.stoneBeigeColor),
                    decoration: InputDecoration(labelText: l.categoryName),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: amountCtrl,
                    style: const TextStyle(color: AppColors.stoneBeigeColor),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(labelText: l.amountDollar),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _AddButton(onTap: onAdd),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (expenses.isNotEmpty)
            BarkCard(
              label: l.branchesReachingOut,
              icon: Icons.spa_outlined,
              child: Column(
                children: expenses.asMap().entries.map((entry) {
                  final i = entry.key;
                  final exp = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen.withValues(
                              alpha: 0.20,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CategoryIcons.forKey(exp.emoji),
                            color: AppColors.lightLeaf,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            exp.name,
                            style: GoogleFonts.nunito(
                              color: AppColors.stoneBeigeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '\$${exp.allocated.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            color: AppColors.lightLeaf,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.stoneBeigeColor.withValues(
                              alpha: 0.45,
                            ),
                          ),
                          onPressed: () => onRemove(i),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 3 – AI allocation plan (rank importance, get plans, pick or do manual)
// ──────────────────────────────────────────────

class _PlanStep extends StatefulWidget {
  final double income;
  final List<ExpenseCategory> expenses;
  final bool settled;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(AllocationPlan) onApplyPlan;
  final VoidCallback onSettleManual;

  const _PlanStep({
    super.key,
    required this.income,
    required this.expenses,
    required this.settled,
    required this.onReorder,
    required this.onApplyPlan,
    required this.onSettleManual,
  });

  @override
  State<_PlanStep> createState() => _PlanStepState();
}

class _PlanStepState extends State<_PlanStep> {
  bool _loading = false;
  String? _error;
  List<AllocationPlan>? _plans;
  int? _selected;
  bool _manual = false;

  final Map<ExpenseCategory, TextEditingController> _amountCtrls = {};

  @override
  void initState() {
    super.initState();
    // With no AI available there's nothing to generate, so start in manual mode.
    _manual = !AiCoachService.instance.isAvailable;
  }

  @override
  void dispose() {
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(ExpenseCategory cat) =>
      _amountCtrls.putIfAbsent(
        cat,
        () => TextEditingController(
          text: cat.allocated > 0 ? cat.allocated.toStringAsFixed(0) : '',
        ),
      );

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ranked = [
        for (var i = 0; i < widget.expenses.length; i++)
          RankedExpense(name: widget.expenses[i].name, rank: i + 1),
      ];
      final plans = await AiCoachService.instance.budgetPlans(
        income: widget.income,
        expenses: ranked,
      );
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
      });
    } on AiUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _manual = true; // fall back to manual entry
      });
    }
  }

  void _applyManual() {
    for (final cat in widget.expenses) {
      cat.allocated = double.tryParse(_ctrlFor(cat).text) ?? 0;
    }
    widget.onSettleManual();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final aiAvailable = AiCoachService.instance.isAvailable;
    return AppScrollbar(
      builder: (controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          // Importance ranking
          BarkCard(
            label: l.rankImportance,
            icon: Icons.low_priority,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.rankImportanceHint,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (o, n) {
                    widget.onReorder(o, n);
                    setState(() {}); // refresh rank numbers
                  },
                  children: [
                    for (var i = 0; i < widget.expenses.length; i++)
                      Padding(
                        key: ValueKey(widget.expenses[i]),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.forestGreen.withValues(
                                  alpha: 0.4,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.nunito(
                                  color: AppColors.lightLeaf,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              CategoryIcons.forKey(widget.expenses[i].emoji),
                              color: AppColors.mossGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.expenses[i].name,
                                style: GoogleFonts.nunito(
                                  color: AppColors.stoneBeigeColor,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: i,
                              child: const Icon(
                                Icons.drag_handle,
                                color: AppColors.mossGreen,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!_manual) ...[
            if (_plans == null)
              _GenerateButton(loading: _loading, onTap: _generate)
            else ...[
              Text(
                l.pickAPlan,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _plans!.length; i++)
                AllocationPlanCard(
                  plan: _plans![i],
                  selected: _selected == i,
                  onSelect: () {
                    setState(() => _selected = i);
                    widget.onApplyPlan(_plans![i]);
                  },
                ),
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l.regeneratePlans),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _manual = true),
                child: Text(l.setAmountsMyself),
              ),
            ),
          ] else ...[
            BarkCard(
              label: l.setAmounts,
              icon: Icons.tune,
              child: Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        l.aiUnavailableManual,
                        style: GoogleFonts.nunito(
                          color: AppColors.warningAmber,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  for (final cat in widget.expenses)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            CategoryIcons.forKey(cat.emoji),
                            color: AppColors.mossGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: GoogleFonts.nunito(
                                color: AppColors.stoneBeigeColor,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: _ctrlFor(cat),
                              style: const TextStyle(
                                color: AppColors.stoneBeigeColor,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                prefixText: '\$ ',
                                isDense: true,
                                labelText: l.amountDollar,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _applyManual,
                      icon: const Icon(Icons.check),
                      label: Text(l.useTheseAmounts),
                    ),
                  ),
                ],
              ),
            ),
            if (aiAvailable) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _manual = false),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(l.useAiPlansInstead),
                ),
              ),
            ],
          ],
          if (widget.settled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.lightLeaf,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.allocationsReady,
                    style: GoogleFonts.nunito(
                      color: AppColors.lightLeaf,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
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

class _GenerateButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GenerateButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
          loading ? l.thinkingUp : l.generatePlans,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final double totalIncome;
  final double totalAllocated;
  const _BudgetBar({required this.totalIncome, required this.totalAllocated});

  @override
  Widget build(BuildContext context) {
    final pct = totalIncome > 0
        ? (totalAllocated / totalIncome).clamp(0.0, 1.0)
        : 0.0;
    final overBudget = totalAllocated > totalIncome;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 10,
        backgroundColor: AppColors.darkBark,
        valueColor: AlwaysStoppedAnimation(
          overBudget
              ? AppColors.dangerRed
              : pct > 0.85
              ? AppColors.warningAmber
              : AppColors.forestGreen,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 3 – Personal info
// ──────────────────────────────────────────────

class _PersonalStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final PayFrequency? payFrequency;
  final DateTime? firstPayDate;
  final ValueChanged<PayFrequency?> onFrequencyChanged;
  final ValueChanged<DateTime?> onFirstPayDateChanged;

  const _PersonalStep({
    super.key,
    required this.nameCtrl,
    required this.payFrequency,
    required this.firstPayDate,
    required this.onFrequencyChanged,
    required this.onFirstPayDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppScrollbar(
      builder: (controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          // Name card
          BarkCard(
            label: l.nameYourTree,
            icon: Icons.park,
            child: TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.stoneBeigeColor),
              decoration: InputDecoration(
                labelText: l.budgetName,
                hintText: l.budgetNameHint,
                prefixIcon: const Icon(Icons.park, color: AppColors.mossGreen),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 14),
          // Pay schedule card
          BarkCard(
            label: l.payScheduleLabel,
            icon: Icons.event_repeat_outlined,
            accent: AppColors.riverBlue,
            child: Column(
              children: [
                DropdownButtonFormField<PayFrequency>(
                  initialValue: payFrequency,
                  isExpanded: true,
                  dropdownColor: AppColors.darkBark,
                  style: const TextStyle(color: AppColors.stoneBeigeColor),
                  decoration: InputDecoration(
                    labelText: l.payFrequencyLabel,
                    prefixIcon: const Icon(
                      Icons.event_repeat_outlined,
                      color: AppColors.mossGreen,
                    ),
                  ),
                  items: PayFrequency.values
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                            f.label,
                            style: const TextStyle(
                              color: AppColors.stoneBeigeColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onFrequencyChanged,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: firstPayDate ?? now,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 2),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.lightLeaf,
                            onPrimary: Colors.white,
                            surface: AppColors.darkBark,
                            onSurface: AppColors.stoneBeigeColor,
                          ),
                          dialogTheme: const DialogThemeData(
                            backgroundColor: AppColors.darkBark,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) onFirstPayDateChanged(picked);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.soilMid,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.mossGreen.withValues(alpha: 0.40),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.mossGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            firstPayDate == null
                                ? l.firstPayDate
                                : l.firstPayOn(_formatDate(firstPayDate!, l)),
                            style: TextStyle(
                              color: firstPayDate == null
                                  ? AppColors.stoneBeigeColor.withValues(
                                      alpha: 0.5,
                                    )
                                  : AppColors.stoneBeigeColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (firstPayDate != null)
                          IconButton(
                            onPressed: () => onFirstPayDateChanged(null),
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.mossGreen.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BarkCard(
            accent: AppColors.riverBlue,
            padding: const EdgeInsets.all(14),
            showAccentStrip: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.riverBlue,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.payScheduleInfo,
                    style: GoogleFonts.nunito(
                      color: AppColors.stoneBeigeColor,
                      fontSize: 12,
                      height: 1.5,
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

  static String _formatDate(DateTime d, AppLocalizations l) {
    final m = monthAbbrevs(l);
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ──────────────────────────────────────────────
// Vibrant circular "add" button
// ──────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8BE65C), Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightLeaf.withValues(alpha: 0.55),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Bottom navigation bar
// ──────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int step;
  final int lastStep;
  final bool canAdvance;
  final VoidCallback onNext;

  const _BottomBar({
    required this.step,
    required this.lastStep,
    required this.canAdvance,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLast = step == lastStep;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: canAdvance
              ? const LinearGradient(
                  colors: [
                    Color(0xFF66BB6A),
                    Color(0xFF2E7D32),
                    Color(0xFF1B5E20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.forestGreen.withValues(alpha: 0.35),
                    AppColors.darkBark,
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: canAdvance
                ? Colors.white.withValues(alpha: 0.5)
                : AppColors.mossGreen.withValues(alpha: 0.2),
            width: canAdvance ? 1.6 : 1,
          ),
          boxShadow: canAdvance
              ? [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canAdvance ? onNext : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLast ? Icons.park : Icons.arrow_forward,
                    color: canAdvance
                        ? Colors.white
                        : AppColors.stoneBeigeColor.withValues(alpha: 0.5),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      isLast ? l.plantMyBudgetTree : l.next,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        color: canAdvance
                            ? Colors.white
                            : AppColors.stoneBeigeColor.withValues(alpha: 0.5),
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
