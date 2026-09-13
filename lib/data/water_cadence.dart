/// How often a goal is "watered" (a contribution is due). Drives the goal
/// watering plan options and the watering reminder schedule. Kept tiny and
/// localization free: the shown label lives in `lib/l10n/water_cadence_labels`
/// so this stays a pure data enum.
enum WaterCadence { weekly, biweekly, monthly }

extension WaterCadenceX on WaterCadence {
  /// Days between waterings — the step used to roll `nextWaterDate` forward.
  int get days {
    switch (this) {
      case WaterCadence.weekly:
        return 7;
      case WaterCadence.biweekly:
        return 14;
      case WaterCadence.monthly:
        return 30;
    }
  }

  /// Approximate waterings per month, used to convert a monthly contribution
  /// into a per-watering amount and back.
  double get perMonth {
    switch (this) {
      case WaterCadence.weekly:
        return 52 / 12;
      case WaterCadence.biweekly:
        return 26 / 12;
      case WaterCadence.monthly:
        return 1.0;
    }
  }

  /// Stable token exchanged with the `ai-coach` edge function.
  String get wire {
    switch (this) {
      case WaterCadence.weekly:
        return 'weekly';
      case WaterCadence.biweekly:
        return 'biweekly';
      case WaterCadence.monthly:
        return 'monthly';
    }
  }
}

/// Decode a persisted index back to a cadence, or null when absent/invalid.
WaterCadence? waterCadenceFromIndex(int? i) {
  if (i == null || i < 0 || i >= WaterCadence.values.length) return null;
  return WaterCadence.values[i];
}

/// Decode the AI's wire token, defaulting to biweekly when unrecognised.
WaterCadence waterCadenceFromWire(String? s) {
  switch (s) {
    case 'weekly':
      return WaterCadence.weekly;
    case 'monthly':
      return WaterCadence.monthly;
    default:
      return WaterCadence.biweekly;
  }
}
