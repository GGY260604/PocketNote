// lib/state/categories_provider.dart
//
// Provider for Categories (spending + income).
// Keeps two lists for fast UI selector rendering.

import 'package:flutter/foundation.dart' hide Category;

import '../core/utils/id_utils.dart';
import '../models/category.dart';
import '../data/local/category_local_repo.dart';
import '../data/repositories/category_repository.dart';

class CategoriesProvider extends ChangeNotifier {
  late final CategoryRepository _repo;

  bool _loading = true;
  String? _error;

  List<Category> _spending = [];
  List<Category> _income = [];

  bool get loading => _loading;
  String? get error => _error;

  List<Category> get spending => List.unmodifiable(_spending);
  List<Category> get income => List.unmodifiable(_income);

  CategoriesProvider() {
    _repo = CategoryRepository(CategoryLocalRepo());
    refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _spending = await _repo.getAll(type: CategoryType.spending);
      _income = await _repo.getAll(type: CategoryType.income);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory({
    required CategoryType type,
    required String name,
    required int iconCodePoint,
    required String iconFontFamily,
    required int iconBgColorValue,
  }) async {
    final now = DateTime.now();
    final c = Category(
      id: IdUtils.newId(),
      type: type,
      name: name,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      iconBgColorValue: iconBgColorValue,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    await _repo.upsert(c);
    await refresh();
  }

  Future<void> updateCategory(Category updated) async {
    await _repo.upsert(updated.copyWith(updatedAt: DateTime.now()));
    await refresh();
  }

  Future<void> deleteCategory(String id) async {
    await _repo.softDelete(id);
    await refresh();
  }

  Category? byId(String id) {
    for (final c in _spending) {
      if (c.id == id) return c;
    }
    for (final c in _income) {
      if (c.id == id) return c;
    }
    return null;
  }
}
