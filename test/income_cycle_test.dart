import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/data/pay_frequency.dart';
import 'package:budget_app_project/models/budget_model.dart';

void main() {
  group('IncomeSource.amountPerCycle', () {
    test('same frequency passes through unchanged', () {
      final s = IncomeSource(
          name: 'Salary', amount: 2000, frequency: PayFrequency.monthly);
      expect(s.amountPerCycle(PayFrequency.monthly), 2000);
    });

    test('bi-weekly salary in a monthly budget is ~26/12 of the amount', () {
      final s = IncomeSource(
          name: 'Salary', amount: 2000, frequency: PayFrequency.biWeekly);
      expect(s.amountPerCycle(PayFrequency.monthly),
          closeTo(2000 * 26 / 12, 0.01));
    });

    test('monthly income in a weekly budget shrinks by 12/52', () {
      final s = IncomeSource(
          name: 'Rent income', amount: 1300, frequency: PayFrequency.monthly);
      expect(s.amountPerCycle(PayFrequency.weekly),
          closeTo(1300 * 12 / 52, 0.01));
    });

    test('legacy income without a frequency passes through', () {
      final s = IncomeSource(name: 'Old', amount: 500);
      expect(s.amountPerCycle(PayFrequency.weekly), 500);
      expect(s.amountPerCycle(null), 500);
    });
  });

  group('BudgetModel.totalIncome', () {
    test('normalises each source into the budget cycle', () {
      final b = BudgetModel(
        budgetName: 'B',
        incomeSources: [
          IncomeSource(
              name: 'Salary', amount: 1000, frequency: PayFrequency.biWeekly),
          IncomeSource(
              name: 'Side', amount: 200, frequency: PayFrequency.monthly),
        ],
        expenses: [],
        payFrequency: PayFrequency.monthly,
      );
      expect(b.totalIncome, closeTo(1000 * 26 / 12 + 200, 0.01));
    });

    test('without a budget cycle raw amounts sum (legacy behaviour)', () {
      final b = BudgetModel(
        budgetName: 'B',
        incomeSources: [
          IncomeSource(
              name: 'Salary', amount: 1000, frequency: PayFrequency.weekly),
        ],
        expenses: [],
      );
      expect(b.totalIncome, 1000);
    });
  });

  group('ExpenseCategory.allocatedPerCycle', () {
    test('monthly rent in a weekly budget asks for ~12/52 each cycle', () {
      final e = ExpenseCategory(
          name: 'Rent',
          allocated: 1200,
          emoji: 'home',
          frequency: PayFrequency.monthly);
      expect(e.allocatedPerCycle(PayFrequency.weekly),
          closeTo(1200 * 12 / 52, 0.01));
    });

    test('legacy expense without a frequency passes through', () {
      final e = ExpenseCategory(name: 'Old', allocated: 300, emoji: 'food');
      expect(e.allocatedPerCycle(PayFrequency.weekly), 300);
      expect(e.allocatedPerCycle(null), 300);
    });

    test('setAllocatedPerCycle inverts the conversion', () {
      final e = ExpenseCategory(
          name: 'Rent',
          allocated: 0,
          emoji: 'home',
          frequency: PayFrequency.monthly);
      e.setAllocatedPerCycle(300, PayFrequency.weekly);
      expect(e.allocatedPerCycle(PayFrequency.weekly), closeTo(300, 0.01));
      expect(e.allocated, closeTo(300 * 52 / 12, 0.01));
    });

    test('totalAllocated and remaining normalise into the budget cycle', () {
      final b = BudgetModel(
        budgetName: 'B',
        incomeSources: [
          IncomeSource(
              name: 'Wage', amount: 500, frequency: PayFrequency.weekly),
        ],
        expenses: [
          ExpenseCategory(
              name: 'Rent',
              allocated: 1300,
              emoji: 'home',
              frequency: PayFrequency.monthly),
          ExpenseCategory(name: 'Food', allocated: 100, emoji: 'food'),
        ],
        payFrequency: PayFrequency.weekly,
      );
      expect(b.totalAllocated, closeTo(1300 * 12 / 52 + 100, 0.01));
      expect(b.remaining, closeTo(500 - (1300 * 12 / 52 + 100), 0.01));
    });

    test('json round-trips the frequency and legacy decodes to null', () {
      final e = ExpenseCategory(
          name: 'Rent',
          allocated: 1200,
          emoji: 'home',
          frequency: PayFrequency.monthly);
      final back = ExpenseCategory.fromJson(e.toJson());
      expect(back.frequency, PayFrequency.monthly);
      expect(back.allocated, 1200);

      final legacy = ExpenseCategory.fromJson(
          {'name': 'Old', 'allocated': 300.0, 'emoji': 'food'});
      expect(legacy.frequency, isNull);
    });
  });

  group('IncomeSource json', () {
    test('round-trips the frequency', () {
      final s = IncomeSource(
          name: 'Salary', amount: 2000, frequency: PayFrequency.biWeekly);
      final back = IncomeSource.fromJson(s.toJson());
      expect(back.frequency, PayFrequency.biWeekly);
      expect(back.amount, 2000);
    });

    test('legacy records without a frequency decode to null', () {
      final back = IncomeSource.fromJson({'name': 'Old', 'amount': 500.0});
      expect(back.frequency, isNull);
      expect(back.amount, 500);
    });
  });
}
