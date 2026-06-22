import 'dart:math' as math;
import '../data/pay_frequency.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import 'budget_repository.dart';
import 'goal_repository.dart';

class PayCycleResult {
  final int periodsProcessed;
  final double totalDeposited;
  final List<Goal> updatedGoals;
  final DateTime nextPayDate;
  const PayCycleResult({
    required this.periodsProcessed,
    required this.totalDeposited,
    required this.updatedGoals,
    required this.nextPayDate,
  });

  bool get hadActivity => periodsProcessed > 0;
}

/// Manages scheduled pay processing: works out how many pay periods have
/// elapsed since the last run, then credits every goal linked to a branch
/// with the per-period share of that branch's monthly allocation.
class PayScheduler {
  PayScheduler._();

  /// Returns the next pay date relative to [now], using [budget]'s first
  /// pay date and frequency. Returns null when the schedule isn't set.
  static DateTime? nextPayDate(BudgetModel budget, DateTime now) {
    final freq = budget.payFrequency;
    final first = budget.firstPayDate;
    if (freq == null || first == null) return null;
    if (now.isBefore(first)) return first;
    final periodMs = freq.periodLength.inMilliseconds;
    final elapsed = now.millisecondsSinceEpoch - first.millisecondsSinceEpoch;
    final periodsSince = (elapsed / periodMs).floor() + 1;
    return first.add(Duration(milliseconds: periodMs * periodsSince));
  }

  /// Counts how many full pay periods elapsed between [from] (inclusive)
  /// and [now] (exclusive of the unfinished current period).
  static int periodsBetween(
      BudgetModel budget, DateTime from, DateTime now) {
    final freq = budget.payFrequency;
    if (freq == null) return 0;
    final periodMs = freq.periodLength.inMilliseconds;
    final diff = now.millisecondsSinceEpoch - from.millisecondsSinceEpoch;
    if (diff <= 0) return 0;
    return (diff / periodMs).floor();
  }

  /// Run the pay-cycle update: for each elapsed period since the budget
  /// was last processed, credit linked goals with their share of the
  /// per-period allocation. Returns a summary of what changed.
  ///
  /// Caps for goals with a [Goal.targetAmount] are respected — any
  /// overflow is dropped (the goal stays at its target).
  static Future<PayCycleResult> runUpdate(BudgetModel budget) async {
    final freq = budget.payFrequency;
    final first = budget.firstPayDate;
    if (freq == null || first == null) {
      return PayCycleResult(
        periodsProcessed: 0,
        totalDeposited: 0,
        updatedGoals: const [],
        nextPayDate: DateTime.now(),
      );
    }

    final now = DateTime.now();
    final since = budget.lastProcessedAt ?? first;
    final periods = periodsBetween(budget, since, now);
    if (periods <= 0) {
      return PayCycleResult(
        periodsProcessed: 0,
        totalDeposited: 0,
        updatedGoals: const [],
        nextPayDate: nextPayDate(budget, now) ?? now,
      );
    }

    final allGoals = await GoalRepository.loadAll();
    final goalsById = {for (final g in allGoals) g.id: g};

    final perMonth = freq.periodsPerMonth;
    final touchedGoals = <String>{};
    double totalDeposited = 0;

    for (final cat in budget.expenses) {
      if (cat.linkedGoalIds.isEmpty) continue;
      final perPeriodPerGoal =
          (cat.allocated / perMonth) / cat.linkedGoalIds.length;
      final perPeriodPerGoalForCycle = perPeriodPerGoal * periods;

      for (final goalId in cat.linkedGoalIds) {
        final goal = goalsById[goalId];
        if (goal == null) continue;
        double toAdd = perPeriodPerGoalForCycle;
        // Respect the target cap for finite goals.
        if (!goal.isUncapped) {
          final headroom = (goal.targetAmount - goal.currentAmount)
              .clamp(0.0, double.infinity);
          toAdd = math.min(toAdd, headroom);
        }
        if (toAdd <= 0) continue;
        final applied = goal.applyContribution(toAdd,
            source: ContributionSource.auto, at: now);
        totalDeposited += applied;
        if (!goal.isUncapped &&
            goal.isComplete &&
            goal.completedAt == null) {
          goal.completedAt = now;
        }
        touchedGoals.add(goalId);
      }
    }

    // Persist updated goals
    for (final id in touchedGoals) {
      final g = goalsById[id];
      if (g != null) await GoalRepository.update(g);
    }

    // Advance the last processed timestamp by the number of full periods
    final advancedMs = freq.periodLength.inMilliseconds * periods;
    budget.lastProcessedAt = since
        .add(Duration(milliseconds: advancedMs));
    if (budget.savedAt != null) {
      await BudgetRepository.update(budget);
    }

    return PayCycleResult(
      periodsProcessed: periods,
      totalDeposited: totalDeposited,
      updatedGoals: touchedGoals.map((id) => goalsById[id]!).toList(),
      nextPayDate: nextPayDate(budget, now) ?? now,
    );
  }

  /// Auto-link branches to existing goals by exact-or-prefix name match.
  /// Returns the number of new links created.
  static Future<int> autoLinkByName(BudgetModel budget) async {
    final goals = await GoalRepository.loadAll();
    if (goals.isEmpty) return 0;
    int created = 0;
    for (final cat in budget.expenses) {
      for (final g in goals) {
        final a = cat.name.toLowerCase().trim();
        final b = g.name.toLowerCase().trim();
        final matches = a == b ||
            a.contains(b) ||
            b.contains(a);
        if (matches && !cat.linkedGoalIds.contains(g.id)) {
          cat.linkedGoalIds.add(g.id);
          created++;
        }
      }
    }
    return created;
  }
}
