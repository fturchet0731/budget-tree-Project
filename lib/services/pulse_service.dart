import '../models/budget_model.dart';
import '../data/calendar.dart';
import '../models/goal_model.dart';
import 'streak_service.dart';

/// What the dashboard's pulse strip should say right now, in priority order:
/// a watering that's due beats a streak nudge, which beats the quiet streak
/// badge, which beats the first-tree call for brand-new users. [PulseKind.none]
/// means the strip stays hidden.
enum PulseKind { waterDue, streakAtRisk, streakActive, plantFirstTree, none }

class PulseInfo {
  final PulseKind kind;

  /// The goal whose watering is due (only for [PulseKind.waterDue]).
  final Goal? goal;

  /// True when the watering slot is in the past rather than today.
  final bool overdue;

  /// Current weekly streak length (streak kinds only).
  final int streakWeeks;

  const PulseInfo._(
    this.kind, {
    this.goal,
    this.overdue = false,
    this.streakWeeks = 0,
  });

  static const none = PulseInfo._(PulseKind.none);
}

/// Picks the single most useful nudge for the dashboard from the user's data.
/// Pure and static, like the other retention services: the widget feeds it the
/// repositories' lists and renders whatever comes back.
class PulseService {
  PulseService._();

  static PulseInfo compute({
    required List<BudgetModel> budgets,
    required List<Goal> goals,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final today = dateOnly(n);
    final tomorrow = addDays(today, 1);

    // 1) A watering that's due today or missed: the week's habit, actionable
    // right now. Earliest due goal wins so backlogs drain oldest-first.
    Goal? due;
    for (final g in goals) {
      if (!g.hasWateringSchedule || g.isCompleted) continue;
      final when = g.nextWaterDate!;
      if (!when.isBefore(tomorrow)) continue;
      if (due == null || when.isBefore(due.nextWaterDate!)) due = g;
    }
    if (due != null) {
      return PulseInfo._(
        PulseKind.waterDue,
        goal: due,
        overdue: due.nextWaterDate!.isBefore(today),
      );
    }

    // 2) The weekly saving streak: warn when it would lapse this week, and
    // otherwise show it quietly so the habit stays visible.
    final streak = StreakService.weeklyStreak(goals, now: n);
    if (streak.atRisk) {
      return PulseInfo._(
        PulseKind.streakAtRisk,
        streakWeeks: streak.currentWeeks,
      );
    }
    if (streak.hasStreak && streak.activeThisWeek) {
      return PulseInfo._(
        PulseKind.streakActive,
        streakWeeks: streak.currentWeeks,
      );
    }

    // 3) Nothing growing yet: point brand-new users at their first tree.
    if (budgets.isEmpty && goals.isEmpty) {
      return const PulseInfo._(PulseKind.plantFirstTree);
    }

    return PulseInfo.none;
  }
}
