import '../data/water_cadence.dart';
import 'app_localizations.dart';

/// Localized labels for [WaterCadence]. The enum stays a pure data type; the
/// shown text lives here, mirroring `preset_labels.dart`.

/// Standalone label used on cadence chips: "Weekly" / "Biweekly" / "Monthly".
String cadenceLabel(AppLocalizations l, WaterCadence c) {
  switch (c) {
    case WaterCadence.weekly:
      return l.cadenceWeekly;
    case WaterCadence.biweekly:
      return l.cadenceBiweekly;
    case WaterCadence.monthly:
      return l.cadenceMonthly;
  }
}

/// Phrase used after an amount, e.g. "every week" / "every 2 weeks" /
/// "every month" so a plan reads "$100 every 2 weeks".
String cadenceEvery(AppLocalizations l, WaterCadence c) {
  switch (c) {
    case WaterCadence.weekly:
      return l.cadenceEveryWeekly;
    case WaterCadence.biweekly:
      return l.cadenceEveryBiweekly;
    case WaterCadence.monthly:
      return l.cadenceEveryMonthly;
  }
}
