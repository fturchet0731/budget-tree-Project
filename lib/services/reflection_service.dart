import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../data/calendar.dart';

import '../l10n/app_localizations_resolver.dart';
import '../models/goal_model.dart';
import '../models/reflection_report.dart';
import 'ai_coach_service.dart';
import 'app_settings.dart';
import 'auth_service.dart';
import 'budget_repository.dart';
import 'comparison_service.dart';
import 'goal_repository.dart';
import 'notification_service.dart';
import 'reflection_stats.dart';
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
  static const _kLatestReport = 'reflection_latest_report_v1';

  /// Note this deliberately does **not** require `notifWeeklySummary`. That
  /// coupling made sense when a reflection was essentially a notification, but
  /// Acorn's Hub now owns them: switching off a *notification* must not
  /// silently stop reflections appearing *in the app*, with no visible cause.
  /// Only the notification itself is gated on that preference.
  bool get _available =>
      SupabaseConfig.isConfigured &&
      AuthService.instance.isSignedIn &&
      AppSettings.instance.aiCoachEnabled;

  /// Monday 00:00 of [d]'s week.
  static DateTime _weekStart(DateTime d) => startOfWeek(d);

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

  /// The structured half of the latest reflection, or null when the stored one
  /// predates it (or the model returned prose only). Callers fall back to
  /// [latest]'s plain text.
  ReflectionReport? _cachedReport;

  Future<ReflectionReport?> loadLatestReport() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLatestReport);
    if (raw == null) return _cachedReport = null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return _cachedReport = null;
      final report = ReflectionReport.fromJson(decoded);
      return _cachedReport = report.isEmpty ? null : report;
    } catch (_) {
      return _cachedReport = null;
    }
  }

  /// Synchronous read of whatever [loadLatestReport] last resolved, for build
  /// methods. Null until that has run at least once.
  ReflectionReport? latestReport() => _cachedReport;

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
      now: addDays(periodStart, 6),
    ); // representative point in the period
    final month = ComparisonService.monthOverMonth(goals);
    final relevant = period == 'weekly' ? week : month;
    if (!relevant.hasActivity) return false;

    final input = await _buildSummary(period, goals);
    final String text;
    final ReflectionReport report;
    try {
      final result = await AiCoachService.instance.reflection(input);
      text = result.text;
      report = result.report;
    } on AiUnavailable {
      return false; // try again next launch
    }

    await _store(period, periodStart, text, report);
    await prefs.setString(key, _dateKey(periodStart));

    if (notify && AppSettings.instance.notifWeeklySummary) {
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
        final share =
            cat.allocatedPerCycle(b.payFrequency) / cat.linkedGoalIds.length;
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

    // The behavioural half: how consistently the user has been checking in,
    // and the only plan-versus-actual figures the app has. Both are already
    // aggregated, so the coach never sees a raw row.
    final stats = await ReflectionStats.load();

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
      'health': {
        'score': stats.health.score.round(),
        'tier': stats.health.tier.name,
        'delta': stats.health.delta.round(),
        'streak': stats.health.currentStreak,
      },
      'checkIns': [
        for (final c in stats.consistency)
          {
            'dueAt': _dateKey(c.at),
            'verdict': c.missed ? 'missed' : (c.verdict?.name ?? 'unknown'),
          },
      ],
      // Empty until the user has volunteered amounts. The prompt must never
      // infer overspending from an allocation gap: allocation is a plan, not a
      // record of spending, and the coach would be confidently wrong.
      'overspend': [
        for (final o in stats.overspend.where((o) => o.isOver))
          {
            'name': o.name,
            'planned': o.planned.round(),
            'actual': o.actual.round(),
          },
      ],
    };
  }

  Future<void> _store(
    String period,
    DateTime periodStart,
    String text,
    ReflectionReport report,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLatestText, text);
    await prefs.setString(_kLatestPeriod, period);
    await prefs.setString(_kLatestStart, _dateKey(periodStart));
    if (report.isEmpty) {
      await prefs.remove(_kLatestReport);
      _cachedReport = null;
    } else {
      await prefs.setString(_kLatestReport, jsonEncode(report.toJson()));
      _cachedReport = report;
    }

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
          'report': report.isEmpty ? null : report.toJson(),
        }, onConflict: 'user_id,period,period_start');
      }
    } catch (_) {
      // Ignore: the reflection still shows from the local cache.
    }
  }
}
