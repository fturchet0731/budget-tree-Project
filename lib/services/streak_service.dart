import 'dart:math' as math;
import '../models/goal_model.dart';

/// Summary of the user's weekly saving streak across all goals.
class StreakInfo {
  /// Consecutive weeks (ending at the current or previous week) that have at
  /// least one deposit. 0 means the streak has lapsed.
  final int currentWeeks;

  /// Longest weekly streak ever achieved.
  final int bestWeeks;

  /// Most recent deposit timestamp, or null if none.
  final DateTime? lastDeposit;

  /// Whether a deposit has already landed in the current week.
  final bool activeThisWeek;

  const StreakInfo({
    required this.currentWeeks,
    required this.bestWeeks,
    required this.lastDeposit,
    required this.activeThisWeek,
  });

  static const empty = StreakInfo(
    currentWeeks: 0,
    bestWeeks: 0,
    lastDeposit: null,
    activeThisWeek: false,
  );

  bool get hasStreak => currentWeeks > 0;

  /// True when the streak is alive but no deposit has landed this week yet —
  /// i.e. the user should save again before the week ends to keep it.
  bool get atRisk => currentWeeks > 0 && !activeThisWeek;
}

/// Computes weekly saving streaks from goal contribution ledgers. A "week"
/// is a Monday-anchored 7-day bucket, so deposits any day within the same
/// week count once toward the streak.
class StreakService {
  StreakService._();

  /// Monday-anchored week index. 1970-01-05 was a Monday, so flooring the
  /// day offset from there by 7 gives a stable, timezone-local week number.
  static int weekIndex(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    final days = midnight.difference(DateTime(1970, 1, 5)).inDays;
    return (days / 7).floor();
  }

  static StreakInfo weeklyStreak(List<Goal> goals, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final weeks = <int>{};
    DateTime? last;
    for (final g in goals) {
      for (final c in g.contributions) {
        if (!c.isDeposit) continue;
        weeks.add(weekIndex(c.at));
        if (last == null || c.at.isAfter(last)) last = c.at;
      }
    }
    if (weeks.isEmpty) return StreakInfo.empty;

    final thisWeek = weekIndex(n);
    final activeThisWeek = weeks.contains(thisWeek);

    // Current streak: walk backward from this week (or last week, granting a
    // one-week grace period so the streak isn't "broken" mid-week).
    int current = 0;
    int probe = activeThisWeek ? thisWeek : thisWeek - 1;
    while (weeks.contains(probe)) {
      current++;
      probe--;
    }

    // Best streak: longest consecutive run across all active weeks.
    final sorted = weeks.toList()..sort();
    int best = 0;
    int run = 0;
    int? prev;
    for (final w in sorted) {
      run = (prev != null && w == prev + 1) ? run + 1 : 1;
      best = math.max(best, run);
      prev = w;
    }

    return StreakInfo(
      currentWeeks: current,
      bestWeeks: math.max(best, current),
      lastDeposit: last,
      activeThisWeek: activeThisWeek,
    );
  }
}
