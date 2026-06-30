import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../l10n/goal_labels.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import '../services/achievement_service.dart';
import '../services/budget_repository.dart';
import '../services/category_repository.dart';
import '../data/water_cadence.dart';
import '../services/goal_repository.dart';
import '../services/notification_scheduler.dart';
import '../services/profile_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../theme/leaf_palette.dart';
import '../widgets/achievements_sheet.dart';
import '../widgets/category_picker.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/sapling_view.dart';
import '../widgets/savings_thermometer.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _LinkedBranchInfo {
  final String budgetName;
  final ExpenseCategory category;
  final double monthlyAllocated;
  _LinkedBranchInfo({
    required this.budgetName,
    required this.category,
    required this.monthlyAllocated,
  });
}

class _GoalDetailScreenState extends State<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late Goal _goal;
  late AnimationController _growCtrl;
  late Animation<double> _growAnim;
  double _displayedProgress = 0;
  bool _changed = false;
  List<_LinkedBranchInfo> _linkedBranches = [];
  TreeCategory? _category;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _growAnim = CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic);
    _growAnim.addListener(_onGrowTick);
    _growCtrl.animateTo(_goal.progress);
    _loadLinkedBranches();
  }

  Future<void> _loadLinkedBranches() async {
    final budgets = await BudgetRepository.loadAll();
    final hits = <_LinkedBranchInfo>[];
    for (final b in budgets) {
      for (final cat in b.expenses) {
        if (cat.linkedGoalIds.contains(_goal.id)) {
          hits.add(
            _LinkedBranchInfo(
              budgetName: b.budgetName,
              category: cat,
              monthlyAllocated: cat.allocated,
            ),
          );
        }
      }
    }
    // Resolve category for tint
    TreeCategory? cat;
    if (_goal.categoryId != null) {
      final all = await CategoryRepository.loadAll();
      cat = all.cast<TreeCategory?>().firstWhere(
        (c) => c?.id == _goal.categoryId,
        orElse: () => null,
      );
    }
    if (mounted) {
      setState(() {
        _linkedBranches = hits;
        _category = cat;
      });
    }
  }

  LeafPalette get _leafPalette => _category != null
      ? LeafPalette.fromAccent(Color(_category!.colorValue))
      : LeafPalette.defaultGreen;

  @override
  void dispose() {
    _growAnim.removeListener(_onGrowTick);
    _growCtrl.dispose();
    super.dispose();
  }

  void _onGrowTick() {
    if (!mounted) return;
    setState(() {
      _displayedProgress = _growAnim.value;
    });
  }

  Future<void> _animateTo(double target) async {
    final from = _displayedProgress;
    // Remove the listener from the previous animation before swapping it
    // out — without this, every deposit added another stale listener that
    // kept firing on the shared controller and eventually called
    // setState on a disposed state when linking to a complete goal.
    _growAnim.removeListener(_onGrowTick);
    _growCtrl
      ..stop()
      ..reset();
    _growAnim = Tween<double>(
      begin: from,
      end: target.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _growCtrl, curve: Curves.easeOutCubic));
    _growAnim.addListener(_onGrowTick);
    if (!mounted) return;
    await _growCtrl.forward();
  }

  Future<void> _persist() async {
    _changed = true;
    await GoalRepository.update(_goal);
  }

  /// Flip whether friends can see this goal. Persists immediately so the
  /// Supabase row's `sharedWithFriends` flag (read by the RLS policy) updates.
  Future<void> _toggleShared(bool v) async {
    setState(() => _goal.sharedWithFriends = v);
    await _persist();
  }

  void _showDeposit() {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D2010),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mossGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.waterTheSapling,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w600,
                  color: AppColors.stoneBeigeColor,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.depositToward(_goal.name),
                style: GoogleFonts.nunito(
                  color: AppColors.mossGreen,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(
                  color: AppColors.lightLeaf,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    color: AppColors.mossGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [25, 50, 100, 250].map((amount) {
                  return ActionChip(
                    label: Text('+\$$amount'),
                    onPressed: () {
                      final cur = double.tryParse(ctrl.text) ?? 0;
                      ctrl.text = (cur + amount).toStringAsFixed(2);
                    },
                    backgroundColor: AppColors.darkBark,
                    side: BorderSide(
                      color: AppColors.mossGreen.withValues(alpha: 0.4),
                    ),
                    labelStyle: const TextStyle(
                      color: AppColors.stoneBeigeColor,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final amount = double.tryParse(ctrl.text) ?? 0;
                    if (amount <= 0) return;
                    Navigator.pop(ctx);
                    final wasComplete = _goal.isComplete;
                    final prevStage = _goal.stage;
                    final prevTier = _goal.tier;
                    setState(() {
                      _goal.applyContribution(
                        amount,
                        source: ContributionSource.manual,
                      );
                      _goal.stampCompletionIfReached();
                      // Watered: move the next watering one cadence out so the
                      // reminders track the user's actual rhythm.
                      final cadence = _goal.waterCadence;
                      if (_goal.waterRemindersEnabled && cadence != null) {
                        _goal.nextWaterDate = DateTime.now().add(
                          Duration(days: cadence.days),
                        );
                      }
                    });
                    SoundService.fundsAllocated();
                    await _persist();
                    await NotificationScheduler.rescheduleAll();
                    await _animateTo(_goal.progress);
                    await _celebrateProgress(wasComplete, prevStage, prevTier);
                  },
                  icon: const Icon(Icons.water_drop, color: Colors.white),
                  label: Text(
                    l.deposit,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final amount = double.tryParse(ctrl.text) ?? 0;
                    if (amount <= 0) return;
                    Navigator.pop(ctx);
                    setState(() {
                      _goal.applyContribution(
                        -amount,
                        source: ContributionSource.adjustment,
                      );
                      // Completion is a permanent trophy — withdrawing below
                      // the target does not undo it.
                    });
                    await _persist();
                    await _animateTo(_goal.progress);
                  },
                  icon: const Icon(Icons.remove, color: AppColors.warningAmber),
                  label: Text(
                    l.withdraw,
                    style: GoogleFonts.nunito(
                      color: AppColors.warningAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.warningAmber.withValues(alpha: 0.6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// After a deposit settles, fire the right celebration: goal completion
  /// wins over a tier/stage milestone, and either way re-check badges. Only
  /// the first crossing of each threshold celebrates.
  Future<void> _celebrateProgress(
    bool wasComplete,
    int prevStage,
    int prevTier,
  ) async {
    if (!mounted) return;
    final earned = await AchievementService.evaluateAndUnlock();

    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (!wasComplete && _goal.isComplete) {
      SoundService.celebrate();
      await showCelebration(
        context,
        title: l.goalReachedTitle,
        message: l.goalReachedMsg(_goal.name),
        icon: Icons.emoji_events,
      );
    } else if (_goal.isUncapped && _goal.tier > prevTier) {
      SoundService.milestone();
      await showCelebration(
        context,
        title: l.newGrowthTitle,
        message: l.newGrowthMsg(
          _goal.name,
          _goal.tier,
          _goal.localizedTierName(l),
        ),
        icon: Icons.nature,
        color: AppColors.lightLeaf,
        buttonLabel: l.keepGrowing,
      );
    } else if (!_goal.isUncapped &&
        _goal.stage > prevStage &&
        _goal.stage < 5) {
      SoundService.milestone();
      await showCelebration(
        context,
        title: l.milestoneTitle,
        message: l.milestoneMsg(
          _goal.name,
          _goal.localizedStageName(l),
          (_goal.progress * 100).round(),
        ),
        icon: Icons.local_florist,
        color: AppColors.lightLeaf,
        buttonLabel: l.nice,
      );
    }

    if (mounted && earned.isNotEmpty) {
      await presentNewAchievements(context, earned);
    }
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2410),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.removeSaplingTitle,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w600,
            color: AppColors.stoneBeigeColor,
            fontSize: 20,
          ),
        ),
        content: Text(
          l.removeSaplingBody(_goal.name),
          style: GoogleFonts.nunito(
            color: AppColors.mossGreen,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.cancel,
              style: GoogleFonts.nunito(color: AppColors.mossGreen),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.delete,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await GoalRepository.delete(_goal.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  void _showEditDialog() {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: _goal.name);
    final targetCtrl = TextEditingController(
      text: _goal.targetAmount > 0 ? _goal.targetAmount.toStringAsFixed(2) : '',
    );
    String? editCategoryId = _goal.categoryId;
    bool uncapped = _goal.isUncapped;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (sbCtx, setSBState) => AlertDialog(
          backgroundColor: const Color(0xFF122B0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l.editGoal,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              color: AppColors.stoneBeigeColor,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.stoneBeigeColor),
                  decoration: InputDecoration(labelText: l.name),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: uncapped ? 0.4 : 1.0,
                  child: TextField(
                    controller: targetCtrl,
                    enabled: !uncapped,
                    style: const TextStyle(color: AppColors.stoneBeigeColor),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l.target,
                      prefixText: '\$ ',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => setSBState(() => uncapped = !uncapped),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          uncapped
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: uncapped
                              ? AppColors.lightLeaf
                              : AppColors.mossGreen.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.growForeverTiers,
                            style: GoogleFonts.nunito(
                              color: AppColors.stoneBeigeColor,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.groupUpper,
                  style: GoogleFonts.nunito(
                    color: AppColors.mossGreen.withValues(alpha: 0.75),
                    fontSize: 10.5,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                CategoryPicker(
                  selectedCategoryId: editCategoryId,
                  onChanged: (id) => setSBState(() => editCategoryId = id),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l.cancel,
                style: GoogleFonts.nunito(color: AppColors.mossGreen),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
              ),
              onPressed: () async {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                final t = uncapped
                    ? 0.0
                    : (double.tryParse(targetCtrl.text) ?? _goal.targetAmount);
                if (!uncapped && t <= 0) return;
                // Resolve the chosen category's colour so the goal carries its
                // tree tint with it (friends can't see the owner's categories).
                TreeCategory? newCat;
                if (editCategoryId != null) {
                  final all = await CategoryRepository.loadAll();
                  newCat = all.cast<TreeCategory?>().firstWhere(
                    (c) => c?.id == editCategoryId,
                    orElse: () => null,
                  );
                }
                setState(() {
                  _goal.name = n;
                  _goal.targetAmount = t;
                  _goal.categoryId = editCategoryId;
                  _goal.leafColorValue = newCat?.colorValue;
                  _category = newCat;
                  // Raising the target above the balance doesn't un-complete a
                  // goal that was already reached — completion is permanent.
                  _goal.stampCompletionIfReached();
                });
                await _persist();
                await _animateTo(_goal.progress);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(
                l.save,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final complete = _goal.isComplete;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(decoration: BoxDecoration(gradient: AppPalettes.sky())),
            // Sapling stage — uncapped goals scale up per tier so a Tier 6
            // tree looks substantially larger than a Tier 1.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 96, 0, 280),
                child: Transform.scale(
                  scale: _goal.isUncapped ? _goal.tierScale : 1.0,
                  child: SaplingView(
                    progress: _displayedProgress,
                    size: Size.infinite,
                    leafPalette: _leafPalette,
                  ),
                ),
              ),
            ),
            // Savings thermometer — fills as money accumulates toward the
            // target, mirroring the sapling's growth on a precise gauge.
            Positioned(
              right: 16,
              top: 150,
              child: Column(
                children: [
                  SavingsThermometer(
                    fill: _displayedProgress,
                    color: complete
                        ? const Color(0xFFFFD54F)
                        : (_category != null
                              ? Color(_category!.colorValue)
                              : AppColors.lightLeaf),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _goal.isUncapped
                          ? 'T${_goal.tier}'
                          : '${(_displayedProgress * 100).round()}%',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context, _changed),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        GoalIcons.forKey(_goal.iconKey),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _goal.name,
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 20,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(1, 2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _goal.localizedStageName(l),
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showEditDialog,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    IconButton(
                      onPressed: _confirmDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom info panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0D2010).withValues(alpha: 0.85),
                      const Color(0xFF0D2010),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.savedUpper,
                              style: GoogleFonts.nunito(
                                color: AppColors.mossGreen.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${_goal.currentAmount.toStringAsFixed(2)}',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                color: complete
                                    ? const Color(0xFFFFD54F)
                                    : AppColors.lightLeaf,
                                fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _goal.isUncapped ? l.tierUpper : l.targetUpper,
                              style: GoogleFonts.nunito(
                                color: AppColors.mossGreen.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _goal.isUncapped
                                  ? '${_goal.tier} · ${_goal.localizedTierName(l)}'
                                  : '\$${_goal.targetAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.nunito(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _displayedProgress,
                        minHeight: 12,
                        backgroundColor: AppColors.soilMid,
                        valueColor: AlwaysStoppedAnimation(
                          complete
                              ? const Color(0xFFFFD54F)
                              : AppColors.lightLeaf,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _goal.isUncapped
                              ? _goal.localizedTierName(l)
                              : l.percentGrown(
                                  (_displayedProgress * 100).round(),
                                ),
                          style: GoogleFonts.nunito(
                            color: AppColors.mossGreen,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _goal.isUncapped
                              ? l.noCapKeepsGrowing
                              : complete
                              ? l.goalReachedShort
                              : l.amountToGo(
                                  '\$${_goal.remaining.toStringAsFixed(2)}',
                                ),
                          style: GoogleFonts.nunito(
                            color: complete
                                ? const Color(0xFFFFD54F)
                                : AppColors.mossGreen,
                            fontSize: 11,
                            fontWeight: complete
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MilestoneRow(progress: _displayedProgress),
                    if (ProfileService.instance.isAvailable) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            _goal.sharedWithFriends
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 16,
                            color: AppColors.mossGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _goal.sharedWithFriends
                                  ? l.visibleToFriends
                                  : l.privateOnlyYou,
                              style: GoogleFonts.nunito(
                                color: AppColors.stoneBeigeColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Switch(
                            value: _goal.sharedWithFriends,
                            activeThumbColor: AppColors.lightLeaf,
                            onChanged: _toggleShared,
                          ),
                        ],
                      ),
                    ],
                    if (_linkedBranches.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 13,
                            color: AppColors.mossGreen.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l.fundedByUpper,
                            style: GoogleFonts.nunito(
                              color: AppColors.mossGreen.withValues(alpha: 0.8),
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _linkedBranches.map((info) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen.withValues(
                                alpha: 0.28,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.lightLeaf.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CategoryIcons.forKey(info.category.emoji),
                                  color: AppColors.lightLeaf,
                                  size: 13,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${info.category.name} · ${info.budgetName}',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.stoneBeigeColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '\$${info.monthlyAllocated.toStringAsFixed(0)}/mo',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.lightLeaf,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showDeposit,
                        icon: const Icon(Icons.water_drop, color: Colors.white),
                        label: Text(
                          complete ? l.adjust : l.waterTheSapling,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          elevation: 4,
                        ),
                      ),
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
// Milestone dots: 0, 1/4, 1/2, 3/4, full
// ──────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  final double progress;
  const _MilestoneRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final stops = [0.0, 0.25, 0.50, 0.75, 1.0];
    final labels = [l.milestoneSeed, '25%', '50%', '75%', l.milestoneMature];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) {
        final reached = progress >= stops[i] - 0.001;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: reached ? 11 : 9,
              height: reached ? 11 : 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached
                    ? (stops[i] >= 1.0
                          ? const Color(0xFFFFD54F)
                          : AppColors.lightLeaf)
                    : AppColors.soilMid,
                border: Border.all(
                  color: reached
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppColors.mossGreen.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[i],
              style: TextStyle(
                color: reached
                    ? AppColors.stoneBeigeColor
                    : AppColors.mossGreen.withValues(alpha: 0.55),
                fontSize: 9,
              ),
            ),
          ],
        );
      }),
    );
  }
}
