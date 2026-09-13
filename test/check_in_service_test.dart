// Covers the check-in signal: calendar-correct pay-date enumeration, the
// derive-pending / persist-only-resolved rule, the install epoch that stops the
// feature debuting with a backlog, and the grace window.
//
// Supabase is unconfigured in tests, so the repositories run purely off the
// shared_preferences cache and every write here is exercised for real.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/data/calendar.dart';
import 'package:budget_app_project/data/rhythm.dart';
import 'package:budget_app_project/data/water_cadence.dart';
import 'package:budget_app_project/models/budget_model.dart';
import 'package:budget_app_project/models/check_in.dart';
import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/budget_repository.dart';
import 'package:budget_app_project/services/check_in_repository.dart';
import 'package:budget_app_project/services/check_in_service.dart';
import 'package:budget_app_project/services/goal_repository.dart';
import 'package:budget_app_project/services/pay_scheduler.dart';

BudgetModel budgetWith({
  required Rhythm rhythm,
  required DateTime firstPay,
  String id = 'b1',
  String name = 'Rent Tree',
  DateTime? savedAt,
}) =>
    BudgetModel(
      id: id,
      budgetName: name,
      incomeSources: [IncomeSource(name: 'Wage', amount: 2000)],
      expenses: [
        ExpenseCategory(name: 'Rent', allocated: 1200, emoji: 'home'),
        ExpenseCategory(name: 'Food', allocated: 400, emoji: 'restaurant'),
      ],
      savedAt: savedAt ?? firstPay,
      payFrequency: rhythm,
      firstPayDate: firstPay,
    );

/// Pretend the install epoch was stamped [daysAgo] days ago, so a test can
/// exercise slots that predate "now" without the epoch suppressing them. The
/// epoch's own behaviour is covered by its dedicated test, which leaves it
/// unstamped so `epoch()` lands on the current moment.
void seedEpoch({int daysAgo = 400}) {
  SharedPreferences.setMockInitialValues({
    'check_ins_epoch_v1':
        addDays(DateTime.now(), -daysAgo).millisecondsSinceEpoch,
  });
  CheckInService.resetEpochCache();
}

