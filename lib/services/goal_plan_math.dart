import 'dart:math' as math;

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
