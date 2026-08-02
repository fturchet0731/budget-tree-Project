import 'pay_frequency.dart';

/// The unit a custom rhythm counts in.
enum CadenceUnit { days, weeks, months }

extension CadenceUnitX on CadenceUnit {
  /// Approximate length of one unit, used to build the period length.
  int get days {
    switch (this) {
      case CadenceUnit.days:
        return 1;
      case CadenceUnit.weeks:
        return 7;
      case CadenceUnit.months:
        return 30;
    }
  }

  /// How many of this unit fit in a month, used for the per-cycle ratios.
  double get perMonth {
    switch (this) {
      case CadenceUnit.days:
        return 365 / 12;
      case CadenceUnit.weeks:
        return 52 / 12;
      case CadenceUnit.months:
        return 1.0;
    }
  }

  /// Stable token exchanged with the `ai-coach` edge function.
  String get wire {
    switch (this) {
      case CadenceUnit.days:
        return 'days';
      case CadenceUnit.weeks:
        return 'weeks';
      case CadenceUnit.months:
        return 'months';
    }
  }
}

CadenceUnit? cadenceUnitFromIndex(int? i) {
  if (i == null || i < 0 || i >= CadenceUnit.values.length) return null;
  return CadenceUnit.values[i];
}

/// How often money arrives or a bill is charged.
///
/// Either one of the four [PayFrequency] presets, or a **custom** interval the
/// user typed ("every 3 weeks", "every 10 days"). Everything downstream — the
/// per-cycle conversions in [BudgetModel], [PayScheduler]'s elapsed-period
/// maths, and the AI payloads — reads [periodsPerMonth] / [periodLength] /
/// [wire] from here, so a custom interval behaves exactly like a preset.
///
/// **Persistence is backwards compatible**: a preset encodes to the bare
/// [PayFrequency] index it always used, so records written before custom
/// rhythms existed decode unchanged. Only custom rhythms write a map.
class Rhythm {
  /// The preset, or null when this is a custom interval.
  final PayFrequency? preset;

  /// For a custom interval: repeat every [count] [unit]s. Ignored for presets.
  final int count;
  final CadenceUnit unit;

  const Rhythm.of(PayFrequency this.preset)
      : count = 1,
        unit = CadenceUnit.months;

  const Rhythm.every(this.count, this.unit) : preset = null;

  static const weekly = Rhythm.of(PayFrequency.weekly);
  static const biWeekly = Rhythm.of(PayFrequency.biWeekly);
  static const semiMonthly = Rhythm.of(PayFrequency.semiMonthly);
  static const monthly = Rhythm.of(PayFrequency.monthly);

  /// The four presets, in the order they're offered as chips.
  static const presets = [weekly, biWeekly, semiMonthly, monthly];

  bool get isCustom => preset == null;

  /// A custom rhythm is only usable once the user has typed a positive count.
  bool get isValid => preset != null || count > 0;

  /// Approximate number of periods per month — the ratio every per-cycle
  /// conversion is built on.
  double get periodsPerMonth {
    final p = preset;
    if (p != null) return p.periodsPerMonth;
    if (count <= 0) return 1.0;
    return unit.perMonth / count;
  }

  /// Approximate length of one period.
  Duration get periodLength {
    final p = preset;
    if (p != null) return p.periodLength;
    final n = count <= 0 ? 1 : count;
    return Duration(days: n * unit.days);
  }

  /// Stable token exchanged with the `ai-coach` edge function. Presets keep
  /// their original tokens; a custom interval reads `every:3:weeks`.
  String get wire {
    final p = preset;
    if (p != null) return p.wire;
    return 'every:$count:${unit.wire}';
  }

  /// Presets persist as the bare int index they always did, so existing rows
  /// are untouched; only custom rhythms need the richer map.
  dynamic toJson() {
    final p = preset;
    if (p != null) return p.index;
    return {'count': count, 'unit': unit.index};
  }

  @override
  bool operator ==(Object other) =>
      other is Rhythm &&
      other.preset == preset &&
      (preset != null || (other.count == count && other.unit == unit));

  @override
  int get hashCode => preset?.hashCode ?? Object.hash(count, unit);
}

/// Decode a persisted rhythm. Accepts the legacy bare [PayFrequency] index, the
/// custom map, or null (meaning "once per budget cycle", the legacy default).
Rhythm? rhythmFromJson(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) {
    final p = payFrequencyFromIndex(raw);
    return p == null ? null : Rhythm.of(p);
  }
  if (raw is num) {
    final p = payFrequencyFromIndex(raw.toInt());
    return p == null ? null : Rhythm.of(p);
  }
  if (raw is Map) {
    final count = (raw['count'] as num?)?.toInt() ?? 0;
    final unit = cadenceUnitFromIndex((raw['unit'] as num?)?.toInt());
    if (count <= 0 || unit == null) return null;
    return Rhythm.every(count, unit);
  }
  return null;
}
