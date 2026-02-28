// lib/pages/chat/widgets/confirm_sheet.dart
//
// Bottom sheet to confirm before saving.
// Allows editing type/category/account/date/amount/title/tag/toggles.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../models/account.dart';
import '../../../models/category.dart';
import '../../../models/chat/draft_record.dart';
import '../../../models/record.dart';
import '../../../state/accounts_provider.dart';
import '../../../state/categories_provider.dart';

class ConfirmSheet extends StatefulWidget {
  final DraftRecord draft;

  const ConfirmSheet({super.key, required this.draft});

  static Future<DraftRecord?> show(BuildContext context, DraftRecord draft) {
    return showModalBottomSheet<DraftRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ConfirmSheet(draft: draft),
    );
  }

  @override
  State<ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<ConfirmSheet> {
  late DraftRecord _d;

  late final TextEditingController _amountCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _tagCtrl;

  @override
  void initState() {
    super.initState();
    _d = widget.draft;

    _amountCtrl = TextEditingController(
      text: MoneyUtils.toDouble(_d.amountCents).toStringAsFixed(2),
    );
    _feeCtrl = TextEditingController(
      text: MoneyUtils.toDouble(_d.serviceChargeCents).toStringAsFixed(2),
    );
    _titleCtrl = TextEditingController(text: _d.title ?? '');
    _tagCtrl = TextEditingController(text: _d.tag ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _titleCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  int _parseCents(String raw, {bool allowZero = false}) {
    final t = raw.trim();
    if (t.isEmpty) return allowZero ? 0 : 0;
    final v = double.tryParse(t);
    if (v == null) return allowZero ? 0 : 0;
    if (!allowZero && v <= 0) return 0;
    if (allowZero && v < 0) return 0;
    return MoneyUtils.toCents(v);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _d.date,
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2100, 12),
    );
    if (picked == null) return;
    setState(
      () => _d = _d.copyWith(
        date: DateTime(picked.year, picked.month, picked.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final catsP = context.watch<CategoriesProvider>();
    final accP = context.watch<AccountsProvider>();

    final accounts = accP.accounts;

    final spendingCats = catsP.spending;
    final incomeCats = catsP.income;

    // ensure default picks
    if ((_d.type == RecordType.spending || _d.type == RecordType.income)) {
      if (_d.accountId == null && accounts.isNotEmpty) {
        _d = _d.copyWith(accountId: accounts.first.id);
      }
      final list = _d.type == RecordType.spending ? spendingCats : incomeCats;
      if (_d.categoryId == null && list.isNotEmpty) {
        _d = _d.copyWith(categoryId: list.first.id);
      }
    } else {
      if (_d.fromAccountId == null && accounts.isNotEmpty) {
        _d = _d.copyWith(fromAccountId: accounts.first.id);
      }
      if (_d.toAccountId == null && accounts.length >= 2) {
        _d = _d.copyWith(toAccountId: accounts[1].id);
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Confirm record before saving',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // type selector
              SegmentedButton<RecordType>(
                segments: const [
                  ButtonSegment(
                    value: RecordType.spending,
                    label: Text('Spending'),
                  ),
                  ButtonSegment(
                    value: RecordType.income,
                    label: Text('Income'),
                  ),
                  ButtonSegment(
                    value: RecordType.transfer,
                    label: Text('Transfer'),
                  ),
                ],
                selected: {_d.type},
                onSelectionChanged: (s) {
                  final t = s.first;
                  setState(() {
                    _d = _d.copyWith(type: t);

                    // reset link fields safely
                    if (t == RecordType.transfer) {
                      _d = _d.copyWith(categoryId: null, accountId: null);
                    } else {
                      _d = _d.copyWith(
                        fromAccountId: null,
                        toAccountId: null,
                        serviceChargeCents: 0,
                      );
                    }
                  });
                },
              ),

              const SizedBox(height: 12),

              // date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateUtilsX.dayKey(_d.date),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'Change',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // amount + optional fee
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount (RM)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  final cents = _parseCents(_amountCtrl.text);
                  setState(() => _d = _d.copyWith(amountCents: cents));
                },
              ),

              if (_d.type == RecordType.transfer) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _feeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Service charge (RM)',
                    hintText: '0.00',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    final cents = _parseCents(_feeCtrl.text, allowZero: true);
                    setState(() => _d = _d.copyWith(serviceChargeCents: cents));
                  },
                ),
              ],

              const SizedBox(height: 12),

              // link selectors
              if (_d.type == RecordType.spending ||
                  _d.type == RecordType.income) ...[
                _CategoryDropdown(
                  label: _d.type == RecordType.spending
                      ? 'Spending category'
                      : 'Income category',
                  categories: _d.type == RecordType.spending
                      ? spendingCats
                      : incomeCats,
                  value: _d.categoryId,
                  onChanged: (v) =>
                      setState(() => _d = _d.copyWith(categoryId: v)),
                ),
                const SizedBox(height: 12),
                _AccountDropdown(
                  label: _d.type == RecordType.spending
                      ? 'Deduct from'
                      : 'Add to',
                  accounts: accounts,
                  value: _d.accountId,
                  onChanged: (v) =>
                      setState(() => _d = _d.copyWith(accountId: v)),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _AccountDropdown(
                        label: 'From',
                        accounts: accounts,
                        value: _d.fromAccountId,
                        onChanged: (v) =>
                            setState(() => _d = _d.copyWith(fromAccountId: v)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => setState(() {
                        final tmp = _d.fromAccountId;
                        _d = _d.copyWith(
                          fromAccountId: _d.toAccountId,
                          toAccountId: tmp,
                        );
                      }),
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Reverse',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AccountDropdown(
                        label: 'To',
                        accounts: accounts,
                        value: _d.toAccountId,
                        onChanged: (v) =>
                            setState(() => _d = _d.copyWith(toAccountId: v)),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  final t = _titleCtrl.text.trim();
                  setState(() => _d = _d.copyWith(title: t.isEmpty ? null : t));
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tag (optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  final t = _tagCtrl.text.trim();
                  setState(() => _d = _d.copyWith(tag: t.isEmpty ? null : t));
                },
              ),

              const SizedBox(height: 8),
              SwitchListTile(
                value: _d.includeInStats,
                onChanged: (v) =>
                    setState(() => _d = _d.copyWith(includeInStats: v)),
                title: const Text('Include in statistics'),
              ),
              SwitchListTile(
                value: _d.includeInBudget,
                onChanged: (v) =>
                    setState(() => _d = _d.copyWith(includeInBudget: v)),
                title: const Text('Include in budget'),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      // basic validation
                      if (_d.amountCents <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Amount must be > 0')),
                        );
                        return;
                      }
                      if (_d.type == RecordType.transfer) {
                        if (_d.fromAccountId == null ||
                            _d.toAccountId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Select From and To accounts'),
                            ),
                          );
                          return;
                        }
                        if (_d.fromAccountId == _d.toAccountId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('From and To cannot be the same'),
                            ),
                          );
                          return;
                        }
                      } else {
                        if (_d.categoryId == null || _d.accountId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Select category and account'),
                            ),
                          );
                          return;
                        }
                      }
                      Navigator.pop(context, _d);
                    },
                    child: const Text('Confirm & Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final String label;
  final List<Account> accounts;
  final String? value;
  final ValueChanged<String> onChanged;

  const _AccountDropdown({
    required this.label,
    required this.accounts,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final actual = (value != null && accounts.any((a) => a.id == value))
        ? value
        : accounts.first.id;

    return DropdownButtonFormField<String>(
      initialValue: actual,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: accounts
          .map(
            (a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String label;
  final List<Category> categories;
  final String? value;
  final ValueChanged<String> onChanged;

  const _CategoryDropdown({
    required this.label,
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final actual = (value != null && categories.any((c) => c.id == value))
        ? value
        : (categories.isEmpty ? null : categories.first.id);

    return DropdownButtonFormField<String>(
      initialValue: actual,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: categories
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
    );
  }
}
