import '../data/calendar.dart';
import '../models/check_in.dart';
import '../models/goal_model.dart';
import 'check_in_service.dart';
import 'goal_repository.dart';
import 'streak_service.dart';
import 'tree_health_service.dart';

/// One resolved check-in, reduced to what a chart needs.
class ConsistencyPoint {
  final DateTime at;
  final CheckInVerdict? verdict;
  final bool missed;
  const ConsistencyPoint({
    required this.at,
    required this.verdict,
    required this.missed,
  });
}

/// Money saved in one calendar week.
class WeekPoint {
  final DateTime weekStart;
  final double amount;
  const WeekPoint({required this.weekStart, required this.amount});
}

/// A branch's plan against what the user said they really spent, summed over
/// the period.
class OverspendRow {
  final String name;
  final double planned;
  final double actual;

  /// How many check-ins contributed a number for this branch.
  final int samples;

  const OverspendRow({
    required this.name,
    required this.planned,
    required this.actual,
    required this.samples,
  });

  double get difference => actual - planned;
  bool get isOver => difference > 0;
}

/// Every number behind Acorn's Hub, computed locally.
///
/// The AI writes prose and nothing else — same split as [GoalPlanMath] against
/// the `goal_plans` action, for the same reason: a model's arithmetic drifts,
/// and a reflection that misreports the user's own figures back to them is
/// worse than no reflection. Everything here is pure, so it is also what gets
/// sent to the coach as already-summarised input.
class ReflectionStats {
  /// Resolved check-ins in the window, oldest first.
  final List<ConsistencyPoint> consistency;

  /// The health score after each of those check-ins, so the trend line shows
  /// the path rather than just the destination.
  final List<double> healthTrail;

  /// Weekly deposit totals, oldest first.
  final List<WeekPoint> savings;

  /// Branches with reported actuals, biggest overspend first. **Empty until
  /// the user has filled in optional amounts** — there is no other source of
  /// plan-versus-actual data, so callers must handle the empty case rather
  /// than drawing an axis with nothing on it.
  final List<OverspendRow> overspend;

  final TreeHealth health;
  final StreakInfo streak;
  final int answered;
  final int missed;

  const ReflectionStats({
    required this.consistency,
    required this.healthTrail,
    required this.savings,
    required this.overspend,
    required this.health,
    required this.streak,
    required this.answered,
    required this.missed,
  });

  static const empty = ReflectionStats(
    consistency: [],
    healthTrail: [],
    savings: [],
    overspend: [],
    health: TreeHealth.fresh,
    streak: StreakInfo.empty,
    answered: 0,
    missed: 0,
  );

  int get total => answered + missed;

  /// 0..1. Zero when nothing has come due yet, which reads as "no data" rather
  /// than as a perfect record.
  double get answerRate => total == 0 ? 0 : answered / total;

  bool get hasCheckIns => total > 0;
  bool get hasActuals => overspend.isNotEmpty;
  bool get hasSavings => savings.any((w) => w.amount > 0);

  /// Build from the user's own data. [weeks] bounds the savings series.
  static Future<ReflectionStats> load({DateTime? now, int weeks = 8}) async {
    final goals = await GoalRepository.loadAll();
    final history = await CheckInService.history();
    return build(goals: goals, history: history, now: now, weeks: weeks);
  }

  /// Pure core, so tests and the hub can both drive it directly.
  static ReflectionStats build({
    required List<Goal> goals,
    required List<CheckIn> history,
    DateTime? now,
    int weeks = 8,
  }) {
    final at = now ?? DateTime.now();
    final resolved = history.where((c) => c.isResolved).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

    final consistency = [
      for (final c in resolved)
        ConsistencyPoint(at: c.dueAt, verdict: c.verdict, missed: c.missed),
    ];

    // Replay the scale one check-in at a time so the trend line matches the
    // score exactly rather than approximating it.
    final trail = <double>[];
    for (var i = 1; i <= resolved.length; i++) {
      trail.add(TreeHealthService.evaluate(resolved.sublist(0, i)).score);
    }

    return ReflectionStats(
      consistency: consistency,
      healthTrail: trail,
      savings: _weeklySavings(goals, at, weeks),
      overspend: _overspend(resolved),
      health: TreeHealthService.evaluate(resolved),
      streak: StreakService.weeklyStreak(goals, now: at),
      answered: resolved.where((c) => c.isConfirmed).length,
      missed: resolved.where((c) => c.missed).length,
    );
  }

  static List<WeekPoint> _weeklySavings(
    List<Goal> goals,
    DateTime now,
    int weeks,
  ) {
    final thisWeek = startOfWeek(now);
    final totals = <int, double>{};
    for (final g in goals) {
      for (final c in g.contributions) {
        if (!c.isDeposit) continue;
        final week = weekIndexOf(c.at);
        totals[week] = (totals[week] ?? 0) + c.amount;
      }
    }
    return [
      for (var i = weeks - 1; i >= 0; i--)
        () {
          final start = addDays(thisWeek, -7 * i);
          return WeekPoint(
            weekStart: start,
            amount: totals[weekIndexOf(start)] ?? 0,
          );
        }(),
    ];
  }

  static List<OverspendRow> _overspend(List<CheckIn> resolved) {
    final planned = <String, double>{};
    final actual = <String, double>{};
    final samples = <String, int>{};
    for (final c in resolved) {
      for (final a in c.actuals) {
        planned[a.name] = (planned[a.name] ?? 0) + a.planned;
        actual[a.name] = (actual[a.name] ?? 0) + a.actual;
        samples[a.name] = (samples[a.name] ?? 0) + 1;
      }
    }
    final rows = [
      for (final name in planned.keys)
        OverspendRow(
          name: name,
          planned: planned[name]!,
          actual: actual[name]!,
          samples: samples[name]!,
        ),
    ]..sort((a, b) => b.difference.compareTo(a.difference));
    return rows;
  }
}
