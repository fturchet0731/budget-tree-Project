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
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/app_scrollbar.dart';
import '../widgets/bark_card.dart';
import '../widgets/category_picker.dart';
import '../widgets/sapling_view.dart';
import '../widgets/scenery.dart';
import '../widgets/vine_step_indicator.dart';

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
        backgroundColor: const Color(0xFF122B0F),
        title: Text(
          l.fundFromBranchTitle,
          style: const TextStyle(color: AppColors.stoneBeigeColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              l.fundFromBranchBody,
              style: const TextStyle(
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
                style: const TextStyle(color: AppColors.stoneBeigeColor),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              l.notNow,
              style: const TextStyle(color: AppColors.mossGreen),
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Palette-driven background scene ───────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: AppPalettes.deepForest()),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GoalSkyPainter())),
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
                VineStepIndicator(
                  currentStep: _gStep,
                  steps: [
                    VineStep(label: l.goalStepName, icon: Icons.spa),
                    VineStep(label: l.goalStepWhen, icon: Icons.event_outlined),
                    VineStep(label: l.vinePlan, icon: Icons.auto_awesome),
                  ],
                ),
                Expanded(
                  child: AppScrollbar(
                    builder: (controller) => ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        if (_gStep == 0) ...[
                          // ── About this goal ──────────
                          BarkCard(
                            label: l.aboutThisGoal,
                            icon: Icons.spa,
                            child: Column(
                              children: [
                                TextField(
                                  controller: _nameCtrl,
                                  style: const TextStyle(
                                    color: AppColors.stoneBeigeColor,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l.goalName,
                                    hintText: l.goalNameHint,
                                    prefixIcon: const Icon(
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
                                  style: const TextStyle(
                                    color: AppColors.stoneBeigeColor,
                                  ),
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: l.notesOptional,
                                    hintText: l.notesHint,
                                    prefixIcon: const Icon(
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
                          BarkCard(
                            label: l.howMuch,
                            icon: Icons.flag_outlined,
                            accent: AppColors.leafYellow,
                            child: Column(
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _uncapped ? 0.4 : 1.0,
                                  child: TextField(
                                    controller: _targetCtrl,
                                    enabled: !_uncapped,
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
                                      labelText: l.targetAmount,
                                      hintText: l.targetHint,
                                      prefixIcon: const Icon(
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
                                      gradient: _uncapped
                                          ? LinearGradient(
                                              colors: [
                                                AppColors.forestGreen
                                                    .withValues(alpha: 0.50),
                                                AppColors.darkBark,
                                              ],
                                            )
                                          : null,
                                      color: _uncapped
                                          ? null
                                          : AppColors.soilMid,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _uncapped
                                            ? AppColors.lightLeaf.withValues(
                                                alpha: 0.8,
                                              )
                                            : AppColors.mossGreen.withValues(
                                                alpha: 0.35,
                                              ),
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
                                                ? AppColors.lightLeaf
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: _uncapped
                                                  ? AppColors.lightLeaf
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
                          BarkCard(
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
                                            ? AppColors.lightLeaf
                                            : AppColors.mossGreen.withValues(
                                                alpha: 0.4,
                                              ),
                                        width: selected ? 1.5 : 1,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.lightLeaf
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
                                              ? AppColors.lightLeaf
                                              : AppColors.mossGreen,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          goalIconLabel(l, key),
                                          style: GoogleFonts.nunito(
                                            color: selected
                                                ? AppColors.lightLeaf
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
                          BarkCard(
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
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.mossGreen.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
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
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                Text(
                  AppLocalizations.of(context).plantASaplingSub,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Decorative leaf badge
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
            child: const Icon(Icons.eco, color: Colors.white, size: 14),
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
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7EC8E3), Color(0xFFB6D7A8), Color(0xFF7CB342)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Sun glow upper-right
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFF59D).withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
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
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      GoalIcons.forKey(iconKey),
                      color: Colors.white,
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
                          color: Colors.white,
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
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(
                          category!.colorValue,
                        ).withValues(alpha: 0.5),
                        blurRadius: 6,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: canSave
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
            color: canSave
                ? Colors.white.withValues(alpha: 0.5)
                : AppColors.mossGreen.withValues(alpha: 0.2),
            width: canSave ? 1.6 : 1,
          ),
          boxShadow: canSave
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
            onTap: canSave && !saving ? onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.spa,
                          color: canSave
                              ? Colors.white
                              : AppColors.stoneBeigeColor.withValues(
                                  alpha: 0.5,
                                ),
                          size: 18,
                        ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).plantSapling,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w600,
                      color: canSave
                          ? Colors.white
                          : AppColors.stoneBeigeColor.withValues(alpha: 0.5),
                      fontSize: 16,
                      letterSpacing: 0.5,
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

// ──────────────────────────────────────────────
// Sky → forest background painter
// ──────────────────────────────────────────────

class _GoalSkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The base gradient is painted behind us from AppPalettes.deepForest();
    // here we only add the glow + silhouettes so the scene follows the palette.

    // Soft glow upper right, tinted to the active palette.
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.06),
      130,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                AppPalettes.celestialGlow().withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: Offset(w * 0.86, h * 0.06), radius: 130),
            ),
    );

    // Tree line near the bottom: two staggered depths of full silhouettes,
    // matching the budget wizard's backdrop.
    final back = const Color(0xFF050D04).withValues(alpha: 0.5);
    final front = const Color(0xFF050D04).withValues(alpha: 0.82);
    final treeY = h * 0.92;
    for (int i = 0; i < 6; i++) {
      final x = (i + 0.5) / 6 * w;
      Scenery.paintTreeSilhouette(
        canvas,
        Offset(x, treeY - 10),
        64 + ((i * 11) % 4) * 9,
        back,
        seed: i + 60,
      );
    }
    for (int i = 0; i < 5; i++) {
      final x = (i + 0.2) / 5 * w + 10;
      Scenery.paintTreeSilhouette(
        canvas,
        Offset(x, treeY + 4),
        50 + ((i * 7) % 3) * 8,
        front,
        seed: i + 12,
      );
    }

    // Bottom vignette
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
  bool shouldRepaint(_GoalSkyPainter old) => false;
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
    return BarkCard(
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
                  const Icon(
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
                    const Icon(
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
        BarkCard(
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
                        backgroundColor: AppColors.forestGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              backgroundColor: AppColors.darkBark,
                              side: BorderSide(
                                color: AppColors.mossGreen.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              label: Text(
                                mat.formatShortDate(a.date),
                                style: const TextStyle(
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
        BarkCard(
          label: l.remindToWaterTitle,
          icon: Icons.notifications_active_outlined,
          accent: AppColors.leafYellow,
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
              Switch(
                value: remind,
                onChanged: onRemindChanged,
                activeThumbColor: AppColors.lightLeaf,
              ),
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
                ? AppColors.forestGreen.withValues(alpha: 0.35)
                : AppColors.soilMid,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.lightLeaf
                  : AppColors.mossGreen.withValues(alpha: 0.4),
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
                color: selected ? AppColors.lightLeaf : AppColors.mossGreen,
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
                        color: AppColors.lightLeaf,
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
        color: AppColors.darkBark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColors.lightLeaf
              : AppColors.mossGreen.withValues(alpha: 0.3),
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
                          ? AppColors.forestGreen.withValues(alpha: 0.45)
                          : AppColors.soilMid,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active && cadence == c
                            ? AppColors.lightLeaf
                            : AppColors.mossGreen.withValues(alpha: 0.4),
                        width: active && cadence == c ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      cadenceLabel(l, c),
                      style: GoogleFonts.nunito(
                        color: active && cadence == c
                            ? AppColors.lightLeaf
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
            style: const TextStyle(color: AppColors.stoneBeigeColor),
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
    return BarkCard(
      label: l.aiPlanPromptTitle,
      icon: Icons.auto_awesome,
      accent: AppColors.leafYellow,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                l.planWithAi,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            disabledBackgroundColor: AppColors.darkBark,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          label: Text(
            l.next,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
