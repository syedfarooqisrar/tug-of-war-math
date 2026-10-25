// 📁 FILE: lib/core/reminder/reminder_format.dart
// 📌 WHAT: Small text helpers for the daily reminder screens (time label, week summary)

class ReminderFormat {
  ReminderFormat._();

  /// First letters of the week days, Monday first.
  static const List<String> weekdayLetters = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  /// Full names, Monday first (read by screen readers).
  static const List<String> weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// "5:00 PM" style label for a time of day (24 hour input).
  static String time(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minutes = minute.toString().padLeft(2, '0');
    return '$hour12:$minutes $period';
  }

  /// "3 of 7 days" next to the Daily Pull title.
  static String weekSummary(int daysPlayed) => '$daysPlayed of 7 days';
}