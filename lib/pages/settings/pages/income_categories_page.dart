// lib/pages/settings/pages/income_categories_page.dart
//
// Same UI as spending categories, but for income.

import 'package:flutter/material.dart';
import '../../../models/category.dart';
import 'spending_categories_page.dart';

class IncomeCategoriesPage extends StatelessWidget {
  const IncomeCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoriesBasePage(
      type: CategoryType.income,
      title: 'Income Categories',
    );
  }
}