import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations_resolver.dart';
import '../models/goal_model.dart';
import 'ai_coach_service.dart';
import 'app_settings.dart';
import 'auth_service.dart';
import 'budget_repository.dart';
import 'comparison_service.dart';
import 'goal_repository.dart';
import 'notification_service.dart';
import 'streak_service.dart';
import 'supabase_config.dart';

/// A stored AI reflection summary.
class Reflection {
  final String period; // weekly | monthly
  final DateTime periodStart;
  final String text;
  final DateTime createdAt;

  const Reflection({
    required this.period,
    required this.periodStart,
    required this.text,
    required this.createdAt,
  });
}

/// Generates and stores the periodic AI reflection ("you funded X well but
/// lacked Y"). Online-only and gated like the other AI features. Dedup + the
/// offline-visible copy live in [SharedPreferences]; the durable record is
/// upserted to the Supabase `ai_reflections` table for cross-device history.
///
/// Flow: [maybeGenerate] runs on boot/resume, decides whether a new weekly (and
/// monthly) reflection is due, builds a compact summary from the local synced
/// data, asks [AiCoachService], stores the result, and fires a local
/// notification. [latest] returns the cached copy for in-app display.
class ReflectionService {
  ReflectionService._();
  static final ReflectionService instance = ReflectionService._();

  static const _table = 'ai_reflections';
  static const _kLatestText = 'reflection_latest_text_v1';
  static const _kLatestPeriod = 'reflection_latest_period_v1';
  static const _kLatestStart = 'reflection_latest_start_v1';
  static const _kWeeklyStart = 'reflection_weekly_start_v1';
  static const _kMonthlyStart = 'reflection_monthly_start_v1';

  bool get _available =>
      SupabaseConfig.isConfigured &&
      AuthService.instance.isSignedIn &&
      AppSettings.instance.aiCoachEnabled &&
      AppSettings.instance.notifWeeklySummary;

  /// Monday 00:00 of [d]'s week.
  static DateTime _weekStart(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The latest reflection cached locally, or null. Safe to call offline.
  Future<Reflection?> latest() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_kLatestText);
    final period = prefs.getString(_kLatestPeriod);
    final start = prefs.getString(_kLatestStart);
    if (text == null || period == null || start == null) return null;
    final parsed = DateTime.tryParse(start);
    if (parsed == null) return null;
    return Reflection(
      period: period,
      periodStart: parsed,
      text: text,
      createdAt: parsed,
    );
  }

  /// Generate any reflections that are now due. Best-effort: any failure is
  /// swallowed so boot never blocks on the network or the model.
  Future<void> maybeGenerate({DateTime? now}) async {
    if (!_available) return;
    final n = now ?? DateTime.now();
    try {
      final goals = await GoalRepository.loadAll();
      // Weekly first (more frequent); only one notification per run.
      final firedWeekly = await _generateIfDue(
        'weekly',
        _weekStart(n),
        goals,
        notify: true,
      );
      await _generateIfDue(
        'monthly',
        DateTime(n.year, n.month, 1),
        goals,
        notify: !firedWeekly,
      );
    } catch (_) {
      // Reflections are a nice-to-have; never surface a boot error.
    }
  }

  Future<bool> _generateIfDue(
    String period,
    DateTime periodStart,
    List<Goal> goals, {
    required bool notify,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = period == 'weekly' ? _kWeeklyStart : _kMonthlyStart;
    final lastKey = prefs.getString(key);
    if (lastKey == _dateKey(periodStart)) return false; // already done

    // Only bother when there's activity worth reflecting on.
    final week = ComparisonService.weekOverWeek(
      goals,
      now: periodStart.add(const Duration(days: 6)),
    ); // representative point in the period
    final month = ComparisonService.monthOverMonth(goals);
    final relevant = period == 'weekly' ? week : month;
    if (!relevant.hasActivity) return false;

    final input = await _buildSummary(period, goals);
    final String text;
    try {
      text = await AiCoachService.instance.reflection(input);
    } on AiUnavailable {
      return false; // try again next launch
    }

    await _store(period, periodStart, text);
    await prefs.setString(key, _dateKey(periodStart));

    if (notify) {
      final l = appLocalizations();
      await NotificationService.showReflectionNow(
        id: NotificationService.idReflection,
        title: l.notifReflectionTitle,
        body: text,
      );
    }
    return true;
  }

  /// Build the compact summary payload the edge function turns into prose.
  Future<Map<String, dynamic>> _buildSummary(
    String period,
    List<Goal> goals,
  ) async {
    final budgets = await BudgetRepository.loadAll();
    final week = ComparisonService.weekOverWeek(goals);
    final month = ComparisonService.monthOverMonth(goals);
    final streak = StreakService.weeklyStreak(goals);

    // Approximate each linked goal's monthly funding from the branches that
    // feed it (allocated split evenly across the goals a branch links).
    final recommended = <String, double>{};
    for (final b in budgets) {
      for (final cat in b.expenses) {
        if (cat.linkedGoalIds.isEmpty || cat.allocated <= 0) continue;
        final share = cat.allocated / cat.linkedGoalIds.length;
        for (final gid in cat.linkedGoalIds) {
          recommended[gid] = (recommended[gid] ?? 0) + share;
        }
      }
    }

    final periodStart = period == 'weekly'
        ? _weekStart(DateTime.now())
        : DateTime(DateTime.now().year, DateTime.now().month, 1);

    final linkedGoals = <Map<String, dynamic>>[];
    for (final g in goals) {
      final rec = recommended[g.id];
      if (rec == null) continue;
      double contributed = 0;
      for (final c in g.contributions) {
        if (c.isDeposit && !c.at.isBefore(periodStart)) contributed += c.amount;
      }
      linkedGoals.add({
        'name': g.name,
        'recommendedMonthly': rec.round(),
        'contributedThisPeriod': contributed.round(),
      });
    }

    Map<String, dynamic> cmp(PeriodComparison c) => {
      'current': c.current.round(),
      'previous': c.previous.round(),
      'pctChange': c.percentChange?.round(),
    };

    return {
      'period': period,
      'budgets': budgets
          .map(
            (b) => {
              'name': b.budgetName,
              'income': b.totalIncome.round(),
              'allocated': b.totalAllocated.round(),
            },
          )
          .toList(),
      'week': cmp(week),
      'month': cmp(month),
      'streakWeeks': streak.currentWeeks,
      'linkedGoals': linkedGoals,
    };
  }

  Future<void> _store(String period, DateTime periodStart, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLatestText, text);
    await prefs.setString(_kLatestPeriod, period);
    await prefs.setString(_kLatestStart, _dateKey(periodStart));

    // Durable cross-device copy. Best-effort: a failure here still leaves the
    // local cache populated.
    try {
      final uid = AuthService.instance.userId;
      if (uid != null) {
        await SupabaseConfig.client.from(_table).upsert({
          'user_id': uid,
          'period': period,
          'period_start': _dateKey(periodStart),
          'text': text,
        }, onConflict: 'user_id,period,period_start');
      }
    } catch (_) {
      // Ignore: the reflection still shows from the local cache.
    }
  }
}
