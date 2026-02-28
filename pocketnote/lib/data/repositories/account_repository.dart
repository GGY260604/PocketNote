// lib/data/repositories/account_repository.dart
//
// Abstraction layer for accounts.
// Today it delegates to local repo (Hive).
// Later we can extend it to sync with Firestore without changing Provider/UI APIs.

import '../../models/account.dart';
import '../local/account_local_repo.dart';

class AccountRepository {
  final AccountLocalRepo _local;

  AccountRepository(this._local);

  Future<List<Account>> getAll({bool includeDeleted = false}) {
    return _local.getAll(includeDeleted: includeDeleted);
  }

  Future<Account?> getById(String id) => _local.getById(id);

  Future<void> upsert(Account account) => _local.upsert(account);

  Future<void> softDelete(String id) => _local.softDelete(id);

  Future<void> restore(String id) => _local.restore(id);
}
