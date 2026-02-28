// lib/state/sync_provider.dart
//
// SyncProvider (ChangeNotifier)
//
// Runs Firestore sync (offline-first).
// - Only runs when user is Google linked (not anonymous)
// - Stores sync status in LocalDb.meta():
//    - last_sync_at (ISO string)
//    - last_sync_error (string)
//
// Depends on:
// - AuthProvider (for uid + auth state)
// - LocalDb + repos + SyncEngine (data layer)

import 'package:flutter/foundation.dart';

import '../data/local/local_db.dart';

import '../data/local/account_local_repo.dart';
import '../data/local/budget_local_repo.dart';
import '../data/local/category_local_repo.dart';
import '../data/local/record_local_repo.dart';

import '../data/remote/firestore_service.dart';
import '../data/remote/account_remote_repo.dart';
import '../data/remote/category_remote_repo.dart';
import '../data/remote/record_remote_repo.dart';
import '../data/remote/budget_remote_repo.dart';

import '../data/sync/sync_engine.dart';

import 'auth_provider.dart';

class SyncProvider extends ChangeNotifier {
  static const String _kLastSyncAt = 'last_sync_at';
  static const String _kLastSyncError = 'last_sync_error';

  bool _running = false;
  bool get isRunning => _running;

  /// ISO string stored in LocalDb.meta()
  String? get lastSyncAtIso => LocalDb.meta().get(_kLastSyncAt);

  /// Error string stored in LocalDb.meta()
  String? get lastSyncError => LocalDb.meta().get(_kLastSyncError);

  /// Convenience: human-ish display string for UI
  String get lastSyncAtText {
    final iso = lastSyncAtIso;
    if (iso == null || iso.trim().isEmpty) return 'Never';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Never';
    return dt.toLocal().toString(); // keep simple (no intl dependency)
  }

  bool get hasLastError {
    final e = lastSyncError;
    return e != null && e.trim().isNotEmpty;
  }

  /// Clears last error (stored) and notifies UI.
  Future<void> clearLastError() async {
    await LocalDb.meta().put(_kLastSyncError, '');
    notifyListeners();
  }

  /// Runs sync once. Safe to call repeatedly.
  ///
  /// Rules:
  /// - Skip if already running
  /// - Skip if no uid
  /// - Skip if anonymous or not google linked
  ///
  /// Stores results:
  /// - last_sync_at on success
  /// - last_sync_error on failure
  Future<void> syncNow(AuthProvider auth) async {
    if (_running) return;

    final uid = auth.uid;
    if (uid == null) return;

    if (auth.isAnonymous || !auth.isGoogleLinked) return;

    _running = true;
    notifyListeners();

    // clear previous error
    await LocalDb.meta().put(_kLastSyncError, '');
    notifyListeners();

    try {
      final fs = FirestoreService();

      final engine = SyncEngine(
        accountLocal: AccountLocalRepo(),
        categoryLocal: CategoryLocalRepo(),
        recordLocal: RecordLocalRepo(),
        budgetLocal: BudgetLocalRepo(),
        accountRemote: AccountRemoteRepo(fs),
        categoryRemote: CategoryRemoteRepo(fs),
        recordRemote: RecordRemoteRepo(fs),
        budgetRemote: BudgetRemoteRepo(fs),
      );

      await engine.syncAll(uid);

      await LocalDb.meta().put(_kLastSyncAt, DateTime.now().toIso8601String());
      await LocalDb.meta().put(_kLastSyncError, '');
      notifyListeners();
    } catch (e) {
      debugPrint('Sync error: $e');
      await LocalDb.meta().put(_kLastSyncError, e.toString());
      notifyListeners();
      rethrow;
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
