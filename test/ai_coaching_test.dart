import 'package:flutter_test/flutter_test.dart';
import 'package:budget_app_project/models/ai_plan.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/goal_plan_math.dart';

void main() {
  group('GoalPlanMath', () {
    test('monthsBetween is at least 1 and counts whole calendar months', () {
      expect(
        GoalPlanMath.monthsBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 20)),
        1,
      );
      expect(
        GoalPlanMath.monthsBetween(DateTime(2026, 1, 1), DateTime(2026, 7, 1)),
        6,
      );
    });

    test('monthlyToReach splits the remaining amount across the months', () {
      final goal = Goal(name: 'Bike', targetAmount: 1200, currentAmount: 0);
      final monthly = GoalPlanMath.monthlyToReach(
        goal,
        DateTime(2026, 7, 1),
        now: DateTime(2026, 1, 1),
      );
      expect(monthly, 200); // 1200 / 6 months
    });

    test('monthlyToReach is 0 for uncapped or already-met goals', () {
      final uncapped = Goal(name: 'Forever', targetAmount: 0);
      expect(GoalPlanMath.monthlyToReach(uncapped, DateTime(2026, 7, 1)), 0);
      final met = Goal(name: 'Done', targetAmount: 100, currentAmount: 150);
      expect(GoalPlanMath.monthlyToReach(met, DateTime(2026, 7, 1)), 0);
    });

    test('dateForMonthly returns a future date that covers the remainder', () {
      final goal = Goal(name: 'Trip', targetAmount: 1000, currentAmount: 0);
      final date = GoalPlanMath.dateForMonthly(
        goal,
        250,
        now: DateTime(2026, 1, 1),
      );
      // 1000 / 250 = 4 months -> May 1.
      expect(date, DateTime(2026, 5, 1));
    });
  });

  group('AI plan parsing', () {
    test('AllocationPlan.listFrom parses items and leftover defensively', () {
      final plans = AllocationPlan.listFrom({
        'plans': [
          {
            'name': 'Balanced',
            'items': [
              {'name': 'Rent', 'amount': 800},
              {'name': 'Food'}, // missing amount -> 0
            ],
            'leftover': 400,
            'rationale': 'Covers the essentials.',
          },
        ],
      });
      expect(plans.length, 1);
      expect(plans.first.name, 'Balanced');
      expect(plans.first.items.length, 2);
      expect(plans.first.items[0].amount, 800);
      expect(plans.first.items[1].amount, 0);
      expect(plans.first.leftover, 400);
    });

    test('AllocationPlan.listFrom tolerates missing plans', () {
      expect(AllocationPlan.listFrom({}), isEmpty);
      expect(AllocationPlan.listFrom({'plans': null}), isEmpty);
    });

    test('GoalPlanResult parses options and alternative dates', () {
      final result = GoalPlanResult.fromJson({
        'plans': [
          {'monthly': 150, 'monthsToTarget': 8, 'rationale': 'Steady pace.'},
        ],
        'alternativeDates': [
          {'isoDate': '2026-12-01', 'monthly': 100, 'note': 'Easier pace.'},
        ],
      });
      expect(result.plans.single.monthly, 150);
      expect(result.plans.single.monthsToTarget, 8);
      expect(result.alternativeDates.single.date, DateTime(2026, 12, 1));
      expect(result.alternativeDates.single.monthly, 100);
    });
  });
}
