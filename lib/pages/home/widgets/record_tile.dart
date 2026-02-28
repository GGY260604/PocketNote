// lib/pages/home/widgets/record_tile.dart
//
// Record tile UI:
// - category icon + name
// - related account
// - amount (income green, spending red, transfer neutral)

import 'package:flutter/material.dart';

import '../../../core/utils/money_utils.dart';
import '../../../models/account.dart';
import '../../../models/category.dart';
import '../../../models/record.dart';

class RecordTile extends StatelessWidget {
  final Record record;
  final Category? category;
  final Account? accountFrom;
  final Account? accountTo;
  final VoidCallback onTap;

  const RecordTile({
    super.key,
    required this.record,
    required this.category,
    required this.accountFrom,
    required this.accountTo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Icon + bg: from category (spending/income), transfer uses account icon
    IconData icon;
    Color bg;
    String title;
    String subtitle;

    if (record.type == RecordType.transfer) {
      final fromName = accountFrom?.name ?? 'From';
      final toName = accountTo?.name ?? 'To';
      title = record.title?.trim().isNotEmpty == true
          ? record.title!.trim()
          : 'Transfer';
      subtitle = '$fromName → $toName';

      icon = IconData(
        (accountFrom?.iconCodePoint ?? Icons.swap_horiz.codePoint),
        fontFamily: accountFrom?.iconFontFamily ?? 'MaterialIcons',
      );
      bg = Color(
        accountFrom?.iconBgColorValue ?? cs.surfaceContainerHighest.toARGB32(),
      );
    } else {
      title = category?.name ?? 'Unknown';
      subtitle = accountFrom?.name ?? 'Account';

      icon = IconData(
        (category?.iconCodePoint ?? Icons.category.codePoint),
        fontFamily: category?.iconFontFamily ?? 'MaterialIcons',
      );
      bg = Color(
        category?.iconBgColorValue ?? cs.surfaceContainerHighest.toARGB32(),
      );
    }

    // Amount color rules
    Color amountColor = cs.onSurface;
    String amountText = MoneyUtils.formatRM(record.amountCents);

    if (record.type == RecordType.income) {
      amountColor = Colors.green;
    } else if (record.type == RecordType.spending) {
      amountColor = Colors.red;
      amountText = '- $amountText';
    } else if (record.type == RecordType.transfer) {
      // neutral
    }

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: bg,
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(title, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, overflow: TextOverflow.ellipsis),
        trailing: Text(
          amountText,
          style: TextStyle(fontWeight: FontWeight.w800, color: amountColor),
        ),
      ),
    );
  }
}
