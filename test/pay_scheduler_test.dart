// Covers the pay-cycle engine: multi-period catch-up, how `lastProcessedAt`
// advances, target caps, and the boot/resume sweep over every saved budget.
//
// Supabase is unconfigured in tests, so the repositories run purely off the
// shared_preferences cache and PayScheduler's persistence is exercised for real.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/data/rhythm.dart';
import 'package:budget_app_project/models/budget_model.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/budget_repository.dart';
import 'package:budget_app_project/services/goal_repository.dart';
import 'package:budget_app_project/services/pay_scheduler.dart';

/// A saved weekly budget whose single branch funds [goalIds], last processed
/// [weeksAgo] weeks ago.
BudgetModel weeklyBudget({
  required List<String> goalIds,
  required int weeksAgo,
  double allocated = 50,
  String name = 'Tree',
}) {
  final start = DateTime.now().subtract(Duration(days: 7 * weeksAgo));
  return BudgetModel(
    budgetName: name,
    incomeSources: [IncomeSource(name: 'Wage', amount: 500)],
    expenses: [
      ExpenseCategory(
        name: 'Savings',
        allocated: allocated,
        emoji: 'savings',
        linkedGoalIds: goalIds,
      ),
    ],
    savedAt: DateTime.now(),
    payFrequency: Rhythm.weekly,
    firstPayDate: start,
    lastProcessedAt: start,
  );
}

