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

  static BudgetWarning budgetWarning(BudgetModel budget) {
    final income = budget.totalIncome;
    if (income <= 0) return BudgetWarning.none;
    final allocated = budget.totalAllocated;

    if (budget.remaining < -0.01) {
      return BudgetWarning(
        level: 2,
        title: '🌳 "${budget.budgetName}" is over budget',
        message:
            'You\'ve assigned \$${allocated.toStringAsFixed(0)} of your '
            '\$${income.toStringAsFixed(0)} income — '
            '\$${(-budget.remaining).toStringAsFixed(0)} too much. '
            'Trim a branch to get back in balance.',
      );
    }

    if (allocated / income >= nearLimitRatio) {
      return BudgetWarning(
        level: 1,
        title: '⚠️ "${budget.budgetName}" is filling up',
        message:
            'You\'ve assigned \$${allocated.toStringAsFixed(0)} of '
            '\$${income.toStringAsFixed(0)}. '
            'Only \$${budget.remaining.toStringAsFixed(0)} left to budget '
            'this cycle.',
      );
    }

    return BudgetWarning.none;
  }

  static String streakTitle(StreakInfo s) =>
      s.currentWeeks > 0 ? '🔥 ${s.currentWeeks}-week streak' : '🌱 Grow a streak';

  static String streakReminder(StreakInfo s) {
    if (s.currentWeeks > 0) {
      return 'You\'re on a ${s.currentWeeks}-week saving streak! Add to a goal '
          'today to keep it growing.';
    }
    return 'Water a goal today, even a little, to start a saving streak.';
  }

  static const String weeklySummaryTitle = '📊 Your week in the grove';

  static String weeklySummary(List<Goal> goals, {DateTime? now}) {
    final week = ComparisonService.weekOverWeek(goals, now: now);
    if (!week.hasActivity) {
      return 'No deposits this week yet. A small amount keeps your saplings '
          'growing — and your streak alive.';
    }
    final buf = StringBuffer(
        'This week you saved \$${week.current.toStringAsFixed(0)}');
    final pct = week.percentChange;
    if (pct != null) {
      final arrow = pct >= 0 ? '↑' : '↓';
      buf.write(' ($arrow ${pct.abs().round()}% vs last week)');
    }
    buf.write('. Keep your goals growing!');
    return buf.toString();
  }
}
