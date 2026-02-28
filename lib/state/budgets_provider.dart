// lib/state/budgets_provider.dart
//
// Provider for Budgets (GLOBAL per spending category).
//
// No monthKey.
// Every month uses the same budgets.
// Changing a budget updates it globally.

import 'package:flutter/foundation.dart';

import '../core/utils/id_utils.dart';
import '../models/budget.dart';
import '../data/local/budget_local_repo.dart';
import '../data/repositories/budget_repository.dart';

class BudgetsProvider extends ChangeNotifier {
  late final BudgetRepository _repo;

  bool _loading = true;
  String? _error;

  List<Budget> _budgets = [];

  bool get loading => _loading;
  String? get error => _error;

  List<Budget> get budgets => List.unmodifiable(_budgets);

  BudgetsProvider() {
    _repo = BudgetRepository(BudgetLocalRepo());
    load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // load ALL budgets (repo should return everything)
      _budgets = await _repo.getAll();
    } catch (e) {
      _error = e.toString();
      _budgets = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Budget? findForCategory(String categoryId) {
    for (final b in _budgets) {
      if (b.categoryId == categoryId && !b.isDeleted) return b;
    }
    return null;
  }

  Future<void> upsertForCategory({
    required String categoryId,
    required int amountCents,
  }) async {
    final now = DateTime.now();
    final existing = findForCategory(categoryId);

    if (existing == null) {
      final b = Budget(
        id: IdUtils.newId(),
        monthKey: 'global', // keep field if model requires it
        categoryId: categoryId,
        amountCents: amountCents,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );
      await _repo.upsert(b);
    } else {
      await _repo.upsert(
        existing.copyWith(
          amountCents: amountCents,
          updatedAt: now,
          isDeleted: false,
        ),
      );
    }

    // keep cache accurate
    await load();
  }

  Future<void> clearForCategory(String categoryId) async {
    final existing = findForCategory(categoryId);
    if (existing == null) return;

    await _repo.softDelete(existing.id);
    await load();
  }

  int totalBudgetCents() {
    return _budgets
        .where((b) => !b.isDeleted)
        .fold<int>(0, (sum, b) => sum + b.amountCents);
  }
}
