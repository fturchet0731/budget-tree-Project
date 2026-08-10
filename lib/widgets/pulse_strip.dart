import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/budget_model.dart';
import '../models/check_in.dart';
import '../models/goal_model.dart';
import '../screens/goal_detail_screen.dart';
import '../screens/goals_screen.dart';
import '../services/budget_repository.dart';
import '../services/check_in_service.dart';
import '../services/goal_repository.dart';
import '../services/pulse_service.dart';
import 'check_in_sheet.dart';
import 'pixel/pixel.dart';

/// The dashboard's "one thing right now" strip: surfaces the weekly habit in
/// the app itself instead of leaving it to notifications. Shows the single
/// most useful nudge from [PulseService] (an unanswered check-in, watering due,
/// streak at risk, quiet streak badge, or a first-tree call for empty accounts)
/// and deep links straight to the place where the user acts on it. Renders
/// nothing when there's nothing worth saying.
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
    final List<CheckIn> pending = await CheckInService.pending();
    if (!mounted) return;
    setState(() {
      _pulse = PulseService.compute(
        budgets: budgets,
        goals: goals,
        pendingCheckIns: pending,
      );
    });
  }

  Future<void> _open() async {
    switch (_pulse.kind) {
      case PulseKind.checkInDue:
        final checkIn = _pulse.checkIn;
        if (checkIn == null) return;
        final saved = await showCheckInSheet(context, checkIn);
        if (saved && mounted) {
          final l = AppLocalizations.of(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.checkInSaved)));
        }
        break;
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

    final String title;
    final String body;
    switch (_pulse.kind) {
      case PulseKind.checkInDue:
        final checkIn = _pulse.checkIn!;
        title = l.pulseCheckInTitle;
        body = _pulse.pendingCheckIns > 1
            ? l.pulseCheckInManyBody(
                _pulse.pendingCheckIns, checkIn.subjectName)
            : (_pulse.overdue
                ? l.pulseCheckInOverdueBody(checkIn.subjectName)
                : l.pulseCheckInBody(checkIn.subjectName));
        break;
      case PulseKind.waterDue:
        final goal = _pulse.goal!;
        final amount = goal.waterAmount ?? 0;
        title = l.pulseWaterTitle;
        body = _pulse.overdue
            ? l.pulseWaterOverdueBody(goal.name)
            : l.pulseWaterBody(
                goal.name, '\$${amount.toStringAsFixed(0)}');
        break;
      case PulseKind.streakAtRisk:
        title = l.pulseStreakAtRiskTitle;
        body = l.pulseStreakAtRiskBody(_pulse.streakWeeks);
        break;
      case PulseKind.streakActive:
        title = l.pulseStreakTitle;
        body = l.pulseStreakBody(_pulse.streakWeeks);
        break;
      case PulseKind.plantFirstTree:
        title = l.pulsePlantTitle;
        body = l.pulsePlantBody;
        break;
      case PulseKind.none:
        return const SizedBox.shrink();
    }

    // The nudge is delivered as Acorn's quest: the same single most-useful
    // action, framed as an NPC handing the player something to do. The gold
    // ACCEPT runs exactly the tap target the strip always had.
    return AcornDialogue(
      speaker: '${l.acornName.toUpperCase()} · ${title.toUpperCase()}',
      text: body,
      actionLabel: l.pulseAccept.toUpperCase(),
      onAction: _open,
      onTap: _open,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    );
  }
}
