import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import 'budget_repository.dart';
import 'goal_repository.dart';
import 'sound_service.dart';
import 'streak_service.dart';

/// Persists which badges the user has unlocked and re-evaluates the catalog
/// after any progress event. Unlocks are sticky — once earned, a badge stays
/// even if the underlying stat later drops (e.g. a withdrawal).
///
/// Storage: key `achievements_v1`, a `List<String>` of `id|unlockedMillis`.
class AchievementService {
  AchievementService._();

  static const _key = 'achievements_v1';

  static Future<Map<String, DateTime>> loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final out = <String, DateTime>{};
    for (final entry in raw) {
      final i = entry.indexOf('|');
      if (i <= 0) continue;
      final id = entry.substring(0, i);
      final ms = int.tryParse(entry.substring(i + 1));
      if (ms == null) continue;
      out[id] = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return out;
  }

  /// Build the aggregate stats used by every badge test from current data.
  static Future<AchievementStats> computeStats() async {
    final goals = await GoalRepository.loadAll();
    final budgets = await BudgetRepository.loadAll();

    int deposits = 0;
    int completed = 0;
    double saved = 0;
    int maxTier = 0;
    for (final g in goals) {
      saved += g.currentAmount;
      if (g.isComplete) completed++;
      if (g.isUncapped && g.tier > maxTier) maxTier = g.tier;
      for (final c in g.contributions) {
        if (c.isDeposit) deposits++;
      }
    }
    final streak = StreakService.weeklyStreak(goals);

    return AchievementStats(
      budgetCount: budgets.where((b) => b.savedAt != null).length,
      goalCount: goals.length,
      depositCount: deposits,
      completedGoals: completed,
      totalSaved: saved,
      maxTier: maxTier,
      bestStreakWeeks: streak.bestWeeks,
    );
  }

  /// Re-evaluate the catalog. Persists and returns any badges newly unlocked
  /// by this pass (empty when nothing changed), playing a cue for the batch.
  static Future<List<Achievement>> evaluateAndUnlock() async {
    final unlocked = await loadUnlocked();
    final stats = await computeStats();
    final now = DateTime.now();
    final newly = <Achievement>[];

    for (final a in AchievementCatalog.all) {
      if (unlocked.containsKey(a.id)) continue;
      if (a.test(stats)) {
        unlocked[a.id] = now;
        newly.add(a);
      }
    }

    if (newly.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final raw = unlocked.entries
          .map((e) => '${e.key}|${e.value.millisecondsSinceEpoch}')
          .toList();
      await prefs.setStringList(_key, raw);
      SoundService.celebrate();
    }
    return newly;
  }
}
