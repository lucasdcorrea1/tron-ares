import 'package:intl/intl.dart';

/// Utility class for formatting dates
/// Primary locale: Portuguese (Brazil)
class DateFormatter {
  // Date formats
  static final _fullDate = DateFormat('d \'de\' MMMM \'de\' yyyy', 'pt_BR');
  static final _shortDate = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _monthYear = DateFormat('MMMM yyyy', 'pt_BR');
  static final _dayMonth = DateFormat('dd MMM', 'pt_BR');
  static final _weekDay = DateFormat('EEEE', 'pt_BR');
  static final _time = DateFormat('HH:mm', 'pt_BR');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  /// Full date format: "5 de Janeiro de 2024"
  static String formatFull(DateTime date) {
    return _fullDate.format(date);
  }

  /// Short date format: "05/01/2024"
  static String formatShort(DateTime date) {
    return _shortDate.format(date);
  }

  /// Month and year: "Janeiro 2024"
  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  /// Day and month: "05 Jan"
  static String formatDayMonth(DateTime date) {
    return _dayMonth.format(date);
  }

  /// Week day name: "Segunda-feira"
  static String formatWeekDay(DateTime date) {
    return _weekDay.format(date);
  }

  /// Time format: "14:30"
  static String formatTime(DateTime date) {
    return _time.format(date);
  }

  /// Date and time: "05/01/2024 14:30"
  static String formatDateTime(DateTime date) {
    return _dateTime.format(date);
  }

  /// Relative date format: "Hoje", "Ontem", "5 de Janeiro"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Ontem';
    } else if (difference == -1) {
      return 'Amanhã';
    } else if (difference > 0 && difference <= 7) {
      return _weekDay.format(date);
    } else {
      return formatDayMonth(date);
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is in current month
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }
}
