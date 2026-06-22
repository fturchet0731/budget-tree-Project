import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// A write-through, offline-first store for one collection of model [T].
///
/// Reads come straight from a local `shared_preferences` cache (instant — the
/// app stays snappy). Writes hit the cache first, then sync to Supabase in the
/// background. If a remote write fails (offline / no session) the op is parked
/// in a per-collection **pending queue** and replayed later by [flushQueue].
///
/// The three data repositories and the achievement store each own one of these
/// and keep their existing static method signatures, so no call sites change.
class SyncedStore<T> {
  SyncedStore({
    required this.prefsKey,
    required this.table,
    required this.toJson,
    required this.fromJson,
    required this.idOf,
  });

  /// Cache key — reuse the *exact* legacy key (e.g. `budget_tree_v1`) so data
  /// saved before this migration is still read.
  final String prefsKey;

  /// Supabase table name (e.g. `budgets`).
  final String table;

  final Map<String, dynamic> Function(T) toJson;
  final T Function(Map<String, dynamic>) fromJson;
  final String Function(T) idOf;

  String get _pendingKey => '${prefsKey}_pending_v1';

  bool get _canSync =>
      SupabaseConfig.isConfigured && AuthService.instance.isSignedIn;
  String? get _userId => AuthService.instance.userId;

  bool _pulling = false;

  // ---------------------------------------------------------------- cache I/O

  Future<List<String>> _rawCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(prefsKey) ?? <String>[];
  }

  Future<void> _writeRawCache(List<String> raw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(prefsKey, raw);
  }

  List<T> _parse(List<String> raw) => raw
      .map((s) => fromJson(jsonDecode(s) as Map<String, dynamic>))
      .toList();

  // -------------------------------------------------------------- public API

  /// Returns the cached collection immediately. Kicks off a background refresh
  /// from Supabase so the *next* read reflects remote changes.
  Future<List<T>> loadAll() async {
    final items = _parse(await _rawCache());
    if (_canSync) unawaited(pull());
    return items;
  }

  Future<void> saveNew(T item) async {
    final raw = await _rawCache();
    raw.add(jsonEncode(toJson(item)));
    await _writeRawCache(raw);
    unawaited(_remoteUpsert(item));
  }

  Future<void> update(T item) async {
    final raw = await _rawCache();
    final id = idOf(item);
    final idx = raw.indexWhere(
        (s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    if (idx >= 0) {
      raw[idx] = jsonEncode(toJson(item));
    } else {
      raw.add(jsonEncode(toJson(item)));
    }
    await _writeRawCache(raw);
    unawaited(_remoteUpsert(item));
  }

  Future<void> delete(String id) async {
    final raw = await _rawCache();
    raw.removeWhere(
        (s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await _writeRawCache(raw);
    unawaited(_remoteDelete(id));
  }

  /// Drop the local cache and any pending ops (used on sign-out).
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
    await prefs.remove(_pendingKey);
  }

  // ------------------------------------------------------------ remote writes

  Future<void> _remoteUpsert(T item) async {
    if (!_canSync) return;
    try {
      await SupabaseConfig.client.from(table).upsert({
        'user_id': _userId,
        'id': idOf(item),
        'data': toJson(item),
      }, onConflict: 'user_id,id');
    } catch (e) {
      await _enqueue({'op': 'upsert', 'id': idOf(item), 'data': toJson(item)});
    }
  }

  Future<void> _remoteDelete(String id) async {
    if (!_canSync) return;
    try {
      await SupabaseConfig.client
          .from(table)
          .delete()
          .eq('user_id', _userId!)
          .eq('id', id);
    } catch (e) {
      await _enqueue({'op': 'delete', 'id': id});
    }
  }

  /// Remove every row this user owns in [table] (used by "erase all data").
  Future<void> deleteAllRemote() async {
    if (!_canSync) return;
    try {
      await SupabaseConfig.client.from(table).delete().eq('user_id', _userId!);
    } catch (_) {
      // Best effort — local cache is already cleared by the caller.
    }
  }

  // ------------------------------------------------------------- sync engine

  /// Overwrite the local cache with the authoritative remote rows. Flushes any
  /// pending writes first so we never clobber un-synced local edits.
  Future<void> pull() async {
    if (!_canSync || _pulling) return;
    _pulling = true;
    try {
      await flushQueue();
      final rows = await SupabaseConfig.client
          .from(table)
          .select('data')
          .eq('user_id', _userId!);
      final raw = rows
          .map((r) => jsonEncode(r['data'] as Map<String, dynamic>))
          .toList();
      await _writeRawCache(raw);
    } catch (e) {
      debugPrint('SyncedStore.pull($table) failed: $e');
    } finally {
      _pulling = false;
    }
  }

  /// Push every locally-cached row up to Supabase. Used once on first sign-in
  /// to migrate data that was created before accounts existed.
  Future<void> pushAllLocal() async {
    if (!_canSync) return;
    final items = _parse(await _rawCache());
    if (items.isEmpty) return;
    try {
      await SupabaseConfig.client.from(table).upsert(
            items
                .map((i) => {
                      'user_id': _userId,
                      'id': idOf(i),
                      'data': toJson(i),
                    })
                .toList(),
            onConflict: 'user_id,id',
          );
    } catch (e) {
      debugPrint('SyncedStore.pushAllLocal($table) failed: $e');
    }
  }

  Future<void> _enqueue(Map<String, dynamic> op) async {
    final prefs = await SharedPreferences.getInstance();
    final q = prefs.getStringList(_pendingKey) ?? <String>[];
    q.add(jsonEncode(op));
    await prefs.setStringList(_pendingKey, q);
  }

  /// Replay queued writes in order. Stops at the first failure so ordering is
  /// preserved for the next attempt (e.g. still offline).
  Future<void> flushQueue() async {
    if (!_canSync) return;
    final prefs = await SharedPreferences.getInstance();
    final q = prefs.getStringList(_pendingKey) ?? <String>[];
    if (q.isEmpty) return;

    final remaining = List<String>.from(q);
    for (final encoded in q) {
      final op = jsonDecode(encoded) as Map<String, dynamic>;
      try {
        if (op['op'] == 'delete') {
          await SupabaseConfig.client
              .from(table)
              .delete()
              .eq('user_id', _userId!)
              .eq('id', op['id'] as String);
        } else {
          await SupabaseConfig.client.from(table).upsert({
            'user_id': _userId,
            'id': op['id'],
            'data': op['data'],
          }, onConflict: 'user_id,id');
        }
        remaining.remove(encoded);
      } catch (_) {
        break; // still offline — keep the rest for later
      }
    }
    await prefs.setStringList(_pendingKey, remaining);
  }
}
