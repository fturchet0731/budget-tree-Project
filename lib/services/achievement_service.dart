import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import 'budget_repository.dart';
import 'goal_repository.dart';
import 'sound_service.dart';
import 'streak_service.dart';
import 'synced_store.dart';

/// Persists which badges the user has unlocked and re-evaluates the catalog
/// after any progress event. Unlocks are sticky — once earned, a badge stays
/// even if the underlying stat later drops (e.g. a withdrawal).
///
/// Each unlock is one row: `id` = badge id, `data` = `{unlockedMillis}`. The
/// store keeps a local cache (key `ach_unlocks_v1`) and syncs to the Supabase
/// `achievements` table. Legacy `achievements_v1` records (`id|millis` strings)
/// are migrated into the store on first read.
class AchievementService {
  AchievementService._();

  static const _legacyKey = 'achievements_v1';

  static final SyncedStore<MapEntry<String, DateTime>> store =
      SyncedStore<MapEntry<String, DateTime>>(
    prefsKey: 'ach_unlocks_v1',
    table: 'achievements',
    toJson: (e) => {
      'id': e.key,
      'unlockedMillis': e.value.millisecondsSinceEpoch,
    },
    fromJson: (j) => MapEntry(
      j['id'] as String,
      DateTime.fromMillisecondsSinceEpoch((j['unlockedMillis'] as num).toInt()),
    ),
    idOf: (e) => e.key,
  );

  /// One-time move of the old `id|millis` list into the new JSON store.
  static Future<void> _migrateLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getStringList(_legacyKey);
    if (legacy == null || legacy.isEmpty) return;
    for (final entry in legacy) {
      final i = entry.indexOf('|');
      if (i <= 0) continue;
      final id = entry.substring(0, i);
      final ms = int.tryParse(entry.substring(i + 1));
      if (ms == null) continue;
      await store.saveNew(
          MapEntry(id, DateTime.fromMillisecondsSinceEpoch(ms)));
    }
    await prefs.remove(_legacyKey);
  }

  static Future<Map<String, DateTime>> loadUnlocked() async {
    await _migrateLegacy();
    final entries = await store.loadAll();
    return {for (final e in entries) e.key: e.value};
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
        await store.saveNew(MapEntry(a.id, now));
        newly.add(a);
      }
    }

    if (newly.isNotEmpty) {
      SoundService.celebrate();
    }
    return newly;
  }
}
