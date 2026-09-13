// Verifies the offline-first contract of SyncedStore when Supabase is NOT
// configured (the test environment passes no dart-defines). In that mode the
// store must behave exactly like the old shared_preferences repositories:
// writes land in the local cache and reads return them — no network involved.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app_project/models/goal_model.dart';
import 'package:budget_app_project/services/goal_repository.dart';
import 'package:budget_app_project/services/supabase_config.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Supabase is not configured in tests (local-only mode)', () {
    expect(SupabaseConfig.isConfigured, isFalse);
  });

  test('saveNew then loadAll round-trips through the local cache', () async {
    final goal = Goal(name: 'New bike', targetAmount: 500);
    await GoalRepository.saveNew(goal);

    final loaded = await GoalRepository.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'New bike');
    expect(loaded.first.id, goal.id);
  });

  test('update mutates the cached record in place', () async {
    final goal = Goal(name: 'Trip', targetAmount: 1000);
    await GoalRepository.saveNew(goal);

    goal.name = 'Big trip';
    await GoalRepository.update(goal);

    final loaded = await GoalRepository.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Big trip');
  });

  test('delete removes the cached record', () async {
    final goal = Goal(name: 'Temp', targetAmount: 50);
    await GoalRepository.saveNew(goal);
    await GoalRepository.delete(goal.id);

    expect(await GoalRepository.loadAll(), isEmpty);
  });
}
