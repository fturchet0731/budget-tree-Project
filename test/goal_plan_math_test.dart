// The day-accurate goal planning maths. Every amount and date the user sees
// comes from here rather than from the model, so a chosen target date is hit
// exactly instead of approximately.

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/data/water_cadence.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/goal_plan_math.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  Goal goal({double target = 1000, double current = 0}) =>
      Goal(name: 'Trip', targetAmount: target, currentAmount: current);

  group('wateringsUntil', () {
    test('counts whole cadence steps to the date', () {
      // 70 days = 10 weeks, 5 fortnights, 2 whole 30-day months.
      final target = now.add(const Duration(days: 70));
      expect(GoalPlanMath.wateringsUntil(target, WaterCadence.weekly, now: now),
          10);
      expect(
          GoalPlanMath.wateringsUntil(target, WaterCadence.biweekly, now: now),
          5);
      expect(
          GoalPlanMath.wateringsUntil(target, WaterCadence.monthly, now: now),
          2);
    });

    test('a date less than one cadence away still gives one watering', () {
      final target = now.add(const Duration(days: 3));
      expect(GoalPlanMath.wateringsUntil(target, WaterCadence.monthly, now: now),
          1);
    });

    test('a past date gives none', () {
      final target = now.subtract(const Duration(days: 5));
      expect(
          GoalPlanMath.wateringsUntil(target, WaterCadence.weekly, now: now), 0);
    });
  });

  group('perWateringForDate', () {
    test('divides exactly across the waterings that fit', () {
      final target = now.add(const Duration(days: 70)); // 10 weeks
      expect(
        GoalPlanMath.perWateringForDate(
            goal(target: 1000), target, WaterCadence.weekly,
            now: now),
        closeTo(100, 0.001),
      );
    });

    test('every cadence lands the same total, just in different bites', () {
      final target = now.add(const Duration(days: 140));
      final g = goal(target: 2800);
      for (final c in WaterCadence.values) {
        final per = GoalPlanMath.perWateringForDate(g, target, c, now: now);
        final n = GoalPlanMath.wateringsUntil(target, c, now: now);
        expect(per * n, closeTo(2800, 0.001), reason: c.name);
      }
    });

    test('accounts for what is already saved', () {
      final target = now.add(const Duration(days: 70));
      expect(
        GoalPlanMath.perWateringForDate(
            goal(target: 1000, current: 400), target, WaterCadence.weekly,
            now: now),
        closeTo(60, 0.001),
      );
    });

    test('an already-met or uncapped goal needs nothing', () {
      final target = now.add(const Duration(days: 70));
      expect(
        GoalPlanMath.perWateringForDate(
            goal(target: 1000, current: 1000), target, WaterCadence.weekly,
            now: now),
        0,
      );
      expect(
        GoalPlanMath.perWateringForDate(
            Goal(name: 'Forever', targetAmount: 0), target, WaterCadence.weekly,
            now: now),
        0,
      );
    });
  });

  group('dateForPerWatering', () {
    test('projects the completion date from the amount', () {
      // $100 a week toward $1000 needs 10 weeks.
      final d = GoalPlanMath.dateForPerWatering(
          goal(target: 1000), 100, WaterCadence.weekly,
          now: now);
      expect(d, now.add(const Duration(days: 70)));
    });

    test('rounds up to a whole watering', () {
      // $300 a month toward $1000 needs 4 payments, not 3.33.
      final d = GoalPlanMath.dateForPerWatering(
          goal(target: 1000), 300, WaterCadence.monthly,
          now: now);
      expect(d, now.add(const Duration(days: 120)));
    });

    test('is the inverse of perWateringForDate', () {
      final target = now.add(const Duration(days: 70));
      final g = goal(target: 1000);
      final per =
          GoalPlanMath.perWateringForDate(g, target, WaterCadence.weekly,
              now: now);
      final back =
          GoalPlanMath.dateForPerWatering(g, per, WaterCadence.weekly,
              now: now);
      expect(back, target);
    });

    test('null for uncapped goals or a non-positive amount', () {
      expect(
        GoalPlanMath.dateForPerWatering(
            Goal(name: 'Forever', targetAmount: 0), 50, WaterCadence.weekly,
            now: now),
        isNull,
      );
      expect(
        GoalPlanMath.dateForPerWatering(
            goal(), 0, WaterCadence.weekly, now: now),
        isNull,
      );
    });
  });

  group('suggestedPerWatering', () {
    test('offers a spread of paces, all positive and distinct', () {
      final s = GoalPlanMath.suggestedPerWatering(
          goal(target: 5000), WaterCadence.weekly, 800);
      expect(s, isNotEmpty);
      expect(s.toSet().length, s.length, reason: 'no duplicates');
      for (final v in s) {
        expect(v, greaterThan(0));
      }
      // Ordered comfortable -> brisk.
      final sorted = [...s]..sort();
      expect(s, sorted);
    });

    test('returns friendly round numbers', () {
      final s = GoalPlanMath.suggestedPerWatering(
          goal(target: 5000), WaterCadence.weekly, 800);
      for (final v in s) {
        expect(v % 5, 0, reason: '$v should be a round figure');
      }
    });

    test('works with no known free income by pacing over a year', () {
      final s = GoalPlanMath.suggestedPerWatering(
          goal(target: 1200), WaterCadence.monthly, 0);
      expect(s, isNotEmpty);
    });

    test('nothing to suggest for uncapped or already-met goals', () {
      expect(
        GoalPlanMath.suggestedPerWatering(
            Goal(name: 'Forever', targetAmount: 0), WaterCadence.weekly, 500),
        isEmpty,
      );
      expect(
        GoalPlanMath.suggestedPerWatering(
            goal(target: 100, current: 100), WaterCadence.weekly, 500),
        isEmpty,
      );
    });
  });
}
