import '../models/goal_model.dart';
import 'synced_store.dart';

/// Savings goals (saplings). Local cache key `goals_v1`, synced to the Supabase
/// `goals` table. Public API unchanged.
class GoalRepository {
  GoalRepository._();

  static final SyncedStore<Goal> store = SyncedStore<Goal>(
    prefsKey: 'goals_v1',
    table: 'goals',
    toJson: (g) => g.toJson(),
    fromJson: Goal.fromJson,
    idOf: (g) => g.id,
  );

  static Future<List<Goal>> loadAll() => store.loadAll();

  /// Cache-only read (no background refresh) — see [SyncedStore.loadCached].
  static Future<List<Goal>> loadCached() => store.loadCached();
  static Future<void> saveNew(Goal goal) => store.saveNew(goal);
  static Future<void> update(Goal goal) => store.update(goal);
  static Future<void> delete(String id) => store.delete(id);

  /// Clears the local cache (and pending queue). Used by "erase all data".
  static Future<void> clear() => store.clearCache();
}
