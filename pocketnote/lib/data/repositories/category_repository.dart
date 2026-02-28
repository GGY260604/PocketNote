// lib/data/repositories/category_repository.dart
//
// Abstraction layer for categories.

import '../../models/category.dart';
import '../local/category_local_repo.dart';

class CategoryRepository {
  final CategoryLocalRepo _local;

  CategoryRepository(this._local);

  Future<List<Category>> getAll({
    required CategoryType type,
    bool includeDeleted = false,
  }) {
    return _local.getAll(type: type, includeDeleted: includeDeleted);
  }

  Future<Category?> getById(String id) => _local.getById(id);

  Future<void> upsert(Category category) => _local.upsert(category);

  Future<void> softDelete(String id) => _local.softDelete(id);

  Future<void> restore(String id) => _local.restore(id);
}
