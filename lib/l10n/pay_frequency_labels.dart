import '../data/pay_frequency.dart';
import 'app_localizations.dart';

/// Localized display names for [PayFrequency], mirroring the
/// `water_cadence_labels.dart` pattern: the enum stays a pure data type and
/// the shown text lives here.
extension PayFrequencyLabels on PayFrequency {
  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case PayFrequency.weekly:
        return l.payFreqWeekly;
      case PayFrequency.biWeekly:
        return l.payFreqBiWeekly;
      case PayFrequency.semiMonthly:
        return l.payFreqSemiMonthly;
      case PayFrequency.monthly:
        return l.payFreqMonthly;
    }
  }
}
