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

void main() {
  setUp(() => _day = 0);

  group('TreeHealthService.evaluate', () {
    test('an empty ledger sits at the baseline and reads as empty', () {
      final health = TreeHealthService.evaluate(const []);
      expect(health.score, TreeHealthService.baseline);
      expect(health.tier, TreeHealthTier.steady);
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
      expect(health.score, lessThan(TreeHealthService.baseline));
      expect(health.tier, TreeHealthTier.wilting);
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
      expect(recovered.tier.index,
          greaterThanOrEqualTo(TreeHealthTier.flourishing.index));
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
    test('boundaries land in the expected tier', () {
      expect(TreeHealthService.tierFor(0), TreeHealthTier.barren);
      expect(TreeHealthService.tierFor(19.9), TreeHealthTier.barren);
      expect(TreeHealthService.tierFor(20), TreeHealthTier.wilting);
      expect(TreeHealthService.tierFor(39.9), TreeHealthTier.wilting);
      expect(TreeHealthService.tierFor(40), TreeHealthTier.steady);
      expect(TreeHealthService.tierFor(59.9), TreeHealthTier.steady);
      expect(TreeHealthService.tierFor(60), TreeHealthTier.flourishing);
      expect(TreeHealthService.tierFor(84.9), TreeHealthTier.flourishing);
      expect(TreeHealthService.tierFor(85), TreeHealthTier.radiant);
      expect(TreeHealthService.tierFor(100), TreeHealthTier.radiant);
    });
  });
}
