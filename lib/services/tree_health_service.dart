import 'dart:math' as math;

import '../data/calendar.dart';
import '../models/check_in.dart';
import 'check_in_service.dart';

/// The eight consistency tiers, driven by the 0 to 100 score. Ordered lowest to
/// highest; `.name` doubles as the sprite key (see `assets/status_trees/`).
enum TreeHealthTier {
  barren,
  sparse,
  wilting,
  holding,
  leafing,
  full,
  flourishing,
  radiant,
}

extension TreeHealthTierX on TreeHealthTier {
  /// 0 (barren) to 1 (radiant) — a rough fullness fraction for progress bars.
  double get fraction => index / (TreeHealthTier.values.length - 1);
}

/// The eight duration-earned prestige tiers, unlocked by holding a radiant
/// (90+) score for a cumulative number of days. Ordered by the days they take;
/// `.name` doubles as the sprite key.
enum PrestigeTier {
  blossoming,
  fruiting,
  ancient,
  silver,
  gilded,
  diamond,
  amethyst,
  ruby,
}

extension PrestigeTierX on PrestigeTier {
  /// Cumulative days at 90+ required to reach this tier.
  int get days {
    switch (this) {
      case PrestigeTier.blossoming:
        return 30;
      case PrestigeTier.fruiting:
        return 60;
      case PrestigeTier.ancient:
        return 120;
      case PrestigeTier.silver:
        return 180;
      case PrestigeTier.gilded:
        return 300;
      case PrestigeTier.diamond:
        return 450;
      case PrestigeTier.amethyst:
        return 600;
      case PrestigeTier.ruby:
        return 730;
    }
  }
}

class TreeHealth {
  /// 0 to 100. Never stored; always replayed from the check-in ledger.
  final double score;

  /// The score tier for [score]. Always one of the eight consistency tiers,
  /// even when a prestige tree is the one on show.
  final TreeHealthTier tier;

  /// The highest prestige tier the user has earned, or null. Earned by
  /// cumulative days at 90+ and, because that total only ever grows, never
  /// lost once reached even if the score later dips.
  final PrestigeTier? earnedPrestige;

  /// Cumulative calendar days the score has spent at or above the radiant
  /// threshold, over the whole ledger. What the prestige tiers are earned on.
  final double prestigeDays;

  /// Consecutive answered check-ins at the end of the ledger. Broken by a miss.
  final int currentStreak;
  final int bestStreak;

  /// How many of the last ten check-ins went unanswered.
  final int missedRecent;

  /// How far the score moved over the most recent five check-ins, so the UI
  /// can say "up 12 this fortnight" rather than just naming a number.
  final double delta;

  /// True when nothing has been answered yet — the UI shows an invitation
  /// rather than a verdict.
  final bool isEmpty;

  const TreeHealth({
    required this.score,
    required this.tier,
    required this.earnedPrestige,
    required this.prestigeDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.missedRecent,
    required this.delta,
    required this.isEmpty,
  });

  static const fresh = TreeHealth(
    score: TreeHealthService.baseline,
    tier: TreeHealthTier.holding,
    earnedPrestige: null,
    prestigeDays: 0,
    currentStreak: 0,
    bestStreak: 0,
    missedRecent: 0,
    delta: 0,
    isEmpty: true,
  );

  /// 0..1, for painters and progress bars.
  double get fraction => (score / 100).clamp(0.0, 1.0);

  /// A prestige tree is only shown while the user is actually radiant: the tree
  /// is an honest read on how you are doing now, so a lapsed Ruby shows the
  /// score tier it has fallen to. The rank itself is kept (see [earnedPrestige])
  /// and the prestige tree returns the moment the score climbs back to 90+.
  bool get showsPrestige =>
      earnedPrestige != null && score >= TreeHealthService.radiantThreshold;

  /// Which of the sixteen sprites to draw. Matches a file in
  /// `assets/status_trees/<key>.png`.
  String get spriteKey =>
      showsPrestige ? earnedPrestige!.name : tier.name;
}

/// Turns the check-in ledger into a single consistency signal.
///
/// Modelled on the way Opal's gem responds to focus streaks: staying consistent
/// grows it, lapsing walks it back. The scale is deliberately **asymmetric** —
/// a missed check-in costs more than an answered one earns — because a tree
/// that only ever creeps upward stops meaning anything. It is not so steep that
/// a lapsed user can never recover: roughly four good check-ins undo three
/// misses, so the way back is always visible.
///
/// The score is **derived, never stored**. Replaying the ledger from a fixed
/// baseline every time means two devices always agree, and there is no
/// persisted number that can drift out of step with the history behind it. The
/// same is true of the prestige clock: it is the calendar time the replayed
/// score spent at 90+, so it too needs nothing persisted.
class TreeHealthService {
  TreeHealthService._();

  /// Where a user with no history starts: mid-scale, neither thriving nor dying.
  static const double baseline = 50;

