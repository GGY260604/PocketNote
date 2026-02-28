// lib/models/chat/draft_record.dart
//
// Draft produced by parsing user message / voice / receipt.
// Confirm sheet edits this draft before saving.

import '../record.dart';

class DraftRecord {
  RecordType type;

  // money
  int amountCents;
  int serviceChargeCents;

  // date + optional text
  DateTime date;
  String? title;
  String? tag;

  bool includeInStats;
  bool includeInBudget;

  // link fields
  String? categoryId; // spending/income
  String? accountId; // spending/income
  String? fromAccountId; // transfer
  String? toAccountId; // transfer

  DraftRecord({
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
  });

  DraftRecord copyWith({
    RecordType? type,
    int? amountCents,
    int? serviceChargeCents,
    DateTime? date,
    String? title,
    String? tag,
    bool? includeInStats,
    bool? includeInBudget,
    String? categoryId,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
  }) {
    return DraftRecord(
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      serviceChargeCents: serviceChargeCents ?? this.serviceChargeCents,
      date: date ?? this.date,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      includeInStats: includeInStats ?? this.includeInStats,
      includeInBudget: includeInBudget ?? this.includeInBudget,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
    );
  }
}
