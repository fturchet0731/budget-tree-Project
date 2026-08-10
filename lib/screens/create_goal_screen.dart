import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/calendar.dart';
import '../data/water_cadence.dart';
import '../l10n/app_localizations.dart';
import '../l10n/preset_labels.dart';
import '../l10n/water_cadence_labels.dart';
import '../models/ai_plan.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../services/achievement_service.dart';
import '../services/ai_coach_service.dart';
import '../services/app_settings.dart';
import '../services/budget_repository.dart';
import '../services/category_repository.dart';
import '../services/goal_plan_math.dart';
import '../services/goal_repository.dart';
import '../services/notification_scheduler.dart';
import '../services/profile_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/ui/app_card.dart' show AppCard;
import '../widgets/ui/app_buttons.dart';
import '../widgets/ui/step_progress.dart';
import '../widgets/category_picker.dart';
import '../widgets/sapling_view.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _iconKey = 'savings';
  String? _categoryId;
  TreeCategory? _pickedCategory;
  bool _uncapped = false;
  bool _saving = false;

  // Wizard step: 0 Name, 1 Amount, 2 Plan & details.
  int _gStep = 0;

  // Whether to plan this goal with the coach. null = the user hasn't been asked
  // yet (we show the prompt before computing anything). Defaults straight to
  // manual when the AI coach isn't available so we don't dangle a dead option.
  bool? _useAi;

  // Target date + AI watering plan.
  DateTime? _targetDate;
  bool _planLoading = false;
  String? _planError;
  GoalPlanResult? _planResult;
  double? _fallbackMonthly; // offline simple math (a monthly figure)

  // Chosen watering schedule. Either a selected AI plan, or a custom one.
  int? _selectedPlan; // index into _planResult.plans
  bool _useCustom = false;
  WaterCadence _customCadence = WaterCadence.biweekly;
  final _customAmountCtrl = TextEditingController();
  bool _remindToWater = true;

  // The range the user is willing to put in each timeframe. Asked before any
  // plan is generated, and it's what the three no-deadline progressions are
  // built from: the floor, the midpoint and the ceiling.
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  double get _willingMin => double.tryParse(_minCtrl.text) ?? 0;
  double get _willingMax => double.tryParse(_maxCtrl.text) ?? 0;
  bool get _hasRange => _willingMin > 0 || _willingMax > 0;

  @override
  void initState() {
    super.initState();
    if (!AiCoachService.instance.isAvailable) _useAi = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _descCtrl.dispose();
    _customAmountCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  /// Whether the current wizard step is complete enough to move forward.
  /// Step 0 now defines the whole goal (name + amount), step 1 is the optional
  /// timeframe, step 2 is the watering plan.
  bool get _canAdvance {
    switch (_gStep) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) return false;
        return _uncapped || (double.tryParse(_targetCtrl.text) ?? 0) > 0;
      default:
        return true;
    }
  }

  /// What to water at [cadence] to land the goal on its target date, computed
  /// exactly rather than taken from the coach. 0 when there's no date to aim at
  /// or nothing left to save.
  double _suggestedPerWatering(WaterCadence cadence) {
    final date = _targetDate;
    final target = double.tryParse(_targetCtrl.text) ?? 0;
    if (date == null || target <= 0) return 0;
    return GoalPlanMath.perWateringForDate(
      _transientGoal(target),
      date,
      cadence,
    );
  }

  /// With no deadline set, the date the amount currently typed into the custom
  /// field would reach the goal on. Null when there's a deadline (the date is
  /// then a given, not a result) or nothing usable has been typed.
  DateTime? _customProjectedDate() {
    if (_targetDate != null) return null;
    final target = double.tryParse(_targetCtrl.text) ?? 0;
    final typed = double.tryParse(_customAmountCtrl.text) ?? 0;
    if (target <= 0 || typed <= 0) return null;
    return GoalPlanMath.dateForPerWatering(
      _transientGoal(target),
      typed,
      _customCadence,
    );
  }

  /// The watering schedule the user settled on, if any: a selected AI plan, a
  /// custom cadence + amount, or the offline monthly fallback. Null when nothing
  /// is set (the goal is then saved without reminders).
  ({WaterCadence cadence, double amount})? get _chosenWatering {
    if (_useCustom) {
      final typed = double.tryParse(_customAmountCtrl.text) ?? 0;
      // Leaving the amount blank is a request, not an omission: the coach
      // fills in what it takes to hit the target date at this cadence.
      final amt = typed > 0 ? typed : _suggestedPerWatering(_customCadence);
      return amt > 0 ? (cadence: _customCadence, amount: amt) : null;
    }
    final plans = _planResult?.plans;
    if (plans != null && _selectedPlan != null && _selectedPlan! < plans.length) {
      final p = plans[_selectedPlan!];
      return (cadence: p.cadence, amount: p.perWatering);
    }
    if (_fallbackMonthly != null && _fallbackMonthly! > 0) {
      return (cadence: WaterCadence.monthly, amount: _fallbackMonthly!);
    }
    return null;
  }

  bool get _canSave {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_uncapped) return true;
    return (double.tryParse(_targetCtrl.text) ?? 0) > 0;
  }

  /// Preview progress derived from the target amount entered: gives the
  /// user a sense of how the sapling will look once they're partway there.
  double get _previewProgress {
    if (_uncapped) return 0.45; // mid-tier feel
    final amt = double.tryParse(_targetCtrl.text) ?? 0;
    if (amt <= 0) return 0.10; // seedling
    // Use a gentle curve so a $500 target doesn't look identical to $50k.
    final v = (amt / 5000).clamp(0.0, 1.0);
    return 0.15 + v * 0.55;
  }

  LeafPalette get _previewPalette => _pickedCategory != null
      ? LeafPalette.fromAccent(Color(_pickedCategory!.colorValue))
      : LeafPalette.defaultGreen;

  /// Ask, at creation time, whether this goal should be visible to friends.
  /// Only shown when the social layer is available (signed in + online-capable)
  /// — otherwise there's nothing to share to, so it stays private.
  Future<bool> _askVisibility() async {
    if (!ProfileService.instance.isAvailable) return false;
    final l = AppLocalizations.of(context);
    final share = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.shareThisGoalTitle),
        content: Text(l.shareThisGoalBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.keepPrivate),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.shareWithFriends),
          ),
        ],
      ),
    );
    return share ?? false;
  }

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    final share = await _askVisibility();
    if (!mounted) return;
    setState(() => _saving = true);
    final goal = Goal(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      targetAmount: _uncapped ? 0 : double.parse(_targetCtrl.text),
      iconKey: _iconKey,
      categoryId: _categoryId,
      sharedWithFriends: share,
      leafColorValue: _pickedCategory?.colorValue,
    );
    goal.targetDate = _targetDate;
    // Apply the chosen watering schedule (drives the watering reminders).
    final watering = _chosenWatering;
    if (watering != null) {
      goal.waterAmount = watering.amount;
      goal.waterCadenceIndex = watering.cadence.index;
      final firstWatering = addDays(DateTime.now(), watering.cadence.days);
      goal.nextWaterDate = firstWatering;
      // The anchor is set once here and never moved, so the watering slots a
      // check-in enumerates stay reproducible even as the cursor above is
      // pushed forward by deposits.
      goal.waterAnchorDate = firstWatering;
      goal.waterRemindersEnabled = _remindToWater;
    }
    await GoalRepository.saveNew(goal);
    SoundService.goalSet();
    await AchievementService.evaluateAndUnlock();
    if (goal.waterRemindersEnabled) {
      // "Remind me to water" is an explicit opt-in: this is the moment the OS
      // permission dialog makes sense to the user.
      await AppSettings.instance.markNotifPermissionAsked();
      await NotificationScheduler.rescheduleAll();
    }
    if (!mounted) return;
    // Offer to fund the goal from a budget branch so the recommended monthly
    // contribution flows in automatically each pay cycle.
    await _offerLink(goal);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime(now.year, now.month + 6, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    setState(() {
      _targetDate = picked;
      _planResult = null;
      _planError = null;
      _fallbackMonthly = null;
    });
  }

  Goal _transientGoal(double target) =>
      Goal(name: _nameCtrl.text.trim(), targetAmount: target);

  /// The plan options for this goal, **computed locally and exactly**.
  ///
  /// With a date: one option per cadence, each the precise amount that lands on
  /// that date. Without one: a spread of paces (or just the user's own figure
  /// if they named one), each carrying the date it would finish on. The coach
  /// never supplies these numbers, only the wording, which is what guarantees a
  /// date the user picked is actually met.
  List<GoalPlanOption> _computeOptions(Goal goal, double freeMonthly) {
    final date = _targetDate;
    if (date != null) {
      return [
        for (final c in WaterCadence.values)
          if (GoalPlanMath.perWateringForDate(goal, date, c) > 0)
            GoalPlanOption(
              cadence: c,
              perWatering: GoalPlanMath.perWateringForDate(goal, date, c),
              monthsToTarget: GoalPlanMath.monthsBetween(DateTime.now(), date),
              rationale: '',
              completionDate: date,
            ),
      ];
    }

    // No deadline: the three plans are three **paces**, built from the range
    // the user said they're willing to put in — their floor, the midpoint, and
    // their ceiling. Each one finishes on a different date, which is the actual
    // choice being made here. With no range given we fall back to a spread
    // anchored on their spare income.
    final amounts = _hasRange
        ? GoalPlanMath.progressionAmounts(min: _willingMin, max: _willingMax)
        : GoalPlanMath.suggestedPerWatering(goal, _customCadence, freeMonthly);

    return [
      for (var i = 0; i < amounts.length; i++)
        if (GoalPlanMath.dateForPerWatering(goal, amounts[i], _customCadence) !=
            null)
          GoalPlanOption(
            cadence: _customCadence,
            perWatering: amounts[i],
            monthsToTarget: GoalPlanMath.monthsForPerWatering(
              goal,
              amounts[i],
              _customCadence,
            ),
            rationale: '',
            completionDate: GoalPlanMath.dateForPerWatering(
              goal,
              amounts[i],
              _customCadence,
            ),
            // Gentlest first, so the set reads as a progression.
            pace: amounts.length == 1
                ? GoalPace.steady
                : GoalPace.values[(i * (GoalPace.values.length - 1) ~/
                    (amounts.length - 1))],
          ),
    ];
  }

  /// Work out the plans, then ask the coach to describe them. The numbers never
  /// change based on what comes back: an AI failure just leaves them unexplained
  /// rather than unusable, which is why this still works offline.
  Future<void> _generatePlan() async {
    final target = double.tryParse(_targetCtrl.text) ?? 0;
    if (target <= 0) return;
    final transient = _transientGoal(target);

    setState(() {
      _planLoading = true;
      _planError = null;
    });

    final free = await GoalPlanMath.freeMonthlyIncome();
    final computed = _computeOptions(transient, free);
    if (!mounted) return;

    if (computed.isEmpty) {
      setState(() {
        _planLoading = false;
        _planResult = null;
      });
      return;
    }

    // Manual mode (or no coach available) shows the computed plans as they are.
    if (_useAi != true || !AiCoachService.instance.isAvailable) {
      setState(() {
        _planLoading = false;
        _planResult =
            GoalPlanResult(plans: computed, alternativeDates: const []);
      });
      return;
    }

    try {
      final date = _targetDate;
      final result = date != null
          ? await AiCoachService.instance.goalPlansByDate(
              goal: transient,
              targetDate: date,
              freeMonthly: free,
              computed: computed,
            )
          : await AiCoachService.instance.goalPlansByAmount(
              goal: transient,
              freeMonthly: free,
              candidates: computed,
            );
      if (!mounted) return;
      setState(() {
        // Keep our figures; take only the coach's words for them.
        _planResult = GoalPlanResult(
          plans: _withRationales(computed, result.plans),
          alternativeDates: result.alternativeDates,
        );
        _planLoading = false;
      });
    } on AiUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _planLoading = false;
        _planError = e.message;
        // The plans are still correct without the prose.
        _planResult =
            GoalPlanResult(plans: computed, alternativeDates: const []);
      });
    }
  }

  /// Graft the coach's rationales onto the computed options, matching on
  /// cadence and amount. Anything it returns that we didn't ask about is
  /// dropped, and an option it skipped simply stays unexplained.
  static List<GoalPlanOption> _withRationales(
    List<GoalPlanOption> computed,
    List<GoalPlanOption> described,
  ) {
    return [
      for (var i = 0; i < computed.length; i++)
        computed[i].copyWith(
          rationale: described
                  .firstWhere(
                    (d) =>
                        d.cadence == computed[i].cadence &&
                        (d.perWatering - computed[i].perWatering).abs() <= 1,
                    orElse: () => i < described.length
                        ? described[i]
                        : const GoalPlanOption(
                            cadence: WaterCadence.monthly,
                            perWatering: 0,
                            monthsToTarget: 0,
                            rationale: '',
                          ),
                  )
                  .rationale,
        ),
    ];
  }

  /// After saving, let the user pick a budget branch to fund this goal.
  Future<void> _offerLink(Goal goal) async {
    final budgets = await BudgetRepository.loadAll();
    final branches = <(BudgetModel, ExpenseCategory)>[];
    for (final b in budgets) {
      for (final c in b.expenses) {
        branches.add((b, c));
      }
    }
    if (!mounted || branches.isEmpty) return;
    final l = AppLocalizations.of(context);
    final picked = await showDialog<(BudgetModel, ExpenseCategory)?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.fundFromBranchTitle),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              l.fundFromBranchBody,
              style: TextStyle(
                color: AppColors.mossGreen,
                fontSize: 12.5,
              ),
            ),
          ),
          for (final pair in branches)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, pair),
              child: Text(
                '${pair.$2.name}  ·  ${pair.$1.budgetName}',
                style: TextStyle(color: AppColors.stoneBeigeColor),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              l.notNow,
              style: TextStyle(color: AppColors.mossGreen),
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    final (budget, branch) = picked;
    if (!branch.linkedGoalIds.contains(goal.id)) {
      branch.linkedGoalIds.add(goal.id);
      await BudgetRepository.update(budget);
    }
  }

  Future<void> _resolveCategory(String? id) async {
    setState(() => _categoryId = id);
    if (id == null) {
      setState(() => _pickedCategory = null);
      return;
    }
    final cats = await CategoryRepository.loadAll();
    if (!mounted) return;
    setState(() {
      _pickedCategory = cats.cast<TreeCategory?>().firstWhere(
        (c) => c?.id == id,
        orElse: () => null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasName = _nameCtrl.text.trim().isNotEmpty;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _Header(
                  onBack: _gStep == 0
                      ? () => Navigator.pop(context)
                      : () => setState(() => _gStep--),
                ),
                // Live sapling preview
                _SaplingPreviewBanner(
                  progress: _previewProgress,
                  palette: _previewPalette,
                  iconKey: _iconKey,
                  goalName: hasName ? _nameCtrl.text.trim() : l.newSapling,
                  category: _pickedCategory,
                ),
                StepProgress(
                  currentStep: _gStep,
                  labels: [l.goalStepName, l.goalStepWhen, l.vinePlan],
                ),
                Expanded(
                  child: AppScrollbar(
                    builder: (controller) => ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        if (_gStep == 0) ...[
                          // ── About this goal ──────────
                          AppCard(
                            label: l.aboutThisGoal,
                            icon: Icons.spa,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _nameCtrl,
                                  style: TextStyle(
                                    color: AppColors.stoneBeigeColor,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l.goalName,
                                    hintText: l.goalNameHint,
                                    prefixIcon: Icon(
                                      Icons.spa,
                                      color: AppColors.mossGreen,
                                    ),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _descCtrl,
                                  style: TextStyle(
                                    color: AppColors.stoneBeigeColor,
                                  ),
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: l.notesOptional,
                                    hintText: l.notesHint,
                                    prefixIcon: Icon(
                                      Icons.notes_outlined,
                                      color: AppColors.mossGreen,
                                    ),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Target (now part of step 0) ──
                        if (_gStep == 0) ...[
                          AppCard(
                            label: l.howMuch,
                            icon: Icons.flag_outlined,
                            accent: const Color(0xFFBA8514),
                            child: Column(
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _uncapped ? 0.4 : 1.0,
                                  child: TextField(
                                    controller: _targetCtrl,
                                    enabled: !_uncapped,
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
                                      labelText: l.targetAmount,
                                      hintText: l.targetHint,
                                      prefixIcon: Icon(
                                        Icons.flag_outlined,
                                        color: AppColors.mossGreen,
                                      ),
                                      prefixText: '\$ ',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Grow-forever toggle styled as a leafy switch
                                InkWell(
                                  onTap: () =>
                                      setState(() => _uncapped = !_uncapped),
                                  borderRadius: BorderRadius.zero,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _uncapped
                                          ? AppTokens.current.accentSoft
                                          : AppTokens.current.canvasSoft,
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: _uncapped
                                            ? AppTokens.current.accentStrong
                                            : AppTokens.current.cardBorder,
                                        width: _uncapped ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: _uncapped
                                                ? AppColors.forestGreen
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: _uncapped
                                                  ? AppColors.forestGreen
                                                  : AppColors.mossGreen
                                                        .withValues(alpha: 0.6),
                                              width: 1.6,
                                            ),
                                          ),
                                          child: _uncapped
                                              ? const Icon(
                                                  Icons.all_inclusive,
                                                  color: Colors.white,
                                                  size: 14,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l.growForever,
                                                style: GoogleFonts.nunito(
                                                  color:
                                                      AppColors.stoneBeigeColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                l.growForeverDesc,
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
                          const SizedBox(height: 14),
                        ],

                        // ── Timeframe (step 1) ──
                        if (_gStep == 1) ...[
                          _TimeframeStep(
                            targetDate: _targetDate,
                            uncapped: _uncapped,
                            onPickDate: _pickDate,
                            onClear: () => setState(() {
                              _targetDate = null;
                              _planResult = null;
                              _fallbackMonthly = null;
                            }),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Watering plan (step 2) ──
                        if (_gStep == 2) ...[
                          _WateringStep(
                            uncapped: _uncapped,
                            hasTarget:
                                (double.tryParse(_targetCtrl.text) ?? 0) > 0,
                            targetDate: _targetDate,
                            aiAvailable: AiCoachService.instance.isAvailable,
                            useAi: _useAi,
                            onChooseAi: () => setState(() => _useAi = true),
                            onChooseManual: () =>
                                setState(() => _useAi = false),
                            loading: _planLoading,
                            error: _planError,
                            result: _planResult,
                            fallbackMonthly: _fallbackMonthly,
                            selectedPlan: _selectedPlan,
                            onSelectPlan: (i) => setState(() {
                              _selectedPlan = i;
                              _useCustom = false;
                            }),
                            onGenerate: _generatePlan,
                            onApplyDate: (d) => setState(() {
                              _targetDate = d;
                              _planResult = null;
                              _fallbackMonthly = null;
                            }),
                            useCustom: _useCustom,
                            customCadence: _customCadence,
                            customAmountCtrl: _customAmountCtrl,
                            suggestedPerWatering:
                                _suggestedPerWatering(_customCadence),
                            customProjectedDate: _customProjectedDate(),
                            minCtrl: _minCtrl,
                            maxCtrl: _maxCtrl,
                            onRangeChanged: () => setState(() {}),
                            onPickCustomCadence: (c) => setState(() {
                              _customCadence = c;
                              _useCustom = true;
                              _selectedPlan = null;
                            }),
                            onCustomFocus: () => setState(() {
                              _useCustom = true;
                              _selectedPlan = null;
                            }),
                            remind: _remindToWater,
                            onRemindChanged: (v) =>
                                setState(() => _remindToWater = v),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Icon ───────────────────────
                        if (_gStep == 0) ...[
                          AppCard(
                            label: l.iconLabel,
                            icon: Icons.local_florist_outlined,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: GoalIcons.presets.map((p) {
                                final (key, _, icon) = p;
                                final selected = _iconKey == key;
                                return GestureDetector(
                                  onTap: () => setState(() => _iconKey = key),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.forestGreen.withValues(
                                              alpha: 0.45,
                                            )
                                          : AppColors.soilMid,
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.forestGreen
                                            : AppColors.mossGreen.withValues(
                                                alpha: 0.4,
                                              ),
                                        width: selected ? 1.5 : 1,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.forestGreen
                                                    .withValues(alpha: 0.30),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 15,
                                          color: selected
                                              ? AppColors.forestGreen
                                              : AppColors.mossGreen,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          goalIconLabel(l, key),
                                          style: GoogleFonts.nunito(
                                            color: selected
                                                ? AppColors.forestGreen
                                                : AppColors.stoneBeigeColor,
                                            fontSize: 12.5,
                                            fontWeight: selected
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
                        ],

                        // ── Group ──────────────────────
                        if (_gStep == 2) ...[
                          AppCard(
                            label: l.groupOptional,
                            icon: Icons.label_outline,
                            accent: AppColors.riverBlue,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.groupNote,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.mossGreen.withValues(
                                      alpha: 0.85,
                                    ),
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CategoryPicker(
                                  selectedCategoryId: _categoryId,
                                  onChanged: _resolveCategory,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _gStep < 2
                    ? _NextButton(
                        enabled: _canAdvance,
                        onTap: () => setState(() => _gStep++),
                      )
                    : _PlantButton(
                        canSave: _canSave,
                        saving: _saving,
                        onTap: _save,
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
// Header with back button + title
// ──────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTokens.current.canvasSoft,
                border: Border.all(color: AppTokens.current.cardBorder),
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
                  AppLocalizations.of(context).plantASaplingTitle,
                  style: GoogleFonts.pixelifySans(
                    fontWeight: FontWeight.w600,
                    color: AppColors.stoneBeigeColor,
                    fontSize: 22,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).plantASaplingSub,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          // Small leaf badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTokens.current.accentSoft,
            ),
            child: Icon(Icons.eco,
                color: AppTokens.current.accentStrong, size: 14),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Live sapling preview banner (sky + ground + growing sapling)
// ──────────────────────────────────────────────

class _SaplingPreviewBanner extends StatelessWidget {
  final double progress;
  final LeafPalette palette;
  final String iconKey;
  final String goalName;
  final TreeCategory? category;

  const _SaplingPreviewBanner({
    required this.progress,
    required this.palette,
    required this.iconKey,
    required this.goalName,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      height: 170,
      decoration: BoxDecoration(
        color: AppTokens.current.accentTint,
        borderRadius: BorderRadius.zero,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Stack(
          children: [
            // The animated sapling
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: SaplingView(
                  key: ValueKey('$progress-${palette.mid.toARGB32()}'),
                  progress: progress,
                  size: Size.infinite,
                  leafPalette: palette,
                ),
              ),
            ),
            // Goal name + icon overlay
            Positioned(
              top: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.current.card,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppTokens.current.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      GoalIcons.forKey(iconKey),
                      color: AppTokens.current.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        goalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.pixelifySans(
                          fontWeight: FontWeight.w600,
                          color: AppTokens.current.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Optional category dot
            if (category != null)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color(category!.colorValue),
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
// Plant Sapling button — chunky, glowing wooden button
// ──────────────────────────────────────────────

class _PlantButton extends StatelessWidget {
  final bool canSave;
  final bool saving;
  final VoidCallback onTap;
  const _PlantButton({
    required this.canSave,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: saving
          ? const SizedBox(
              height: 54,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : AppPrimaryButton(
              label: l.plantSapling,
              icon: Icons.spa,
              onPressed: canSave ? onTap : null,
            ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 1 — Timeframe (target date)
// ──────────────────────────────────────────────

class _TimeframeStep extends StatelessWidget {
  final DateTime? targetDate;
  final bool uncapped;
  final VoidCallback onPickDate;
  final VoidCallback onClear;
  const _TimeframeStep({
    required this.targetDate,
    required this.uncapped,
    required this.onPickDate,
    required this.onClear,
  });

  bool get hasDate => targetDate != null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mat = MaterialLocalizations.of(context);
    return AppCard(
      label: l.targetDateLabel,
      icon: Icons.event_outlined,
      accent: AppColors.riverBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            uncapped ? l.timeframeUncappedNote : l.timeframeNote,
            style: GoogleFonts.nunito(
              color: AppColors.mossGreen.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          // Which way the plan gets solved hangs off this one answer: with a
          // date we work out the amount, without one we work out the date.
          Text(
            l.haveADateInMind,
            style: GoogleFonts.nunito(
              color: AppColors.stoneBeigeColor,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ModeChoice(
                  label: l.haveADateYes,
                  detail: l.haveADateYesDetail,
                  selected: hasDate,
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeChoice(
                  label: l.haveADateNo,
                  detail: l.haveADateNoDetail,
                  selected: !hasDate,
                  onTap: onClear,
                ),
              ),
            ],
          ),
          if (!hasDate) ...[
            const SizedBox(height: 12),
            Text(
              l.noDateExplainer,
              style: GoogleFonts.nunito(
                color: AppColors.mossGreen.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (hasDate) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.soilMid,
                borderRadius: BorderRadius.zero,
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
                      targetDate == null
                          ? l.pickATargetDate
                          : mat.formatFullDate(targetDate!),
                      style: GoogleFonts.nunito(
                        color: targetDate == null
                            ? AppColors.stoneBeigeColor.withValues(alpha: 0.5)
                            : AppColors.stoneBeigeColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (targetDate != null)
                    IconButton(
                      onPressed: onClear,
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.mossGreen.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    Icon(
                      Icons.edit_calendar_outlined,
                      color: AppColors.mossGreen,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}

/// "How much are you willing to put in each time?" — the floor and ceiling the
/// three no-deadline paces are built from, asked before any plan is generated.
class _WillingRangeCard extends StatelessWidget {
  const _WillingRangeCard({
    required this.cadence,
    required this.minCtrl,
    required this.maxCtrl,
    required this.onCadenceChanged,
    required this.onChanged,
  });

  final WaterCadence cadence;
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final ValueChanged<WaterCadence> onCadenceChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.current;

    Widget field(TextEditingController c, String label) => Expanded(
          child: TextField(
            controller: c,
            style: TextStyle(color: AppColors.stoneBeigeColor),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: label,
              prefixText: '\$ ',
              isDense: true,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.canvasSoft,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.willingRangeTitle,
            style: GoogleFonts.nunito(
              color: AppColors.stoneBeigeColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.willingRangeSub,
            style: GoogleFonts.nunito(
              color: t.textSecondary,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // The range is per timeframe, so the timeframe is picked right here.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in WaterCadence.values)
                GestureDetector(
                  onTap: () => onCadenceChanged(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: cadence == c ? t.accentSoft : t.card,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: cadence == c ? t.accentStrong : t.cardBorder,
                        width: cadence == c ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      cadenceLabel(l, c),
                      style: GoogleFonts.nunito(
                        color: cadence == c ? t.accentStrong : t.textPrimary,
                        fontSize: 12.5,
                        fontWeight:
                            cadence == c ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              field(minCtrl, l.willingRangeMin),
              const SizedBox(width: 10),
              field(maxCtrl, l.willingRangeMax),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the two planning modes on the timeframe step.
class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? t.accentSoft : t.canvasSoft,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: selected ? t.accentStrong : t.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: selected ? t.accentStrong : t.textTertiary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.nunito(
                      color: selected ? t.accentStrong : t.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              style: GoogleFonts.nunito(
                color: t.textSecondary,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Step 2 — Watering plan (AI cadence plans + custom + reminders)
// ──────────────────────────────────────────────

class _WateringStep extends StatelessWidget {
  final bool uncapped;
  final bool hasTarget;
  final DateTime? targetDate;
  final bool aiAvailable;
  final bool? useAi;
  final VoidCallback onChooseAi;
  final VoidCallback onChooseManual;
  final bool loading;
  final String? error;
  final GoalPlanResult? result;
  final double? fallbackMonthly;
  final int? selectedPlan;
  final ValueChanged<int> onSelectPlan;
  final VoidCallback onGenerate;
  final ValueChanged<DateTime> onApplyDate;
  final bool useCustom;
  final WaterCadence customCadence;
  final TextEditingController customAmountCtrl;

  /// Coach's per-watering figure for the currently selected custom cadence.
  final double suggestedPerWatering;

  /// With no deadline, when the typed custom amount would reach the goal.
  final DateTime? customProjectedDate;

  /// The range the user is willing to put in each timeframe.
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final VoidCallback onRangeChanged;
  final ValueChanged<WaterCadence> onPickCustomCadence;
  final VoidCallback onCustomFocus;
  final bool remind;
  final ValueChanged<bool> onRemindChanged;

  const _WateringStep({
    required this.uncapped,
    required this.hasTarget,
    required this.targetDate,
    required this.aiAvailable,
    required this.useAi,
    required this.onChooseAi,
    required this.onChooseManual,
    required this.loading,
    required this.error,
    required this.result,
    required this.fallbackMonthly,
    required this.selectedPlan,
    required this.onSelectPlan,
    required this.onGenerate,
    required this.onApplyDate,
    required this.useCustom,
    required this.customCadence,
    required this.customAmountCtrl,
    required this.suggestedPerWatering,
    this.customProjectedDate,
    required this.minCtrl,
    required this.maxCtrl,
    required this.onRangeChanged,
    required this.onPickCustomCadence,
    required this.onCustomFocus,
    required this.remind,
    required this.onRemindChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mat = MaterialLocalizations.of(context);
    // AI planning needs a capped goal with an amount, but **not** a date: with
    // one we solve for the contribution, without one we solve for the date the
    // goal lands on. Only an uncapped goal has nothing to plan toward.
    final showAi = aiAvailable && !uncapped && hasTarget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          label: l.wateringPlanTitle,
          icon: Icons.water_drop_outlined,
          accent: AppColors.riverBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.wateringPlanIntro,
                style: GoogleFonts.nunito(
                  color: AppColors.mossGreen.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              if (showAi && useAi == null)
                _AiPrompt(onAi: onChooseAi, onManual: onChooseManual)
              else ...[
                // Asked before anything is generated: the three no-deadline
                // paces are built straight out of this range, and with a
                // deadline it tells the user whether the required amount is
                // one they'd actually be happy with.
                if (!uncapped && hasTarget) ...[
                  _WillingRangeCard(
                    cadence: customCadence,
                    minCtrl: minCtrl,
                    maxCtrl: maxCtrl,
                    onCadenceChanged: onPickCustomCadence,
                    onChanged: onRangeChanged,
                  ),
                  const SizedBox(height: 12),
                ],
                if (showAi && useAi == true) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : onGenerate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 18,
                            ),
                      label: Text(
                        result == null ? l.planWithAi : l.regeneratePlans,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 12),
                    for (var i = 0; i < result!.plans.length; i++)
                      _WaterPlanCard(
                        plan: result!.plans[i],
                        selected: !useCustom && selectedPlan == i,
                        onTap: () => onSelectPlan(i),
                      ),
                    if (result!.alternativeDates.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.alternativeDates,
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen.withValues(alpha: 0.8),
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in result!.alternativeDates)
                            ActionChip(
                              backgroundColor: AppTokens.current.canvasSoft,
                              side: BorderSide(
                                color: AppTokens.current.cardBorder,
                              ),
                              label: Text(
                                mat.formatShortDate(a.date),
                                style: TextStyle(
                                  color: AppColors.stoneBeigeColor,
                                  fontSize: 11.5,
                                ),
                              ),
                              onPressed: () => onApplyDate(a.date),
                            ),
                        ],
                      ),
                    ],
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.aiUnavailableSimple,
                      style: GoogleFonts.nunito(
                        color: AppColors.warningAmber,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
                // Custom watering schedule — always available.
                _CustomWaterCard(
                  active: useCustom,
                  cadence: customCadence,
                  amountCtrl: customAmountCtrl,
                  onPickCadence: onPickCustomCadence,
                  onFocus: onCustomFocus,
                  suggested: suggestedPerWatering,
                  projectedDate: customProjectedDate,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Reminders toggle.
        AppCard(
          label: l.remindToWaterTitle,
          icon: Icons.notifications_active_outlined,
          accent: const Color(0xFFBA8514),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.remindToWaterSub,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              Switch(value: remind, onChanged: onRemindChanged),
            ],
          ),
        ),
      ],
    );
  }
}

// One selectable AI watering plan, e.g. "$100 every 2 weeks · about 8 months".
class _WaterPlanCard extends StatelessWidget {
  final GoalPlanOption plan;
  final bool selected;
  final VoidCallback onTap;
  const _WaterPlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppTokens.current.accentSoft
                : AppTokens.current.canvasSoft,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: selected
                  ? AppTokens.current.accentStrong
                  : AppTokens.current.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected
                    ? AppTokens.current.accentStrong
                    : AppTokens.current.textTertiary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Without a deadline the three options are a progression
                    // from gentlest to quickest, so name the pace: it's the
                    // difference between them.
                    if (plan.pace != null) ...[
                      Text(
                        goalPaceLabel(l, plan.pace!),
                        style: GoogleFonts.nunito(
                          color: AppTokens.current.accentStrong,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      '\$${plan.perWatering.toStringAsFixed(0)} ${cadenceEvery(l, plan.cadence)}',
                      style: GoogleFonts.pixelifySans(
                        fontWeight: FontWeight.w600,
                        color: AppColors.stoneBeigeColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // With a deadline every plan hits the same date and so
                    // costs the same per month; saying so turns what looks
                    // like duplicate options into a real choice of rhythm.
                    // Without one, the date IS the differentiator, so lead
                    // with it.
                    Text(
                      plan.completionDate == null
                          ? '${l.planAboutMonths(plan.monthsToTarget)} · '
                              '${l.sameMonthlyAs('\$${plan.monthly.toStringAsFixed(0)}')}'
                          : '${l.reachesGoalBy(MaterialLocalizations.of(context).formatMediumDate(plan.completionDate!))} · '
                              '${l.sameMonthlyAs('\$${plan.monthly.toStringAsFixed(0)}')}',
                      style: GoogleFonts.nunito(
                        color: AppColors.forestGreen,
                        fontSize: 11.5,
                      ),
                    ),
                    if (plan.rationale.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.rationale,
                        style: GoogleFonts.nunito(
                          color: AppColors.mossGreen.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom watering schedule: pick a cadence and a per-watering amount.
class _CustomWaterCard extends StatelessWidget {
  final bool active;
  final WaterCadence cadence;
  final TextEditingController amountCtrl;
  final ValueChanged<WaterCadence> onPickCadence;
  final VoidCallback onFocus;

  /// What the coach would put in each watering at the selected cadence, used
  /// when the user leaves the field blank. 0 when it can't be worked out yet.
  final double suggested;

  /// When the goal has no deadline, the date the entered amount would reach it
  /// on. Recomputed as the user types, so the pace and its consequence are on
  /// screen together.
  final DateTime? projectedDate;

  const _CustomWaterCard({
    required this.active,
    required this.cadence,
    required this.amountCtrl,
    required this.onPickCadence,
    required this.onFocus,
    required this.suggested,
    this.projectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? AppTokens.current.accentTint
            : AppTokens.current.canvasSoft,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: active
              ? AppTokens.current.accentStrong
              : AppTokens.current.cardBorder,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.customWaterTitle,
            style: GoogleFonts.nunito(
              color: AppColors.stoneBeigeColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in WaterCadence.values)
                GestureDetector(
                  onTap: () => onPickCadence(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active && cadence == c
                          ? AppTokens.current.accentSoft
                          : AppTokens.current.card,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: active && cadence == c
                            ? AppTokens.current.accentStrong
                            : AppTokens.current.cardBorder,
                        width: active && cadence == c ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      cadenceLabel(l, c),
                      style: GoogleFonts.nunito(
                        color: active && cadence == c
                            ? AppTokens.current.accentStrong
                            : AppColors.stoneBeigeColor,
                        fontSize: 12.5,
                        fontWeight: active && cadence == c
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: amountCtrl,
            style: TextStyle(color: AppColors.stoneBeigeColor),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onTap: onFocus,
            onChanged: (_) => onFocus(),
            decoration: InputDecoration(
              labelText: l.amountPerWatering,
              prefixText: '\$ ',
              isDense: true,
              // Leaving it blank isn't an error: the coach's own number for
              // this cadence is used instead, so say what that number is.
              hintText: suggested > 0 ? suggested.toStringAsFixed(0) : null,
              helperText: suggested > 0
                  ? l.leaveBlankForSuggested(
                      '\$${suggested.toStringAsFixed(0)}',
                    )
                  : null,
              helperMaxLines: 2,
            ),
          ),
          // No deadline: show what this pace actually buys them.
          if (projectedDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.flag_outlined,
                    size: 15, color: AppTokens.current.accentStrong),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l.reachesGoalBy(
                      MaterialLocalizations.of(context)
                          .formatMediumDate(projectedDate!),
                    ),
                    style: GoogleFonts.nunito(
                      color: AppTokens.current.accentStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// AI opt-in prompt — shown before anything is calculated
// ──────────────────────────────────────────────

class _AiPrompt extends StatelessWidget {
  final VoidCallback onAi;
  final VoidCallback onManual;
  const _AiPrompt({required this.onAi, required this.onManual});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      label: l.aiPlanPromptTitle,
      icon: Icons.auto_awesome,
      accent: const Color(0xFFBA8514),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.aiPlanPromptBody,
            style: GoogleFonts.nunito(
              color: AppColors.mossGreen.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAi,
              icon: const Icon(Icons.auto_awesome),
              label: Text(l.planWithAi),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onManual,
              child: Text(l.setItUpMyself),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Wizard "Next" button (mirrors the plant button styling, lighter)
// ──────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _NextButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: AppPrimaryButton(
        label: l.next,
        icon: Icons.arrow_forward,
        onPressed: enabled ? onTap : null,
      ),
    );
  }
}
