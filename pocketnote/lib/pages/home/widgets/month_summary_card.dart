// lib/pages/home/widgets/month_summary_card.dart
//
// Summary card:
// - surplus
// - budget remaining
// - expense
// - income
//
// NEW:
// - Tap Surplus/Expense/Income -> push AccountsPage
// - Tap Budget Remaining -> push BudgetsPage
// - Back button pops -> returns to Home (normal Navigator push)
//
// Notes:
// - Uses MaterialPageRoute so it works without named routes.
// - Wrap metrics with InkWell (keeps ripple + rounded corners).
// - Overflow safe preserved.

import 'package:flutter/material.dart';
import '../../../core/utils/money_utils.dart';

// add these imports (adjust paths if your folder differs)
import '../../settings/pages/accounts_page.dart';
import '../../settings/pages/budgets_page.dart';

class MonthSummaryCard extends StatelessWidget {
  final String monthKey;
  final int surplusCents;
  final int budgetRemainingCents;
  final int expenseCents;
  final int incomeCents;

  const MonthSummaryCard({
    super.key,
    required this.monthKey,
    required this.surplusCents,
    required this.budgetRemainingCents,
    required this.expenseCents,
    required this.incomeCents,
  });

  void _goAccounts(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AccountsPage()));
  }

  void _goBudgets(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BudgetsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final surplusColor = surplusCents >= 0 ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Month Summary ($monthKey)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Surplus',
                    value: MoneyUtils.formatRM(surplusCents),
                    valueColor: surplusColor,
                    onTap: () => _goAccounts(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Metric(
                    label: 'Budget Remaining',
                    value: MoneyUtils.formatRM(budgetRemainingCents),
                    valueColor: budgetRemainingCents >= 0
                        ? Colors.green
                        : Colors.red,
                    onTap: () => _goBudgets(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Expense',
                    value: MoneyUtils.formatRM(expenseCents),
                    valueColor: Colors.red,
                    onTap: () => _goAccounts(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Metric(
                    label: 'Income',
                    value: MoneyUtils.formatRM(incomeCents),
                    valueColor: Colors.green,
                    onTap: () => _goAccounts(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;

  const _Metric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
