// lib/state/accounts_provider.dart
//
// Provider for Accounts.
// Adds balance adjustment helpers so RecordHub can update balances
// for spending/income/transfer without touching UI later.

import 'package:flutter/foundation.dart';

import '../core/utils/id_utils.dart';
import '../models/account.dart';
import '../models/record.dart';
import '../data/local/account_local_repo.dart';
import '../data/repositories/account_repository.dart';

class AccountsProvider extends ChangeNotifier {
  late final AccountRepository _repo;

  bool _loading = true;
  String? _error;

  List<Account> _accounts = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Account> get accounts => List.unmodifiable(_accounts);

  AccountsProvider() {
    _repo = AccountRepository(AccountLocalRepo());
    refresh();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _accounts = await _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Account? byId(String id) {
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> addAccount({
    required String name,
    required int iconCodePoint,
    required String iconFontFamily,
    required int iconBgColorValue,
    int initialBalanceCents = 0,
  }) async {
    final now = DateTime.now();
    final a = Account(
      id: IdUtils.newId(),
      name: name,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      iconBgColorValue: iconBgColorValue,
      balanceCents: initialBalanceCents,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    await _repo.upsert(a);
    await refresh();
  }

  Future<void> updateAccount(Account updated) async {
    await _repo.upsert(updated.copyWith(updatedAt: DateTime.now()));
    await refresh();
  }

  Future<void> deleteAccount(String id) async {
    await _repo.softDelete(id);
    await refresh();
  }

  /// Apply a delta to an account balance (can be positive or negative).
  Future<void> applyBalanceDelta({
    required String accountId,
    required int deltaCents,
  }) async {
    final acc = byId(accountId);
    if (acc == null) return;

    final updated = acc.copyWith(
      balanceCents: acc.balanceCents + deltaCents,
      updatedAt: DateTime.now(),
    );

    await _repo.upsert(updated);
    await refresh();
  }

  /// Apply multiple deltas in one logical action.
  /// If any account is missing, we skip it safely.
  Future<void> applyBalanceDeltas(Map<String, int> deltas) async {
    for (final entry in deltas.entries) {
      await applyBalanceDelta(accountId: entry.key, deltaCents: entry.value);
    }
  }

  Map<String, int> _deltasForRecord(Record r, {int sign = 1}) {
    if (r.isDeleted) return const {};

    switch (r.type) {
      case RecordType.spending:
        {
          final acc = r.accountId;
          if (acc == null) return const {};
          // Spending reduces account balance
          return {acc: -sign * r.amountCents};
        }

      case RecordType.income:
        {
          final acc = r.accountId;
          if (acc == null) return const {};
          // Income increases account balance
          return {acc: sign * r.amountCents};
        }

      case RecordType.transfer:
        {
          final from = r.fromAccountId;
          final to = r.toAccountId;
          if (from == null || to == null) return const {};
          // From loses amount + service charge; To gains amount
          return {
            from: -sign * (r.amountCents + r.serviceChargeCents),
            to: sign * r.amountCents,
          };
        }
    }
  }

  /// Apply effect of ONE record to balances.
  /// sign = +1 means apply effect
  /// sign = -1 means undo effect
  Future<void> applyRecordEffect(Record r, {int sign = 1}) async {
    final deltas = _deltasForRecord(r, sign: sign);
    if (deltas.isEmpty) return;
    await applyBalanceDeltas(deltas);
  }

  /// Editing: undo old record effect, then apply new record effect.
  Future<void> applyRecordUpdate(Record oldR, Record newR) async {
    // undo old (only if not deleted)
    if (!oldR.isDeleted) {
      await applyRecordEffect(oldR, sign: -1);
    }
    // apply new (only if not deleted)
    if (!newR.isDeleted) {
      await applyRecordEffect(newR, sign: 1);
    }
  }

  /// Deleting: undo record effect once.
  Future<void> applyRecordDelete(Record r) async {
    if (r.isDeleted) return;
    await applyRecordEffect(r, sign: -1);
  }
}
