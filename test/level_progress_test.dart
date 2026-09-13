import 'package:flutter_test/flutter_test.dart';
import 'package:budget_app_project/services/tree_health_service.dart';

TreeHealth _h({
  required double score,
  PrestigeTier? prestige,
  double prestigeDays = 0,
}) =>
    TreeHealth(
      score: score,
      tier: TreeHealthService.tierFor(score),
      earnedPrestige: prestige,
      prestigeDays: prestigeDays,
      currentStreak: 0,
      bestStreak: 0,
      missedRecent: 0,
      delta: 0,
      isEmpty: false,
    );

void main() {
  test('score band fills toward the next tier', () {
    // holding is 39..51; the next band (leafing) starts at 52.
    final p = _h(score: 45).level;
    expect(p.inDays, isFalse);
    expect(p.nextTier, TreeHealthTier.leafing);
    expect(p.toNext, 52 - 45);
    expect(p.fraction, closeTo((45 - 39) / (52 - 39), 1e-9));
    expect(p.atMax, isFalse);
  });

  test('the very bottom starts empty', () {
    final p = _h(score: 0).level;
    expect(p.fraction, 0);
    expect(p.nextTier, TreeHealthTier.sparse);
    expect(p.toNext, 13);
  });

  test('radiant with no prestige climbs by days toward the first prestige', () {
    // score >= 90 but no prestige earned yet -> not showing prestige.
    final p = _h(score: 95, prestigeDays: 12).level;
    expect(p.inDays, isTrue);
    expect(p.nextPrestige, PrestigeTier.blossoming);
    final target = PrestigeTier.blossoming.days;
    expect(p.toNext, target - 12);
    expect(p.fraction, closeTo(12 / target, 1e-9));
  });

  test('within the prestige tiers, fills by days toward the next', () {
    final cur = PrestigeTier.blossoming;
    final next = PrestigeTier.fruiting;
    final days = cur.days + (next.days - cur.days) / 2; // exactly halfway
    final p = _h(score: 95, prestige: cur, prestigeDays: days).level;
    expect(p.inDays, isTrue);
    expect(p.nextPrestige, next);
    expect(p.fraction, closeTo(0.5, 1e-9));
  });

  test('ruby is the max level', () {
    final p = _h(score: 99, prestige: PrestigeTier.ruby, prestigeDays: 9999)
        .level;
    expect(p.atMax, isTrue);
    expect(p.fraction, 1);
    expect(p.nextTier, isNull);
    expect(p.nextPrestige, isNull);
  });

  test('a lapsed prestige rank shows the score climb, not prestige', () {
    // Earned ruby but score fell to 40 -> not showing prestige, so the level
    // bar reflects the score-tier climb back up.
    final p = _h(score: 40, prestige: PrestigeTier.ruby, prestigeDays: 9999)
        .level;
    expect(p.inDays, isFalse);
    expect(p.nextTier, TreeHealthTier.leafing); // 40 is in holding (39..51)
    expect(p.atMax, isFalse);
  });
}
