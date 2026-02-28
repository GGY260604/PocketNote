// lib/models/account.dart
//
// Asset account: cash/bank/e-wallet/etc.
// balanceCents tracks current value.
// Transfers and records will update balances (via provider/repository logic).

import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 0)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCodePoint;

  @HiveField(3)
  String iconFontFamily;

  @HiveField(4)
  int iconBgColorValue;

  @HiveField(5)
  int balanceCents;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool isDeleted;

  Account({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.iconBgColorValue,
    required this.balanceCents,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Account copyWith({
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    int? iconBgColorValue,
    int? balanceCents,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconBgColorValue: iconBgColorValue ?? this.iconBgColorValue,
      balanceCents: balanceCents ?? this.balanceCents,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
