import '../l10n/app_localizations.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import 'comparison_service.dart';
import 'streak_service.dart';

/// Result of evaluating a budget for an allocation warning. [level] both
/// drives the message *and* dedups notifications: we only notify when the
/// level rises (none → near-limit → over-budget), never repeatedly at the
/// same level.
class BudgetWarning {
  /// 0 = healthy, 1 = near the income limit, 2 = over budget.
  final int level;
  final String title;
  final String message;

  const BudgetWarning({
    required this.level,
    required this.title,
    required this.message,
  });

  static const none =
      BudgetWarning(level: 0, title: '', message: '');
}

/// Builds the actual notification copy. Pure and side-effect free so the
/// wording is unit-testable independent of the OS plugin.
///
/// NOTE: Budget Tree tracks money *allocated* across branches, not per-category
/// spending logs, so the "spending limit" here is the income the trunk can
/// support. A budget is "near its limit" when 80%+ of income is assigned and
/// "over budget" once allocations exceed income.
class NotificationContent {
  NotificationContent._();

  static const double nearLimitRatio = 0.8;

  static BudgetWarning budgetWarning(BudgetModel budget, AppLocalizations l) {
    final income = budget.totalIncome;
    if (income <= 0) return BudgetWarning.none;
    final allocated = budget.totalAllocated;

    if (budget.remaining < -0.01) {
      return BudgetWarning(
        level: 2,
        title: l.notifOverBudgetTitle(budget.budgetName),
        message: l.notifOverBudgetMsg(
          '\$${allocated.toStringAsFixed(0)}',
          '\$${income.toStringAsFixed(0)}',
          '\$${(-budget.remaining).toStringAsFixed(0)}',
        ),
      );
    }

    if (allocated / income >= nearLimitRatio) {
      return BudgetWarning(
        level: 1,
        title: l.notifFillingTitle(budget.budgetName),
        message: l.notifFillingMsg(
          '\$${allocated.toStringAsFixed(0)}',
          '\$${income.toStringAsFixed(0)}',
          '\$${budget.remaining.toStringAsFixed(0)}',
        ),
      );
    }

    return BudgetWarning.none;
  }

  static String streakTitle(StreakInfo s, AppLocalizations l) =>
      s.currentWeeks > 0
          ? l.notifStreakTitleActive(s.currentWeeks)
          : l.notifStreakTitleNone;

  static String streakReminder(StreakInfo s, AppLocalizations l) {
    if (s.currentWeeks > 0) return l.notifStreakActive(s.currentWeeks);
    return l.notifStreakNone;
  }

  static String weeklySummaryTitle(AppLocalizations l) => l.notifWeeklyTitle;

  static String weeklySummary(List<Goal> goals, AppLocalizations l,
      {DateTime? now}) {
    final week = ComparisonService.weekOverWeek(goals, now: now);
    if (!week.hasActivity) return l.notifWeeklyNone;
    final amount = '\$${week.current.toStringAsFixed(0)}';
    final pct = week.percentChange;
    if (pct != null) {
      final arrow = pct >= 0 ? '↑' : '↓';
      return l.notifWeeklyChange(amount, arrow, pct.abs().round());
    }
    return l.notifWeeklyPlain(amount);
  }
}
