// lib/models/record.dart
//
// 3 record types: spending, income, transfer.
// Common fields support stats/budget toggles + soft delete + updatedAt for sync.
//
// All money fields are in cents.

import 'package:hive/hive.dart';

part 'record.g.dart';

@HiveType(typeId: 4)
enum RecordType {
  @HiveField(0)
  spending,
  @HiveField(1)
  income,
  @HiveField(2)
  transfer,
}

@HiveType(typeId: 5)
class Record extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final RecordType type;

  @HiveField(2)
  int amountCents;

  @HiveField(3)
  DateTime date; // normalized day

  @HiveField(4)
  String? title;

  @HiveField(5)
  String? tag;

  @HiveField(6)
  bool includeInStats;

  @HiveField(7)
  bool includeInBudget;

  // For spending/income:
  @HiveField(8)
  String? categoryId;

  @HiveField(9)
  String? accountId;

  // For transfer:
  @HiveField(10)
  String? fromAccountId;

  @HiveField(11)
  String? toAccountId;

  @HiveField(12)
  int serviceChargeCents;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  DateTime updatedAt;

  @HiveField(15)
  bool isDeleted;

  Record({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.date,
    this.title,
    this.tag,
    this.includeInStats = true,
    this.includeInBudget = true,
    this.categoryId,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.serviceChargeCents = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Record copyWith({
    int? amountCents,
    DateTime? date,
    String? title,
    String? tag,
    bool? includeInStats,
    bool? includeInBudget,
    String? categoryId,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
    int? serviceChargeCents,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Record(
      id: id,
      type: type,
      amountCents: amountCents ?? this.amountCents,
      date: date ?? this.date,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      includeInStats: includeInStats ?? this.includeInStats,
      includeInBudget: includeInBudget ?? this.includeInBudget,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      serviceChargeCents: serviceChargeCents ?? this.serviceChargeCents,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
