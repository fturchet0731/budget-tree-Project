import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/pulse_service.dart';

void main() {
  // A fixed "now" mid-week keeps the streak week math deterministic.
  final now = DateTime(2026, 7, 1, 12); // a Wednesday

  Goal goal({
    String name = 'Goal',
    double target = 1000,
    double? waterAmount,
    DateTime? nextWaterDate,
    DateTime? completedAt,
    List<Contribution>? contributions,
  }) {
    return Goal(
      name: name,
      targetAmount: target,
      waterAmount: waterAmount,
      waterCadenceIndex: waterAmount == null ? null : 0, // weekly
      nextWaterDate: nextWaterDate,
      completedAt: completedAt,
      contributions: contributions,
    );
  }

  Contribution deposit(DateTime at) => Contribution(at: at, amount: 10);

  group('PulseService.compute', () {
    test('hidden when there is nothing to say', () {
      final info = PulseService.compute(
        budgets: const [],
        goals: [goal()],
        now: now,
      );
      expect(info.kind, PulseKind.none);
    });

    test('points brand-new users at their first tree', () {
      final info = PulseService.compute(
        budgets: const [],
        goals: const [],
        now: now,
      );
      expect(info.kind, PulseKind.plantFirstTree);
    });

    test('watering due today wins', () {
      final g = goal(
        name: 'Trip',
        waterAmount: 25,
        nextWaterDate: DateTime(2026, 7, 1, 9),
      );
      final info = PulseService.compute(
        budgets: const [],
        goals: [g],
        now: now,
      );
      expect(info.kind, PulseKind.waterDue);
      expect(info.goal, same(g));
      expect(info.overdue, isFalse);
    });

    test('missed watering is flagged overdue and oldest due goal wins', () {
      final older = goal(
        name: 'Older',
        waterAmount: 10,
        nextWaterDate: DateTime(2026, 6, 20),
      );
      final newer = goal(
        name: 'Newer',
        waterAmount: 10,
        nextWaterDate: DateTime(2026, 6, 28),
      );
      final info = PulseService.compute(
        budgets: const [],
        goals: [newer, older],
        now: now,
      );
      expect(info.kind, PulseKind.waterDue);
      expect(info.goal, same(older));
      expect(info.overdue, isTrue);
    });

    test('future waterings and completed goals do not trigger the strip', () {
      final future = goal(
        waterAmount: 10,
        nextWaterDate: DateTime(2026, 7, 2),
      );
      final done = goal(
        waterAmount: 10,
        nextWaterDate: DateTime(2026, 6, 1),
        completedAt: DateTime(2026, 6, 1),
      );
      final info = PulseService.compute(
        budgets: const [],
        goals: [future, done],
        now: now,
      );
      expect(info.kind, PulseKind.none);
    });

    test('streak at risk when alive but not fed this week', () {
      final g = goal(
        contributions: [
          deposit(DateTime(2026, 6, 24)), // last week
          deposit(DateTime(2026, 6, 17)), // week before
        ],
      );
      final info = PulseService.compute(
        budgets: const [],
        goals: [g],
        now: now,
      );
      expect(info.kind, PulseKind.streakAtRisk);
      expect(info.streakWeeks, 2);
    });

    test('active streak shows quietly once fed this week', () {
      final g = goal(
        contributions: [
          deposit(DateTime(2026, 6, 30)), // this week
          deposit(DateTime(2026, 6, 24)), // last week
        ],
      );
      final info = PulseService.compute(
        budgets: const [],
        goals: [g],
        now: now,
      );
      expect(info.kind, PulseKind.streakActive);
      expect(info.streakWeeks, 2);
    });

    test('watering due outranks the streak nudge', () {
      final g = goal(
        waterAmount: 25,
        nextWaterDate: DateTime(2026, 7, 1),
        contributions: [deposit(DateTime(2026, 6, 24))],
      );
      final info = PulseService.compute(
        budgets: const [],
        goals: [g],
        now: now,
      );
      expect(info.kind, PulseKind.waterDue);
    });
  });
}
