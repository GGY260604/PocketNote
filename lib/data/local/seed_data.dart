// lib/data/local/seed_data.dart
//
// First-launch seeding logic.
// Inserts default accounts + categories if boxes are empty
// OR if the "seed_v1_done" flag is missing.
//
// Safe design:
// - Uses stable IDs for defaults
// - Does NOT overwrite user-edited data
// - Only inserts missing default items by ID

import '../../core/constants/default_categories.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import 'local_db.dart';

class SeedData {
  static const String _seedFlagKey = 'seed_v1_done';

  static Future<void> ensureSeeded() async {
    final meta = LocalDb.meta();

    final done = meta.get(_seedFlagKey, defaultValue: '0') == '1';
    if (done) return;

    final now = DateTime.now();

    // Seed accounts
    final accBox = LocalDb.accounts();
    for (final a in DefaultCategories.accounts) {
      final exists = accBox.values.any((x) => x.id == a.id);
      if (!exists) {
        await accBox.add(
          Account(
            id: a.id,
            name: a.name,
            iconCodePoint: a.iconCodePoint,
            iconFontFamily: a.iconFontFamily,
            iconBgColorValue: a.iconBgColorValue,
            balanceCents: a.initialBalanceCents,
            createdAt: now,
            updatedAt: now,
            isDeleted: false,
          ),
        );
      }
    }

    // Seed categories (spending)
    final catBox = LocalDb.categories();
    for (final c in DefaultCategories.spending) {
      final exists = catBox.values.any((x) => x.id == c.id);
      if (!exists) {
        await catBox.add(
          Category(
            id: c.id,
            type: CategoryType.spending,
            name: c.name,
            iconCodePoint: c.iconCodePoint,
            iconFontFamily: c.iconFontFamily,
            iconBgColorValue: c.iconBgColorValue,
            createdAt: now,
            updatedAt: now,
            isDeleted: false,
          ),
        );
      }
    }

    // Seed categories (income)
    for (final c in DefaultCategories.income) {
      final exists = catBox.values.any((x) => x.id == c.id);
      if (!exists) {
        await catBox.add(
          Category(
            id: c.id,
            type: CategoryType.income,
            name: c.name,
            iconCodePoint: c.iconCodePoint,
            iconFontFamily: c.iconFontFamily,
            iconBgColorValue: c.iconBgColorValue,
            createdAt: now,
            updatedAt: now,
            isDeleted: false,
          ),
        );
      }
    }

    await meta.put(_seedFlagKey, '1');
  }
}