/// Millisecond precision, matching what survives the JSON round trip through
/// the repositories (dates persist as `millisecondsSinceEpoch`).
DateTime nowMs() =>
    DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CheckInService.resetEpochCache();
  });

  group('PayScheduler.payDateAt', () {
    test('monthly walks the calendar instead of drifting by 30 days', () {
      final first = DateTime(2026, 1, 31);
      // The engine's 30-day approximation would land on 27 December here.
      expect(PayScheduler.payDateAt(Rhythm.monthly, first, 11),
          DateTime(2026, 12, 31));
    });

    test('monthly clamps to the last day of a shorter month', () {
      final first = DateTime(2026, 1, 31);
      expect(PayScheduler.payDateAt(Rhythm.monthly, first, 1),
          DateTime(2026, 2, 28));
      expect(PayScheduler.payDateAt(Rhythm.monthly, first, 3),
          DateTime(2026, 4, 30));
    });

    test('weekly and biweekly step exact calendar days', () {
      final first = DateTime(2026, 3, 2);
      expect(PayScheduler.payDateAt(Rhythm.weekly, first, 5),
          DateTime(2026, 4, 6));
      expect(PayScheduler.payDateAt(Rhythm.biWeekly, first, 3),
          DateTime(2026, 4, 13));
    });

    test('semiMonthly alternates between the anchor day and fifteen days on',
        () {
      final first = DateTime(2026, 1, 5);
      expect(PayScheduler.payDateAt(Rhythm.semiMonthly, first, 0),
          DateTime(2026, 1, 5));
      expect(PayScheduler.payDateAt(Rhythm.semiMonthly, first, 1),
          DateTime(2026, 1, 20));
      expect(PayScheduler.payDateAt(Rhythm.semiMonthly, first, 2),
          DateTime(2026, 2, 5));
    });

    test('a custom rhythm with a zero count cannot stall the enumeration', () {
      final first = DateTime(2026, 1, 1);
      const broken = Rhythm.every(0, CadenceUnit.days);
      // Treated as a one-day step rather than returning `first` forever.
      expect(PayScheduler.payDateAt(broken, first, 3), DateTime(2026, 1, 4));
    });
  });

  group('PayScheduler.elapsedPayDates', () {
    test('returns only dates inside the window, oldest first', () {
      final first = DateTime(2026, 1, 1);
      final budget = budgetWith(rhythm: Rhythm.weekly, firstPay: first);
      final dates = PayScheduler.elapsedPayDates(
        budget,
        now: DateTime(2026, 2, 1),
        notBefore: DateTime(2026, 1, 15),
      );
      expect(dates, [
        DateTime(2026, 1, 15),
        DateTime(2026, 1, 22),
        DateTime(2026, 1, 29),
      ]);
    });

    test('keeps only the most recent maxCount when the window is huge', () {
      final first = DateTime(2024, 1, 1);
      final budget = budgetWith(rhythm: Rhythm.weekly, firstPay: first);
      final dates = PayScheduler.elapsedPayDates(
        budget,
        now: DateTime(2026, 1, 1),
        notBefore: first,
        maxCount: 8,
      );
      expect(dates.length, 8);
      expect(dates.last, DateTime(2025, 12, 29));
      expect(dates.first.isBefore(dates.last), isTrue);
    });

    test('is empty when the schedule has not started yet', () {
      final budget =
          budgetWith(rhythm: Rhythm.weekly, firstPay: DateTime(2027, 1, 1));
      expect(
        PayScheduler.elapsedPayDates(
          budget,
          now: DateTime(2026, 1, 1),
          notBefore: DateTime(2026, 1, 1),
        ),
        isEmpty,
      );
    });
  });

  group('CheckInService.pending', () {
    test('derives one slot per elapsed pay date', () async {
      seedEpoch();
      final now = nowMs();
      await BudgetRepository.saveNew(budgetWith(
        rhythm: Rhythm.weekly,
        firstPay: addDays(now, -21),
      ));

      final pending = await CheckInService.pending(now: now);
      // Four slots: three past pay days plus the one that lands today, which
      // is precisely the moment the user is meant to be asked.
      expect(pending.length, 4);
      expect(pending.every((c) => c.kind == CheckInKind.payday), isTrue);
      expect(pending.first.subjectName, 'Rent Tree');
      // Soonest due first.
      expect(pending.first.dueAt.isBefore(pending.last.dueAt), isTrue);
    });

    test('never reaches back before the install epoch', () async {
      // Stamp the epoch first, as a fresh install would.
      final now = nowMs();
      await CheckInService.epoch();

      // A budget whose first pay date is eighteen months in the past.
      await BudgetRepository.saveNew(budgetWith(
        rhythm: Rhythm.monthly,
        firstPay: addDays(now, -550),
        savedAt: addDays(now, -550),
      ));

      final pending = await CheckInService.pending(now: now);
      expect(pending, isEmpty,
          reason: 'an existing budget must not backfill a lapsed backlog');
    });

    test('is idempotent: a resolved slot stops being pending', () async {
      seedEpoch();
      final now = nowMs();
      await BudgetRepository.saveNew(budgetWith(
        rhythm: Rhythm.weekly,
        firstPay: addDays(now, -14),
      ));

      final first = await CheckInService.pending(now: now);
      expect(first.length, 3);

      await CheckInService.confirm(first.first,
          verdict: CheckInVerdict.onTrack);

      final second = await CheckInService.pending(now: now);
      expect(second.length, 2);
      expect(second.map((c) => c.id), isNot(contains(first.first.id)));
    });

    test('skips drafts and budgets with no schedule', () async {
      seedEpoch();
      final now = nowMs();
      final draft = budgetWith(
        rhythm: Rhythm.weekly,
        firstPay: addDays(now, -14),
        id: 'draft',
      )..savedAt = null;
      await BudgetRepository.saveNew(draft);

      expect(await CheckInService.pending(now: now), isEmpty);
    });

    test('derives watering slots from the anchor, not the moving cursor',
        () async {
      seedEpoch();
      final now = nowMs();
      final anchor = addDays(now, -21);
      await GoalRepository.saveNew(Goal(
        id: 'g1',
        name: 'Bike',
        targetAmount: 1000,
        waterAmount: 40,
        waterCadenceIndex: WaterCadence.weekly.index,
        // The cursor has been pushed far into the future by deposits; the
        // anchor is what the slots must come from.
        nextWaterDate: addDays(now, 7),
        waterAnchorDate: anchor,
      ));

      final pending = await CheckInService.pending(now: now);
      // Anchor plus three weekly steps, the last landing today.
      expect(pending.length, 4);
      expect(pending.every((c) => c.kind == CheckInKind.watering), isTrue);
      expect(pending.first.dueAt, anchor);
    });
  });

  group('CheckInService.sync', () {
    test('writes off only slots past their grace window', () async {
      seedEpoch();
      final now = nowMs();
      // Weekly period: grace is half of seven days, so three.
      await BudgetRepository.saveNew(budgetWith(
        rhythm: Rhythm.weekly,
        firstPay: addDays(now, -8),
      ));

      await CheckInService.sync(now: now);

      final stored = await CheckInRepository.loadCached();
      expect(stored.length, 1, reason: 'only the eight-day-old slot lapsed');
      expect(stored.single.missed, isTrue);
      expect(stored.single.isConfirmed, isFalse);

      // The one-day-old slot is still answerable.
      final pending = await CheckInService.pending(now: now);
      expect(pending.length, 1);
      expect(pending.single.dueAt, addDays(now, -1));
    });

    test('running twice does not duplicate or re-write anything', () async {
      seedEpoch();
      final now = nowMs();
      await BudgetRepository.saveNew(budgetWith(
        rhythm: Rhythm.weekly,
        firstPay: addDays(now, -8),
      ));

      await CheckInService.sync(now: now);
      await CheckInService.sync(now: now);

      expect((await CheckInRepository.loadCached()).length, 1);
    });

    test('a confirmation survives a later sweep', () async {
      seedEpoch();
      final now = nowMs();
      await BudgetRepository.saveNew(budgetWith(
        rhythm: Rhythm.weekly,
        firstPay: addDays(now, -8),
      ));

      final slot = (await CheckInService.pending(now: now)).first;
      await CheckInService.confirm(
        slot,
        verdict: CheckInVerdict.slipped,
        actuals: const [
          BranchActual(name: 'Food', planned: 400, actual: 515),
        ],
      );

      await CheckInService.sync(now: now);

      final stored = await CheckInRepository.loadCached();
      final saved = stored.firstWhere((c) => c.id == slot.id);
      expect(saved.missed, isFalse);
      expect(saved.verdict, CheckInVerdict.slipped);
      expect(saved.overspentBranches.single.name, 'Food');
      expect(saved.overspentBranches.single.overspend, closeTo(115, 0.001));
    });
  });

  group('CheckInService.history', () {
    test('returns resolved check-ins oldest first', () async {
      seedEpoch();
      final now = nowMs();
      await BudgetRepository.saveNew(budgetWith(
        rhythm: Rhythm.weekly,
        firstPay: addDays(now, -21),
      ));

      await CheckInService.sync(now: now);
      final history = await CheckInService.history();

      expect(history.length, greaterThanOrEqualTo(2));
      expect(history.every((c) => c.isResolved), isTrue);
      for (var i = 1; i < history.length; i++) {
        expect(history[i - 1].dueAt.isAfter(history[i].dueAt), isFalse);
      }
    });
  });
}
