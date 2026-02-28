// lib/core/constants/default_categories.dart
//
// Default (built-in) categories & accounts.
// These are constant seed definitions inserted on first launch.
//
// NOTE:
// We store icon as:
// - iconCodePoint (int)
// - iconFontFamily (String) = 'MaterialIcons'
//
// iconBgColorValue is ARGB int (0xFFRRGGBB).

import 'package:flutter/material.dart';

class DefaultSeedCategory {
  final String id; // stable id for defaults
  final String name;
  final int iconCodePoint;
  final String iconFontFamily;
  final int iconBgColorValue;

  const DefaultSeedCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.iconBgColorValue,
  });
}

class DefaultSeedAccount {
  final String id; // stable id for defaults
  final String name;
  final int iconCodePoint;
  final String iconFontFamily;
  final int iconBgColorValue;
  final int initialBalanceCents;

  const DefaultSeedAccount({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.iconBgColorValue,
    required this.initialBalanceCents,
  });
}

class DefaultCategories {
  static String _font(IconData i) => i.fontFamily ?? 'MaterialIcons';

  // ==============================
  // 🟡 Spending Categories
  // ==============================
  static final List<DefaultSeedCategory> spending = [
    DefaultSeedCategory(
      id: 'sp_food',
      name: 'Food & Dining',
      iconCodePoint: Icons.restaurant.codePoint,
      iconFontFamily: _font(Icons.restaurant),
      iconBgColorValue: 0xFFFFF3CD,
    ),
    DefaultSeedCategory(
      id: 'sp_transport',
      name: 'Transport',
      iconCodePoint: Icons.directions_car.codePoint,
      iconFontFamily: _font(Icons.directions_car),
      iconBgColorValue: 0xFFE3F2FD,
    ),
    DefaultSeedCategory(
      id: 'sp_groceries',
      name: 'Groceries',
      iconCodePoint: Icons.local_grocery_store.codePoint,
      iconFontFamily: _font(Icons.local_grocery_store),
      iconBgColorValue: 0xFFFFF9C4,
    ),
    DefaultSeedCategory(
      id: 'sp_rent',
      name: 'Rent / Mortgage',
      iconCodePoint: Icons.home.codePoint,
      iconFontFamily: _font(Icons.home),
      iconBgColorValue: 0xFFBBDEFB,
    ),
    DefaultSeedCategory(
      id: 'sp_utilities',
      name: 'Utilities',
      iconCodePoint: Icons.bolt.codePoint,
      iconFontFamily: _font(Icons.bolt),
      iconBgColorValue: 0xFFB3E5FC,
    ),
    DefaultSeedCategory(
      id: 'sp_shopping',
      name: 'Shopping',
      iconCodePoint: Icons.shopping_bag.codePoint,
      iconFontFamily: _font(Icons.shopping_bag),
      iconBgColorValue: 0xFFE1BEE7,
    ),
    DefaultSeedCategory(
      id: 'sp_entertainment',
      name: 'Entertainment',
      iconCodePoint: Icons.movie.codePoint,
      iconFontFamily: _font(Icons.movie),
      iconBgColorValue: 0xFFF8BBD0,
    ),
    DefaultSeedCategory(
      id: 'sp_health',
      name: 'Health & Medical',
      iconCodePoint: Icons.local_hospital.codePoint,
      iconFontFamily: _font(Icons.local_hospital),
      iconBgColorValue: 0xFFC8E6C9,
    ),
    DefaultSeedCategory(
      id: 'sp_travel',
      name: 'Travel',
      iconCodePoint: Icons.flight.codePoint,
      iconFontFamily: _font(Icons.flight),
      iconBgColorValue: 0xFFD1C4E9,
    ),
    DefaultSeedCategory(
      id: 'sp_other',
      name: 'Other',
      iconCodePoint: Icons.more_horiz.codePoint,
      iconFontFamily: _font(Icons.more_horiz),
      iconBgColorValue: 0xFFE0E0E0,
    ),
  ];

  // ==============================
  // 🟢 Income Categories
  // ==============================
  static final List<DefaultSeedCategory> income = [
    DefaultSeedCategory(
      id: 'in_salary',
      name: 'Salary',
      iconCodePoint: Icons.work.codePoint,
      iconFontFamily: _font(Icons.work),
      iconBgColorValue: 0xFFC8E6C9,
    ),
    DefaultSeedCategory(
      id: 'in_bonus',
      name: 'Bonus',
      iconCodePoint: Icons.card_giftcard.codePoint,
      iconFontFamily: _font(Icons.card_giftcard),
      iconBgColorValue: 0xFFDCE775,
    ),
    DefaultSeedCategory(
      id: 'in_business',
      name: 'Business',
      iconCodePoint: Icons.store.codePoint,
      iconFontFamily: _font(Icons.store),
      iconBgColorValue: 0xFFA5D6A7,
    ),
    DefaultSeedCategory(
      id: 'in_investment',
      name: 'Investment',
      iconCodePoint: Icons.trending_up.codePoint,
      iconFontFamily: _font(Icons.trending_up),
      iconBgColorValue: 0xFFB2DFDB,
    ),
    DefaultSeedCategory(
      id: 'in_interest',
      name: 'Interest',
      iconCodePoint: Icons.attach_money.codePoint,
      iconFontFamily: _font(Icons.attach_money),
      iconBgColorValue: 0xFFDCEDC8,
    ),
  ];

  // ==============================
  // 🏦 Default Accounts
  // ==============================
  static final List<DefaultSeedAccount> accounts = [
    DefaultSeedAccount(
      id: 'ac_cash',
      name: 'Cash',
      iconCodePoint: Icons.payments.codePoint,
      iconFontFamily: _font(Icons.payments),
      iconBgColorValue: 0xFFFFF9C4,
      initialBalanceCents: 0,
    ),
    DefaultSeedAccount(
      id: 'ac_bank',
      name: 'Bank Account',
      iconCodePoint: Icons.account_balance.codePoint,
      iconFontFamily: _font(Icons.account_balance),
      iconBgColorValue: 0xFFBBDEFB,
      initialBalanceCents: 0,
    ),
    DefaultSeedAccount(
      id: 'ac_savings',
      name: 'Savings',
      iconCodePoint: Icons.savings.codePoint,
      iconFontFamily: _font(Icons.savings),
      iconBgColorValue: 0xFFB2DFDB,
      initialBalanceCents: 0,
    ),
    DefaultSeedAccount(
      id: 'ac_credit',
      name: 'Credit Card',
      iconCodePoint: Icons.credit_card.codePoint,
      iconFontFamily: _font(Icons.credit_card),
      iconBgColorValue: 0xFFFFCDD2,
      initialBalanceCents: 0,
    ),
  ];
}
