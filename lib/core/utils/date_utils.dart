// lib/core/utils/date_utils.dart
//
// PocketNote uses day-level dates for records (not time-precise).
// We normalize dates to yyyy-mm-dd at local time (00:00).

import 'package:intl/intl.dart';

class DateUtilsX {
  static DateTime normalizeDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  static String dayKey(DateTime dt) {
    final d = normalizeDay(dt);
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  static String monthKey(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}";
  }

  static String formatDayHeader(DateTime dt) {
    return DateFormat("EEE, d MMM yyyy").format(dt);
  }

  static String formatMonthTitle(DateTime dt) {
    return DateFormat("MMMM yyyy").format(dt);
  }
}
