import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';

class CategoryRepository {
  static const String _key = 'tree_categories_v1';

  static Future<List<TreeCategory>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) =>
            TreeCategory.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveNew(TreeCategory cat) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(cat.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> update(TreeCategory cat) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final idx = raw.indexWhere((s) {
      final c =
          TreeCategory.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return c.id == cat.id;
    });
    if (idx >= 0) {
      raw[idx] = jsonEncode(cat.toJson());
    } else {
      raw.add(jsonEncode(cat.toJson()));
    }
    await prefs.setStringList(_key, raw);
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final c =
          TreeCategory.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return c.id == id;
    });
    await prefs.setStringList(_key, raw);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
