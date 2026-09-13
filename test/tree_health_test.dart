// Covers the consistency scale behind the tree's appearance.
//
// The score is derived, never stored, so these tests replay ledgers directly
// rather than going through the repositories. What they pin is the *shape* of
// the scale: it rises with answered check-ins, falls faster when they are
// missed, clamps at both ends, and a lapsed user can always climb back.

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/data/calendar.dart';
import 'package:budget_app_project/models/check_in.dart';
import 'package:budget_app_project/services/tree_health_service.dart';

int _day = 0;

/// A resolved check-in, dated so the ledger stays ordered.
CheckIn resolved({CheckInVerdict? verdict, bool missed = false}) {
  final due = addDays(DateTime(2026, 1, 1), _day++);
  return CheckIn(
    kind: CheckInKind.payday,
    subjectId: 'b1',
    subjectName: 'Tree',
    dueAt: due,
    confirmedAt: missed ? null : due,
    verdict: missed ? null : verdict,
    missed: missed,
  );
}

List<CheckIn> repeat(int n, CheckIn Function() make) =>
    List.generate(n, (_) => make());

/// A resolved check-in on an explicit date, for the prestige-clock tests where
/// the calendar spacing between check-ins is what matters.
CheckIn at(DateTime due, {CheckInVerdict? verdict, bool missed = false}) =>
    CheckIn(
      kind: CheckInKind.payday,
      subjectId: 'b1',
      subjectName: 'Tree',
      dueAt: due,
      confirmedAt: missed ? null : due,
      verdict: missed ? null : verdict,
      missed: missed,
    );

final _base = DateTime(2026, 1, 1);
DateTime _at(int day) => addDays(_base, day);
List<CheckIn> _onTrack(Iterable<int> days) =>
    [for (final d in days) at(_at(d), verdict: CheckInVerdict.onTrack)];

