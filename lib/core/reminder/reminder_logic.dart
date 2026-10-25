// 📁 FILE: lib/core/reminder/reminder_logic.dart
// 📌 WHAT: Pure rules for the daily reminder: when to remind and what to say (no plugin, easy to test)

/// Tuning values for the daily reminder. Change a number here and it updates
/// everywhere in the app.
class ReminderConfig {
  ReminderConfig._();

  /// Reminders are never scheduled outside this time of day (24 h clock),
  /// so children are not disturbed in the morning or at night.
  static const int earliestHour = 8;
  static const int latestHour = 20;

  /// Reminder time used until the player picks another one.
  static const int defaultHour = 17;
  static const int defaultMinute = 0;

  /// Hours offered in the reminder sheet.
  static const List<int> hourChoices = [16, 17, 18, 19];

  /// How many days ahead are scheduled at once. If the app is not opened for
  /// this many days, the reminders simply stop.
  static const int windowDays = 7;

  /// Notification ids used by the app: firstNotificationId + 0 .. windowDays - 1.
  static const int firstNotificationId = 100;

  /// Id of the "Send a test" notification.
  static const int testNotificationId = 99;
}

/// One friendly reminder text.
class ReminderMessage {
  const ReminderMessage(this.title, this.body);

  final String title;
  final String body;
}

/// The pool of reminder texts. They are positive and never pressure the
/// player: no guilt, no "you will lose something".
class ReminderMessages {
  ReminderMessages._();

  static const List<ReminderMessage> pool = [
    ReminderMessage('Your rope is waiting', 'One quick 60-second maths round?'),
    ReminderMessage('Time for a maths pull!', 'A short round is all it takes.'),
    ReminderMessage('Ready, set, pull!', 'Tug the rope with a quick maths round.'),
    ReminderMessage('Brain warm-up time', 'Solve a few sums and pull the rope.'),
    ReminderMessage('Team Blue or Team Red?', 'Pick a side and play a round.'),
    ReminderMessage('A little maths, a lot of fun', 'Come and pull the rope today.'),
    ReminderMessage('Challenge a friend', 'Two players, one screen, one rope.'),
    ReminderMessage('How fast can you solve it?', 'Try to beat your best round.'),
  ];

  /// The message for a given day. Consecutive days always get different
  /// messages, and the same day always gets the same one.
  static ReminderMessage forDate(DateTime date) {
    final days = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(1970))
        .inDays;
    return pool[days % pool.length];
  }
}

/// When to remind.
class ReminderLogic {
  ReminderLogic._();

  /// Keeps an hour inside the allowed range.
  static int clampHour(int hour) {
    if (hour < ReminderConfig.earliestHour) return ReminderConfig.earliestHour;
    if (hour > ReminderConfig.latestHour) return ReminderConfig.latestHour;
    return hour;
  }

  static int _clampMinute(int minute) {
    if (minute < 0) return 0;
    if (minute > 59) return 59;
    return minute;
  }

  /// The next [days] reminder moments (device local time).
  ///
  /// Today is left out when the player has already played today, or when
  /// today's reminder time has already passed.
  static List<DateTime> upcoming({
    required DateTime now,
    required int hour,
    required int minute,
    required bool playedToday,
    int days = ReminderConfig.windowDays,
  }) {
    final safeHour = clampHour(hour);
    final safeMinute = _clampMinute(minute);
    final result = <DateTime>[];

    for (var offset = 0; offset <= days && result.length < days; offset++) {
      final moment = DateTime(
        now.year,
        now.month,
        now.day + offset,
        safeHour,
        safeMinute,
      );
      final isToday = offset == 0;
      if (isToday && (playedToday || !moment.isAfter(now))) continue;
      result.add(moment);
    }
    return result;
  }
}