// 📁 FILE: lib/core/reminder/play_log.dart
// 📌 WHAT: Remembers on which days the player finished a game (feeds the Daily Pull week row)

/// One day in the "Daily Pull" week row.
class WeekDot {
  const WeekDot({
    required this.date,
    required this.played,
    required this.isToday,
    required this.isFuture,
  });

  final DateTime date;
  final bool played;
  final bool isToday;
  final bool isFuture;
}

/// The days (as "yyyy-MM-dd" keys) on which at least one game was finished.
class PlayLog {
  const PlayLog([this.days = const <String>{}]);

  final Set<String> days;

  /// Older days are forgotten so the saved list stays small.
  static const int keepDays = 60;

  /// "2026-03-05" style key for a date.
  static String keyFor(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Turns a key back into a date, or null when the key is not valid.
  static DateTime? parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  bool playedOn(DateTime date) => days.contains(keyFor(date));

  /// A copy of the log with [date] added. Days older than [keepDays] and
  /// invalid keys are dropped.
  PlayLog withPlayed(DateTime date) {
    final oldest = DateTime(date.year, date.month, date.day - keepDays);
    final kept = <String>{
      for (final key in days)
        if (parseKey(key)?.isBefore(oldest) == false) key,
    };
    kept.add(keyFor(date));
    return PlayLog(kept);
  }

  /// The seven days of the week that contains [now], Monday first.
  List<WeekDot> weekDots(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return List<WeekDot>.generate(7, (index) {
      final date = DateTime(monday.year, monday.month, monday.day + index);
      return WeekDot(
        date: date,
        played: playedOn(date),
        isToday: date == today,
        isFuture: date.isAfter(today),
      );
    });
  }

  int daysPlayedThisWeek(DateTime now) =>
      weekDots(now).where((dot) => dot.played).length;

  /// Sorted list for saving.
  List<String> toList() => days.toList()..sort();
}