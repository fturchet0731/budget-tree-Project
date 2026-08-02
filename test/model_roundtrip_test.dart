// Guards the toJson/fromJson contract every synced model depends on.
//
// Each Supabase table stores the whole model in a `data` jsonb column, so a
// field that `toJson` forgets (or `fromJson` never reads) is silently dropped
// on the next pull — with no compile error and no analyzer warning. These tests
// set every field to a non-default value and assert it survives the round trip,
// so adding a field without wiring both halves fails here.
//
// They also pin the null-safe fallbacks: a legacy record written before a field
// existed must still decode.

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/data/rhythm.dart';
import 'package:budget_app_project/data/water_cadence.dart';
import 'package:budget_app_project/models/budget_model.dart';
import 'package:budget_app_project/models/category_model.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/achievement_service.dart';

void main() {
  group('Goal', () {
    test('every field survives toJson -> fromJson', () {
      final created = DateTime(2026, 1, 2, 3, 4);
      final completed = DateTime(2026, 5, 6, 7, 8);
      final target = DateTime(2026, 12, 25);
      final next = DateTime(2026, 8, 9);
      final contributedAt = DateTime(2026, 3, 4, 5, 6);

      final goal = Goal(
        id: 'goal-1',
        name: 'New bike',
        description: 'A fast one',
        targetAmount: 1200,
        currentAmount: 450,
        iconKey: 'transport',
        createdAt: created,
        completedAt: completed,
        targetDate: target,
        categoryId: 'cat-9',
        sharedWithFriends: true,
        leafColorValue: 0xFF123456,
        waterAmount: 75,
        waterCadenceIndex: WaterCadence.biweekly.index,
        nextWaterDate: next,
        waterRemindersEnabled: true,
        contributions: [
          Contribution(
            amount: 200,
            source: ContributionSource.auto,
            at: contributedAt,
          ),
          Contribution(
            amount: -50,
            source: ContributionSource.adjustment,
            at: contributedAt,
          ),
        ],
      );

      final back = Goal.fromJson(goal.toJson());

      expect(back.id, 'goal-1');
      expect(back.name, 'New bike');
      expect(back.description, 'A fast one');
      expect(back.targetAmount, 1200);
      expect(back.currentAmount, 450);
      expect(back.iconKey, 'transport');
      expect(back.createdAt, created);
      expect(back.completedAt, completed);
      expect(back.targetDate, target);
      expect(back.categoryId, 'cat-9');
      expect(back.sharedWithFriends, isTrue);
      expect(back.leafColorValue, 0xFF123456);
      expect(back.waterAmount, 75);
      expect(back.waterCadenceIndex, WaterCadence.biweekly.index);
      expect(back.nextWaterDate, next);
      expect(back.waterRemindersEnabled, isTrue);

      expect(back.contributions, hasLength(2));
      expect(back.contributions[0].amount, 200);
      expect(back.contributions[0].source, ContributionSource.auto);
      expect(back.contributions[0].at, contributedAt);
      expect(back.contributions[1].amount, -50);
      expect(back.contributions[1].source, ContributionSource.adjustment);
    });

    test('a legacy record decodes with safe defaults', () {
      final back = Goal.fromJson({
        'id': 'old',
        'name': 'Old goal',
        'targetAmount': 100.0,
        'currentAmount': 10.0,
        'createdAt': DateTime(2025, 1, 1).millisecondsSinceEpoch,
      });

      expect(back.description, '');
      expect(back.iconKey, 'savings');
      expect(back.completedAt, isNull);
      expect(back.targetDate, isNull);
      expect(back.categoryId, isNull);
      expect(back.sharedWithFriends, isFalse);
      expect(back.leafColorValue, isNull);
      expect(back.waterAmount, isNull);
      expect(back.waterCadenceIndex, isNull);
      expect(back.nextWaterDate, isNull);
      expect(back.waterRemindersEnabled, isFalse);
      expect(back.contributions, isEmpty);
    });
  });

  group('BudgetModel', () {
    test('every field survives toJson -> fromJson', () {
      final saved = DateTime(2026, 2, 3, 4, 5);
      final firstPay = DateTime(2026, 2, 1);
      final processed = DateTime(2026, 6, 1);

      final budget = BudgetModel(
        budgetName: 'Main tree',
        incomeSources: [
          IncomeSource(
            name: 'Salary',
            amount: 2000,
            frequency: Rhythm.biWeekly,
          ),
        ],
        expenses: [
          ExpenseCategory(
            name: 'Rent',
            allocated: 1200,
            emoji: 'home',
            linkedGoalIds: ['g1', 'g2'],
            frequency: Rhythm.monthly,
          ),
        ],
        id: 'budget-1',
        savedAt: saved,
        categoryId: 'cat-3',
        payFrequency: Rhythm.weekly,
        firstPayDate: firstPay,
        lastProcessedAt: processed,
      );

      final back = BudgetModel.fromJson(budget.toJson());

      expect(back.budgetName, 'Main tree');
      expect(back.id, 'budget-1');
      expect(back.savedAt, saved);
      expect(back.categoryId, 'cat-3');
      expect(back.payFrequency, Rhythm.weekly);
      expect(back.firstPayDate, firstPay);
      expect(back.lastProcessedAt, processed);

      expect(back.incomeSources, hasLength(1));
      expect(back.incomeSources.first.name, 'Salary');
      expect(back.incomeSources.first.amount, 2000);
      expect(back.incomeSources.first.frequency, Rhythm.biWeekly);

      expect(back.expenses, hasLength(1));
      expect(back.expenses.first.name, 'Rent');
      expect(back.expenses.first.allocated, 1200);
      expect(back.expenses.first.emoji, 'home');
      expect(back.expenses.first.linkedGoalIds, ['g1', 'g2']);
      expect(back.expenses.first.frequency, Rhythm.monthly);
    });

    test('a legacy record decodes with safe defaults', () {
      final back = BudgetModel.fromJson({
        'budgetName': 'Old tree',
        'incomeSources': [
          {'name': 'Wage', 'amount': 500.0},
        ],
        'expenses': [
          {'name': 'Food', 'allocated': 100.0, 'emoji': 'food'},
        ],
      });

      expect(back.id, isNotEmpty);
      expect(back.savedAt, isNull);
      expect(back.categoryId, isNull);
      expect(back.payFrequency, isNull);
      expect(back.firstPayDate, isNull);
      expect(back.lastProcessedAt, isNull);
      expect(back.incomeSources.first.frequency, isNull);
      expect(back.expenses.first.linkedGoalIds, isEmpty);
      expect(back.expenses.first.frequency, isNull);
    });
  });

  group('TreeCategory', () {
    test('every field survives toJson -> fromJson', () {
      final cat = TreeCategory(id: 'c1', name: 'Trips', colorValue: 0xFF00AAFF);
      final back = TreeCategory.fromJson(cat.toJson());

      expect(back.id, 'c1');
      expect(back.name, 'Trips');
      expect(back.colorValue, 0xFF00AAFF);
    });
  });

  group('Achievement unlock entry', () {
    test('the store codec round-trips a badge id and unlock time', () {
      final store = AchievementService.store;
      final unlockedAt = DateTime(2026, 4, 5, 6, 7);

      final back = store.fromJson(
        store.toJson(MapEntry('first_tree', unlockedAt)),
      );

      expect(back.key, 'first_tree');
      expect(back.value, unlockedAt);
      expect(store.idOf(back), 'first_tree');
    });
  });
}
