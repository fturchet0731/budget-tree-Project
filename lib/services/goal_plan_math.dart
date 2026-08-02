import 'dart:math' as math;

import '../data/water_cadence.dart';
import '../models/goal_model.dart';
import 'budget_repository.dart';

/// Pure savings math used both as the offline fallback for the AI goal planner
/// and to compute the "free monthly income" figure fed into the AI call. Kept
/// side-effect free (except the repository read in [freeMonthlyIncome]) so the
/// core numbers are unit-testable without a network.
class GoalPlanMath {
  GoalPlanMath._();

  /// Whole calendar months from [from] to [to], at least 1 (so a same-month
  /// target still yields a finite monthly figure rather than dividing by zero).
  static int monthsBetween(DateTime from, DateTime to) {
    final months = (to.year - from.year) * 12 + (to.month - from.month);
    return math.max(1, months);
  }

  /// Monthly contribution needed to take [goal] from its current balance to its
  /// target by [targetDate]. Returns 0 for uncapped goals or when already met.
  static double monthlyToReach(
    Goal goal,
    DateTime targetDate, {
    DateTime? now,
  }) {
    if (goal.isUncapped) return 0;
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return 0;
    final months = monthsBetween(now ?? DateTime.now(), targetDate);
    return remaining / months;
  }

  /// Per-watering contribution needed to reach [goal] by [targetDate] at the
  /// given [cadence]. Derived from the monthly figure so the offline fallback
  /// and the custom plan share one source of truth.
  static double perWateringToReach(
    Goal goal,
    DateTime targetDate,
    WaterCadence cadence, {
    DateTime? now,
  }) {
    final monthly = monthlyToReach(goal, targetDate, now: now);
    if (monthly <= 0) return 0;
    return monthly / cadence.perMonth;
  }

  /// Whole months to reach [goal] by contributing [perWatering] every
  /// [cadence]. At least 1 when there is anything left to save.
  static int monthsForPerWatering(
    Goal goal,
    double perWatering,
    WaterCadence cadence,
  ) {
    if (goal.isUncapped || perWatering <= 0) return 0;
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return 0;
    final perMonth = perWatering * cadence.perMonth;
    if (perMonth <= 0) return 0;
    return math.max(1, (remaining / perMonth).ceil());
  }

  /// The completion date implied by saving [monthly] toward [goal] from now.
  /// Returns null when [monthly] is non-positive or the goal is uncapped.
  static DateTime? dateForMonthly(Goal goal, double monthly, {DateTime? now}) {
    if (goal.isUncapped || monthly <= 0) return null;
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return now ?? DateTime.now();
    final months = (remaining / monthly).ceil();
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month + months, n.day);
  }

  // ── Day-accurate planning ─────────────────────────────────────────────
  //
  // The calendar-month helpers above are fine for rough monthly figures, but a
  // user who picks a date expects to land ON it. These work in whole waterings
  // between today and the target, so "every 2 weeks until March 14th" is an
  // exact count rather than a month approximation. **All amounts and dates the
  // user is shown come from here, never from the model**, which is what stopped
  // a chosen date from being honoured.

  /// How many waterings at [cadence] fit between [now] and [targetDate].
  ///
  /// At least 1 whenever the date is in the future, so there's always a
  /// finite amount to divide by. Returns 0 for a date that has already passed.
  static int wateringsUntil(
    DateTime targetDate,
    WaterCadence cadence, {
    DateTime? now,
  }) {
    final from = now ?? DateTime.now();
    final days = targetDate.difference(from).inDays;
    if (days <= 0) return 0;
    return math.max(1, days ~/ cadence.days);
  }

  /// The per-watering amount that lands [goal] exactly on [targetDate] at
  /// [cadence]. 0 when the goal is uncapped, already met, or the date has gone.
  static double perWateringForDate(
    Goal goal,
    DateTime targetDate,
    WaterCadence cadence, {
    DateTime? now,
  }) {
    if (goal.isUncapped) return 0;
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return 0;
    final n = wateringsUntil(targetDate, cadence, now: now);
    if (n <= 0) return 0;
    return remaining / n;
  }

  /// The date [goal] is reached by putting in [perWatering] every [cadence].
  /// Null when the goal is uncapped or the amount is non-positive.
  static DateTime? dateForPerWatering(
    Goal goal,
    double perWatering,
    WaterCadence cadence, {
    DateTime? now,
  }) {
    if (goal.isUncapped || perWatering <= 0) return null;
    final from = now ?? DateTime.now();
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return from;
    final waterings = (remaining / perWatering).ceil();
    return from.add(Duration(days: waterings * cadence.days));
  }

  /// The three paces a goal can be approached at when there's no deadline.
  /// They differ in commitment (and therefore in finish date), which is the
  /// real choice being made here — unlike the fixed-date plans, where every
  /// option costs the same and only the rhythm changes.
  ///
  /// Ordered gentlest first so the cards read as a progression.
  static List<double> progressionAmounts({
    required double min,
    required double max,
  }) {
    if (min <= 0 && max <= 0) return const [];
    // Tolerate them being entered the wrong way round.
    var lo = math.min(min, max);
    var hi = math.max(min, max);
    if (lo <= 0) lo = hi;
    if (hi <= 0) hi = lo;

    final out = <double>[];
    for (final v in [lo, (lo + hi) / 2, hi]) {
      final rounded = _friendly(v);
      if (rounded > 0 && !out.contains(rounded)) out.add(rounded);
    }
    return out;
  }

  /// Sensible per-watering amounts to offer when the user has no date in mind:
  /// a comfortable, a middling and a brisk pace, derived from whatever headroom
  /// they have ([freeMonthly]) and floored so the goal still finishes in a
  /// sane time. Rounded to friendly numbers. Never returns duplicates.
  static List<double> suggestedPerWatering(
    Goal goal,
    WaterCadence cadence,
    double freeMonthly,
  ) {
    if (goal.isUncapped) return const [];
    final remaining = goal.targetAmount - goal.currentAmount;
    if (remaining <= 0) return const [];

    // Anchor on the user's spare income when we know it; otherwise pace the
    // goal over a year.
    final anchorMonthly = freeMonthly > 0 ? freeMonthly : remaining / 12;
    final perW = anchorMonthly / cadence.perMonth;

    final out = <double>[];
    for (final factor in [0.25, 0.5, 0.8]) {
      final raw = perW * factor;
      if (raw <= 0) continue;
      final rounded = _friendly(raw);
      if (rounded > 0 && !out.contains(rounded)) out.add(rounded);
    }
    return out;
  }

  /// Round to a number a person would actually pick: nearest 5 under 100,
  /// nearest 10 under 500, nearest 25 above that.
  static double _friendly(double v) {
    if (v < 100) return math.max(5, (v / 5).round() * 5).toDouble();
    if (v < 500) return ((v / 10).round() * 10).toDouble();
    return ((v / 25).round() * 25).toDouble();
  }

  /// Estimate of income not already committed to expenses across all saved
  /// budgets: sum of each budget's `remaining` (income minus allocations),
  /// floored at 0. This is the headroom available to fund a new goal.
  static Future<double> freeMonthlyIncome() async {
    final budgets = await BudgetRepository.loadAll();
    double free = 0;
    for (final b in budgets) {
      final r = b.remaining;
      if (r > 0) free += r;
    }
    return free;
  }
}
