// lib/pages/edit_record/edit_record_page.dart
//
// EditRecordPage
// - Supports editing spending, income, transfer
// - Overflow-safe: ListView + keyboard padding
// - Uses Provider data: RecordsProvider, CategoriesProvider, AccountsProvider
//
// Navigation:
// Navigator.push(context, MaterialPageRoute(
//   builder: (_) => EditRecordPage(recordId: record.id),
// ));

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/money_utils.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/record.dart';
import '../../state/accounts_provider.dart';
import '../../state/categories_provider.dart';
import '../../state/records_provider.dart';

class EditRecordPage extends StatefulWidget {
  final String recordId;

  const EditRecordPage({super.key, required this.recordId});

  @override
  State<EditRecordPage> createState() => _EditRecordPageState();
}

class _EditRecordPageState extends State<EditRecordPage> {
  final _formKey = GlobalKey<FormState>();

  // Editable fields
  late RecordType _type;
  String? _categoryId;
  String? _accountId;

  String? _fromAccountId;
  String? _toAccountId;

  late DateTime _date;

  late TextEditingController _amountCtrl;
  late TextEditingController _serviceCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _tagCtrl;

  bool _includeInStats = true;
  bool _includeInBudget = true;

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _serviceCtrl = TextEditingController();
    _titleCtrl = TextEditingController();
    _tagCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _serviceCtrl.dispose();
    _titleCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _loadInitial() {
    final recP = context.read<RecordsProvider>();
    final r = recP.byId(widget.recordId);

    if (r == null) {
      // show error state
      setState(() => _ready = true);
      return;
    }

    _type = r.type;
    _categoryId = r.categoryId;
    _accountId = r.accountId;
    _fromAccountId = r.fromAccountId;
    _toAccountId = r.toAccountId;

    _date = DateTime(r.date.year, r.date.month, r.date.day);

    _amountCtrl.text = MoneyUtils.toDouble(r.amountCents).toStringAsFixed(2);
    _serviceCtrl.text = MoneyUtils.toDouble(
      r.serviceChargeCents,
    ).toStringAsFixed(2);
    _titleCtrl.text = (r.title ?? '');
    _tagCtrl.text = (r.tag ?? '');

    _includeInStats = r.includeInStats;
    _includeInBudget = r.includeInBudget;

    setState(() => _ready = true);
  }

  IconData _iconFrom(Category c) =>
      IconData(c.iconCodePoint, fontFamily: c.iconFontFamily);
  IconData _iconFromAccount(Account a) =>
      IconData(a.iconCodePoint, fontFamily: a.iconFontFamily);

  Widget _categoryChip(Category c) {
    final selected = c.id == _categoryId;
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => setState(() => _categoryId = c.id),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Color(c.iconBgColorValue),
              child: Icon(_iconFrom(c), size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  void _reverseTransfer() {
    setState(() {
      final tmp = _fromAccountId;
      _fromAccountId = _toAccountId;
      _toAccountId = tmp;
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final recP = context.read<RecordsProvider>();
    final accP = context.read<AccountsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final old = recP.byId(widget.recordId);
    if (old == null) return;

    final amountCents = MoneyUtils.toCents(
      double.parse(_amountCtrl.text.trim()),
    );
    final serviceCents = MoneyUtils.toCents(
      double.tryParse(_serviceCtrl.text.trim()) ?? 0,
    );

    // Basic validation by type
    if ((_type == RecordType.spending || _type == RecordType.income) &&
        _categoryId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    if (_type == RecordType.spending || _type == RecordType.income) {
      if (_accountId == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please select an account.')),
        );
        return;
      }
    }

    if (_type == RecordType.transfer) {
      if (_fromAccountId == null || _toAccountId == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please select From/To accounts.')),
        );
        return;
      }
      if (_fromAccountId == _toAccountId) {
        messenger.showSnackBar(
          const SnackBar(content: Text('From and To cannot be the same.')),
        );
        return;
      }
    }

    final updated = old.copyWith(
      amountCents: amountCents,
      date: _date,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
      includeInStats: _includeInStats,
      includeInBudget: _includeInBudget,
      categoryId: (_type == RecordType.transfer) ? null : _categoryId,
      accountId: (_type == RecordType.transfer) ? null : _accountId,
      fromAccountId: (_type == RecordType.transfer) ? _fromAccountId : null,
      toAccountId: (_type == RecordType.transfer) ? _toAccountId : null,
      serviceChargeCents: (_type == RecordType.transfer) ? serviceCents : 0,
      updatedAt: DateTime.now(),
    );

    await accP.applyRecordUpdate(old, updated);
    await recP.updateRecord(updated);

    if (!mounted) return;
    navigator.pop(true);
  }

  Future<void> _confirmDelete() async {
    final navigator = Navigator.of(context);
    final recP = context.read<RecordsProvider>();
    final accP = context.read<AccountsProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text('This record will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => navigator.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final r = recP.byId(widget.recordId);
    if (r != null) {
      await accP.applyRecordDelete(r);
    }

    await recP.softDelete(widget.recordId);

    if (!mounted) return;
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final accP = context.watch<AccountsProvider>();
    final catP = context.watch<CategoriesProvider>();
    final recP = context.watch<RecordsProvider>();
    final r = recP.byId(widget.recordId);

    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Record')),
        body: const Center(child: Text('Record not found.')),
      );
    }

    final categories = (_type == RecordType.income)
        ? catP.income
        : catP.spending;
    final accounts = accP.accounts.where((a) => !a.isDeleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Record'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            children: [
              // Record type badge
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _type == RecordType.spending
                              ? 'Spending'
                              : _type == RecordType.income
                              ? 'Income'
                              : 'Transfer',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        _fmtDate(_date),
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _pickDate,
                        child: const Text('Change date'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Category selector (spending/income only)
              if (_type != RecordType.transfer) ...[
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _categoryChip(categories[i]),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Accounts (spending/income) or From/To (transfer)
              if (_type != RecordType.transfer) ...[
                DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    border: OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(a.iconBgColorValue),
                                child: Icon(
                                  _iconFromAccount(a),
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // use ConstrainedBox instead of Expanded
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: Text(
                                  a.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                  validator: (v) =>
                      (v == null) ? 'Please select an account' : null,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _fromAccountId,
                        decoration: const InputDecoration(
                          labelText: 'From account',
                          border: OutlineInputBorder(),
                        ),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  a.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _fromAccountId = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Reverse',
                      onPressed: _reverseTransfer,
                      icon: const Icon(Icons.swap_horiz),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _toAccountId,
                        decoration: const InputDecoration(
                          labelText: 'To account',
                          border: OutlineInputBorder(),
                        ),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  a.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _toAccountId = v),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _type == RecordType.income
                      ? 'Income amount (RM)'
                      : 'Amount (RM)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  final d = double.tryParse(t);
                  if (d == null || d <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Service charge (transfer only)
              if (_type == RecordType.transfer) ...[
                TextFormField(
                  controller: _serviceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Service charge (RM)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    final d = double.tryParse(t);
                    if (d == null || d < 0) {
                      return 'Enter a valid service charge';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Title + Tag
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tag (optional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Toggles
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _includeInStats,
                      onChanged: (v) => setState(() => _includeInStats = v),
                      title: const Text('Include in statistics'),
                    ),
                    SwitchListTile(
                      value: _includeInBudget,
                      onChanged: (v) => setState(() => _includeInBudget = v),
                      title: const Text('Include in budget'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Save button
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
