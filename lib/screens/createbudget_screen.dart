import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/rhythm.dart';
import '../l10n/app_localizations.dart';
import '../l10n/rhythm_labels.dart';
import '../l10n/preset_labels.dart';
import '../l10n/survey_labels.dart';
import '../models/ai_plan.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../services/ai_coach_service.dart';
import '../services/goal_repository.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/category_icons.dart';
import '../widgets/acorn_coach.dart';
import '../widgets/allocation_plan_card.dart';
import '../widgets/rhythm_picker.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/info_button.dart';
import '../theme/app_shadows.dart';
import '../widgets/ui/app_buttons.dart';
import '../widgets/ui/app_card.dart' show AppCard;
import '../widgets/ui/step_progress.dart';
import '../tutorial/tutorial_content.dart';
import '../tutorial/tutorial_overlay.dart';
import 'budget_tree_screen.dart';

/// Deep amber used for small labels on white cards (the shared warm accent,
/// dark enough to stay readable on a light surface).
const _amber = Color(0xFFBA8514);

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

  // Step 1 – Income. The budget cycle is chosen here, up front, so every
  // amount in the wizard reads "per cycle"; each income source carries its
  // own arrival rhythm and is normalised into the cycle.
  final List<IncomeSource> _incomeSources = [];
  final _incomeNameCtrl = TextEditingController();
  final _incomeAmountCtrl = TextEditingController();
  Rhythm? _newIncomeFreq; // null = arrives once per budget cycle
  // Progressive reveal: the budget cycle card only appears once the user has
  // confirmed they're done listing income, so the step opens uncluttered.
  bool _incomeConfirmed = false;

  // Step 2 – Expenses
  final List<ExpenseCategory> _expenses = [];
  final _expNameCtrl = TextEditingController();
  final _expAmountCtrl = TextEditingController();
  String _selectedIconKey = 'other';
  Rhythm? _newExpenseFreq; // null = charged once per budget cycle
  // Same reveal pattern: the budget-standing summary appears once the user
  // confirms they're done adding expense branches.
  bool _expensesConfirmed = false;

  // Scroll-through gate: Next stays disabled until the user has scrolled to
  // the end of the current step, so nothing below the fold gets missed. A
  // step whose content fits on screen passes immediately (its first metrics
  // notification reports nothing left below), and freshly revealed content
  // that extends past the fold re-arms the gate.
  final Map<int, bool> _seenEnd = {};
  final Map<int, double> _lastMaxExtent = {};
  // Guards against piling up post-frame callbacks when many scroll/metrics
  // notifications fire within one frame (see [_noteScrollMetrics]).
  bool _gateRebuildScheduled = false;

  // Step 3 – Survey (questionnaire answers keyed by question key -> option key)
  // plus an optional free-text note the coach folds into its reasoning.
  // Questions are shown one at a time; skipped ones are remembered so leaving
  // and re-entering the step resumes at the summary instead of re-asking.
  final Map<String, String> _surveyAnswers = {};
  final Set<String> _surveySkipped = {};
  final _noteCtrl = TextEditingController();

  // Finishing touches (Plan step) – budget name + first pay date. The cycle
  // itself ([_payFrequency]) is picked on the Income step.
  // Seeded with the localized default in [didChangeDependencies], since the
  // field initialiser runs before there's a context to read strings from.
  final _budgetNameCtrl = TextEditingController();
  bool _nameSeeded = false;
  Rhythm _payFrequency = Rhythm.monthly;
  DateTime? _firstPayDate;

  // The widgets Acorn's coach can ring while he talks about them (tutorial
  // mode). Keys are attached unconditionally — each lives in at most one
  // place in the tree at a time — so the map can stay simple.
  final Map<String, GlobalKey> _coachTargets = {
    CoachTargets.incomeAdd: GlobalKey(),
    CoachTargets.expenseAdd: GlobalKey(),
    CoachTargets.remaining: GlobalKey(),
    CoachTargets.survey: GlobalKey(),
    CoachTargets.plans: GlobalKey(),
    CoachTargets.finishing: GlobalKey(),
    CoachTargets.next: GlobalKey(),
  };

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed once so a language change mid-wizard never overwrites what the user
    // has typed.
    if (!_nameSeeded) {
      _nameSeeded = true;
      _budgetNameCtrl.text = AppLocalizations.of(context).defaultBudgetName;
    }
  }

  @override
  void dispose() {
    _incomeNameCtrl.dispose();
    _incomeAmountCtrl.dispose();
    _expNameCtrl.dispose();
    _expAmountCtrl.dispose();
    _noteCtrl.dispose();
    _budgetNameCtrl.dispose();
    super.dispose();
  }

  /// The questionnaire answers converted to readable "question: answer" pairs
  /// for the coach. Only answered questions are included.
  Map<String, String> _surveyForAi(AppLocalizations l) => {
    for (final q in budgetSurveyQuestions())
      if (_surveyAnswers[q.key] != null)
        q.prompt(l): q.options
            .firstWhere((o) => o.key == _surveyAnswers[q.key])
            .label(l),
  };

  /// Add a funding branch that routes the budget's leftover into [goal]. The
  /// branch is linked to the goal so [PayScheduler] auto-funds it each cycle.
  void _addGoalBranch(String name, double amount, String goalId) {
    setState(() {
      _expenses.add(
        ExpenseCategory(
          name: name,
          allocated: amount,
          emoji: 'savings',
          linkedGoalIds: [goalId],
        ),
      );
      // Leftover is intentionally consumed; allocations stay settled.
    });
  }

  double get _totalIncome =>
      _incomeSources.fold(0.0, (s, e) => s + e.amountPerCycle(_payFrequency));
  double get _totalAllocated =>
      _expenses.fold(0.0, (s, e) => s + e.allocatedPerCycle(_payFrequency));
  bool get _overBudget => _totalAllocated > _totalIncome + 0.005;

  /// Feed every scroll/metrics report from the current step into the
  /// scroll-through gate. Reaching (or starting at) the end opens it; content
  /// growing past the fold re-arms it.
  void _noteScrollMetrics(ScrollMetrics m) {
    if (!m.hasContentDimensions || !m.hasPixels || m.axis != Axis.vertical) {
      return;
    }
    const eps = 40.0;
    final step = _step;
    final atEnd = m.extentAfter <= eps;
    final grew = m.maxScrollExtent > (_lastMaxExtent[step] ?? 0) + eps;
    _lastMaxExtent[step] = m.maxScrollExtent;
    final next = atEnd ? true : (grew ? false : _seenEnd[step]);
    if (next == null || next == _seenEnd[step]) return;
    // These notifications arrive DURING layout (a viewport/scroll correction
    // as revealed content or the keyboard resizes the view). Calling setState
    // synchronously here throws "Build scheduled during frame", so record the
    // flag now and coalesce a single rebuild once the frame has finished.
    _seenEnd[step] = next;
    if (_gateRebuildScheduled) return;
    _gateRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gateRebuildScheduled = false;
      if (mounted) setState(() {});
    });
  }

  /// Acorn steps in and refuses to move on while the branches ask for more
  /// than the income brings in, telling the user what to trim. Runs for every
  /// user, tutorial or not.
  void _warnOverBudget() {
    final l = AppLocalizations.of(context);
    final over = _totalAllocated - _totalIncome;
    showTutorialDialog(
      context,
      steps: [
        TutorialStep(l.tutOverBudget1),
        TutorialStep(l.tutOverBudget2('\$${over.toStringAsFixed(2)}')),
      ],
      lastStepHint: l.overBudgetFixHint,
      skipLabel: l.tourClose,
    );
  }

  void _addIncome() {
    final name = _incomeNameCtrl.text.trim();
    final amount = double.tryParse(_incomeAmountCtrl.text) ?? 0;
    if (name.isEmpty || amount <= 0) return;
    setState(() {
      _incomeSources.add(IncomeSource(
        name: name,
        amount: amount,
        frequency: _newIncomeFreq ?? _payFrequency,
      ));
      _incomeNameCtrl.clear();
      _incomeAmountCtrl.clear();
      _planSettled = false; // income changed; the plan totals are stale
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
          frequency: _newExpenseFreq ?? _payFrequency,
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
    // Emptying the list retracts the revealed summary.
    if (_expenses.isEmpty) _expensesConfirmed = false;
  });

  /// Apply a chosen AI plan: write each plan item's amount onto the matching
  /// expense (by name), leaving any leftover unallocated as savings headroom.
  /// Plan amounts are per budget cycle, so an expense with its own charge
  /// rhythm converts them back into its raw amount.
  void _applyPlan(AllocationPlan plan) => setState(() {
    for (final cat in _expenses) {
      final match = plan.items.cast<PlanItem?>().firstWhere(
        (it) => it!.name.toLowerCase().trim() == cat.name.toLowerCase().trim(),
        orElse: () => null,
      );
      if (match != null) cat.setAllocatedPerCycle(match.amount, _payFrequency);
    }
    _planSettled = true;
  });

  /// Mark allocations settled after the user edits amounts manually.
  void _settleManual() => setState(() => _planSettled = true);

  Future<void> _plantTree() async {
    final model = BudgetModel(
      budgetName: _budgetNameCtrl.text.trim().isEmpty
          ? AppLocalizations.of(context).defaultBudgetName
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
      l.stepSurveyTitle,
      l.stepPlanTitle,
    ];
    final subtitles = [
      l.stepIncomeSub,
      l.stepExpensesSub,
      l.stepSurveySub,
      l.stepPlanSub,
    ];
    final stepTitle = titles[_step];
    final stepSubtitle = subtitles[_step];

    return Scaffold(
      body: Stack(
        children: [
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
                StepProgress(
                  currentStep: _step,
                  labels: [
                    l.vineSeed,
                    l.vineBranches,
                    l.vineSurvey,
                    l.vinePlan,
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  // Both listeners feed the scroll-through gate: metrics
                  // notifications cover steps whose content already fits (and
                  // content growing on reveal), scroll notifications cover the
                  // user actually reaching the end.
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (n) {
                      _noteScrollMetrics(n.metrics);
                      return false;
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        _noteScrollMetrics(n.metrics);
                        return false;
                      },
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
                            addBoxKey: _coachTargets[CoachTargets.incomeAdd]!,
                            sources: _incomeSources,
                            nameCtrl: _incomeNameCtrl,
                            amountCtrl: _incomeAmountCtrl,
                            suggestions: incomeSuggestionKeys,
                            cycle: _payFrequency,
                            newIncomeFreq: _newIncomeFreq ?? _payFrequency,
                            confirmed: _incomeConfirmed,
                            onConfirm: () =>
                                setState(() => _incomeConfirmed = true),
                            onCycleChanged: (f) => setState(() {
                              _payFrequency = f;
                              _planSettled = false; // totals just changed
                            }),
                            onIncomeFreqChanged: (f) =>
                                setState(() => _newIncomeFreq = f),
                            onAdd: _addIncome,
                            onRemove: (i) => setState(() {
                              _incomeSources.removeAt(i);
                              _planSettled = false;
                              if (_incomeSources.isEmpty) {
                                _incomeConfirmed = false;
                              }
                            }),
                          )
                        : _step == 1
                        ? _ExpenseStep(
                            key: const ValueKey(1),
                            addBoxKey: _coachTargets[CoachTargets.expenseAdd]!,
                            summaryKey: _coachTargets[CoachTargets.remaining]!,
                            expenses: _expenses,
                            nameCtrl: _expNameCtrl,
                            amountCtrl: _expAmountCtrl,
                            selectedIconKey: _selectedIconKey,
                            totalIncome: _totalIncome,
                            totalAllocated: _totalAllocated,
                            presets: _presets,
                            cycle: _payFrequency,
                            newExpenseFreq: _newExpenseFreq ?? _payFrequency,
                            onExpenseFreqChanged: (f) =>
                                setState(() => _newExpenseFreq = f),
                            confirmed: _expensesConfirmed,
                            onConfirm: () =>
                                setState(() => _expensesConfirmed = true),
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
                        ? _SurveyStep(
                            key: const ValueKey(2),
                            highlightKey: _coachTargets[CoachTargets.survey]!,
                            answers: _surveyAnswers,
                            skipped: _surveySkipped,
                            noteCtrl: _noteCtrl,
                            onAnswer: (qKey, optKey) => setState(() {
                              _surveyAnswers[qKey] = optKey;
                              _surveySkipped.remove(qKey);
                              _planSettled = false; // answers changed; re-plan
                            }),
                            onSkip: (qKey) =>
                                setState(() => _surveySkipped.add(qKey)),
                          )
                        : _PlanStep(
                            key: const ValueKey(3),
                            plansKey: _coachTargets[CoachTargets.plans]!,
                            finishingKey:
                                _coachTargets[CoachTargets.finishing]!,
                            income: _totalIncome,
                            expenses: _expenses,
                            settled: _planSettled,
                            note: _noteCtrl.text,
                            survey: _surveyForAi(l),
                            onApplyPlan: _applyPlan,
                            onSettleManual: _settleManual,
                            onAddGoalBranch: _addGoalBranch,
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
                  ),
                ),
                Builder(builder: (context) {
                  final stepReady = _step == 0
                      ? _incomeConfirmed
                      : _step == 1
                      ? _expensesConfirmed
                      : _step == 2
                      ? true // questionnaire is optional
                      : _planSettled;
                  final seenAll = _seenEnd[_step] == true;
                  return _BottomBar(
                  step: _step,
                  lastStep: 3,
                  buttonKey: _coachTargets[CoachTargets.next],
                  canAdvance: stepReady && seenAll,
                  // Everything on the step is settled but something below the
                  // fold hasn't been seen yet: say so instead of leaving a
                  // silently disabled button.
                  hint: stepReady && !seenAll
                      ? AppLocalizations.of(context).scrollToContinue
                      : null,
                  onNext: () {
                    // Never move past a step whose branches outgrow the
                    // income; Acorn explains what to fix instead.
                    if ((_step == 1 || _step == 3) && _overBudget) {
                      _warnOverBudget();
                      return;
                    }
                    if (_step < 3) {
                      setState(() => _step++);
                    } else {
                      _plantTree();
                    }
                  },
                );
                }),
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
                  targets: _coachTargets,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
                color: AppTokens.current.canvasSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppTokens.current.cardBorder),
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionInfoButton(section: TutorialSection.create),
          const SizedBox(width: 10),
          // Small step-count badge
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.current.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${step + 1}',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                color: AppTokens.current.accentStrong,
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
// Progressive-reveal helpers (shared by the wizard steps)
// ──────────────────────────────────────────────

/// Fades + slides its child up once, when it is first inserted. Wrapping a
/// newly revealed card in this makes it grow in gently instead of popping,
/// which is what sells the "one box at a time" feel.
class _Reveal extends StatelessWidget {
  final Widget child;
  const _Reveal({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 20),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// The quiet "I'm done with this box, show me the next" affordance that drives
/// the reveal within a step. Full width so it reads as the step's forward move
/// while the bottom bar stays disabled until the step is complete.
class _ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ContinueButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          side: BorderSide(color: AppColors.forestGreen.withValues(alpha: 0.6)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: Text(
          label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 1 – Income
// ──────────────────────────────────────────────

class _IncomeStep extends StatefulWidget {
  /// Ring anchor for the tutorial coach (the add-a-source box).
  final GlobalKey addBoxKey;
  final List<IncomeSource> sources;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final List<String> suggestions;

  /// The budget's own rhythm, chosen here at the top of the wizard. Every
  /// amount on later steps reads "per cycle".
  final Rhythm cycle;

  /// Arrival rhythm for the income being typed into the hero input.
  final Rhythm newIncomeFreq;

  /// True once the user has said they've listed all their income — reveals the
  /// budget-cycle card.
  final bool confirmed;
  final VoidCallback onConfirm;
  final ValueChanged<Rhythm> onCycleChanged;
  final ValueChanged<Rhythm> onIncomeFreqChanged;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _IncomeStep({
    super.key,
    required this.addBoxKey,
    required this.sources,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.suggestions,
    required this.cycle,
    required this.newIncomeFreq,
    required this.confirmed,
    required this.onConfirm,
    required this.onCycleChanged,
    required this.onIncomeFreqChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_IncomeStep> createState() => _IncomeStepState();
}

class _IncomeStepState extends State<_IncomeStep> {
  final _nameFocus = FocusNode();
  ScrollController? _scrollCtrl;

  List<IncomeSource> get sources => widget.sources;
  TextEditingController get nameCtrl => widget.nameCtrl;
  TextEditingController get amountCtrl => widget.amountCtrl;
  List<String> get suggestions => widget.suggestions;
  Rhythm get cycle => widget.cycle;
  Rhythm get newIncomeFreq => widget.newIncomeFreq;
  bool get confirmed => widget.confirmed;
  VoidCallback get onConfirm => widget.onConfirm;
  ValueChanged<Rhythm> get onCycleChanged => widget.onCycleChanged;
  ValueChanged<Rhythm> get onIncomeFreqChanged =>
      widget.onIncomeFreqChanged;
  VoidCallback get onAdd => widget.onAdd;
  void Function(int) get onRemove => widget.onRemove;

  @override
  void dispose() {
    _nameFocus.dispose();
    super.dispose();
  }

  /// Jump back to the add-a-source box at the top and put the cursor in the
  /// name field, so adding several incomes never means scrolling around.
  void _backToAddBox() {
    _scrollCtrl?.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    _nameFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = sources.fold(0.0, (s, e) => s + e.amountPerCycle(cycle));
    return AppScrollbar(
      builder: (controller) {
        _scrollCtrl = controller;
        return ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // Only the "add a source" box is shown up front; the budget cycle
          // reveals itself once the user confirms they've listed all income.
          // One clear hero input: type a source + amount, tap to add. The
          // quick-picks sit quietly beneath so the screen stays uncluttered.
          AppCard(
            key: widget.addBoxKey,
            label: l.addASource,
            icon: Icons.add_circle_outline,
            accent: AppColors.riverBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: nameCtrl,
                        focusNode: _nameFocus,
                        style: TextStyle(
                          color: AppColors.stoneBeigeColor,
                        ),
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
                        style: TextStyle(
                          color: AppColors.stoneBeigeColor,
                        ),
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
                const SizedBox(height: 12),
                // The income's own rhythm; a bi-weekly salary in a monthly
                // budget gets converted automatically.
                Text(
                  l.incomeArrives,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RhythmPicker(
                  value: newIncomeFreq,
                  onChanged: onIncomeFreqChanged,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in suggestions)
                      GestureDetector(
                        onTap: () =>
                            nameCtrl.text = incomeSuggestionLabel(l, s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.riverBlue.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.riverBlue.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            incomeSuggestionLabel(l, s),
                            style: GoogleFonts.nunito(
                              color: AppColors.stoneBeigeColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Reveal(
              child: AppCard(
              label: l.rootsFeedingTree,
              icon: Icons.water_drop,
              accent: AppColors.forestGreen,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.stoneBeigeColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (s.frequency != null)
                                  Text(
                                    s.frequency!.localizedLabel(l),
                                    style: GoogleFonts.nunito(
                                      color: AppColors.mossGreen,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${s.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.nunito(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              // Show the per-cycle equivalent when the income
                              // arrives on a different rhythm than the budget.
                              if (s.frequency != null && s.frequency != cycle)
                                Text(
                                  l.approxEachCycle(
                                    '\$${s.amountPerCycle(cycle).toStringAsFixed(0)}',
                                  ),
                                  style: GoogleFonts.nunito(
                                    color: AppColors.mossGreen,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
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
                    children: [
                      // Flexible so a long label (or wide test font) wraps
                      // instead of overflowing; the amount always shows whole.
                      Expanded(
                        child: Text(
                          l.totalIncomeCycle(cycle.localizedLabel(l)),
                          style: GoogleFonts.nunito(
                            color: AppColors.mossGreen,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w600,
                          color: AppColors.forestGreen,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ],
          // Once income is listed, confirm to reveal the budget cycle.
          if (sources.isNotEmpty && !confirmed) ...[
            const SizedBox(height: 14),
            _Reveal(
              child: _ContinueButton(
                label: l.incomeDoneAdding,
                onTap: onConfirm,
              ),
            ),
          ],
          if (confirmed) ...[
            const SizedBox(height: 14),
            _Reveal(
              child: AppCard(
                label: l.budgetCycleTitle,
                icon: Icons.event_repeat_outlined,
                accent: _amber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RhythmPicker(value: cycle, onChanged: onCycleChanged),
                    const SizedBox(height: 8),
                    Text(
                      l.budgetCycleBody,
                      style: GoogleFonts.nunito(
                        color: AppColors.mossGreen.withValues(alpha: 0.9),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Once the list has grown past the fold, offer a one-tap way back
          // to the add box instead of making the user scroll.
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppSecondaryButton(
              label: l.incomeAddAnother,
              icon: Icons.add,
              onPressed: _backToAddBox,
            ),
          ],
        ],
      );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Step 2 – Expenses
// ──────────────────────────────────────────────

class _ExpenseStep extends StatelessWidget {
  /// Ring anchors for the tutorial coach: the add-a-branch box and the
  /// always-visible allocation meter.
  final GlobalKey addBoxKey;
  final GlobalKey summaryKey;
  final List<ExpenseCategory> expenses;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final String selectedIconKey;
  final double totalIncome;
  final double totalAllocated;
  final List<(String, String)> presets;

  /// The budget's cycle, so a branch charged on a different rhythm can show
  /// its per-cycle set-aside.
  final Rhythm cycle;

  /// Charge rhythm for the expense being typed into the hero input.
  final Rhythm newExpenseFreq;
  final ValueChanged<Rhythm> onExpenseFreqChanged;

  /// True once the user confirms they've listed all their branches — reveals
  /// the "where you stand" budget summary.
  final bool confirmed;
  final VoidCallback onConfirm;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(String name, String iconKey) onPresetTap;

  const _ExpenseStep({
    super.key,
    required this.addBoxKey,
    required this.summaryKey,
    required this.expenses,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.selectedIconKey,
    required this.totalIncome,
    required this.totalAllocated,
    required this.presets,
    required this.cycle,
    required this.newExpenseFreq,
    required this.onExpenseFreqChanged,
    required this.confirmed,
    required this.onConfirm,
    required this.onAdd,
    required this.onRemove,
    required this.onPresetTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        // Pinned "where you stand" meter: always in view while branches are
        // added or removed, so the user never loses track of what's left to
        // allocate (it flips red the moment they go over).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _AllocationStrip(
            key: summaryKey,
            totalIncome: totalIncome,
            totalAllocated: totalAllocated,
          ),
        ),
        Expanded(
          child: AppScrollbar(
      builder: (controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // The "add a branch" box comes first. The amount is optional (the
          // survey and plan steps fill it in), and the presets sit quietly
          // beneath.
          AppCard(
            key: addBoxKey,
            label: l.addABranch,
            icon: Icons.add_circle_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: nameCtrl,
                        style: TextStyle(
                          color: AppColors.stoneBeigeColor,
                        ),
                        decoration: InputDecoration(labelText: l.categoryName),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountCtrl,
                        style: TextStyle(
                          color: AppColors.stoneBeigeColor,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: l.amountOptionalLabel,
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
                const SizedBox(height: 6),
                Text(
                  l.amountOptionalHint,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen.withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                // The bill's own rhythm; monthly rent in a weekly budget gets
                // converted into a per-cycle set-aside automatically.
                Text(
                  l.expenseCharged,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RhythmPicker(
                  value: newExpenseFreq,
                  onChanged: onExpenseFreqChanged,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets.map((p) {
                    final iconKey = p.$1;
                    final name = expensePresetLabel(l, iconKey);
                    final isSelected = selectedIconKey == iconKey;
                    final t = AppTokens.current;
                    return GestureDetector(
                      onTap: () => onPresetTap(name, iconKey),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? t.accentSoft : t.canvasSoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                isSelected ? t.accentStrong : t.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CategoryIcons.forKey(iconKey),
                              size: 14,
                              color: isSelected
                                  ? t.accentStrong
                                  : t.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: GoogleFonts.nunito(
                                color: isSelected
                                    ? t.accentStrong
                                    : t.textPrimary,
                                fontSize: 12,
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
              ],
            ),
          ),
          if (expenses.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Reveal(
              child: AppCard(
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
                            color: AppColors.forestGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.name,
                                style: GoogleFonts.nunito(
                                  color: AppColors.stoneBeigeColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (exp.frequency != null)
                                Text(
                                  exp.frequency!.localizedLabel(l),
                                  style: GoogleFonts.nunito(
                                    color: AppColors.mossGreen,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${exp.allocated.toStringAsFixed(2)}',
                              style: GoogleFonts.nunito(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            // The set-aside advice: what this bill asks of
                            // each budget cycle when its rhythm differs.
                            if (exp.allocated > 0 &&
                                exp.frequency != null &&
                                exp.frequency != cycle)
                              Text(
                                l.approxEachCycle(
                                  '\$${exp.allocatedPerCycle(cycle).toStringAsFixed(0)}',
                                ),
                                style: GoogleFonts.nunito(
                                  color: AppColors.mossGreen,
                                  fontSize: 11,
                                ),
                              ),
                          ],
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
            ),
          ],
          // Confirm the branch list to unlock the step's Next button (the
          // meter above already shows where the budget stands at all times).
          if (expenses.isNotEmpty && !confirmed) ...[
            const SizedBox(height: 14),
            _Reveal(
              child: _ContinueButton(
                label: l.expensesDoneAdding,
                onTap: onConfirm,
              ),
            ),
          ],
        ],
      ),
          ),
        ),
      ],
    );
  }
}

/// The always-visible "where you stand" strip: the allocation meter plus
/// allocated / remaining figures, pinned above the scrolling content of the
/// Expenses and Plan steps so what's left to allocate is never out of sight.
/// Amounts are wrapped in [FittedBox]es so the full number always shows, no
/// matter how large it gets. Goes red the moment allocations exceed income.
class _AllocationStrip extends StatelessWidget {
  final double totalIncome;
  final double totalAllocated;
  const _AllocationStrip({
    super.key,
    required this.totalIncome,
    required this.totalAllocated,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.current;
    final remaining = totalIncome - totalAllocated;
    final overBudget = remaining < -0.005;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overBudget
              ? AppColors.dangerRed.withValues(alpha: 0.65)
              : t.cardBorder,
          width: overBudget ? 1.5 : 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _BudgetBar(totalIncome: totalIncome, totalAllocated: totalAllocated),
          const SizedBox(height: 7),
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.allocatedAmount('\$${totalAllocated.toStringAsFixed(0)}'),
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    overBudget
                        ? l.overByAmount('\$${(-remaining).toStringAsFixed(0)}')
                        : l.remainingAmount('\$${remaining.toStringAsFixed(0)}'),
                    style: GoogleFonts.nunito(
                      color: overBudget
                          ? AppColors.dangerRed
                          : AppColors.forestGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 3 – Survey (questionnaire + optional note)
// ──────────────────────────────────────────────

/// The questionnaire, one question at a time: tap an answer to move on, skip
/// what you don't want to share, and edit any earlier answer from the summary
/// rows. When every question is answered or skipped it settles on a summary
/// view with the optional free-text note.
class _SurveyStep extends StatefulWidget {
  /// Ring anchor for the tutorial coach (the question area).
  final GlobalKey highlightKey;
  final Map<String, String> answers;
  final Set<String> skipped;
  final TextEditingController noteCtrl;
  final void Function(String questionKey, String optionKey) onAnswer;
  final void Function(String questionKey) onSkip;

  const _SurveyStep({
    super.key,
    required this.highlightKey,
    required this.answers,
    required this.skipped,
    required this.noteCtrl,
    required this.onAnswer,
    required this.onSkip,
  });

  @override
  State<_SurveyStep> createState() => _SurveyStepState();
}

class _SurveyStepState extends State<_SurveyStep> {
  final List<SurveyQuestion> _questions = budgetSurveyQuestions();

  /// Index of the question on screen; `_questions.length` is the summary view.
  late int _index = _nextPending(0);

  bool _seen(SurveyQuestion q) =>
      widget.answers.containsKey(q.key) || widget.skipped.contains(q.key);

  /// First question at or after [from] the user hasn't dealt with yet, or the
  /// summary index when there is none.
  int _nextPending(int from) {
    for (var i = from; i < _questions.length; i++) {
      if (!_seen(_questions[i])) return i;
    }
    return _questions.length;
  }

  void _answer(SurveyQuestion q, String optKey) {
    widget.onAnswer(q.key, optKey);
    // Let the chip's selected state land before sliding to the next question.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _index = _nextPending(0));
    });
  }

  void _skip(SurveyQuestion q) {
    widget.onSkip(q.key);
    setState(() => _index = _nextPending(0));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final done = _index >= _questions.length;
    final answeredCount = _questions.where(_seen).length;

    return AppScrollbar(
      builder: (controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          // Thin progress bar + counter so the user always knows how much of
          // the questionnaire is left.
          _SurveyProgress(
            current: done ? _questions.length : _index + 1,
            total: _questions.length,
            completed: answeredCount,
            label: done
                ? l.surveyDoneTitle
                : l.surveyProgress(_index + 1, _questions.length),
          ),
          const SizedBox(height: 12),
          // The coach's ring anchors here, outside the switcher, so the key
          // never exists twice while a question transition is mid-flight.
          KeyedSubtree(
            key: widget.highlightKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: done
                  ? _summaryView(l)
                  : _questionView(l, _questions[_index]),
            ),
          ),
        ],
      ),
    );
  }

  /// One question, its options, and a skip affordance.
  Widget _questionView(AppLocalizations l, SurveyQuestion q) {
    return Column(
      key: ValueKey('q${q.key}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_index == 0 && widget.answers.isEmpty && widget.skipped.isEmpty) ...[
          Text(
            l.surveyIntroBody,
            style: GoogleFonts.nunito(
              color: AppColors.mossGreen.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          label: q.prompt(l),
          icon: Icons.help_outline,
          accent: _amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final opt in q.options)
                    _SurveyChip(
                      label: opt.label(l),
                      selected: widget.answers[q.key] == opt.key,
                      onTap: () => _answer(q, opt.key),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _skip(q),
                  child: Text(
                    l.tourSkip,
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_answeredRows(l).isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._answeredRows(l),
        ],
      ],
    );
  }

  /// Everything answered or skipped: the editable recap + the optional note.
  Widget _summaryView(AppLocalizations l) {
    return Column(
      key: const ValueKey('summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.surveyDoneBody,
          style: GoogleFonts.nunito(
            color: AppColors.mossGreen.withValues(alpha: 0.9),
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        ..._answeredRows(l, includeSkipped: true),
        const SizedBox(height: 6),
        AppCard(
          label: l.budgetNoteTitle,
          icon: Icons.chat_bubble_outline,
          child: TextField(
            controller: widget.noteCtrl,
            maxLines: 3,
            style: TextStyle(color: AppColors.stoneBeigeColor),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l.budgetNoteHint,
              hintStyle: GoogleFonts.nunito(
                color: AppColors.mossGreen.withValues(alpha: 0.7),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Compact recap rows for questions the user has already dealt with. Tapping
  /// one jumps back to that question to change the answer.
  List<Widget> _answeredRows(
    AppLocalizations l, {
    bool includeSkipped = false,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (i == _index) continue;
      final answerKey = widget.answers[q.key];
      if (answerKey == null && !(includeSkipped && widget.skipped.contains(q.key))) {
        continue;
      }
      final answerLabel = answerKey == null
          ? null
          : q.options.firstWhere((o) => o.key == answerKey).label(l);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _AnswerRow(
            prompt: q.prompt(l),
            answer: answerLabel ?? l.surveySkippedLabel,
            skipped: answerLabel == null,
            onTap: () => setState(() => _index = i),
          ),
        ),
      );
    }
    return rows;
  }
}

/// "Question 2 of 6" over a thin fill bar.
class _SurveyProgress extends StatelessWidget {
  final int current;
  final int total;
  final int completed;
  final String label;
  const _SurveyProgress({
    required this.current,
    required this.total,
    required this.completed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            color: _amber,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 5,
            child: LinearProgressIndicator(
              value: completed / total,
              backgroundColor: AppColors.soilMid,
              valueColor: AlwaysStoppedAnimation(AppColors.forestGreen),
            ),
          ),
        ),
      ],
    );
  }
}

/// A settled question: prompt, chosen answer, and a pencil hinting it's
/// editable. Tap anywhere on the row to reopen that question.
class _AnswerRow extends StatelessWidget {
  final String prompt;
  final String answer;
  final bool skipped;
  final VoidCallback onTap;
  const _AnswerRow({
    required this.prompt,
    required this.answer,
    required this.skipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.soilMid.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.mossGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: AppColors.mossGreen,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    answer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: skipped
                          ? AppColors.mossGreen.withValues(alpha: 0.8)
                          : AppColors.forestGreen,
                      fontSize: 13,
                      fontStyle: skipped ? FontStyle.italic : FontStyle.normal,
                      fontWeight: skipped ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_outlined,
              color: AppColors.mossGreen.withValues(alpha: 0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SurveyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SurveyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? t.accentSoft : t.canvasSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? t.accentStrong : t.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: selected ? t.accentStrong : t.textPrimary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 4 – AI allocation plan (get plans, pick or do manual), and once the
// allocations settle, the finishing touches (tree name + pay schedule) appear
// below — the wizard ends here, no separate "roots" step.
// ──────────────────────────────────────────────

class _PlanStep extends StatefulWidget {
  /// Ring anchors for the tutorial coach: the plan-picking area and the
  /// finishing-touch cards (name + pay schedule).
  final GlobalKey plansKey;
  final GlobalKey finishingKey;
  final double income;
  final List<ExpenseCategory> expenses;
  final bool settled;
  final String note;
  final Map<String, String> survey;
  final void Function(AllocationPlan) onApplyPlan;
  final VoidCallback onSettleManual;
  final void Function(String name, double amount, String goalId)
  onAddGoalBranch;
  final TextEditingController nameCtrl;
  final Rhythm payFrequency;
  final DateTime? firstPayDate;
  final ValueChanged<Rhythm> onFrequencyChanged;
  final ValueChanged<DateTime?> onFirstPayDateChanged;

  const _PlanStep({
    super.key,
    required this.plansKey,
    required this.finishingKey,
    required this.income,
    required this.expenses,
    required this.settled,
    required this.note,
    required this.survey,
    required this.onApplyPlan,
    required this.onSettleManual,
    required this.onAddGoalBranch,
    required this.nameCtrl,
    required this.payFrequency,
    required this.firstPayDate,
    required this.onFrequencyChanged,
    required this.onFirstPayDateChanged,
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
      // Amounts go to the coach per budget cycle, whatever rhythm each bill
      // is charged on, so its plans stay like-for-like with the income.
      final inputs = [
        for (final cat in widget.expenses)
          BudgetExpenseInput(
            name: cat.name,
            amount: cat.allocatedPerCycle(widget.payFrequency),
          ),
      ];
      final plans = await AiCoachService.instance.budgetPlans(
        income: widget.income,
        expenses: inputs,
        synopsis: widget.note.trim(),
        survey: widget.survey,
        cycle: widget.payFrequency.wire,
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
    final totalAllocated = widget.expenses
        .fold(0.0, (s, e) => s + e.allocatedPerCycle(widget.payFrequency));
    return Column(
      children: [
        // Same always-visible meter as the Expenses step: allocations settle
        // here, so what's left (or how far over) must stay in sight too.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _AllocationStrip(
            totalIncome: widget.income,
            totalAllocated: totalAllocated,
          ),
        ),
        Expanded(
          child: AppScrollbar(
      builder: (controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // The expenses the user declared (read-only here). A "$X" tag means
          // they fixed that amount; the rest are left for the coach to choose.
          AppCard(
            label: l.yourExpenses,
            icon: Icons.account_tree_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in widget.expenses)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.soilMid,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.mossGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CategoryIcons.forKey(cat.emoji),
                          color: AppColors.mossGreen,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.allocated > 0
                              ? (cat.frequency != null &&
                                        cat.frequency != widget.payFrequency
                                    ? '${cat.name}  \$${cat.allocated.toStringAsFixed(0)} (${cat.frequency!.localizedLabel(l)})'
                                    : '${cat.name}  \$${cat.allocated.toStringAsFixed(0)}')
                              : cat.name,
                          style: GoogleFonts.nunito(
                            color: AppColors.stoneBeigeColor,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // The coach's "pick a plan" ring anchors around the whole plan
          // area, whichever mode (AI plans or manual amounts) it's in.
          KeyedSubtree(
            key: widget.plansKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
            AppCard(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.stoneBeigeColor,
                                    fontSize: 13.5,
                                  ),
                                ),
                                // Manual amounts are entered in the bill's own
                                // rhythm; make that rhythm visible when it
                                // differs from the cycle the meter reads in.
                                if (cat.frequency != null &&
                                    cat.frequency != widget.payFrequency)
                                  Text(
                                    cat.frequency!.localizedLabel(l),
                                    style: GoogleFonts.nunito(
                                      color: AppColors.mossGreen,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            // Wide enough that a 5-digit amount shows whole:
                            // at 90px the theme's 18px content padding plus
                            // the "$ " prefix clipped "1200" to "120".
                            width: 132,
                            child: TextField(
                              controller: _ctrlFor(cat),
                              style: TextStyle(
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
              ],
            ),
          ),
          if (widget.settled) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.forestGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.allocationsReady,
                    style: GoogleFonts.nunito(
                      color: AppColors.forestGreen,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_leftover > 0.5) ...[
              const SizedBox(height: 14),
              _Reveal(child: _buildLeftoverCard(context, l)),
            ],
            // Finishing touches, revealed only once the plan is settled so the
            // step stays one decision at a time: name the tree, set the pay
            // schedule, then the bottom bar plants it.
            const SizedBox(height: 14),
            KeyedSubtree(
              key: widget.finishingKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Reveal(child: _buildNameCard(l)),
                  const SizedBox(height: 14),
                  _Reveal(child: _buildPayCard(context, l)),
                ],
              ),
            ),
          ],
        ],
      ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameCard(AppLocalizations l) {
    return AppCard(
      label: l.nameYourTree,
      icon: Icons.park,
      child: TextField(
        controller: widget.nameCtrl,
        style: TextStyle(color: AppColors.stoneBeigeColor),
        decoration: InputDecoration(
          labelText: l.budgetName,
          hintText: l.budgetNameHint,
          prefixIcon: Icon(Icons.park, color: AppColors.mossGreen),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  Widget _buildPayCard(BuildContext context, AppLocalizations l) {
    return AppCard(
      label: l.payScheduleLabel,
      icon: Icons.event_repeat_outlined,
      accent: AppColors.riverBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The cycle was picked on the Income step; it stays adjustable here
          // as the same chips, right where the pay date is set.
          RhythmPicker(
            value: widget.payFrequency,
            onChanged: widget.onFrequencyChanged,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: widget.firstPayDate ?? now,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) widget.onFirstPayDateChanged(picked);
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
                  Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.mossGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.firstPayDate == null
                          ? l.firstPayDate
                          : l.firstPayOn(
                              _formatDate(widget.firstPayDate!, l)),
                      style: TextStyle(
                        color: widget.firstPayDate == null
                            ? AppColors.stoneBeigeColor.withValues(alpha: 0.5)
                            : AppColors.stoneBeigeColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (widget.firstPayDate != null)
                    IconButton(
                      onPressed: () => widget.onFirstPayDateChanged(null),
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
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.riverBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.payScheduleInfo,
                  style: GoogleFonts.nunito(
                    color: AppColors.stoneBeigeColor.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d, AppLocalizations l) {
    final m = monthAbbrevs(l);
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  double get _leftover =>
      widget.income -
      widget.expenses
          .fold(0.0, (s, e) => s + e.allocatedPerCycle(widget.payFrequency));

  Widget _buildLeftoverCard(BuildContext context, AppLocalizations l) {
    return AppCard(
      label: l.leftoverGoalTitle,
      icon: Icons.eco_outlined,
      accent: _amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.leftoverGoalBody('\$${_leftover.toStringAsFixed(0)}'),
            style: GoogleFonts.nunito(
              color: AppColors.mossGreen.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _sendLeftoverToGoal(context, l),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.spa, color: Colors.white, size: 18),
              label: Text(
                l.growAGoalWithIt,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Let the user route the leftover into a goal: pick an existing goal or
  /// quick-create one, then add a linked funding branch to the budget.
  Future<void> _sendLeftoverToGoal(
    BuildContext context,
    AppLocalizations l,
  ) async {
    final leftover = _leftover;
    final goals = await GoalRepository.loadAll();
    if (!context.mounted) return;
    final choice = await showDialog<Goal>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          l.leftoverPickGoalTitle,
          style: TextStyle(color: AppColors.stoneBeigeColor),
        ),
        children: [
          for (final g in goals)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, g),
              child: Text(
                g.name,
                style: TextStyle(color: AppColors.stoneBeigeColor),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, Goal(name: '', targetAmount: 0)),
            child: Text(
              l.leftoverNewGoal,
              style: TextStyle(color: AppColors.forestGreen),
            ),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;

    Goal goal = choice;
    // The "new goal" sentinel has an empty name — prompt for one and save it.
    if (goal.name.isEmpty) {
      final name = await _promptGoalName(context, l);
      if (name == null || name.trim().isEmpty || !context.mounted) return;
      goal = Goal(name: name.trim(), targetAmount: 0);
      await GoalRepository.saveNew(goal);
    }
    widget.onAddGoalBranch(goal.name, leftover, goal.id);
  }

  Future<String?> _promptGoalName(
    BuildContext context,
    AppLocalizations l,
  ) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.leftoverNewGoalTitle,
          style: TextStyle(color: AppColors.stoneBeigeColor),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: AppColors.stoneBeigeColor),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l.goalNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(l.save),
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
          padding: const EdgeInsets.symmetric(vertical: 15),
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
        backgroundColor: AppColors.soilMid,
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
            color: AppTokens.current.accent,
            boxShadow: AppShadows.pill,
          ),
          child: Icon(Icons.add, color: AppTokens.current.onAccent, size: 22),
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

  /// Shown above the button when the only thing holding Next back is content
  /// below the fold the user hasn't scrolled through yet.
  final String? hint;

  /// Ring anchor for the tutorial coach ("tap Next" lines).
  final GlobalKey? buttonKey;

  const _BottomBar({
    required this.step,
    required this.lastStep,
    required this.canAdvance,
    required this.onNext,
    this.hint,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLast = step == lastStep;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_double_arrow_down,
                    size: 15,
                    color: AppColors.mossGreen,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      hint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: AppColors.mossGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AppPrimaryButton(
            key: buttonKey,
            label: isLast ? l.plantMyBudgetTree : l.next,
            icon: isLast ? Icons.park : Icons.arrow_forward,
            onPressed: canAdvance ? onNext : null,
          ),
        ],
      ),
    );
  }
}
