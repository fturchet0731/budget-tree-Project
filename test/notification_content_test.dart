// Unit tests for notification copy. These cover the pure message/level logic
// only — the OS plugin layer (NotificationService) can't be exercised in a
// headless test and is wrapped in try/catch no-ops by design.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_app_project/l10n/app_localizations.dart';
import 'package:budget_app_project/models/budget_model.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/notification_content.dart';
import 'package:budget_app_project/services/streak_service.dart';

final l = lookupAppLocalizations(const Locale('en'));

BudgetModel budget(double income, double allocated) => BudgetModel(
      budgetName: 'Main',
      incomeSources: [IncomeSource(name: 'Job', amount: income)],
      expenses: [
        ExpenseCategory(name: 'Spending', allocated: allocated, emoji: 'home')
      ],
      age: 30,
      location: 'X',
    );

void main() {
  group('Budget warning levels', () {
    test('healthy budget produces no warning', () {
      final w = NotificationContent.budgetWarning(budget(1000, 500), l);
      expect(w.level, 0);
    });

    test('80%+ allocated is a near-limit (level 1) warning with money left', () {
      final w = NotificationContent.budgetWarning(budget(1000, 850), l);
      expect(w.level, 1);
      expect(w.message, contains('150')); // $150 left
    });

    test('over-allocated is a level 2 warning', () {
      final w = NotificationContent.budgetWarning(budget(1000, 1200), l);
      expect(w.level, 2);
      expect(w.message, contains('200')); // $200 too much
    });

    test('no income yields no warning (cannot advise)', () {
      final w = NotificationContent.budgetWarning(budget(0, 0), l);
      expect(w.level, 0);
    });
  });

  group('Streak reminder copy', () {
    test('active streak mentions the week count', () {
      final goal = Goal(name: 'S', targetAmount: 0);
      goal.applyContribution(10, at: DateTime(2026, 6, 21));
      final info = StreakService.weeklyStreak([goal], now: DateTime(2026, 6, 21));
      final body = NotificationContent.streakReminder(info, l);
      expect(body, contains('${info.currentWeeks} week'));
    });

    test('no streak invites the user to start one', () {
      final body = NotificationContent.streakReminder(StreakInfo.empty, l);
      expect(body.toLowerCase(), contains('start'));
    });
  });

  group('Weekly summary copy', () {
    test('summarizes the amount saved this week with a delta', () {
      final now = DateTime(2026, 6, 17); // mid-week Wednesday
      final goal = Goal(name: 'S', targetAmount: 0);
      goal.applyContribution(50, at: DateTime(2026, 6, 9)); // last week
      goal.applyContribution(80, at: DateTime(2026, 6, 16)); // this week
      final body = NotificationContent.weeklySummary([goal], l, now: now);
      expect(body, contains('80'));
      expect(body, contains('%'));
    });

    test('quiet week nudges the user', () {
      final body = NotificationContent.weeklySummary(const [], l, now: DateTime(2026, 6, 17));
      expect(body.toLowerCase(), contains('no deposits'));
    });
  });
}
