// lib/state/records_provider.dart
//
// Robust RecordsProvider:
// - loading always returns to false
// - exposes rangeRecords + monthRecords
// - loadRange filters locally (Hive) via repo.getAll()
// - errors are surfaced in error string (ChartPage will show it)

import 'package:flutter/foundation.dart';

import '../core/utils/record_filters.dart';
import '../models/record.dart';
import '../data/local/record_local_repo.dart';
import '../data/repositories/record_repository.dart';

class RecordsProvider extends ChangeNotifier {
  late final RecordRepository _repo;

  bool _loading = false; // start false so UI doesn't spin forever by default
  String? _error;

  List<Record> _monthRecords = [];
  List<Record> _rangeRecords = [];

  bool get loading => _loading;
  String? get error => _error;

  List<Record> get monthRecords => List.unmodifiable(_monthRecords);
  List<Record> get rangeRecords => List.unmodifiable(_rangeRecords);

  RecordsProvider() {
    _repo = RecordRepository(RecordLocalRepo());
  }

  Future<void> loadMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    await loadRange(start, end, alsoSetMonth: true);
  }

  Future<void> loadRange(
    DateTime start,
    DateTime end, {
    bool alsoSetMonth = false,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final all = await _repo.getAll();

      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);

      bool inRange(DateTime d) {
        final dd = DateTime(d.year, d.month, d.day);
        final afterStart = dd.isAtSameMomentAs(s) || dd.isAfter(s);
        final beforeEnd = dd.isAtSameMomentAs(e) || dd.isBefore(e);
        return afterStart && beforeEnd;
      }

      final filtered =
          all.where((r) => !r.isDeleted && inRange(r.date)).toList()
            ..sort((a, b) {
              final byDate = b.date.compareTo(a.date);
              if (byDate != 0) return byDate;
              return b.updatedAt.compareTo(a.updatedAt);
            });

      _rangeRecords = filtered;
      if (alsoSetMonth) _monthRecords = filtered;
    } catch (e) {
      _error = e.toString();
      // ensure we don't keep stale data silently
      _rangeRecords = [];
      if (alsoSetMonth) _monthRecords = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> upsertRecord(Record record) async {
    await _repo.upsert(record);
  }

  Future<void> deleteRecord(String id) async {
    await softDelete(id);
  }

  int monthExpenseCents({bool statsOnly = true}) {
    final list = monthRecords;
    final filtered = statsOnly
        ? list.where(RecordFilters.countsForStats)
        : list.where((r) => !r.isDeleted);

    return filtered
        .where(RecordFilters.isExpense)
        .fold(0, (sum, r) => sum + r.amountCents);
  }

  int monthIncomeCents({bool statsOnly = true}) {
    final list = monthRecords;
    final filtered = statsOnly
        ? list.where(RecordFilters.countsForStats)
        : list.where((r) => !r.isDeleted);

    return filtered
        .where(RecordFilters.isIncome)
        .fold(0, (sum, r) => sum + r.amountCents);
  }

  int rangeExpenseCents({bool statsOnly = true}) {
    final list = rangeRecords;
    final filtered = statsOnly
        ? list.where(RecordFilters.countsForStats)
        : list.where((r) => !r.isDeleted);

    return filtered
        .where(RecordFilters.isExpense)
        .fold(0, (sum, r) => sum + r.amountCents);
  }

  int rangeIncomeCents({bool statsOnly = true}) {
    final list = rangeRecords;
    final filtered = statsOnly
        ? list.where(RecordFilters.countsForStats)
        : list.where((r) => !r.isDeleted);

    return filtered
        .where(RecordFilters.isIncome)
        .fold(0, (sum, r) => sum + r.amountCents);
  }

  Map<String, int> monthBudgetSpentByCategoryCents() {
    // For budgets: spending only, includeInBudget only
    final filtered = monthRecords
        .where(RecordFilters.countsForBudget)
        .where(RecordFilters.isExpense)
        .where((r) => r.categoryId != null);

    final map = <String, int>{};
    for (final r in filtered) {
      final id = r.categoryId!;
      map[id] = (map[id] ?? 0) + r.amountCents;
    }
    return map;
  }

  Record? byId(String id) {
    // search range first (usually newest loaded)
    final iRange = _rangeRecords.indexWhere((r) => r.id == id);
    if (iRange >= 0) return _rangeRecords[iRange];

    final iMonth = _monthRecords.indexWhere((r) => r.id == id);
    if (iMonth >= 0) return _monthRecords[iMonth];

    return null;
  }

  /// Update an existing record (repo + in-memory lists).
  Future<void> updateRecord(Record updated) async {
    // Update in-memory (range)
    final iRange = _rangeRecords.indexWhere((r) => r.id == updated.id);
    if (iRange >= 0) {
      _rangeRecords[iRange] = updated;
    }

    // Update in-memory (month)
    final iMonth = _monthRecords.indexWhere((r) => r.id == updated.id);
    if (iMonth >= 0) {
      _monthRecords[iMonth] = updated;
    }

    notifyListeners();

    // Persist
    await _repo.upsert(updated);
  }

  /// Soft delete helper (marks isDeleted=true)
  Future<void> softDelete(String id) async {
    final r = byId(id);
    if (r == null) return;

    await updateRecord(r.copyWith(isDeleted: true, updatedAt: DateTime.now()));
  }
}
