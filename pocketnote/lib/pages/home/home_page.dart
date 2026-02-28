// lib/pages/home/home_page.dart
//
// Home (content-only):
// - Month switcher (prev/next + pick)
// - Top summary card:
//    surplus, budget remaining, monthly expense, monthly income
// - Records list for selected month:
//    grouped by date header
//    dismissible (L->R) delete with confirm
//    tap tile -> edit record page
//
// Uses Providers:
// - AppSessionProvider (homeMonth)
// - RecordsProvider (loadMonth, delete)
// - CategoriesProvider / AccountsProvider (resolve names/icons)
// - BudgetsProvider (load budgets by monthKey)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../core/utils/date_utils.dart';
import '../../models/record.dart';
import '../../state/accounts_provider.dart';
import '../../state/app_session_provider.dart';
import '../../state/budgets_provider.dart';
import '../../state/categories_provider.dart';
import '../../state/records_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../edit_record/edit_record_page.dart';

import 'widgets/date_header.dart';
import 'widgets/month_header.dart';
import 'widgets/month_summary_card.dart';
import 'widgets/record_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Optional: refresh when coming back from other pages (Budgets / Edit / Settings)
class _HomePageState extends State<HomePage> with RouteAware {
  String? _lastLoadedMonthKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    final session = context.read<AppSessionProvider>();
    final records = context.read<RecordsProvider>();
    final budgets = context.read<BudgetsProvider>();

    final month = session.homeMonth;
    final monthKey = DateUtilsX.monthKey(month);

    if (_lastLoadedMonthKey == monthKey) return;

    _lastLoadedMonthKey = monthKey;

    await records.loadMonth(month);
    await budgets.load();
  }

  Future<void> _reload() async {
    // Capture everything before any await
    final session = context.read<AppSessionProvider>();
    final records = context.read<RecordsProvider>();
    final budgets = context.read<BudgetsProvider>();

    final month = session.homeMonth;
    final monthKey = DateUtilsX.monthKey(month);

    // keep loaded key in sync for refresh
    _lastLoadedMonthKey = monthKey;

    await records.loadMonth(month);
    await budgets.load();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionProvider>();
    final recordsP = context.watch<RecordsProvider>();
    final catsP = context.watch<CategoriesProvider>();
    final accP = context.watch<AccountsProvider>();
    final budgetsP = context.watch<BudgetsProvider>();

    // Ensure correct month data loaded when month changes via UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureLoaded();
    });

    final month = session.homeMonth;
    final monthKey = DateUtilsX.monthKey(month);

    final records = recordsP.monthRecords;

    // ✅ Summary numbers (respect stats + budgets)
    final expenseCents = recordsP.monthExpenseCents(statsOnly: true);
    final incomeCents = recordsP.monthIncomeCents(statsOnly: true);
    final surplusCents = incomeCents - expenseCents;

    // ✅ Budget remaining
    // - includeInBudget only (spending records)
    // - total budget from budgets provider (current monthKey already loaded)
    final spentByCat = recordsP.monthBudgetSpentByCategoryCents();
    final totalSpentBudgetCents = spentByCat.values.fold<int>(
      0,
      (a, b) => a + b,
    );

    final totalBudgetCents = budgetsP.totalBudgetCents();
    final budgetRemainingCents = totalBudgetCents - totalSpentBudgetCents;

    // Group records by day (yyyy-mm-dd)
    final groups = <String, List<Record>>{};
    for (final r in records) {
      if (r.isDeleted) continue;
      final key = DateUtilsX.dayKey(r.date);
      groups.putIfAbsent(key, () => []).add(r);
    }

    // Sort day keys desc (newest first)
    final dayKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _reload,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: MonthHeader(
                month: month,
                onPrev: () async {
                  session.setHomeMonth(DateTime(month.year, month.month - 1));
                  await _ensureLoaded();
                },
                onNext: () async {
                  session.setHomeMonth(DateTime(month.year, month.month + 1));
                  await _ensureLoaded();
                },
                onPick: () async {
                  final picked = await showMonthPicker(
                    context: context,
                    initialDate: month,
                    firstDate: DateTime(2000, 1),
                    lastDate: DateTime(2100, 12),
                  );
                  if (picked == null) return;

                  session.setHomeMonth(DateTime(picked.year, picked.month));
                  await _ensureLoaded();
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MonthSummaryCard(
                monthKey: monthKey,
                surplusCents: surplusCents,
                budgetRemainingCents: budgetRemainingCents,
                expenseCents: expenseCents,
                incomeCents: incomeCents,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          if (recordsP.loading ||
              catsP.loading ||
              accP.loading ||
              budgetsP.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recordsP.error != null)
            SliverFillRemaining(
              child: Center(child: Text('Records error: ${recordsP.error}')),
            )
          else if (catsP.error != null)
            SliverFillRemaining(
              child: Center(child: Text('Categories error: ${catsP.error}')),
            )
          else if (accP.error != null)
            SliverFillRemaining(
              child: Center(child: Text('Accounts error: ${accP.error}')),
            )
          else if (records.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.receipt_long,
                title: 'No records yet',
                message:
                    'Tap the + Record button to add spending, income, or transfer.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final dayKey = dayKeys[index];
                final dayRecords = groups[dayKey] ?? const [];

                // Sort within the day by updatedAt desc
                dayRecords.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DateHeader(dayKey: dayKey),
                      const SizedBox(height: 8),
                      ...dayRecords.map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey(r.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return ConfirmDialog.show(
                                context,
                                title: 'Delete record',
                                message:
                                    'Delete this record? You can’t undo this easily.',
                                confirmText: 'Delete',
                              );
                            },
                            onDismissed: (_) async {
                              // capture before await
                              final recP = context.read<RecordsProvider>();
                              final accP = context.read<AccountsProvider>();

                              // undo balance effect first
                              await accP.applyRecordDelete(r);

                              // then soft delete
                              await recP.softDelete(r.id);

                              if (!mounted) return;
                              await _reload();
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                            child: RecordTile(
                              record: r,
                              category: catsP.byId(r.categoryId ?? ''),
                              accountFrom: accP.byId(
                                r.accountId ?? r.fromAccountId ?? '',
                              ),
                              accountTo: accP.byId(r.toAccountId ?? ''),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditRecordPage(recordId: r.id),
                                  ),
                                );
                                // after editing, refresh month data so summary/budgets stay correct
                                if (!mounted) return;
                                await _reload();
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }, childCount: dayKeys.length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
