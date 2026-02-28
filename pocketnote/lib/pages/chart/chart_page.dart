// lib/pages/chart/chart_page.dart
//
// Features:
// - Period: week / month / year
// - Kind: Expense or Income (separate views)
// - Stats respect: includeInStats + !isDeleted
// - Trend line (daily total)
// - Pie ratio by category with colorful slices (category.iconBgColorValue)
// - Legend shows color rectangle + category name + amount
// - Rank list shows category icon (circle bg) + name + amount
//
// Requires: fl_chart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/utils/money_utils.dart';
import '../../core/utils/record_filters.dart';
import '../../models/category.dart';
import '../../models/record.dart';
import '../../state/categories_provider.dart';
import '../../state/records_provider.dart';

enum ChartPeriod { week, month, year }

enum AnalyzeKind { expense, income }

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  ChartPeriod _period = ChartPeriod.month;
  AnalyzeKind _kind = AnalyzeKind.expense;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTimeRange _rangeFor(ChartPeriod p) {
    final now = DateTime.now();
    final today = _dateOnly(now);

    switch (p) {
      case ChartPeriod.week:
        final start = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: start, end: today);
      case ChartPeriod.month:
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case ChartPeriod.year:
        final start = DateTime(today.year, 1, 1);
        final end = DateTime(today.year, 12, 31);
        return DateTimeRange(start: start, end: end);
    }
  }

  Future<void> _load() async {
    final recP = context.read<RecordsProvider>();
    final r = _rangeFor(_period);
    await recP.loadRange(r.start, r.end);
  }

  bool _matchKind(Record r) {
    if (_kind == AnalyzeKind.expense) return r.type == RecordType.spending;
    return r.type == RecordType.income;
  }

  List<Record> _statsRecords(List<Record> all) {
    return all
        .where(RecordFilters.countsForStats) // !isDeleted && includeInStats
        .where(_matchKind)
        .toList();
  }

  Map<DateTime, int> _dailyTotals(DateTimeRange range, List<Record> records) {
    final map = <DateTime, int>{};
    final start = _dateOnly(range.start);
    final end = _dateOnly(range.end);

    for (
      DateTime d = start;
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))
    ) {
      map[d] = 0;
    }

    for (final r in records) {
      final day = _dateOnly(r.date);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      map[day] = (map[day] ?? 0) + r.amountCents;
    }
    return map;
  }

  Map<String, int> _totalsByCategory(List<Record> records) {
    final map = <String, int>{};
    for (final r in records) {
      final id = r.categoryId;
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + r.amountCents;
    }
    return map;
  }

  Color _catColor(Category c) => Color(c.iconBgColorValue);

  IconData _catIcon(Category c) =>
      IconData(c.iconCodePoint, fontFamily: c.iconFontFamily);

  Widget _metricCard(
    BuildContext context,
    String title,
    String value, {
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: valueColor ?? cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _kindLabel() => _kind == AnalyzeKind.expense ? 'Expense' : 'Income';
  Color _kindColor() =>
      _kind == AnalyzeKind.expense ? Colors.red : Colors.green;

  @override
  Widget build(BuildContext context) {
    final recP = context.watch<RecordsProvider>();
    final catP = context.watch<CategoriesProvider>();
    final cs = Theme.of(context).colorScheme;

    if (recP.loading || catP.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recP.error != null) {
      return Center(child: Text('Error: ${recP.error}'));
    }
    if (catP.error != null) {
      return Center(child: Text('Error: ${catP.error}'));
    }

    final range = _rangeFor(_period);

    // includeInStats + kind
    final records = _statsRecords(recP.rangeRecords);

    final totalCents = records.fold<int>(0, (sum, r) => sum + r.amountCents);
    final count = records.length;

    final days = (range.end.difference(range.start).inDays + 1).clamp(1, 366);
    final avgDaily = (totalCents / days).round();

    // Trend spots (RM)
    final dayMap = _dailyTotals(range, records);
    final daysList = dayMap.keys.toList()..sort((a, b) => a.compareTo(b));
    final spots = <FlSpot>[];
    for (var i = 0; i < daysList.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), (dayMap[daysList[i]] ?? 0).toDouble() / 100.0),
      );
    }

    // Category totals + rank
    final totalsByCat = _totalsByCategory(records);
    final ranked = totalsByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pie sections + legend
    final pieSections = <PieChartSectionData>[];
    final legendItems = <_LegendItemData>[];

    final denom = totalCents <= 0 ? 1 : totalCents;

    const maxSlices = 7;
    int othersSum = 0;

    for (var i = 0; i < ranked.length; i++) {
      final e = ranked[i];
      final c = catP.byId(e.key);
      if (c == null || c.isDeleted) continue;

      if (i >= maxSlices) {
        othersSum += e.value;
        continue;
      }

      final color = _catColor(c);
      final percent = (e.value / denom) * 100;

      pieSections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          radius: 60,
          color: color,
          title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      );

      legendItems.add(
        _LegendItemData(color: color, title: c.name, amountCents: e.value),
      );
    }

    if (othersSum > 0) {
      final percent = (othersSum / denom) * 100;
      final color = cs.outlineVariant;

      pieSections.add(
        PieChartSectionData(
          value: othersSum.toDouble(),
          radius: 60,
          color: color,
          title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      );

      legendItems.add(
        _LegendItemData(color: color, title: 'Others', amountCents: othersSum),
      );
    }

    final label = _kindLabel();
    final labelColor = _kindColor();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Controls
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Period:',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                DropdownButton<ChartPeriod>(
                  value: _period,
                  items: const [
                    DropdownMenuItem(
                      value: ChartPeriod.week,
                      child: Text('Week'),
                    ),
                    DropdownMenuItem(
                      value: ChartPeriod.month,
                      child: Text('Month'),
                    ),
                    DropdownMenuItem(
                      value: ChartPeriod.year,
                      child: Text('Year'),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _period = v);
                    await _load();
                  },
                ),
                SegmentedButton<AnalyzeKind>(
                  segments: const [
                    ButtonSegment(
                      value: AnalyzeKind.expense,
                      label: Text('Expense'),
                    ),
                    ButtonSegment(
                      value: AnalyzeKind.income,
                      label: Text('Income'),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Metrics
        Row(
          children: [
            _metricCard(
              context,
              '$label total',
              MoneyUtils.formatRM(totalCents),
              valueColor: labelColor,
            ),
            const SizedBox(width: 10),
            _metricCard(context, 'Avg daily', MoneyUtils.formatRM(avgDaily)),
          ],
        ),
        Row(
          children: [
            _metricCard(context, '$label count', '$count'),
            const SizedBox(width: 10),
            _metricCard(
              context,
              'Range',
              '${range.start.month}/${range.start.day} - ${range.end.month}/${range.end.day}',
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Trend
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label trend',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 220,
                  child: spots.isEmpty
                      ? const Center(child: Text('No data'))
                      : LineChart(
                          LineChartData(
                            minY: 0,
                            gridData: const FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: (daysList.length / 4)
                                      .clamp(1, 999)
                                      .toDouble(),
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.round();
                                    if (idx < 0 || idx >= daysList.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final d = daysList[idx];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${d.month}/${d.day}',
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                color: cs.primary,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Pie + Legend
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label ratio by category',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (pieSections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No category data'),
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: pieSections,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Legend(items: legendItems),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Rank list with icons
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label rank',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (ranked.isEmpty)
                  const Text('No data')
                else
                  ...ranked.take(10).map((e) {
                    final c = catP.byId(e.key);
                    if (c == null || c.isDeleted) {
                      return const SizedBox.shrink();
                    }
                    final bg = _catColor(c);
                    final icon = _catIcon(c);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: bg,
                            child: Icon(icon, color: Colors.black87, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            MoneyUtils.formatRM(e.value),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItemData {
  final Color color;
  final String title;
  final int amountCents;

  _LegendItemData({
    required this.color,
    required this.title,
    required this.amountCents,
  });
}

class _Legend extends StatelessWidget {
  final List<_LegendItemData> items;

  const _Legend({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: items.map((it) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // colored rectangle legend
              Container(
                width: 14,
                height: 10,
                decoration: BoxDecoration(
                  color: it.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  it.title,
                  style: TextStyle(color: cs.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                MoneyUtils.formatRM(it.amountCents),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