void main() {
  setUp(() => _day = 0);

  group('TreeHealthService.evaluate', () {
    test('an empty ledger sits at the baseline and reads as empty', () {
      final health = TreeHealthService.evaluate(const []);
      expect(health.score, TreeHealthService.baseline);
      expect(health.tier, TreeHealthTier.holding);
      expect(health.isEmpty, isTrue);
    });

    test('pending check-ins are not a verdict and do not move the score', () {
      final pending = CheckIn(
        kind: CheckInKind.payday,
        subjectId: 'b1',
        subjectName: 'Tree',
        dueAt: DateTime(2026, 1, 1),
      );
      final health = TreeHealthService.evaluate([pending]);
      expect(health.isEmpty, isTrue);
      expect(health.score, TreeHealthService.baseline);
    });

    test('staying on track climbs to radiant', () {
      final health = TreeHealthService.evaluate(
        repeat(8, () => resolved(verdict: CheckInVerdict.onTrack)),
      );
      expect(health.score, greaterThanOrEqualTo(85));
      expect(health.tier, TreeHealthTier.radiant);
      expect(health.currentStreak, 8);
      expect(health.missedRecent, 0);
    });

    test('missing check-ins walks the tree backwards', () {
      final health = TreeHealthService.evaluate(repeat(3, () => resolved(missed: true)));
      // 50 -> 40 -> 30 -> 20, which is the sparse band under the finer scale.
      expect(health.score, lessThan(TreeHealthService.baseline));
      expect(health.tier, TreeHealthTier.sparse);
      expect(health.currentStreak, 0);
      expect(health.missedRecent, 3);
    });

    test('a miss costs more than an answer earns', () {
      final up = TreeHealthService.evaluate(
        [resolved(verdict: CheckInVerdict.onTrack)],
      ).score;
      final down = TreeHealthService.evaluate([resolved(missed: true)]).score;

      expect(up - TreeHealthService.baseline,
          lessThan(TreeHealthService.baseline - down));
    });

    test('a healthy tree visibly reacts to a lapse', () {
      final thriving = TreeHealthService.evaluate(
        repeat(8, () => resolved(verdict: CheckInVerdict.onTrack)),
      );
      final lapsed = TreeHealthService.evaluate([
        ...repeat(8, () => resolved(verdict: CheckInVerdict.onTrack)),
        ...repeat(3, () => resolved(missed: true)),
      ]);

      expect(lapsed.score, lessThan(thriving.score));
      expect(lapsed.tier.index, lessThan(thriving.tier.index));
      expect(lapsed.delta, isNegative);
    });

    test('a lapsed user can always climb back', () {
      final recovered = TreeHealthService.evaluate([
        ...repeat(6, () => resolved(missed: true)),
        ...repeat(8, () => resolved(verdict: CheckInVerdict.onTrack)),
      ]);
      // 6 misses bottom out at 0, then 8 answers climb back to the leafing band.
      expect(recovered.tier.index,
          greaterThanOrEqualTo(TreeHealthTier.leafing.index));
      expect(recovered.delta, isPositive);
    });

    test('clamps at both ends however long the run', () {
      final floor =
          TreeHealthService.evaluate(repeat(40, () => resolved(missed: true)));
      final ceiling = TreeHealthService.evaluate(
        repeat(40, () => resolved(verdict: CheckInVerdict.onTrack)),
      );
      expect(floor.score, 0);
      expect(floor.tier, TreeHealthTier.barren);
      expect(ceiling.score, 100);
      expect(ceiling.tier, TreeHealthTier.radiant);
    });

    test('slipping still counts for something; going off plan does not', () {
      final slipped = TreeHealthService.evaluate(
        repeat(4, () => resolved(verdict: CheckInVerdict.slipped)),
      );
      final offPlan = TreeHealthService.evaluate(
        repeat(4, () => resolved(verdict: CheckInVerdict.offPlan)),
      );
      expect(slipped.score, greaterThan(TreeHealthService.baseline));
      expect(offPlan.score, lessThan(TreeHealthService.baseline));
      // Both were answered, so neither breaks the streak.
      expect(slipped.currentStreak, 4);
      expect(offPlan.currentStreak, 4);
    });

    test('only the most recent window counts', () {
      // Ancient misses beyond the window must not drag the present down.
      final health = TreeHealthService.evaluate([
        ...repeat(30, () => resolved(missed: true)),
        ...repeat(TreeHealthService.historyWindow,
            () => resolved(verdict: CheckInVerdict.onTrack)),
      ]);
      expect(health.score, 100);
    });

    test('best streak survives a later break', () {
      final health = TreeHealthService.evaluate([
        ...repeat(5, () => resolved(verdict: CheckInVerdict.onTrack)),
        resolved(missed: true),
        ...repeat(2, () => resolved(verdict: CheckInVerdict.onTrack)),
      ]);
      expect(health.bestStreak, 5);
      expect(health.currentStreak, 2);
    });
  });

  group('TreeHealthService.tierFor', () {
    test('the eight bands land in the expected tier', () {
      expect(TreeHealthService.tierFor(0), TreeHealthTier.barren);
      expect(TreeHealthService.tierFor(12), TreeHealthTier.barren);
      expect(TreeHealthService.tierFor(13), TreeHealthTier.sparse);
      expect(TreeHealthService.tierFor(25), TreeHealthTier.sparse);
      expect(TreeHealthService.tierFor(26), TreeHealthTier.wilting);
      expect(TreeHealthService.tierFor(38), TreeHealthTier.wilting);
      expect(TreeHealthService.tierFor(39), TreeHealthTier.holding);
      expect(TreeHealthService.tierFor(51), TreeHealthTier.holding);
      expect(TreeHealthService.tierFor(52), TreeHealthTier.leafing);
      expect(TreeHealthService.tierFor(64), TreeHealthTier.leafing);
      expect(TreeHealthService.tierFor(65), TreeHealthTier.full);
      expect(TreeHealthService.tierFor(77), TreeHealthTier.full);
      expect(TreeHealthService.tierFor(78), TreeHealthTier.flourishing);
      expect(TreeHealthService.tierFor(89), TreeHealthTier.flourishing);
      expect(TreeHealthService.tierFor(90), TreeHealthTier.radiant);
      expect(TreeHealthService.tierFor(100), TreeHealthTier.radiant);
    });
  });

  group('prestige clock', () {
    test('never radiant means no prestige days', () {
      // One answer lifts the score to 58, which never crosses 90.
      final days = TreeHealthService.prestigeDaysAtRadiant(
        [at(_at(0), verdict: CheckInVerdict.onTrack)],
        now: _at(100),
      );
      expect(days, 0);
      expect(TreeHealthService.prestigeFor(days), isNull);
    });

    test('calendar time held at radiant accrues, and earns a tier', () {
      // Five answers reach 90 by day 4; a sixth on day 34 keeps it radiant, so
      // the day 4 to day 34 interval counts for exactly 30 days.
      final ledger = _onTrack([0, 1, 2, 3, 4, 34]);
      final days =
          TreeHealthService.prestigeDaysAtRadiant(ledger, now: _at(34));
      expect(days, 30);
      expect(TreeHealthService.prestigeFor(days), PrestigeTier.blossoming);
    });

    test('dropping below 90 pauses the clock without un-counting', () {
      // Radiant from day 4, held to day 34 (30 days), then a miss on day 40
      // drops below 90. The day 34 to 40 stretch is still radiant (six days);
      // everything after the drop accrues nothing however far "now" is.
      final ledger = [
        ..._onTrack([0, 1, 2, 3, 4, 34]),
        at(_at(40), missed: true),
      ];
      final days =
          TreeHealthService.prestigeDaysAtRadiant(ledger, now: _at(400));
      expect(days, 36);
      // Already past the 30 day mark, so the tier is held despite the lapse.
      expect(TreeHealthService.prestigeFor(days), PrestigeTier.blossoming);
    });

    test('a radiant streak shows its prestige tree', () {
      final h = TreeHealthService.evaluate(
        _onTrack([0, 1, 2, 3, 4, 34, 35]),
        now: _at(35),
      );
      expect(h.earnedPrestige, PrestigeTier.blossoming);
      expect(h.score, greaterThanOrEqualTo(90));
      expect(h.showsPrestige, isTrue);
      expect(h.spriteKey, 'blossoming');
    });

    test('a lapsed prestige tree keeps its rank but shows the score tier', () {
      final h = TreeHealthService.evaluate(
        [
          ..._onTrack([0, 1, 2, 3, 4, 34, 35]),
          at(_at(36), missed: true),
          at(_at(37), missed: true),
          at(_at(38), missed: true),
        ],
        now: _at(38),
      );
      // The rank is not lost...
      expect(h.earnedPrestige, PrestigeTier.blossoming);
      // ...but with the score below 90 the honest score tier is on show.
      expect(h.score, lessThan(90));
      expect(h.showsPrestige, isFalse);
      expect(h.spriteKey, isNot('blossoming'));
      expect(h.spriteKey, h.tier.name);
    });
  });
}
