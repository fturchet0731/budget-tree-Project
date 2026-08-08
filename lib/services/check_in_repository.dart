import '../models/check_in.dart';
import 'synced_store.dart';

/// Resolved check-ins (confirmed or missed). Same offline-first shape as the
/// other four collections: local cache `check_ins_v1`, Supabase table
/// `check_ins`, whole model in a `data` jsonb column under per-user RLS.
///
/// Pending check-ins deliberately never reach here — [CheckInService] derives
/// them from the budgets' pay schedules on every read. Storing only resolved
/// rows makes every write monotonic (pending becomes confirmed or missed, never
/// the other way), so a replayed offline write is idempotent and there is
/// nothing to merge across devices.
class CheckInRepository {
  CheckInRepository._();

  static final SyncedStore<CheckIn> store = SyncedStore<CheckIn>(
    prefsKey: 'check_ins_v1',
    table: 'check_ins',
    toJson: (c) => c.toJson(),
    fromJson: CheckIn.fromJson,
    idOf: (c) => c.id,
  );

  static Future<List<CheckIn>> loadAll() => store.loadAll();

  /// Cache-only read (no background refresh) — see [SyncedStore.loadCached].
  /// The sweep and every read-then-write path uses this so a pull it started
  /// itself can't overwrite the cache underneath it.
  static Future<List<CheckIn>> loadCached() => store.loadCached();
  static Future<void> saveNew(CheckIn checkIn) => store.saveNew(checkIn);
  static Future<void> update(CheckIn checkIn) => store.update(checkIn);
  static Future<void> delete(String id) => store.delete(id);
}
