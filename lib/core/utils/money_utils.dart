// lib/core/utils/money_utils.dart
//
// Money is stored as integer cents to avoid floating-point errors.
// Example: RM 12.34 => 1234 cents

class MoneyUtils {
  static int toCents(num value) {
    // handles 12, 12.3, 12.34 safely
    return (value * 100).round();
  }

  static double toDouble(int cents) => cents / 100.0;

  static String formatRM(int cents) {
    final sign = cents < 0 ? "-" : "";
    final abs = cents.abs();
    final rm = abs ~/ 100;
    final cent = abs % 100;
    return "${sign}RM $rm.${cent.toString().padLeft(2, '0')}";
  }
}
