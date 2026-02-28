// lib/data/local/budget_local_repo.dart
//
// Hive implementation for Budgets.
// monthKey = "YYYY-MM".

import '../../models/budget.dart';
import 'local_db.dart';

class BudgetLocalRepo {
  Future<List<Budget>> getAll({bool includeDeleted = false}) async {
    final box = LocalDb.budgets();
    final list = box.values.toList();
    final filtered = includeDeleted
        ? list
        : list.where((b) => !b.isDeleted).toList();

    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  Future<List<Budget>> getByMonthKey(
    String monthKey, {
    bool includeDeleted = false,
  }) async {
    final all = await getAll(includeDeleted: includeDeleted);
    final filtered = all.where((b) => b.monthKey == monthKey).toList();

    filtered.sort((a, b) => a.categoryId.compareTo(b.categoryId));
    return filtered;
  }

  Future<Budget?> getById(String id) async {
    final box = LocalDb.budgets();
    for (final b in box.values) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<void> upsert(Budget budget) async {
    final box = LocalDb.budgets();
    final key = _findKeyById(budget.id);
    if (key != null) {
      await box.put(key, budget);
    } else {
      await box.put(budget.id, budget);
    }
  }

  Future<void> softDelete(String id) async {
    final box = LocalDb.budgets();
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
    final box = LocalDb.budgets();
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
    final box = LocalDb.budgets();
    for (final k in box.keys) {
      final v = box.get(k);
      if (v != null && v.id == id) return k;
    }
    return null;
  }
}
