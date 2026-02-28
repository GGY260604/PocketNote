// lib/data/local/account_local_repo.dart
//
// Hive implementation for Accounts.
// Works with both int keys (from add()) and string keys (from put()).
// We always locate entries by Account.id for stability.

import '../../models/account.dart';
import 'local_db.dart';

class AccountLocalRepo {
  Future<List<Account>> getAll({bool includeDeleted = false}) async {
    final box = LocalDb.accounts();
    final list = box.values.toList();
    final filtered = includeDeleted
        ? list
        : list.where((a) => !a.isDeleted).toList();

    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  Future<Account?> getById(String id) async {
    final box = LocalDb.accounts();
    for (final a in box.values) {
      if (a.id == id) return a;
    }
    return null;
  }

  // Update + insert (if id not found).
  Future<void> upsert(Account account) async {
    final box = LocalDb.accounts();
    final key = _findKeyById(account.id);
    if (key != null) {
      await box.put(key, account);
    } else {
      // use id as key for new inserts
      await box.put(account.id, account);
    }
  }

  Future<void> softDelete(String id) async {
    final box = LocalDb.accounts();
    final key = _findKeyById(id);
    if (key == null) return;

    final current = box.get(key);
    if (current == null) return;

    final updated = current.copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );

    await box.put(key, updated);
  }

  Future<void> restore(String id) async {
    final box = LocalDb.accounts();
    final key = _findKeyById(id);
    if (key == null) return;

    final current = box.get(key);
    if (current == null) return;

    final updated = current.copyWith(
      isDeleted: false,
      updatedAt: DateTime.now(),
    );

    await box.put(key, updated);
  }

  dynamic _findKeyById(String id) {
    final box = LocalDb.accounts();
    for (final k in box.keys) {
      final v = box.get(k);
      if (v != null && v.id == id) return k;
    }
    return null;
  }
}
