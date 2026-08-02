import '../data/rhythm.dart';
import 'app_localizations.dart';
import 'pay_frequency_labels.dart';

/// Localized display names for a [Rhythm], mirroring the
/// `pay_frequency_labels.dart` / `water_cadence_labels.dart` pattern: the data
/// type stays copy-free and the shown text lives here. Presets defer to their
/// existing [PayFrequencyLabels] strings so nothing changes for them; a custom
/// interval reads "Every 3 weeks" through an ICU plural, so "Every 1 weeks"
/// can't happen.
extension RhythmLabels on Rhythm {
  String localizedLabel(AppLocalizations l) {
    final p = preset;
    if (p != null) return p.localizedLabel(l);
    switch (unit) {
      case CadenceUnit.days:
        return l.rhythmEveryDays(count);
      case CadenceUnit.weeks:
        return l.rhythmEveryWeeks(count);
      case CadenceUnit.months:
        return l.rhythmEveryMonths(count);
    }
  }
}

extension CadenceUnitLabels on CadenceUnit {
  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case CadenceUnit.days:
        return l.rhythmUnitDays;
      case CadenceUnit.weeks:
        return l.rhythmUnitWeeks;
      case CadenceUnit.months:
        return l.rhythmUnitMonths;
    }
  }
}
