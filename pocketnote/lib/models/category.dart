// lib/models/category.dart
//
// Category for spending or income.
// Stored locally in Hive; also synced to Firestore later.
//
// iconCodePoint + iconFontFamily allow reconstructing IconData.
// iconBgColorValue is ARGB int (e.g., 0xFF00FF00).
//
// softDelete supports sync without losing history.

import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2)
enum CategoryType {
  @HiveField(0)
  spending,
  @HiveField(1)
  income,
}

@HiveType(typeId: 3)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final CategoryType type;

  @HiveField(2)
  String name;

  @HiveField(3)
  int iconCodePoint;

  @HiveField(4)
  String iconFontFamily;

  @HiveField(5)
  int iconBgColorValue;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool isDeleted;

  Category({
    required this.id,
    required this.type,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.iconBgColorValue,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Category copyWith({
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    int? iconBgColorValue,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Category(
      id: id,
      type: type,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconBgColorValue: iconBgColorValue ?? this.iconBgColorValue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
