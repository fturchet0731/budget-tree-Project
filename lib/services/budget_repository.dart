import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  static const String _key = 'budget_tree_v1';

  static Future<List<BudgetModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => BudgetModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveNew(BudgetModel budget) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(budget.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final m = BudgetModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return m.id == id;
    });
    await prefs.setStringList(_key, raw);
  }

  static Future<void> update(BudgetModel budget) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final idx = raw.indexWhere((s) {
      final m = BudgetModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return m.id == budget.id;
    });
    if (idx >= 0) {
      raw[idx] = jsonEncode(budget.toJson());
    } else {
      raw.add(jsonEncode(budget.toJson()));
    }
    await prefs.setStringList(_key, raw);
  }
}
