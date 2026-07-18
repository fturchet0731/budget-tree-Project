import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../screens/goal_detail_screen.dart';
import '../screens/goals_screen.dart';
import '../services/budget_repository.dart';
import '../services/goal_repository.dart';
import '../services/pulse_service.dart';
import '../theme/app_dims.dart';
import '../theme/app_shadows.dart';
import '../theme/app_tokens.dart';
import 'ui/pressable.dart';

/// The dashboard's "one thing right now" strip: surfaces the weekly habit in
/// the app itself instead of leaving it to notifications. Shows the single
/// most useful nudge from [PulseService] (watering due, streak at risk, quiet
/// streak badge, or a first-tree call for empty accounts) and deep links
/// straight to the place where the user acts on it. Renders nothing when
/// there's nothing worth saying, mirroring [ReflectionBanner].
class PulseStrip extends StatefulWidget {
  const PulseStrip({super.key, required this.onPlantTree});

  /// Opens the Create flow (the dashboard owns that navigation because it also
  /// shows the "new tree" snackbar on completion).
  final VoidCallback onPlantTree;

  @override
  State<PulseStrip> createState() => PulseStripState();
}

class PulseStripState extends State<PulseStrip> {
  PulseInfo _pulse = PulseInfo.none;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Reload from the repositories (cache-first, so this is cheap). The
  /// dashboard calls this after any navigation that could change goals.
  Future<void> refresh() async {
    final List<BudgetModel> budgets = await BudgetRepository.loadAll();
    final List<Goal> goals = await GoalRepository.loadAll();
    if (!mounted) return;
    setState(() {
      _pulse = PulseService.compute(budgets: budgets, goals: goals);
    });
  }

  Future<void> _open() async {
    switch (_pulse.kind) {
      case PulseKind.waterDue:
        final goal = _pulse.goal;
        if (goal == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
        );
        break;
      case PulseKind.streakAtRisk:
      case PulseKind.streakActive:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GoalsScreen()),
        );
        break;
      case PulseKind.plantFirstTree:
        widget.onPlantTree();
        return; // the dashboard refreshes us when the Create flow returns
      case PulseKind.none:
        return;
    }
    if (mounted) await refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_pulse.kind == PulseKind.none) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    final t = AppTokens.of(context);
    final IconData icon;
    final Color accent;
    final String title;
    final String body;
    switch (_pulse.kind) {
      case PulseKind.waterDue:
        final goal = _pulse.goal!;
        final amount = goal.waterAmount ?? 0;
        icon = Icons.water_drop;
        accent = const Color(0xFF5B8DB8);
        title = l.pulseWaterTitle;
        body = _pulse.overdue
            ? l.pulseWaterOverdueBody(goal.name)
            : l.pulseWaterBody(
                goal.name, '\$${amount.toStringAsFixed(0)}');
        break;
      case PulseKind.streakAtRisk:
        icon = Icons.local_fire_department;
        accent = t.warning;
        title = l.pulseStreakAtRiskTitle;
        body = l.pulseStreakAtRiskBody(_pulse.streakWeeks);
        break;
      case PulseKind.streakActive:
        icon = Icons.local_fire_department;
        accent = t.accentStrong;
        title = l.pulseStreakTitle;
        body = l.pulseStreakBody(_pulse.streakWeeks);
        break;
      case PulseKind.plantFirstTree:
        icon = Icons.park;
        accent = t.accentStrong;
        title = l.pulsePlantTitle;
        body = l.pulsePlantBody;
        break;
      case PulseKind.none:
        return const SizedBox.shrink();
    }

    // Kept deliberately slim (one-line body, small icon) so the nudges never
    // crowd the friends strip and menu grid below them.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: PressableScale(
        onTap: _open,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(AppDims.rInner),
            border: Border.all(color: t.cardBorder),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: t.textPrimary,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.textTertiary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
