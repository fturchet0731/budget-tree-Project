// Unit tests for the retention engine: contribution ledger, weekly streaks,
// period comparisons, and allocation suggestions. These are pure functions,
// so no widget/pump harness is needed.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/models/budget_model.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/comparison_service.dart';
import 'package:budget_app_project/services/streak_service.dart';
import 'package:budget_app_project/services/suggestion_service.dart';

void main() {
  group('Contribution ledger', () {
    test('applyContribution records a dated entry and updates the balance', () {
      final g = Goal(name: 'Bike', targetAmount: 100);
      final applied = g.applyContribution(40);
      expect(applied, 40);
      expect(g.currentAmount, 40);
      expect(g.contributions, hasLength(1));
      expect(g.contributions.single.isDeposit, isTrue);
    });

    test('withdrawal clamps the balance at zero and returns what was applied',
        () {
      final g = Goal(name: 'Bike', targetAmount: 100, currentAmount: 30);
      final applied =
          g.applyContribution(-50, source: ContributionSource.adjustment);
      expect(applied, -30); // only 30 could be removed
      expect(g.currentAmount, 0);
    });

    test('ledger survives a JSON round-trip', () {
      final g = Goal(name: 'Bike', targetAmount: 100);
      g.applyContribution(25);
      final restored = Goal.fromJson(g.toJson());
      expect(restored.currentAmount, 25);
      expect(restored.contributions, hasLength(1));
      expect(restored.contributions.single.amount, 25);
    });

    test('legacy records without a contributions field still parse', () {
      final legacy = {
        'id': '1',
        'name': 'Old',
        'description': '',
        'targetAmount': 100.0,
        'currentAmount': 50.0,
        'iconKey': 'savings',
        'createdAt': DateTime(2024).millisecondsSinceEpoch,
      };
      final g = Goal.fromJson(legacy);
      expect(g.currentAmount, 50);
      expect(g.contributions, isEmpty);
    });
  });

  group('Weekly streaks', () {
    Goal goalWithDeposits(List<DateTime> dates) {
      final g = Goal(name: 'S', targetAmount: 1000);
      for (final d in dates) {
        g.applyContribution(10, at: d);
      }
      return g;
    }

    test('three consecutive weeks counts as a 3-week streak', () {
      final now = DateTime(2026, 6, 21); // a Sunday
      final g = goalWithDeposits([
        now,
        now.subtract(const Duration(days: 7)),
        now.subtract(const Duration(days: 14)),
      ]);
      final info = StreakService.weeklyStreak([g], now: now);
      expect(info.currentWeeks, 3);
      expect(info.activeThisWeek, isTrue);
    });

    test('a gap breaks the current streak', () {
      final now = DateTime(2026, 6, 21);
      final g = goalWithDeposits([
        now,
        now.subtract(const Duration(days: 21)), // skips last & this-1 week
      ]);
      final info = StreakService.weeklyStreak([g], now: now);
      expect(info.currentWeeks, 1);
    });

    test('last week but not this week is still an active (at-risk) streak', () {
      final now = DateTime(2026, 6, 21);
      final g = goalWithDeposits([now.subtract(const Duration(days: 7))]);
      final info = StreakService.weeklyStreak([g], now: now);
      expect(info.currentWeeks, 1);
      expect(info.activeThisWeek, isFalse);
      expect(info.atRisk, isTrue);
    });
  });

  group('Period comparisons', () {
    test('month-over-month percent change is computed from deposits', () {
      final now = DateTime(2026, 6, 21);
      final g = Goal(name: 'S', targetAmount: 0);
      g.applyContribution(100, at: DateTime(2026, 5, 10)); // last month
      g.applyContribution(115, at: DateTime(2026, 6, 10)); // this month
      final cmp = ComparisonService.monthOverMonth([g], now: now);
      expect(cmp.previous, 100);
      expect(cmp.current, 115);
      expect(cmp.percentChange, closeTo(15, 0.001));
      expect(cmp.improved, isTrue);
    });

    test('no prior month yields a null percent (no divide-by-zero)', () {
      final now = DateTime(2026, 6, 21);
      final g = Goal(name: 'S', targetAmount: 0);
      g.applyContribution(50, at: DateTime(2026, 6, 5));
      final cmp = ComparisonService.monthOverMonth([g], now: now);
      expect(cmp.percentChange, isNull);
      expect(cmp.hasActivity, isTrue);
    });
  });

  group('Allocation suggestions', () {
    final l = lookupAppLocalizations(const Locale('en'));
    BudgetModel budget(List<ExpenseCategory> exp, double income) => BudgetModel(
          budgetName: 'B',
          incomeSources: [IncomeSource(name: 'Job', amount: income)],
          expenses: exp,
          age: 30,
          location: 'X',
        );

    test('flags over-allocation', () {
      final b = budget([
        ExpenseCategory(name: 'Rent', allocated: 1200, emoji: 'home'),
      ], 1000);
      final s = SuggestionService.forBudget(b, l);
      expect(s.any((x) => x.tone == SuggestionTone.warn), isTrue);
    });

    test('flags a heavy branch over 35% of income', () {
      final b = budget([
        ExpenseCategory(name: 'Rent', allocated: 600, emoji: 'home'),
      ], 1000);
      final s = SuggestionService.forBudget(b, l);
      expect(s.any((x) => x.title.contains('heavy branch')), isTrue);
    });

    test('a balanced budget that feeds a goal gets positive reinforcement', () {
      final b = budget([
        ExpenseCategory(
            name: 'Savings',
            allocated: 200,
            emoji: 'savings',
            linkedGoalIds: ['g1']),
      ], 1000);
      final s = SuggestionService.forBudget(b, l);
      expect(s.any((x) => x.tone == SuggestionTone.good), isTrue);
    });
  });
}
