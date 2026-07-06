import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  /// The watering schedule the user settled on, if any: a selected AI plan, a
  /// custom cadence + amount, or the offline monthly fallback. Null when nothing
  /// is set (the goal is then saved without reminders).
  ({WaterCadence cadence, double amount})? get _chosenWatering {
    if (_useCustom) {
      final amt = double.tryParse(_customAmountCtrl.text) ?? 0;
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
      goal.nextWaterDate = DateTime.now().add(
        Duration(days: watering.cadence.days),
      );
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

  /// Build a transient goal and ask the AI for contribution plans + alternative
  /// dates. Falls back to simple math (still useful offline).
  Future<void> _generatePlan() async {
    final date = _targetDate;
    final target = double.tryParse(_targetCtrl.text) ?? 0;
    if (date == null || target <= 0) return;
    final transient = Goal(name: _nameCtrl.text.trim(), targetAmount: target);

    // Honour the user's choice: manual (or no AI available) just does the
    // simple offline math; only AI mode hits the coach.
    if (_useAi != true || !AiCoachService.instance.isAvailable) {
      setState(
        () => _fallbackMonthly = GoalPlanMath.monthlyToReach(transient, date),
      );
      return;
    }
    setState(() {
      _planLoading = true;
      _planError = null;
    });
    try {
      final free = await GoalPlanMath.freeMonthlyIncome();
      final result = await AiCoachService.instance.goalPlans(
        goal: transient,
        targetDate: date,
        freeMonthly: free,
      );
      if (!mounted) return;
      setState(() {
        _planResult = result;
        _planLoading = false;
      });
    } on AiUnavailable catch (e) {
      if (!mounted) return;
      setState(() {
        _planLoading = false;
        _planError = e.message;
        _fallbackMonthly = GoalPlanMath.monthlyToReach(transient, date);
      });
    }
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
                                  borderRadius: BorderRadius.circular(12),
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
                                      borderRadius: BorderRadius.circular(12),
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
                                            shape: BoxShape.circle,
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
                                      borderRadius: BorderRadius.circular(20),
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
                shape: BoxShape.circle,
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
                  style: GoogleFonts.fredoka(
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
              shape: BoxShape.circle,
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
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
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
                  borderRadius: BorderRadius.circular(14),
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
                        style: GoogleFonts.fredoka(
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
                    shape: BoxShape.circle,
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
          const SizedBox(height: 12),
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.soilMid,
                borderRadius: BorderRadius.circular(12),
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
    required this.onPickCustomCadence,
    required this.onCustomFocus,
    required this.remind,
    required this.onRemindChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mat = MaterialLocalizations.of(context);
    // AI planning only makes sense for a capped goal with a chosen date.
    final showAi = aiAvailable && !uncapped && hasTarget && targetDate != null;
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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppTokens.current.accentSoft
                : AppTokens.current.canvasSoft,
            borderRadius: BorderRadius.circular(12),
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
                    Text(
                      '\$${plan.perWatering.toStringAsFixed(0)} ${cadenceEvery(l, plan.cadence)}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w600,
                        color: AppColors.stoneBeigeColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.planAboutMonths(plan.monthsToTarget),
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
  const _CustomWaterCard({
    required this.active,
    required this.cadence,
    required this.amountCtrl,
    required this.onPickCadence,
    required this.onFocus,
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
        borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(20),
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
            ),
          ),
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
