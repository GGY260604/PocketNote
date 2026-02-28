// lib/pages/settings/pages/budgets_page.dart
//
// Redesigned Budget Page
//
// Top summary card:
// - Shows Monthly Budget amount
// - Full-width progress bar
// - Below bar: Spent (left) + Over (right)
//
// Category section:
// - Container lighter than summary card
// - Tiles ordered by spent desc
// - Leading icon, name, progress bar
// - Spent (left) + Over (right)
// - Trailing budget amount
// - Tap to edit
// - Swipe right->left to delete with confirmation
// - Overflow safe (ellipsis, constraints)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_utils.dart';
import '../../../models/category.dart';
import '../../../state/app_session_provider.dart';
import '../../../state/budgets_provider.dart';
import '../../../state/categories_provider.dart';
import '../../../state/records_provider.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final budgetsP = context.read<BudgetsProvider>();
    final recordsP = context.read<RecordsProvider>();
    final session = context.read<AppSessionProvider>();

    await budgetsP.load();
    await recordsP.loadMonth(session.homeMonth);

    if (!mounted) return;
    setState(() {});
  }

  IconData _catIcon(Category c) =>
      IconData(c.iconCodePoint, fontFamily: c.iconFontFamily);

  String _rm(int cents) => MoneyUtils.toDouble(cents).toStringAsFixed(2);

  Future<void> _editBudget(Category c) async {
    final budP = context.read<BudgetsProvider>();

    final existing = budP.findForCategory(c.id);
    final existingCents = existing?.amountCents ?? 0;
    final existingRM = _rm(existingCents);

    final ctrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text('Current: $existingRM'),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'New budget (RM)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    final txt = result.trim();
    if (txt.isEmpty) return;

    final val = double.tryParse(txt);
    if (val == null || val < 0) return;

    await budP.upsertForCategory(
      categoryId: c.id,
      amountCents: MoneyUtils.toCents(val),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _confirmClear(Category c) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete budget'),
        content: Text('Clear budget for "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final catP = context.watch<CategoriesProvider>();
    final budP = context.watch<BudgetsProvider>();
    final recP = context.watch<RecordsProvider>();
    final cs = Theme.of(context).colorScheme;

    if (catP.loading || budP.loading || recP.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cats = catP.spending.where((c) => !c.isDeleted).toList();

    final spentByCat = recP.monthBudgetSpentByCategoryCents();

    cats.sort(
      (a, b) => (spentByCat[b.id] ?? 0).compareTo(spentByCat[a.id] ?? 0),
    );

    final totalBudgetCents = budP.totalBudgetCents();
    final totalSpentCents = spentByCat.values.fold(0, (s, v) => s + v);
    final overCents = totalBudgetCents - totalSpentCents;

    final progress = (totalBudgetCents <= 0)
        ? 0.0
        : (totalSpentCents / totalBudgetCents).clamp(0.0, 1.0);

    final summaryBg = cs.primaryContainer.withValues(alpha: 0.50);
    final groupBg = cs.primaryContainer.withValues(alpha: 0.12);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // ===== Summary Card =====
          Card(
            elevation: 0,
            color: summaryBg,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Budget',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ✅ Show Monthly Budget amount
                  Text(
                    'RM ${_rm(totalBudgetCents)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Spent: ${_rm(totalSpentCents)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Over: ${_rm(overCents)}',
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ===== Category Group Container =====
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: groupBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: cats.map((c) {
                final budgetCents =
                    budP.findForCategory(c.id)?.amountCents ?? 0;
                final spentCents = spentByCat[c.id] ?? 0;
                final over = budgetCents - spentCents;

                final catProgress = (budgetCents <= 0)
                    ? 0.0
                    : (spentCents / budgetCents).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey('budget-${c.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmClear(c),
                    onDismissed: (_) async {
                      await context.read<BudgetsProvider>().clearForCategory(
                        c.id,
                      );
                      if (!mounted) return;
                      setState(() {});
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: cs.errorContainer,
                      child: Icon(Icons.delete, color: cs.onErrorContainer),
                    ),
                    child: InkWell(
                      onTap: () => _editBudget(c),
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(c.iconBgColorValue),
                                child: Icon(_catIcon(c), color: Colors.black87),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: catProgress,
                                      minHeight: 8,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Spent: ${_rm(spentCents)}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Over: ${_rm(over)}',
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 90),
                                child: Text(
                                  ' ${_rm(budgetCents)}',
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
