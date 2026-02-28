// lib/data/repositories/budget_repository.dart
//
// Abstraction layer for budgets.

import '../../models/budget.dart';
import '../local/budget_local_repo.dart';

class BudgetRepository {
  final BudgetLocalRepo _local;

  BudgetRepository(this._local);

  Future<List<Budget>> getAll({bool includeDeleted = false}) {
    return _local.getAll(includeDeleted: includeDeleted);
  }

  Future<List<Budget>> getByMonthKey(
    String monthKey, {
    bool includeDeleted = false,
  }) {
    return _local.getByMonthKey(monthKey, includeDeleted: includeDeleted);
  }

  Future<Budget?> getById(String id) => _local.getById(id);

  Future<void> upsert(Budget budget) => _local.upsert(budget);

  Future<void> softDelete(String id) => _local.softDelete(id);

  Future<void> restore(String id) => _local.restore(id);
}
