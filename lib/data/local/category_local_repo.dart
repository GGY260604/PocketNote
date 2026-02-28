// lib/data/local/category_local_repo.dart
//
// Hive implementation for Categories.

import '../../models/category.dart';
import 'local_db.dart';

class CategoryLocalRepo {
  Future<List<Category>> getAll({
    required CategoryType type,
    bool includeDeleted = false,
  }) async {
    final box = LocalDb.categories();
    final list = box.values.where((c) => c.type == type).toList();
    final filtered = includeDeleted
        ? list
        : list.where((c) => !c.isDeleted).toList();

    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  Future<Category?> getById(String id) async {
    final box = LocalDb.categories();
    for (final c in box.values) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> upsert(Category category) async {
    final box = LocalDb.categories();
    final key = _findKeyById(category.id);
    if (key != null) {
      await box.put(key, category);
    } else {
      await box.put(category.id, category);
    }
  }

  Future<void> softDelete(String id) async {
    final box = LocalDb.categories();
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
    final box = LocalDb.categories();
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
    final box = LocalDb.categories();
    for (final k in box.keys) {
      final v = box.get(k);
      if (v != null && v.id == id) return k;
    }
    return null;
  }
}