Future<Goal> reloadGoal(String id) async {
  final goals = await GoalRepository.loadAll();
  return goals.firstWhere((g) => g.id == id);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PayScheduler.runUpdate', () {
    test('credits one share per elapsed period, not just one', () async {
      final goal = Goal(id: 'g1', name: 'Bike', targetAmount: 10000);
      await GoalRepository.saveNew(goal);

      final budget = weeklyBudget(goalIds: ['g1'], weeksAgo: 3);
      await BudgetRepository.saveNew(budget);

      final result = await PayScheduler.runUpdate(budget);

      expect(result.periodsProcessed, 3);
      expect(result.totalDeposited, closeTo(150, 0.01));
      expect((await reloadGoal('g1')).currentAmount, closeTo(150, 0.01));
    });

    test(
      'advances lastProcessedAt by the periods processed, not to now',
      () async {
        await GoalRepository.saveNew(
          Goal(id: 'g1', name: 'Bike', targetAmount: 10000),
        );

        // 3.5 weeks back: 3 whole periods elapse and the half period must be
        // carried forward rather than swallowed by stamping "now".
        final start = DateTime.now().subtract(
          const Duration(days: 7 * 3, hours: 84),
        );
        final budget = BudgetModel(
          budgetName: 'Tree',
          incomeSources: [IncomeSource(name: 'Wage', amount: 500)],
          expenses: [
            ExpenseCategory(
              name: 'Savings',
              allocated: 50,
              emoji: 'savings',
              linkedGoalIds: ['g1'],
            ),
          ],
          savedAt: DateTime.now(),
          payFrequency: Rhythm.weekly,
          firstPayDate: start,
          lastProcessedAt: start,
        );
        await BudgetRepository.saveNew(budget);

        final result = await PayScheduler.runUpdate(budget);

        expect(result.periodsProcessed, 3);
        expect(budget.lastProcessedAt, start.add(const Duration(days: 21)));
        // The leftover half period is still pending, so it is in the past.
        expect(budget.lastProcessedAt!.isBefore(DateTime.now()), isTrue);
      },
    );

    test(
      'running twice in the same period is a no-op the second time',
      () async {
        await GoalRepository.saveNew(
          Goal(id: 'g1', name: 'Bike', targetAmount: 10000),
        );
        final budget = weeklyBudget(goalIds: ['g1'], weeksAgo: 2);
        await BudgetRepository.saveNew(budget);

        final first = await PayScheduler.runUpdate(budget);
        final second = await PayScheduler.runUpdate(budget);

        expect(first.periodsProcessed, 2);
        expect(second.periodsProcessed, 0);
        expect(second.hadActivity, isFalse);
        expect((await reloadGoal('g1')).currentAmount, closeTo(100, 0.01));
      },
    );

    test('respects the target cap and stamps completion once', () async {
      await GoalRepository.saveNew(
        Goal(id: 'g1', name: 'Small', targetAmount: 120),
      );
      final budget = weeklyBudget(goalIds: ['g1'], weeksAgo: 5);
      await BudgetRepository.saveNew(budget);

      final result = await PayScheduler.runUpdate(budget);

      // 5 x 50 = 250 available, but the goal caps at 120.
      expect(result.totalDeposited, closeTo(120, 0.01));
      final stored = await reloadGoal('g1');
      expect(stored.currentAmount, closeTo(120, 0.01));
      expect(stored.isCompleted, isTrue);
      expect(stored.completedAt, isNotNull);
    });

    test('splits a branch allocation evenly across its linked goals', () async {
      await GoalRepository.saveNew(
        Goal(id: 'g1', name: 'A', targetAmount: 10000),
      );
      await GoalRepository.saveNew(
        Goal(id: 'g2', name: 'B', targetAmount: 10000),
      );

      final budget = weeklyBudget(goalIds: ['g1', 'g2'], weeksAgo: 2);
      await BudgetRepository.saveNew(budget);

      await PayScheduler.runUpdate(budget);

      expect((await reloadGoal('g1')).currentAmount, closeTo(50, 0.01));
      expect((await reloadGoal('g2')).currentAmount, closeTo(50, 0.01));
    });

    test('records auto contributions in the ledger', () async {
      await GoalRepository.saveNew(
        Goal(id: 'g1', name: 'Bike', targetAmount: 10000),
      );
      final budget = weeklyBudget(goalIds: ['g1'], weeksAgo: 1);
      await BudgetRepository.saveNew(budget);

      await PayScheduler.runUpdate(budget);

      final stored = await reloadGoal('g1');
      expect(stored.contributions, hasLength(1));
      expect(stored.contributions.single.source, ContributionSource.auto);
      expect(stored.contributions.single.amount, closeTo(50, 0.01));
    });
  });

  group('PayScheduler.runAllDue', () {
    test('processes budgets the user never opened', () async {
      await GoalRepository.saveNew(
        Goal(id: 'g1', name: 'A', targetAmount: 10000),
      );
      await GoalRepository.saveNew(
        Goal(id: 'g2', name: 'B', targetAmount: 10000),
      );

      await BudgetRepository.saveNew(
        weeklyBudget(goalIds: ['g1'], weeksAgo: 2, name: 'One'),
      );
      await BudgetRepository.saveNew(
        weeklyBudget(goalIds: ['g2'], weeksAgo: 4, name: 'Two'),
      );

      final credited = await PayScheduler.runAllDue();

      expect(credited, 2);
      expect((await reloadGoal('g1')).currentAmount, closeTo(100, 0.01));
      expect((await reloadGoal('g2')).currentAmount, closeTo(200, 0.01));
    });

    test('is idempotent — a second sweep credits nothing', () async {
      await GoalRepository.saveNew(
        Goal(id: 'g1', name: 'A', targetAmount: 10000),
      );
      await BudgetRepository.saveNew(
        weeklyBudget(goalIds: ['g1'], weeksAgo: 3),
      );

      expect(await PayScheduler.runAllDue(), 1);
      expect(await PayScheduler.runAllDue(), 0);

      final stored = await reloadGoal('g1');
      expect(stored.currentAmount, closeTo(150, 0.01));
      expect(stored.contributions, hasLength(1));
    });

    test('skips unsaved drafts and budgets with no pay schedule', () async {
      await GoalRepository.saveNew(
        Goal(id: 'g1', name: 'A', targetAmount: 10000),
      );

      // Saved, but never given a cycle or a first pay date.
      await BudgetRepository.saveNew(
        BudgetModel(
          budgetName: 'No schedule',
          incomeSources: [IncomeSource(name: 'Wage', amount: 500)],
          expenses: [
            ExpenseCategory(
              name: 'Savings',
              allocated: 50,
              emoji: 'savings',
              linkedGoalIds: ['g1'],
            ),
          ],
          savedAt: DateTime.now(),
        ),
      );

      // Scheduled, but still a draft (never planted).
      final draft = weeklyBudget(goalIds: ['g1'], weeksAgo: 3);
      draft.savedAt = null;
      await BudgetRepository.saveNew(draft);

      expect(await PayScheduler.runAllDue(), 0);
      expect((await reloadGoal('g1')).currentAmount, 0);
    });

    test('a budget linking a deleted goal does not stop the others', () async {
      await GoalRepository.saveNew(
        Goal(id: 'g1', name: 'A', targetAmount: 10000),
      );

      // Links a goal that no longer exists. It still advances its own clock,
      // but moves no money, so it is not counted as credited.
      await BudgetRepository.saveNew(
        weeklyBudget(goalIds: ['missing'], weeksAgo: 2, name: 'Orphan'),
      );
      await BudgetRepository.saveNew(
        weeklyBudget(goalIds: ['g1'], weeksAgo: 2, name: 'Good'),
      );

      final credited = await PayScheduler.runAllDue();

      expect(credited, 1);
      expect((await reloadGoal('g1')).currentAmount, closeTo(100, 0.01));
    });

    test('with no budgets at all it is a quiet no-op', () async {
      expect(await PayScheduler.runAllDue(), 0);
    });
  });
}
