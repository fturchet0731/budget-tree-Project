import 'dart:math' as math;

import '../models/check_in.dart';
import 'check_in_service.dart';

/// How healthy the user's tree looks, on a 0 to 100 scale.
enum TreeHealthTier { barren, wilting, steady, flourishing, radiant }

extension TreeHealthTierX on TreeHealthTier {
  /// 0 (barren) to 1 (radiant) — the fraction the painters use to decide how
  /// full and how green a tree is drawn.
  double get fraction => index / (TreeHealthTier.values.length - 1);
}

class TreeHealth {
  /// 0 to 100. Never stored; always replayed from the check-in ledger.
  final double score;
  final TreeHealthTier tier;

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
    required this.currentStreak,
    required this.bestStreak,
    required this.missedRecent,
    required this.delta,
    required this.isEmpty,
  });

  static const fresh = TreeHealth(
    score: TreeHealthService.baseline,
    tier: TreeHealthTier.steady,
    currentStreak: 0,
    bestStreak: 0,
    missedRecent: 0,
    delta: 0,
    isEmpty: true,
  );

  /// 0..1, for painters and progress bars.
  double get fraction => (score / 100).clamp(0.0, 1.0);
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
/// persisted number that can drift out of step with the history behind it.
class TreeHealthService {
  TreeHealthService._();

  /// Where a user with no history starts: mid-scale, neither thriving nor dying.
  static const double baseline = 50;

  static const double _onTrack = 8;
  static const double _slipped = 3;
  static const double _offPlan = -2;
  static const double _missed = -10;

  /// How far back the replay reaches. Long enough that a good run feels earned,
  /// short enough that ancient history stops dragging on the present.
  static const int historyWindow = 60;

  /// Score a ledger. [history] must be oldest first; anything unresolved is
  /// ignored (a pending check-in is not yet a verdict about anything).
  static TreeHealth evaluate(List<CheckIn> history) {
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

    return TreeHealth(
      score: score,
      tier: tierFor(score),
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
    if (score < 20) return TreeHealthTier.barren;
    if (score < 40) return TreeHealthTier.wilting;
    if (score < 60) return TreeHealthTier.steady;
    if (score < 85) return TreeHealthTier.flourishing;
    return TreeHealthTier.radiant;
  }

  /// Read the ledger and score it.
  static Future<TreeHealth> current() async =>
      evaluate(await CheckInService.history(limit: historyWindow));
}
