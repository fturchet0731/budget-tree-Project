import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/calendar.dart';
import '../data/water_cadence.dart';
import '../models/budget_model.dart';
import '../models/check_in.dart';
import '../models/goal_model.dart';
import 'achievement_service.dart';
import 'budget_repository.dart';
import 'check_in_repository.dart';
import 'goal_repository.dart';
import 'pay_scheduler.dart';

/// Derives, resolves and reads back check-ins.
///
/// **Pending check-ins are never stored.** They're computed on every call from
/// the budgets' pay schedules and the goals' watering anchors, and a slot is
/// pending exactly when no resolved row already claims its id. That single
/// decision removes a whole class of bugs: [SyncedStore.update] replaces a row
/// wholesale and `pull()` overwrites the cache after flushing the offline
/// queue, so a re-derived pending row would happily erase another device's
/// confirmation. Here the only write is monotonic (pending becomes confirmed or
/// missed, never the reverse), so replays are idempotent and there is nothing
/// to merge.
///
/// It also gives the right answer when a user edits a budget's pay schedule:
/// the pending set re-derives against the new schedule, while the history of
/// what they already answered stays exactly as it was.
class CheckInService {
  CheckInService._();

  /// Stamped the first time [sync] ever runs on this install.
  ///
  /// Generation never reaches back before it. Without this the create wizard's
  /// two-year-back date picker means an existing user's first launch backfills
  /// a fistful of long-lapsed check-ins, every one of them immediately missed,
  /// and the feature debuts with a dead tree the user did nothing to deserve.
  static const _kEpoch = 'check_ins_epoch_v1';

  /// How many periods back generation will ever reach, per subject.
  static const _maxBackfill = 8;

  /// Guards overlapping sweeps. [PayScheduler]'s own flag doesn't cover this,
  /// and `flushAndPull` fires on both resume and connectivity change, which
  /// routinely land together.
  static bool _syncing = false;

  static DateTime? _epochCache;

