// lib/data/sync/sync_engine.dart
//
// Offline-first sync (Hive <-> Firestore)
// Strategy:
// - last-write-wins using updatedAt
// - soft delete via isDeleted
//
// It does:
// 1) pull remote -> merge into local
// 2) push local -> merge into remote

import '../../models/category.dart';

import '../local/account_local_repo.dart';
import '../local/budget_local_repo.dart';
import '../local/category_local_repo.dart';
import '../local/record_local_repo.dart';

import '../remote/account_remote_repo.dart';
import '../remote/budget_remote_repo.dart';
import '../remote/category_remote_repo.dart';
import '../remote/record_remote_repo.dart';

class SyncEngine {
  final AccountLocalRepo _accLocal;
  final CategoryLocalRepo _catLocal;
  final RecordLocalRepo _recLocal;
  final BudgetLocalRepo _budLocal;

  final AccountRemoteRepo _accRemote;
  final CategoryRemoteRepo _catRemote;
  final RecordRemoteRepo _recRemote;
  final BudgetRemoteRepo _budRemote;

  SyncEngine({
    required AccountLocalRepo accountLocal,
    required CategoryLocalRepo categoryLocal,
    required RecordLocalRepo recordLocal,
    required BudgetLocalRepo budgetLocal,
    required AccountRemoteRepo accountRemote,
    required CategoryRemoteRepo categoryRemote,
    required RecordRemoteRepo recordRemote,
    required BudgetRemoteRepo budgetRemote,
  }) : _accLocal = accountLocal,
       _catLocal = categoryLocal,
       _recLocal = recordLocal,
       _budLocal = budgetLocal,
       _accRemote = accountRemote,
       _catRemote = categoryRemote,
       _recRemote = recordRemote,
       _budRemote = budgetRemote;

  Future<void> syncAll(String uid) async {
    // Pull remote first (so local sees newer remote edits)
    await _syncAccounts(uid);
    await _syncCategories(uid);
    await _syncBudgets(uid);
    await _syncRecords(uid);

    // Then push local
    await _pushAccounts(uid);
    await _pushCategories(uid);
    await _pushBudgets(uid);
    await _pushRecords(uid);
  }

  // ---------- Accounts ----------
  Future<void> _syncAccounts(String uid) async {
    final remote = await _accRemote.getAll(uid);
    for (final r in remote) {
      final local = await _accLocal.getById(r.id);
      if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
        await _accLocal.upsert(r);
      }
    }
  }

  Future<void> _pushAccounts(String uid) async {
    final local = await _accLocal.getAll(includeDeleted: true);
    final remote = await _accRemote.getAll(uid);
    final remoteById = {for (final x in remote) x.id: x};

    for (final l in local) {
      final r = remoteById[l.id];
      if (r == null || l.updatedAt.isAfter(r.updatedAt)) {
        await _accRemote.upsert(uid, l);
      }
    }
  }

  // ---------- Categories ----------
  Future<void> _syncCategories(String uid) async {
    final remote = await _catRemote.getAll(uid);
    for (final r in remote) {
      final local = await _catLocal.getById(r.id);
      if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
        await _catLocal.upsert(r);
      }
    }
  }

  Future<void> _pushCategories(String uid) async {
    // local categories are separated by type in repo.getAll, so we pull both types
    final localSp = await _catLocal.getAll(
      type: CategoryType.spending,
      includeDeleted: true,
    );
    final localIn = await _catLocal.getAll(
      type: CategoryType.income,
      includeDeleted: true,
    );
    final local = [...localSp, ...localIn];

    final remote = await _catRemote.getAll(uid);
    final remoteById = {for (final x in remote) x.id: x};

    for (final l in local) {
      final r = remoteById[l.id];
      if (r == null || l.updatedAt.isAfter(r.updatedAt)) {
        await _catRemote.upsert(uid, l);
      }
    }
  }

  // ---------- Budgets ----------
  Future<void> _syncBudgets(String uid) async {
    final remote = await _budRemote.getAll(uid);
    for (final r in remote) {
      final local = await _budLocal.getById(r.id);
      if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
        await _budLocal.upsert(r);
      }
    }
  }

  Future<void> _pushBudgets(String uid) async {
    final local = await _budLocal.getAll(includeDeleted: true);
    final remote = await _budRemote.getAll(uid);
    final remoteById = {for (final x in remote) x.id: x};

    for (final l in local) {
      final r = remoteById[l.id];
      if (r == null || l.updatedAt.isAfter(r.updatedAt)) {
        await _budRemote.upsert(uid, l);
      }
    }
  }

  // ---------- Records ----------
  Future<void> _syncRecords(String uid) async {
    final remote = await _recRemote.getAll(uid);
    final localAll = await _recLocal.getAll();
    final localById = {for (final x in localAll) x.id: x};

    for (final r in remote) {
      final local = localById[r.id];
      if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
        await _recLocal.upsert(r);
      }
    }
  }

  Future<void> _pushRecords(String uid) async {
    final local = await _recLocal.getAll();
    final remote = await _recRemote.getAll(uid);
    final remoteById = {for (final x in remote) x.id: x};

    for (final l in local) {
      final r = remoteById[l.id];
      if (r == null || l.updatedAt.isAfter(r.updatedAt)) {
        await _recRemote.upsert(uid, l);
      }
    }
  }
}
