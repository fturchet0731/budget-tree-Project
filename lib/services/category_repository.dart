import '../models/category_model.dart';
import 'synced_store.dart';

/// Shared budget/goal categories. Local cache key `tree_categories_v1`, synced
/// to the Supabase `categories` table. Public API unchanged.
class CategoryRepository {
  CategoryRepository._();

  static final SyncedStore<TreeCategory> store = SyncedStore<TreeCategory>(
    prefsKey: 'tree_categories_v1',
    table: 'categories',
    toJson: (c) => c.toJson(),
    fromJson: TreeCategory.fromJson,
    idOf: (c) => c.id,
  );

  static Future<List<TreeCategory>> loadAll() => store.loadAll();
  static Future<void> saveNew(TreeCategory cat) => store.saveNew(cat);
  static Future<void> update(TreeCategory cat) => store.update(cat);
  static Future<void> delete(String id) => store.delete(id);
  static Future<void> clear() => store.clearCache();
}
