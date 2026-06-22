enum PayFrequency { weekly, biWeekly, semiMonthly, monthly }

extension PayFrequencyX on PayFrequency {
  String get label {
    switch (this) {
      case PayFrequency.weekly:
        return 'Weekly';
      case PayFrequency.biWeekly:
        return 'Bi-weekly';
      case PayFrequency.semiMonthly:
        return 'Semi-monthly';
      case PayFrequency.monthly:
        return 'Monthly';
    }
  }

  /// Approximate number of pay periods per month.
  double get periodsPerMonth {
    switch (this) {
      case PayFrequency.weekly:
        return 52 / 12;
      case PayFrequency.biWeekly:
        return 26 / 12;
      case PayFrequency.semiMonthly:
        return 2.0;
      case PayFrequency.monthly:
        return 1.0;
    }
  }

  /// Approximate length of one pay period.
  Duration get periodLength {
    switch (this) {
      case PayFrequency.weekly:
        return const Duration(days: 7);
      case PayFrequency.biWeekly:
        return const Duration(days: 14);
      case PayFrequency.semiMonthly:
        return const Duration(days: 15);
      case PayFrequency.monthly:
        return const Duration(days: 30);
    }
  }
}

PayFrequency? payFrequencyFromIndex(int? i) {
  if (i == null || i < 0 || i >= PayFrequency.values.length) return null;
  return PayFrequency.values[i];
}
