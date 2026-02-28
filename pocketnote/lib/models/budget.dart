// lib/models/budget.dart
//
// Monthly budget for a spending category.
// monthKey is "YYYY-MM" (e.g., 2026-02).
// amountCents is the budget limit for that month.

import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String monthKey;

  @HiveField(2)
  String categoryId; // spending category

  @HiveField(3)
  int amountCents;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  bool isDeleted;

  Budget({
    required this.id,
    required this.monthKey,
    required this.categoryId,
    required this.amountCents,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Budget copyWith({
    String? monthKey,
    String? categoryId,
    int? amountCents,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Budget(
      id: id,
      monthKey: monthKey ?? this.monthKey,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
