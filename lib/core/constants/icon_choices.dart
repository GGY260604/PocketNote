// lib/core/constants/icon_choices.dart
//
// Small curated icon list for category/account customization.
// Keeps UI simple and avoids extra packages.

import 'package:flutter/material.dart';

class IconChoices {
  static const String materialFont = 'MaterialIcons';

  static const List<IconData> icons = [
    // ==============================
    // 💰 Finance / Assets / Money
    // ==============================
    Icons.payments,
    Icons.attach_money,
    Icons.account_balance,
    Icons.account_balance_wallet,
    Icons.savings,
    Icons.credit_card,
    Icons.receipt_long,
    Icons.trending_up,
    Icons.trending_down,
    Icons.paid,
    Icons.currency_exchange,
    Icons.calculate, // tax / finance
    Icons.request_quote, // invoice
    // ==============================
    // 🏠 Fixed / Essential Expenses
    // ==============================
    Icons.home,
    Icons.apartment,
    Icons.bolt,
    Icons.wifi,
    Icons.water_drop,
    Icons.phone_android,
    Icons.tv,
    Icons.security,
    Icons.local_gas_station,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.train,
    Icons.directions_bike,

    // ==============================
    // 🍽 Daily Living
    // ==============================
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_grocery_store,
    Icons.shopping_cart,
    Icons.shopping_bag,
    Icons.fastfood,
    Icons.delivery_dining,

    // ==============================
    // 🏥 Health
    // ==============================
    Icons.local_hospital,
    Icons.medical_services,
    Icons.fitness_center,
    Icons.monitor_heart,

    // ==============================
    // 🎉 Lifestyle / Entertainment
    // ==============================
    Icons.movie,
    Icons.sports_esports,
    Icons.sports_soccer,
    Icons.music_note,
    Icons.flight,
    Icons.beach_access,
    Icons.weekend,
    Icons.card_giftcard,

    // ==============================
    // 💼 Work / Income
    // ==============================
    Icons.work,
    Icons.business,
    Icons.store,
    Icons.school,
    Icons.engineering,
    Icons.handshake,
    Icons.inventory_2,

    // ==============================
    // 🐾 Misc
    // ==============================
    Icons.pets,
    Icons.child_care,
    Icons.more_horiz,
  ];

  static const List<Color> colors = [
    // Red / Debt
    Color(0xFFFFCDD2),
    Color(0xFFF8BBD0),

    // Purple / Lifestyle
    Color(0xFFE1BEE7),
    Color(0xFFD1C4E9),

    // Blue / Fixed / Utilities
    Color(0xFFBBDEFB),
    Color(0xFFB3E5FC),

    // Teal / Savings / Stable
    Color(0xFFB2EBF2),
    Color(0xFFB2DFDB),

    // Green / Income
    Color(0xFFC8E6C9),
    Color(0xFFDCEDC8),

    // Yellow / Daily spending
    Color(0xFFFFF9C4),
    Color(0xFFFFE0B2),

    // Orange / Variable
    Color(0xFFFFCCBC),

    // Brown / Investment
    Color(0xFFD7CCC8),

    // Grey / Neutral
    Color(0xFFCFD8DC),
  ];
}
