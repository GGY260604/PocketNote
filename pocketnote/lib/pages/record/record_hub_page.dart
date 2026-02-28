// lib/pages/record/record_hub_page.dart
//
// Record Hub (content-only):
// - Spending / Income / Transfer
// - Category icon selector (spending/income)
// - Amount, optional title/tag
// - Account picker + date picker
// - includeInStats/includeInBudget toggles
//
// Save behavior:
// - Insert record into Hive via RecordsProvider.upsertRecord
// - Update account balances via AccountsProvider.updateAccount
// - Switch Home month to record date month and reload Home list

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/id_utils.dart';
import '../../core/utils/money_utils.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/record.dart';
import '../../state/accounts_provider.dart';
import '../../state/app_session_provider.dart';
import '../../state/categories_provider.dart';
import '../../state/records_provider.dart';
import '../../widgets/empty_state.dart';

class RecordHubPage extends StatefulWidget {
  const RecordHubPage({super.key});

  @override
  State<RecordHubPage> createState() => _RecordHubPageState();
}

class _RecordHubPageState extends State<RecordHubPage>
    with TickerProviderStateMixin {
  late final TabController _tab;

  // shared
  DateTime _date = DateTime.now();
  bool _includeInStats = true;
  bool _includeInBudget = true;
  final _titleCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  // spending/income
  String? _selectedCategoryId;
  String? _selectedAccountId;
  final _amountCtrl = TextEditingController();

  // transfer
  String? _fromAccountId;
  String? _toAccountId;
  final _transferAmountCtrl = TextEditingController();
  final _serviceChargeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _tagCtrl.dispose();
    _amountCtrl.dispose();
    _transferAmountCtrl.dispose();
    _serviceChargeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2100, 12),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  int _parseCents(TextEditingController c) {
    final raw = c.text.trim();
    if (raw.isEmpty) return 0;
    final v = double.tryParse(raw);
    if (v == null) return 0;
    if (v <= 0) return 0;
    return MoneyUtils.toCents(v);
  }

  Future<void> _afterSaveNavigateHomeMonth(DateTime date) async {
    final session = context.read<AppSessionProvider>();
    final month = DateTime(date.year, date.month);
    session.setHomeMonth(month);

    // Reload records for home month
    await context.read<RecordsProvider>().loadMonth(month);

    // Switch tab to Home
    session.setTab(0);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Record saved')));
    }
  }

  Future<void> _saveSpending() async {
    final cats = context.read<CategoriesProvider>();
    final accs = context.read<AccountsProvider>();
    final records = context.read<RecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final amountCents = _parseCents(_amountCtrl);

    if (amountCents <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    if (_selectedCategoryId == null ||
        cats.byId(_selectedCategoryId!) == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select a spending category')),
      );
      return;
    }

    if (_selectedAccountId == null || accs.byId(_selectedAccountId!) == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select an account')),
      );
      return;
    }

    final now = DateTime.now();

    final record = Record(
      id: IdUtils.newId(),
      type: RecordType.spending,
      amountCents: amountCents,
      date: _date,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
      includeInStats: _includeInStats,
      includeInBudget: _includeInBudget,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
      fromAccountId: null,
      toAccountId: null,
      serviceChargeCents: 0,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    await accs.applyRecordEffect(record, sign: 1);
    await records.upsertRecord(record);

    // If you do UI actions after awaits, guard it (State only)
    if (!mounted) return;

    // Clear for next entry
    _amountCtrl.clear();
    _titleCtrl.clear();
    _tagCtrl.clear();

    await _afterSaveNavigateHomeMonth(_date);
  }

  Future<void> _saveIncome() async {
    final cats = context.read<CategoriesProvider>();
    final accs = context.read<AccountsProvider>();
    final records = context.read<RecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final amountCents = _parseCents(_amountCtrl);
    if (amountCents <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    if (_selectedCategoryId == null ||
        cats.byId(_selectedCategoryId!) == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select an income category')),
      );
      return;
    }

    if (_selectedAccountId == null || accs.byId(_selectedAccountId!) == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select an account')),
      );
      return;
    }

    final now = DateTime.now();

    final record = Record(
      id: IdUtils.newId(),
      type: RecordType.income,
      amountCents: amountCents,
      date: _date,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
      includeInStats: _includeInStats,
      includeInBudget: _includeInBudget,
      categoryId: _selectedCategoryId,
      accountId: _selectedAccountId,
      fromAccountId: null,
      toAccountId: null,
      serviceChargeCents: 0,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    await accs.applyRecordEffect(record, sign: 1);
    await records.upsertRecord(record);

    // UI work after awaits: guard (State only)
    if (!mounted) return;

    _amountCtrl.clear();
    _titleCtrl.clear();
    _tagCtrl.clear();

    await _afterSaveNavigateHomeMonth(_date);
  }

  Future<void> _saveTransfer() async {
    final accs = context.read<AccountsProvider>();
    final records = context.read<RecordsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final amountCents = _parseCents(_transferAmountCtrl);
    final feeCents = _parseCents(_serviceChargeCtrl);

    if (amountCents <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid transfer amount')),
      );
      return;
    }
    if (_fromAccountId == null || accs.byId(_fromAccountId!) == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select From account')),
      );
      return;
    }
    if (_toAccountId == null || accs.byId(_toAccountId!) == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select To account')),
      );
      return;
    }
    if (_fromAccountId == _toAccountId) {
      messenger.showSnackBar(
        const SnackBar(content: Text('From and To cannot be the same')),
      );
      return;
    }

    final now = DateTime.now();

    final record = Record(
      id: IdUtils.newId(),
      type: RecordType.transfer,
      amountCents: amountCents,
      date: _date,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
      includeInStats: _includeInStats,
      includeInBudget: _includeInBudget,
      categoryId: null,
      accountId: null,
      fromAccountId: _fromAccountId,
      toAccountId: _toAccountId,
      serviceChargeCents: feeCents,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    await accs.applyRecordEffect(record, sign: 1);
    await records.upsertRecord(record);

    if (!mounted) return;

    _transferAmountCtrl.clear();
    _serviceChargeCtrl.clear();
    _titleCtrl.clear();
    _tagCtrl.clear();

    await _afterSaveNavigateHomeMonth(_date);
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<CategoriesProvider>();
    final accs = context.watch<AccountsProvider>();

    final spendingCats = cats.spending;
    final incomeCats = cats.income;
    final accounts = accs.accounts;

    // auto-select defaults if empty
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }
    if (_fromAccountId == null && accounts.isNotEmpty) {
      _fromAccountId = accounts.first.id;
    }
    if (_toAccountId == null && accounts.length >= 2) {
      _toAccountId = accounts[1].id;
    }
    if (_selectedCategoryId == null) {
      final list = _tab.index == 0 ? spendingCats : incomeCats;
      if (list.isNotEmpty) _selectedCategoryId = list.first.id;
    }

    if (cats.loading || accs.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cats.error != null) {
      return Center(child: Text('Categories error: ${cats.error}'));
    }
    if (accs.error != null) {
      return Center(child: Text('Accounts error: ${accs.error}'));
    }
    if (accounts.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No accounts',
        message:
            'Create at least one account in Settings → Assets before adding records.',
      );
    }

    return Column(
      children: [
        // top tabs
        Material(
          elevation: 1,
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Spending'),
              Tab(text: 'Income'),
              Tab(text: 'Transfer'),
            ],
            onTap: (_) => setState(() {
              // reset category selection based on tab type
              if (_tab.index == 0 && spendingCats.isNotEmpty) {
                _selectedCategoryId = spendingCats.first.id;
              } else if (_tab.index == 1 && incomeCats.isNotEmpty) {
                _selectedCategoryId = incomeCats.first.id;
              }
            }),
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _SpendingIncomeForm(
                mode: _FormMode.spending,
                categories: spendingCats,
                accounts: accounts,
                date: _date,
                includeInStats: _includeInStats,
                includeInBudget: _includeInBudget,
                titleCtrl: _titleCtrl,
                tagCtrl: _tagCtrl,
                amountCtrl: _amountCtrl,
                selectedCategoryId: _selectedCategoryId,
                selectedAccountId: _selectedAccountId,
                onPickDate: _pickDate,
                onChangeCategory: (id) =>
                    setState(() => _selectedCategoryId = id),
                onChangeAccount: (id) =>
                    setState(() => _selectedAccountId = id),
                onChangeIncludeInStats: (v) =>
                    setState(() => _includeInStats = v),
                onChangeIncludeInBudget: (v) =>
                    setState(() => _includeInBudget = v),
                onSave: _saveSpending,
              ),
              _SpendingIncomeForm(
                mode: _FormMode.income,
                categories: incomeCats,
                accounts: accounts,
                date: _date,
                includeInStats: _includeInStats,
                includeInBudget: _includeInBudget,
                titleCtrl: _titleCtrl,
                tagCtrl: _tagCtrl,
                amountCtrl: _amountCtrl,
                selectedCategoryId: _selectedCategoryId,
                selectedAccountId: _selectedAccountId,
                onPickDate: _pickDate,
                onChangeCategory: (id) =>
                    setState(() => _selectedCategoryId = id),
                onChangeAccount: (id) =>
                    setState(() => _selectedAccountId = id),
                onChangeIncludeInStats: (v) =>
                    setState(() => _includeInStats = v),
                onChangeIncludeInBudget: (v) =>
                    setState(() => _includeInBudget = v),
                onSave: _saveIncome,
              ),
              _TransferForm(
                accounts: accounts,
                date: _date,
                includeInStats: _includeInStats,
                includeInBudget: _includeInBudget,
                titleCtrl: _titleCtrl,
                tagCtrl: _tagCtrl,
                amountCtrl: _transferAmountCtrl,
                feeCtrl: _serviceChargeCtrl,
                fromId: _fromAccountId,
                toId: _toAccountId,
                onPickDate: _pickDate,
                onChangeFrom: (id) => setState(() => _fromAccountId = id),
                onChangeTo: (id) => setState(() => _toAccountId = id),
                onReverse: () => setState(() {
                  final tmp = _fromAccountId;
                  _fromAccountId = _toAccountId;
                  _toAccountId = tmp;
                }),
                onChangeIncludeInStats: (v) =>
                    setState(() => _includeInStats = v),
                onChangeIncludeInBudget: (v) =>
                    setState(() => _includeInBudget = v),
                onSave: _saveTransfer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _FormMode { spending, income }

class _SpendingIncomeForm extends StatelessWidget {
  final _FormMode mode;
  final List<Category> categories;
  final List<Account> accounts;

  final DateTime date;

  final bool includeInStats;
  final bool includeInBudget;

  final TextEditingController titleCtrl;
  final TextEditingController tagCtrl;
  final TextEditingController amountCtrl;

  final String? selectedCategoryId;
  final String? selectedAccountId;

  final VoidCallback onPickDate;
  final ValueChanged<String> onChangeCategory;
  final ValueChanged<String> onChangeAccount;

  final ValueChanged<bool> onChangeIncludeInStats;
  final ValueChanged<bool> onChangeIncludeInBudget;

  final Future<void> Function() onSave;

  const _SpendingIncomeForm({
    required this.mode,
    required this.categories,
    required this.accounts,
    required this.date,
    required this.includeInStats,
    required this.includeInBudget,
    required this.titleCtrl,
    required this.tagCtrl,
    required this.amountCtrl,
    required this.selectedCategoryId,
    required this.selectedAccountId,
    required this.onPickDate,
    required this.onChangeCategory,
    required this.onChangeAccount,
    required this.onChangeIncludeInStats,
    required this.onChangeIncludeInBudget,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const EmptyState(
        icon: Icons.category_outlined,
        title: 'No categories',
        message: 'Create categories in Settings first.',
      );
    }

    final isIncome = mode == _FormMode.income;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              title: isIncome
                  ? 'Select income category'
                  : 'Select spending category',
            ),
            const SizedBox(height: 8),

            _CategorySelector(
              categories: categories,
              selectedId: selectedCategoryId,
              onSelect: onChangeCategory,
            ),

            const SizedBox(height: 14),
            _SectionTitle(title: 'Details'),
            const SizedBox(height: 8),

            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
                hintText: 'e.g. 12.50',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(isIncome ? Icons.add : Icons.remove),
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: tagCtrl,
              decoration: const InputDecoration(
                labelText: 'Tag (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),
            _SectionTitle(
              title: isIncome ? 'Add to account' : 'Deduct from account',
            ),
            const SizedBox(height: 8),

            _AccountDropdown(
              accounts: accounts,
              value: selectedAccountId,
              onChanged: onChangeAccount,
            ),

            const SizedBox(height: 12),
            _DateRow(date: date, onPick: onPickDate),

            const SizedBox(height: 12),
            _Toggles(
              includeInStats: includeInStats,
              includeInBudget: includeInBudget,
              onChangeIncludeInStats: onChangeIncludeInStats,
              onChangeIncludeInBudget: onChangeIncludeInBudget,
            ),

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onSave(),
              icon: const Icon(Icons.check),
              label: Text(isIncome ? 'Save Income' : 'Save Spending'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferForm extends StatelessWidget {
  final List<Account> accounts;
  final DateTime date;

  final bool includeInStats;
  final bool includeInBudget;

  final TextEditingController titleCtrl;
  final TextEditingController tagCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController feeCtrl;

  final String? fromId;
  final String? toId;

  final VoidCallback onPickDate;
  final ValueChanged<String> onChangeFrom;
  final ValueChanged<String> onChangeTo;
  final VoidCallback onReverse;

  final ValueChanged<bool> onChangeIncludeInStats;
  final ValueChanged<bool> onChangeIncludeInBudget;

  final Future<void> Function() onSave;

  const _TransferForm({
    required this.accounts,
    required this.date,
    required this.includeInStats,
    required this.includeInBudget,
    required this.titleCtrl,
    required this.tagCtrl,
    required this.amountCtrl,
    required this.feeCtrl,
    required this.fromId,
    required this.toId,
    required this.onPickDate,
    required this.onChangeFrom,
    required this.onChangeTo,
    required this.onReverse,
    required this.onChangeIncludeInStats,
    required this.onChangeIncludeInBudget,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.length < 2) {
      return const EmptyState(
        icon: Icons.swap_horiz,
        title: 'Need 2 accounts',
        message: 'Create at least 2 accounts to use transfer.',
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(title: 'Transfer accounts'),
            const SizedBox(height: 8),

            LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 520; // adjust if you want

                if (compact) {
                  // Stack vertically to prevent overflow
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AccountDropdown(
                        label: 'From',
                        accounts: accounts,
                        value: fromId,
                        onChanged: onChangeFrom,
                      ),
                      const SizedBox(height: 1),
                      Align(
                        alignment: Alignment.center,
                        child: IconButton(
                          onPressed: onReverse,
                          icon: const Icon(Icons.swap_vert),
                          tooltip: 'Reverse',
                        ),
                      ),
                      const SizedBox(height: 1),
                      _AccountDropdown(
                        label: 'To',
                        accounts: accounts,
                        value: toId,
                        onChanged: onChangeTo,
                      ),
                    ],
                  );
                }

                // Wide layout: keep side-by-side
                return Row(
                  children: [
                    Expanded(
                      child: _AccountDropdown(
                        label: 'From',
                        accounts: accounts,
                        value: fromId,
                        onChanged: onChangeFrom,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: onReverse,
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Reverse',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AccountDropdown(
                        label: 'To',
                        accounts: accounts,
                        value: toId,
                        onChanged: onChangeTo,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 14),
            _SectionTitle(title: 'Details'),
            const SizedBox(height: 8),

            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (RM)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: feeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Service charge (RM, optional)',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: tagCtrl,
              decoration: const InputDecoration(
                labelText: 'Tag (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),
            _DateRow(date: date, onPick: onPickDate),

            const SizedBox(height: 12),
            _Toggles(
              includeInStats: includeInStats,
              includeInBudget: includeInBudget,
              onChangeIncludeInStats: onChangeIncludeInStats,
              onChangeIncludeInBudget: onChangeIncludeInBudget,
            ),

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onSave(),
              icon: const Icon(Icons.check),
              label: const Text('Save Transfer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPick;

  const _DateRow({required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                DateUtilsX.dayKey(date),
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('Change', style: TextStyle(color: cs.primary)),
          ],
        ),
      ),
    );
  }
}

class _Toggles extends StatelessWidget {
  final bool includeInStats;
  final bool includeInBudget;
  final ValueChanged<bool> onChangeIncludeInStats;
  final ValueChanged<bool> onChangeIncludeInBudget;

  const _Toggles({
    required this.includeInStats,
    required this.includeInBudget,
    required this.onChangeIncludeInStats,
    required this.onChangeIncludeInBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          value: includeInStats,
          onChanged: onChangeIncludeInStats,
          title: const Text('Include in statistics'),
        ),
        SwitchListTile(
          value: includeInBudget,
          onChanged: onChangeIncludeInBudget,
          title: const Text('Include in budget'),
        ),
      ],
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final String? label;
  final List<Account> accounts;
  final String? value;
  final ValueChanged<String> onChanged;

  const _AccountDropdown({
    this.label,
    required this.accounts,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final actualValue = (value != null && accounts.any((a) => a.id == value))
        ? value
        : accounts.first.id;

    return DropdownButtonFormField<String>(
      initialValue: actualValue,
      decoration: InputDecoration(
        labelText: label ?? 'Account',
        border: const OutlineInputBorder(),
      ),
      items: accounts.map((a) {
        return DropdownMenuItem(
          value: a.id,
          child: Text(a.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final selected = c.id == selectedId;

          final icon = IconData(c.iconCodePoint, fontFamily: c.iconFontFamily);
          final bg = Color(c.iconBgColorValue);

          return InkWell(
            onTap: () => onSelect(c.id),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 72,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: bg,
                    child: Icon(icon, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
