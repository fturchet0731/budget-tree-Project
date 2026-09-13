/// Calendar-day arithmetic that survives daylight saving.
///
/// `DateTime.add(Duration(days: 7))` adds exactly 168 hours, not "a week". On
/// the two days a year a zone shifts, that lands an hour early or late, which
/// is enough to slide a midnight-anchored value into the previous or next day.
/// The same trap catches `difference(...).inDays`, which truncates: the gap
/// between two local midnights a week apart is 6 days 23 hours across a
/// spring-forward, so `.inDays` reports **6**.
///
/// Everything here works on calendar fields instead. Day counts go through UTC,
/// which has no transitions, so they're exact; day stepping goes through the
/// `DateTime` constructor, which normalises overflow (month 13 becomes January)
/// and re-resolves the wall clock in local time.
library;

/// Local midnight on the same day as [d].
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [d] moved [days] calendar days, keeping the same wall-clock time of day.
/// Negative values step backwards.
DateTime addDays(DateTime d, int days) => DateTime(
      d.year,
      d.month,
      d.day + days,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
      d.microsecond,
    );

/// Whole calendar days from [a] to [b], ignoring the time of day. Negative when
/// [b] is before [a]. Exact across daylight saving because it compares UTC
/// midnights rather than local ones.
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

/// Monday-anchored week number. 1970-01-05 was a Monday, so flooring the day
/// offset from there by 7 gives a stable week index that doesn't drift.
int weekIndexOf(DateTime d) {
  final days = daysBetween(DateTime(1970, 1, 5), d);
  return (days / 7).floor();
}

/// Local midnight on the Monday of [d]'s week.
DateTime startOfWeek(DateTime d) => addDays(dateOnly(d), -(d.weekday - 1));