  /// The floor of the top (radiant) band. Prestige days accrue only at or above
  /// this score.
  static const double radiantThreshold = 90;

  static const double _onTrack = 8;
  static const double _slipped = 3;
  static const double _offPlan = -2;
  static const double _missed = -10;

  /// How far back the **score** replay reaches. Long enough that a good run
  /// feels earned, short enough that ancient history stops dragging on the
  /// present. Prestige days are measured over the full ledger, not this window.
  static const int historyWindow = 60;

  /// A limit large enough to pull the entire resolved ledger for the prestige
  /// clock (two years of even daily check-ins is well under this).
  static const int prestigeWindow = 5000;

  /// Score a ledger. [history] must be oldest first; anything unresolved is
  /// ignored (a pending check-in is not yet a verdict about anything). Pass the
  /// **full** ledger, not just the score window, so the prestige clock can see
  /// the whole timeline.
  static TreeHealth evaluate(List<CheckIn> history, {DateTime? now}) {
    final resolved = history.where((c) => c.isResolved).toList();
    if (resolved.isEmpty) return TreeHealth.fresh;

    final window = resolved.length <= historyWindow
        ? resolved
        : resolved.sublist(resolved.length - historyWindow);

    var score = baseline;
    // The score as of five check-ins from the end, for the delta readout.
    var scoreBeforeRecent = baseline;
    final deltaFrom = math.max(0, window.length - 5);

    var streak = 0;
    var best = 0;

    for (var i = 0; i < window.length; i++) {
      if (i == deltaFrom) scoreBeforeRecent = score;

      final c = window[i];
      score = (score + _weightOf(c)).clamp(0.0, 100.0);

      if (c.isConfirmed) {
        streak++;
        best = math.max(best, streak);
      } else {
        streak = 0;
      }
    }

    final recent = window.length <= 10
        ? window
        : window.sublist(window.length - 10);

    final prestigeDays = prestigeDaysAtRadiant(resolved, now: now);

    return TreeHealth(
      score: score,
      tier: tierFor(score),
      earnedPrestige: prestigeFor(prestigeDays),
      prestigeDays: prestigeDays,
      currentStreak: streak,
      bestStreak: best,
      missedRecent: recent.where((c) => c.missed).length,
      delta: score - scoreBeforeRecent,
      isEmpty: false,
    );
  }

  static double _weightOf(CheckIn c) {
    if (c.missed) return _missed;
    switch (c.verdict) {
      case CheckInVerdict.onTrack:
        return _onTrack;
      case CheckInVerdict.slipped:
        return _slipped;
      case CheckInVerdict.offPlan:
        return _offPlan;
      case null:
        // Confirmed with no verdict shouldn't happen, but a half-written row
        // must not silently count as a miss.
        return 0;
    }
  }

  static TreeHealthTier tierFor(double score) {
    if (score <= 12) return TreeHealthTier.barren;
    if (score <= 25) return TreeHealthTier.sparse;
    if (score <= 38) return TreeHealthTier.wilting;
    if (score <= 51) return TreeHealthTier.holding;
    if (score <= 64) return TreeHealthTier.leafing;
    if (score <= 77) return TreeHealthTier.full;
    if (score <= 89) return TreeHealthTier.flourishing;
    return TreeHealthTier.radiant;
  }

  /// The highest prestige tier reached by [days] cumulative days at 90+, or
  /// null before the first one is earned.
  static PrestigeTier? prestigeFor(double days) {
    PrestigeTier? earned;
    for (final p in PrestigeTier.values) {
      if (days >= p.days) earned = p;
    }
    return earned;
  }

  /// Cumulative calendar days the running score spends at or above
  /// [radiantThreshold], replayed over the **full** resolved [history] (oldest
  /// first). Each interval between consecutive check-ins is credited when the
  /// score in force during it is radiant; the final interval runs to [now].
  ///
  /// Intervals below the threshold simply contribute nothing, which is exactly
  /// "dropping below 90 pauses progress". Past intervals never un-count, so the
  /// total only ever grows and a prestige tier, once reached, is never lost.
  static double prestigeDaysAtRadiant(List<CheckIn> history, {DateTime? now}) {
    final resolved = history.where((c) => c.isResolved).toList();
    if (resolved.isEmpty) return 0;
    final end = now ?? DateTime.now();

    var score = baseline;
    var total = 0.0;
    for (var i = 0; i < resolved.length; i++) {
      score = (score + _weightOf(resolved[i])).clamp(0.0, 100.0);
      final from = resolved[i].dueAt;
      final to = i + 1 < resolved.length ? resolved[i + 1].dueAt : end;
      if (score >= radiantThreshold) {
        final span = daysBetween(from, to);
        if (span > 0) total += span;
      }
    }
    return total;
  }

  /// Read the ledger and score it. Pulls the full ledger so the prestige clock
  /// sees the whole timeline, not just the score window.
  static Future<TreeHealth> current() async =>
      evaluate(await CheckInService.history(limit: prestigeWindow));
}
