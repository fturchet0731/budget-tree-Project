enum PayFrequency { weekly, biWeekly, semiMonthly, monthly }

extension PayFrequencyX on PayFrequency {
  // Shown labels live in `lib/l10n/pay_frequency_labels.dart` so this stays a
  // pure, localization-free data enum.

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

  /// Stable token exchanged with the `ai-coach` edge function.
  String get wire {
    switch (this) {
      case PayFrequency.weekly:
        return 'weekly';
      case PayFrequency.biWeekly:
        return 'biweekly';
      case PayFrequency.semiMonthly:
        return 'semimonthly';
      case PayFrequency.monthly:
        return 'monthly';
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
