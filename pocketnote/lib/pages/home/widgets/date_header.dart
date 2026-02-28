// lib/pages/home/widgets/date_header.dart
//
// Date header for grouped records list.

import 'package:flutter/material.dart';

class DateHeader extends StatelessWidget {
  final String dayKey; // yyyy-mm-dd

  const DateHeader({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      dayKey,
      style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurfaceVariant),
    );
  }
}
