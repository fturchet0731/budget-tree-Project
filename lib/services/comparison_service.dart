import '../models/goal_model.dart';

/// A "this period vs last period" saving comparison.
class PeriodComparison {
  final String unit; // 'week' or 'month'
  final double current;
  final double previous;

  const PeriodComparison({
    required this.unit,
    required this.current,
    required this.previous,
  });

  bool get hasPrevious => previous > 0;

  /// Percent change vs the previous period. Null when there's no prior
  /// baseline to compare against (avoids divide-by-zero "∞%").
  double? get percentChange =>
      hasPrevious ? ((current - previous) / previous) * 100 : null;

  bool get improved => current > previous;
  bool get hasActivity => current > 0 || previous > 0;
}

/// Aggregates goal deposits into calendar-aligned weekly and monthly totals
/// for the "You saved 15% more this month!" style comparisons.
class ComparisonService {
  ComparisonService._();

  static double _depositsBetween(
      List<Goal> goals, DateTime from, DateTime to) {
    double sum = 0;
    for (final g in goals) {
      for (final c in g.contributions) {
        if (!c.isDeposit) continue;
        if (!c.at.isBefore(from) && c.at.isBefore(to)) sum += c.amount;
      }
    }
    return sum;
  }

  /// Monday 00:00 of the week containing [d].
  static DateTime _weekStart(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }

  static PeriodComparison weekOverWeek(List<Goal> goals, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final thisStart = _weekStart(n);
    final lastStart = thisStart.subtract(const Duration(days: 7));
    return PeriodComparison(
      unit: 'week',
      current: _depositsBetween(goals, thisStart, n),
      previous: _depositsBetween(goals, lastStart, thisStart),
    );
  }

  static PeriodComparison monthOverMonth(List<Goal> goals, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final thisStart = DateTime(n.year, n.month, 1);
    final lastStart = DateTime(n.year, n.month - 1, 1);
    return PeriodComparison(
      unit: 'month',
      current: _depositsBetween(goals, thisStart, n),
      previous: _depositsBetween(goals, lastStart, thisStart),
    );
  }
}
