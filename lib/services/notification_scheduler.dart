import 'package:shared_preferences/shared_preferences.dart';
import '../data/calendar.dart';
import '../l10n/app_localizations_resolver.dart';
import '../models/budget_model.dart';
import 'app_settings.dart';
import 'goal_repository.dart';
import 'notification_content.dart';
import 'notification_service.dart';
import 'reflection_service.dart';
import 'streak_service.dart';

/// Decides *what* notifications exist and keeps them in sync with the user's
/// preferences and data. The recurring reminders (streak, weekly summary) are
/// (re)scheduled here; budget warnings are event-driven via [checkBudget].
///
/// Launch set is intentionally just three types to avoid notification
/// overload, with the daily streak nudge consolidating what would otherwise
/// be constant pings, and the weekly summary replacing seven daily recaps.
class NotificationScheduler {
  NotificationScheduler._();

  static const _kBudgetLevels = 'notif_budget_levels_v1';

  /// Cancel and rebuild the recurring reminders from current prefs + data.
  /// Call on startup, after preference changes, and after deposits so the
  /// streak/summary copy stays current. Safe to call often.
  static Future<void> rescheduleAll() async {
    final settings = AppSettings.instance;
    // Only surface the OS permission dialog after the user has opted into
    // notifications somewhere (Settings, or a goal's watering reminder) — a
    // first launch should never open with a permission request out of thin
    // air. Scheduling below is safe without permission; it just stays silent.
    if (settings.anyNotificationsEnabled && settings.notifPermissionAsked) {
      await NotificationService.requestPermissions();
    }

    final goals = await GoalRepository.loadAll();
    final l = appLocalizations();

    // ── Daily streak reminder ──
    if (settings.notifStreakReminders) {
      final streak = StreakService.weeklyStreak(goals);
      await NotificationService.scheduleDaily(
        id: NotificationService.idStreak,
        hour: settings.streakHour,
        minute: settings.streakMinute,
        title: NotificationContent.streakTitle(streak, l),
        body: NotificationContent.streakReminder(streak, l),
      );
    } else {
      await NotificationService.cancel(NotificationService.idStreak);
    }

    // ── Weekly summary ──
    if (settings.notifWeeklySummary) {
      // Prefer the latest AI reflection text (richer, personalised) when one is
      // cached; otherwise fall back to the rule-based summary.
      final reflection = await ReflectionService.instance.latest();
      final body = reflection != null && reflection.period == 'weekly'
          ? reflection.text
          : NotificationContent.weeklySummary(goals, l);
      await NotificationService.scheduleWeekly(
        id: NotificationService.idWeekly,
        weekday: settings.weeklyWeekday,
        hour: settings.weeklyHour,
        title: NotificationContent.weeklySummaryTitle(l),
        body: body,
      );
    } else {
      await NotificationService.cancel(NotificationService.idWeekly);
    }

    // ── Per-goal watering reminders ──
    // For each goal with a watering schedule, seed two one-shot reminders: a
    // heads-up 2 days before the due date and a nudge on the due date itself
    // (both at the user's watering hour). rescheduleAll runs on boot/resume and
    // after deposits, so the next occurrence is always re-seeded.
    for (final goal in goals) {
      final dueId =
          NotificationService.waterIdBase + (goal.id.hashCode & 0xfff);
      final soonId =
          NotificationService.waterSoonIdBase + (goal.id.hashCode & 0xfff);
      if (!settings.notifGoalWatering ||
          !goal.waterRemindersEnabled ||
          goal.nextWaterDate == null ||
          goal.isCompleted) {
        await NotificationService.cancel(dueId);
        await NotificationService.cancel(soonId);
        continue;
      }
      // Roll the due date forward past any missed waterings.
      goal.advanceWatering();
      final due = goal.nextWaterDate!;
      final dueAt = DateTime(
        due.year,
        due.month,
        due.day,
        settings.waterHour,
      );
      final soonAt = addDays(dueAt, -2);
      await NotificationService.scheduleGoalWateringOnce(
        id: dueId,
        when: dueAt,
        title: NotificationContent.wateringDueTitle(goal, l),
        body: NotificationContent.wateringDueBody(goal, l),
      );
      await NotificationService.scheduleGoalWateringOnce(
        id: soonId,
        when: soonAt,
        title: NotificationContent.wateringSoonTitle(goal, l),
        body: NotificationContent.wateringSoonBody(goal, l),
      );
    }
  }

  /// Event-driven budget warning. Fires only when a budget *crosses up* into a
  /// higher warning level (healthy → near-limit → over-budget), so the user
  /// gets each alert once rather than on every save.
  static Future<void> checkBudget(BudgetModel budget) async {
    if (!AppSettings.instance.notifBudgetWarnings) return;
    final warning = NotificationContent.budgetWarning(
      budget,
      appLocalizations(),
    );

    final prefs = await SharedPreferences.getInstance();
    final levels = _readLevels(prefs);
    final previous = levels[budget.id] ?? 0;

    if (warning.level > previous) {
      await NotificationService.showNow(
        id: NotificationService.budgetIdBase + (budget.id.hashCode & 0xfff),
        title: warning.title,
        body: warning.message,
      );
    }

    // Persist the new level (including drops, so re-crossing notifies again).
    if (warning.level != previous) {
      levels[budget.id] = warning.level;
      await _writeLevels(prefs, levels);
    }
  }

  static Map<String, int> _readLevels(SharedPreferences prefs) {
    final raw = prefs.getStringList(_kBudgetLevels) ?? const [];
    final out = <String, int>{};
    for (final e in raw) {
      final i = e.lastIndexOf(':');
      if (i <= 0) continue;
      final id = e.substring(0, i);
      final lvl = int.tryParse(e.substring(i + 1));
      if (lvl != null) out[id] = lvl;
    }
    return out;
  }

  static Future<void> _writeLevels(
    SharedPreferences prefs,
    Map<String, int> levels,
  ) async {
    final raw = levels.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_kBudgetLevels, raw);
  }

  /// Forget a deleted budget's warning state so a future budget reusing the id
  /// starts fresh. Best-effort.
  static Future<void> forgetBudget(String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final levels = _readLevels(prefs);
    if (levels.remove(budgetId) != null) {
      await _writeLevels(prefs, levels);
    }
  }
}
