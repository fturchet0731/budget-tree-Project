import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'achievement_service.dart';
import 'auth_service.dart';
import 'budget_repository.dart';
import 'category_repository.dart';
import 'goal_repository.dart';
import 'notification_scheduler.dart';
import 'supabase_config.dart';
import 'synced_store.dart';

/// Coordinates the per-collection [SyncedStore]s: first-login data migration,
/// pulling fresh data, flushing the offline queue, and clearing caches on
/// sign-out. Also wires up automatic re-sync on app-resume and when the
/// network comes back.
class SyncEngine {
  SyncEngine._();

  static List<SyncedStore<dynamic>> get _stores => [
        BudgetRepository.store,
        GoalRepository.store,
        CategoryRepository.store,
        AchievementService.store,
      ];

  static final _SyncLifecycle _lifecycle = _SyncLifecycle();
  static StreamSubscription<List<ConnectivityResult>>? _connSub;

  /// Register lifecycle + connectivity listeners. Call once at boot.
  static void init() {
    if (!SupabaseConfig.isConfigured) return;
    WidgetsBinding.instance.addObserver(_lifecycle);
    _connSub ??= Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && AuthService.instance.isSignedIn) {
        unawaited(flushAndPull());
      }
    });
  }

  /// Run after a successful sign-in. Pushes any local-only rows up (migrating
  /// data created before accounts existed), then pulls the authoritative set,
  /// then refreshes reminders now that data is present.
  static Future<void> onSignedIn() async {
    for (final s in _stores) {
      await s.pushAllLocal();
    }
    for (final s in _stores) {
      await s.pull();
    }
    unawaited(NotificationScheduler.rescheduleAll());
  }

  /// Drop every local data cache + pending queue (on sign-out). Device-level
  /// settings (theme, tutorial-seen) are intentionally left untouched.
  static Future<void> clearLocalCaches() async {
    for (final s in _stores) {
      await s.clearCache();
    }
  }

  /// Replay queued writes then refresh caches (app-resume / back-online).
  static Future<void> flushAndPull() async {
    for (final s in _stores) {
      await s.flushQueue();
    }
    for (final s in _stores) {
      await s.pull();
    }
  }

  /// Erase the signed-in user's rows from every remote table (used by the
  /// Settings "erase all data" action). Local caches are cleared by the caller.
  static Future<void> deleteAllRemote() async {
    for (final s in _stores) {
      await s.deleteAllRemote();
    }
  }
}

class _SyncLifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        AuthService.instance.isSignedIn) {
      unawaited(SyncEngine.flushAndPull());
    }
  }
}
