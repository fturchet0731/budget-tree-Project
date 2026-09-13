// Calendar-day arithmetic across daylight saving.
//
// The trap these guard against: `DateTime.add(Duration(days: 7))` adds 168
// hours, not a week, and `difference(...).inDays` truncates. Between two local
// midnights a week apart across a spring-forward the gap is 6 days 23 hours, so
// the naive version reports 6 and everything keyed on it (week index, streaks,
// watering counts) slides by one.
//
// Tests run in the machine's own zone, so the DST assertions only bite where
// there is one. The invariants below hold everywhere either way.

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/data/calendar.dart';

void main() {
  group('dateOnly', () {
    test('strips the time', () {
      expect(
        dateOnly(DateTime(2026, 3, 8, 23, 59, 59)),
        DateTime(2026, 3, 8),
      );
    });

    test('is idempotent', () {
      final d = dateOnly(DateTime(2026, 7, 4, 13));
      expect(dateOnly(d), d);
    });
  });

  group('addDays', () {
    test('rolls over month and year boundaries', () {
      expect(addDays(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 1));
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });

    test('handles leap years', () {
      expect(addDays(DateTime(2028, 2, 28), 1), DateTime(2028, 2, 29));
      expect(addDays(DateTime(2026, 2, 28), 1), DateTime(2026, 3, 1));
    });

    test('keeps the wall-clock time of day across a DST transition', () {
      // US spring-forward 2026 is March 8th; the day before at 09:00 plus two
      // days must still read 09:00, not 08:00 or 10:00.
      final before = DateTime(2026, 3, 7, 9);
      final after = addDays(before, 2);
      expect(after.hour, 9);
      expect(after.day, 9);
    });

    test('an autumn transition keeps the hour too', () {
      // US fall-back 2026 is November 1st.
      final before = DateTime(2026, 10, 31, 9);
      final after = addDays(before, 2);
      expect(after.hour, 9);
      expect(after.day, 2);
      expect(after.month, 11);
    });

    test('zero is a no-op and steps compose', () {
      final d = DateTime(2026, 5, 20, 8, 30);
      expect(addDays(d, 0), d);
      expect(addDays(addDays(d, 3), 4), addDays(d, 7));
    });
  });

  group('daysBetween', () {
    test('counts whole days and is signed', () {
      expect(daysBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 8)), 7);
      expect(daysBetween(DateTime(2026, 1, 8), DateTime(2026, 1, 1)), -7);
      expect(daysBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 1)), 0);
    });

    test('ignores the time of day', () {
      expect(
        daysBetween(DateTime(2026, 1, 1, 23), DateTime(2026, 1, 2, 1)),
        1,
      );
    });

    test('is exact across a spring-forward', () {
      // The naive `difference(...).inDays` reports 6 here in a DST zone.
      expect(daysBetween(DateTime(2026, 3, 5), DateTime(2026, 3, 12)), 7);
      expect(daysBetween(DateTime(2026, 3, 7), DateTime(2026, 3, 8)), 1);
    });

    test('is exact across a fall-back', () {
      expect(daysBetween(DateTime(2026, 10, 29), DateTime(2026, 11, 5)), 7);
      expect(daysBetween(DateTime(2026, 10, 31), DateTime(2026, 11, 1)), 1);
    });

    test('agrees with addDays for any step', () {
      final start = DateTime(2026, 3, 1, 14);
      for (final n in [1, 5, 7, 14, 30, 90, 365]) {
        expect(daysBetween(start, addDays(start, n)), n, reason: 'step $n');
      }
    });
  });

  group('weekIndexOf', () {
    test('the anchor Monday is week zero', () {
      expect(weekIndexOf(DateTime(1970, 1, 5)), 0);
    });

    test('every day of one week shares an index', () {
      // 2026-03-02 is a Monday, spanning the US spring-forward on the 8th.
      final monday = DateTime(2026, 3, 2);
      final expected = weekIndexOf(monday);
      for (var i = 0; i < 7; i++) {
        expect(weekIndexOf(addDays(monday, i)), expected, reason: 'day $i');
      }
      // The next Monday starts a new week.
      expect(weekIndexOf(addDays(monday, 7)), expected + 1);
    });

    test('increments by exactly one per week over a year', () {
      var d = DateTime(2026, 1, 5); // a Monday
      var previous = weekIndexOf(d);
      for (var i = 0; i < 52; i++) {
        d = addDays(d, 7);
        final current = weekIndexOf(d);
        expect(current, previous + 1, reason: 'week $i');
        previous = current;
      }
    });

    test('goes negative before the anchor without skipping', () {
      expect(weekIndexOf(DateTime(1969, 12, 29)), -1);
      expect(weekIndexOf(DateTime(1970, 1, 4)), -1); // the Sunday before
    });
  });

  group('startOfWeek', () {
    test('lands on Monday midnight', () {
      for (var i = 0; i < 7; i++) {
        final d = addDays(DateTime(2026, 3, 2, 15, 30), i);
        final start = startOfWeek(d);
        expect(start.weekday, DateTime.monday, reason: 'offset $i');
        expect(start.hour, 0);
        expect(start, DateTime(2026, 3, 2));
      }
    });

    test('a Monday is its own week start', () {
      expect(startOfWeek(DateTime(2026, 3, 2, 9)), DateTime(2026, 3, 2));
    });

    test('consecutive week starts are exactly seven days apart', () {
      final a = startOfWeek(DateTime(2026, 3, 4));
      final b = startOfWeek(DateTime(2026, 3, 11));
      expect(daysBetween(a, b), 7);
    });
  });
}
