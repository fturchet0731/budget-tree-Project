import '../models/budget_model.dart';
import 'synced_store.dart';

/// Budget trees. Public API is unchanged from the original
/// `shared_preferences`-only version — all logic now lives in [SyncedStore],
/// which keeps a local cache (key `budget_tree_v1`) and syncs to the Supabase
/// `budgets` table in the background.
class BudgetRepository {
  BudgetRepository._();

  static final SyncedStore<BudgetModel> store = SyncedStore<BudgetModel>(
    prefsKey: 'budget_tree_v1',
    table: 'budgets',
    toJson: (b) => b.toJson(),
    fromJson: BudgetModel.fromJson,
    idOf: (b) => b.id,
  );

  static Future<List<BudgetModel>> loadAll() => store.loadAll();
  static Future<void> saveNew(BudgetModel budget) => store.saveNew(budget);
  static Future<void> update(BudgetModel budget) => store.update(budget);
  static Future<void> delete(String id) => store.delete(id);
}
