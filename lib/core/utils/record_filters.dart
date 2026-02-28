// lib/core/utils/record_filters.dart
//
// Centralized rules for which records count for:
// - stats (charts, trend, summary)
// - budgets (budget remaining)

import '../../models/record.dart';

class RecordFilters {
  static bool countsForStats(Record r) => !r.isDeleted && r.includeInStats;

  static bool countsForBudget(Record r) => !r.isDeleted && r.includeInBudget;

  static bool isExpense(Record r) => r.type == RecordType.spending;
  static bool isIncome(Record r) => r.type == RecordType.income;

  // For analytics we usually exclude transfers from income/expense totals
  static bool isTransfer(Record r) => r.type == RecordType.transfer;
}
