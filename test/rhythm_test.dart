// The custom "every N days/weeks/months" rhythm, and the back-compatible
// persistence that lets it live alongside the four original presets.

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/data/pay_frequency.dart';
import 'package:budget_app_project/data/rhythm.dart';
import 'package:budget_app_project/models/budget_model.dart';

void main() {
  group('presets behave exactly as the old enum did', () {
    test('periodsPerMonth and periodLength defer to the preset', () {
      expect(Rhythm.weekly.periodsPerMonth, 52 / 12);
      expect(Rhythm.biWeekly.periodsPerMonth, 26 / 12);
      expect(Rhythm.monthly.periodsPerMonth, 1.0);
      expect(Rhythm.weekly.periodLength, const Duration(days: 7));
      expect(Rhythm.monthly.periodLength, const Duration(days: 30));
    });

    test('wire tokens are unchanged', () {
      expect(Rhythm.weekly.wire, 'weekly');
      expect(Rhythm.biWeekly.wire, 'biweekly');
      expect(Rhythm.semiMonthly.wire, 'semimonthly');
      expect(Rhythm.monthly.wire, 'monthly');
    });

    test('a preset still persists as its bare PayFrequency index', () {
      expect(Rhythm.weekly.toJson(), PayFrequency.weekly.index);
      expect(Rhythm.monthly.toJson(), PayFrequency.monthly.index);
    });
  });

  group('custom intervals', () {
    test('every 3 weeks is a third of the weekly rate', () {
      final r = const Rhythm.every(3, CadenceUnit.weeks);
      expect(r.isCustom, isTrue);
      expect(r.periodsPerMonth, closeTo((52 / 12) / 3, 0.0001));
      expect(r.periodLength, const Duration(days: 21));
      expect(r.wire, 'every:3:weeks');
    });

    test('every 10 days', () {
      final r = const Rhythm.every(10, CadenceUnit.days);
      expect(r.periodsPerMonth, closeTo((365 / 12) / 10, 0.0001));
      expect(r.periodLength, const Duration(days: 10));
      expect(r.wire, 'every:10:days');
    });

    test('every 1 month matches the monthly preset ratio', () {
      expect(
        const Rhythm.every(1, CadenceUnit.months).periodsPerMonth,
        closeTo(Rhythm.monthly.periodsPerMonth, 0.0001),
      );
    });

    test('a zero or negative count degrades safely instead of dividing by zero',
        () {
      final r = const Rhythm.every(0, CadenceUnit.weeks);
      expect(r.isValid, isFalse);
      expect(r.periodsPerMonth, 1.0);
      expect(r.periodLength, const Duration(days: 7));
    });
  });

  group('persistence', () {
    test('a custom rhythm round-trips through its map form', () {
      final r = const Rhythm.every(3, CadenceUnit.weeks);
      final back = rhythmFromJson(r.toJson());
      expect(back, r);
      expect(back!.count, 3);
      expect(back.unit, CadenceUnit.weeks);
    });

    test('a legacy bare int index still decodes to the right preset', () {
      expect(rhythmFromJson(PayFrequency.biWeekly.index), Rhythm.biWeekly);
      expect(rhythmFromJson(0), Rhythm.weekly);
    });

    test('null and malformed values decode to null', () {
      expect(rhythmFromJson(null), isNull);
      expect(rhythmFromJson(99), isNull);
      expect(rhythmFromJson({'count': 0, 'unit': 1}), isNull);
      expect(rhythmFromJson({'count': 3}), isNull);
      expect(rhythmFromJson('weekly'), isNull);
    });
  });

  group('per-cycle conversion with a custom rhythm', () {
    test('income arriving every 3 weeks, in a monthly budget', () {
      final s = IncomeSource(
        name: 'Contract',
        amount: 900,
        frequency: const Rhythm.every(3, CadenceUnit.weeks),
      );
      // 900 every 3 weeks -> 900 * (52/12/3) per month.
      expect(
        s.amountPerCycle(Rhythm.monthly),
        closeTo(900 * (52 / 12 / 3), 0.01),
      );
    });

    test('a bill charged every 2 months, in a weekly budget', () {
      final e = ExpenseCategory(
        name: 'Insurance',
        allocated: 400,
        emoji: 'other',
        frequency: const Rhythm.every(2, CadenceUnit.months),
      );
      // 400 every 2 months -> 400 * 0.5 per month -> divided into weeks.
      expect(
        e.allocatedPerCycle(Rhythm.weekly),
        closeTo(400 * 0.5 / (52 / 12), 0.01),
      );
    });

    test('setAllocatedPerCycle inverts a custom conversion', () {
      final e = ExpenseCategory(
        name: 'Insurance',
        allocated: 0,
        emoji: 'other',
        frequency: const Rhythm.every(2, CadenceUnit.months),
      );
      e.setAllocatedPerCycle(50, Rhythm.weekly);
      expect(e.allocatedPerCycle(Rhythm.weekly), closeTo(50, 0.01));
    });

    test('a budget mixing preset and custom rhythms totals correctly', () {
      final b = BudgetModel(
        budgetName: 'Mixed',
        incomeSources: [
          IncomeSource(name: 'Salary', amount: 1000, frequency: Rhythm.biWeekly),
          IncomeSource(
            name: 'Contract',
            amount: 600,
            frequency: const Rhythm.every(6, CadenceUnit.weeks),
          ),
        ],
        expenses: [
          ExpenseCategory(
            name: 'Rent',
            allocated: 1200,
            emoji: 'home',
            frequency: Rhythm.monthly,
          ),
        ],
        payFrequency: Rhythm.monthly,
      );

      expect(
        b.totalIncome,
        closeTo(1000 * 26 / 12 + 600 * (52 / 12 / 6), 0.01),
      );
      expect(b.totalAllocated, closeTo(1200, 0.01));
    });
  });

  test('a budget with a custom cycle round-trips through json', () {
    final b = BudgetModel(
      budgetName: 'Odd cycle',
      incomeSources: [
        IncomeSource(
          name: 'Gig',
          amount: 300,
          frequency: const Rhythm.every(10, CadenceUnit.days),
        ),
      ],
      expenses: const [],
      payFrequency: const Rhythm.every(3, CadenceUnit.weeks),
    );

    final back = BudgetModel.fromJson(b.toJson());
    expect(back.payFrequency, const Rhythm.every(3, CadenceUnit.weeks));
    expect(
      back.incomeSources.first.frequency,
      const Rhythm.every(10, CadenceUnit.days),
    );
  });
}
