import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal_model.dart';

class GoalRepository {
  static const String _key = 'goals_v1';

  static Future<List<Goal>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => Goal.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveNew(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(goal.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> update(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final idx = raw.indexWhere((s) {
      final g = Goal.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return g.id == goal.id;
    });
    if (idx >= 0) {
      raw[idx] = jsonEncode(goal.toJson());
    } else {
      raw.add(jsonEncode(goal.toJson()));
    }
    await prefs.setStringList(_key, raw);
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final g = Goal.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return g.id == id;
    });
    await prefs.setStringList(_key, raw);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
