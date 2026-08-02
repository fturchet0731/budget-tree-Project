import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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
/// with that branch's per-cycle allocation for each elapsed period.
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
  ///
  /// Set [fromCache] to read goals without triggering a background pull. The
  /// sweep in [runAllDue] uses it so its own writes can't be overwritten by a
  /// refresh it started itself.
  static Future<PayCycleResult> runUpdate(
    BudgetModel budget, {
    bool fromCache = false,
  }) async {
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

    final allGoals = fromCache
        ? await GoalRepository.loadCached()
        : await GoalRepository.loadAll();
    final goalsById = {for (final g in allGoals) g.id: g};

    final touchedGoals = <String>{};
    double totalDeposited = 0;

    for (final cat in budget.expenses) {
      if (cat.linkedGoalIds.isEmpty) continue;
      // Allocations are per budget cycle (one pay period), normalised from
      // the expense's own charge rhythm, so each elapsed period credits the
      // full per-cycle share.
      final perPeriodPerGoal =
          cat.allocatedPerCycle(freq) / cat.linkedGoalIds.length;
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
        // Go through the model so the stamping rule lives in exactly one place.
        goal.stampCompletionIfReached();
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

  /// Guards against two sweeps overlapping (boot and resume can land close
  /// together), which would read the same `lastProcessedAt` twice.
  static bool _sweeping = false;

  /// Run [runUpdate] for **every** saved budget that has a pay schedule.
  ///
  /// Without this, a budget is only ever processed when the user opens its
  /// tree, so trees they don't visit never fund their linked goals — and the
  /// streaks, comparisons and achievements that read the contribution ledger
  /// all understate as a result.
  ///
  /// Safe to call repeatedly: [runUpdate] advances `lastProcessedAt` by exactly
  /// the periods it credited, so a second sweep inside the same period finds
  /// nothing to do. One budget failing never stops the rest.
  ///
  /// Returns how many budgets actually moved money into a goal. A budget whose
  /// periods elapsed but whose branches feed nothing (no links, or the linked
  /// goal was deleted) still advances its clock, but doesn't count here.
  static Future<int> runAllDue() async {
    if (_sweeping) return 0;
    _sweeping = true;
    try {
      final budgets = await BudgetRepository.loadCached();
      var credited = 0;
      for (final budget in budgets) {
        // Unsaved drafts and budgets with no schedule have nothing to process.
        if (budget.savedAt == null ||
            budget.payFrequency == null ||
            budget.firstPayDate == null) {
          continue;
        }
        try {
          final result = await runUpdate(budget, fromCache: true);
          if (result.totalDeposited > 0) credited++;
        } catch (e) {
          debugPrint('PayScheduler.runAllDue(${budget.id}) failed: $e');
        }
      }
      return credited;
    } finally {
      _sweeping = false;
    }
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