  /// The install epoch, stamped on first use.
  static Future<DateTime> epoch() async {
    final cached = _epochCache;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_kEpoch);
    if (stored != null) {
      return _epochCache = DateTime.fromMillisecondsSinceEpoch(stored);
    }
    final now = DateTime.now();
    await prefs.setInt(_kEpoch, now.millisecondsSinceEpoch);
    return _epochCache = now;
  }

  /// Test seam: forget the memoised epoch.
  @visibleForTesting
  static void resetEpochCache() => _epochCache = null;

  // ── Deriving ────────────────────────────────────────────────

  /// How long after [dueAt] the user still gets to answer before the slot is
  /// written off as missed. Half a period feels proportionate (a weekly budget
  /// shouldn't get the same slack as a monthly one) but is clamped so it's
  /// never punishing and never open-ended.
  static Duration graceFor(Duration period) {
    final half = period.inDays ~/ 2;
    return Duration(days: half.clamp(2, 7));
  }

  static bool _graceLapsed(CheckIn c, Duration period, DateTime now) =>
      now.isAfter(c.dueAt.add(graceFor(period)));

  /// The period length backing [c]'s grace window.
  static Duration _periodFor(
    CheckIn c,
    Map<String, BudgetModel> budgets,
    Map<String, Goal> goals,
  ) {
    if (c.kind == CheckInKind.payday) {
      return budgets[c.subjectId]?.payFrequency?.periodLength ??
          const Duration(days: 14);
    }
    final cadence = goals[c.subjectId]?.waterCadence;
    return Duration(days: cadence?.days ?? 14);
  }

  /// Every check-in slot that has come due and has no answer yet, soonest due
  /// first. Includes slots whose grace has already lapsed but that [sync]
  /// hasn't written off yet, so a user who opens the app late can still answer.
  static Future<List<CheckIn>> pending({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final epochAt = await epoch();

    // Cache-only: loadAll() fires an unawaited pull() that would overwrite the
    // cache underneath the sweep that usually calls this.
    final resolved = {
      for (final c in await CheckInRepository.loadCached()) c.id,
    };
    final budgets = await BudgetRepository.loadCached();
    final goals = await GoalRepository.loadCached();

    final out = <CheckIn>[];

    for (final budget in budgets) {
      // Same gate as the pay sweep: drafts and unscheduled budgets have no
      // pay days to ask about.
      if (budget.savedAt == null ||
          budget.payFrequency == null ||
          budget.firstPayDate == null) {
        continue;
      }
      final notBefore = _latest([
        budget.firstPayDate!,
        budget.savedAt!,
        epochAt,
      ]);
      final dates = PayScheduler.elapsedPayDates(
        budget,
        now: at,
        notBefore: notBefore,
        maxCount: _maxBackfill,
      );
      for (final due in dates) {
        final id = CheckIn.idFor(CheckInKind.payday, budget.id, due);
        if (resolved.contains(id)) continue;
        out.add(CheckIn(
          kind: CheckInKind.payday,
          subjectId: budget.id,
          subjectName: budget.budgetName,
          dueAt: due,
        ));
      }
    }

    for (final goal in goals) {
      final cadence = goal.waterCadence;
      final anchor = goal.waterAnchorDate;
      if (cadence == null || anchor == null || goal.isCompleted) continue;
      for (final due in _wateringSlots(
        anchor: anchor,
        stepDays: cadence.days,
        now: at,
        notBefore: _latest([anchor, epochAt]),
      )) {
        final id = CheckIn.idFor(CheckInKind.watering, goal.id, due);
        if (resolved.contains(id)) continue;
        out.add(CheckIn(
          kind: CheckInKind.watering,
          subjectId: goal.id,
          subjectName: goal.name,
          dueAt: due,
        ));
      }
    }

    out.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return out;
  }

  /// Watering slots in `[notBefore, now]`, oldest first, capped at
  /// [_maxBackfill]. Mirrors [PayScheduler.elapsedPayDates] but the step is a
  /// plain day count, so it walks the calendar directly.
  static List<DateTime> _wateringSlots({
    required DateTime anchor,
    required int stepDays,
    required DateTime now,
    required DateTime notBefore,
  }) {
    final step = math.max(1, stepDays);
    var n = math.max(0, (daysBetween(anchor, notBefore) / step).floor() - 1);
    final out = <DateTime>[];
    for (var i = 0; i < 512; i++, n++) {
      final date = addDays(anchor, step * n);
      if (date.isAfter(now)) break;
      if (!date.isBefore(notBefore)) out.add(date);
    }
    if (out.length <= _maxBackfill) return out;
    return out.sublist(out.length - _maxBackfill);
  }

  static DateTime _latest(List<DateTime> dates) =>
      dates.reduce((a, b) => a.isAfter(b) ? a : b);

  // ── Resolving ───────────────────────────────────────────────

  /// Write off every pending check-in whose grace window has lapsed.
  ///
  /// This is the service's *only* unprompted write, and it only ever moves a
  /// slot from pending to missed. Safe to call repeatedly.
  static Future<void> sync({DateTime? now}) async {
    if (_syncing) return;
    _syncing = true;
    try {
      final at = now ?? DateTime.now();
      final budgets = {
        for (final b in await BudgetRepository.loadCached()) b.id: b,
      };
      final goals = {
        for (final g in await GoalRepository.loadCached()) g.id: g,
      };
      for (final slot in await pending(now: at)) {
        final period = _periodFor(slot, budgets, goals);
        if (!_graceLapsed(slot, period, at)) continue;
        try {
          slot.missed = true;
          await CheckInRepository.saveNew(slot);
        } catch (e) {
          debugPrint('CheckInService.sync(${slot.id}) failed: $e');
        }
      }
    } finally {
      _syncing = false;
    }
  }

  /// Record the user's answer. [actuals] may be empty: the per-branch amounts
  /// are optional by design, so the one-tap path stays one tap.
  static Future<void> confirm(
    CheckIn checkIn, {
    required CheckInVerdict verdict,
    List<BranchActual> actuals = const [],
    DateTime? at,
  }) async {
    checkIn.verdict = verdict;
    checkIn.confirmedAt = at ?? DateTime.now();
    checkIn.actuals = List.of(actuals);
    // A confirmation always wins over a write-off, including one this device
    // already made: answering late is still answering.
    checkIn.missed = false;
    await CheckInRepository.saveNew(checkIn);
    await AchievementService.evaluateAndUnlock();
  }

  // ── Reading back ────────────────────────────────────────────

  /// Resolved check-ins, oldest first, capped at [limit]. The ledger tree
  /// health and every consistency chart are built from.
  static Future<List<CheckIn>> history({int limit = 60}) async {
    final all = await CheckInRepository.loadCached();
    final resolved = all.where((c) => c.isResolved).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    if (resolved.length <= limit) return resolved;
    return resolved.sublist(resolved.length - limit);
  }
}
