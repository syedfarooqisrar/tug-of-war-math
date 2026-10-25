// 📁 FILE: lib/core/reminder/reminder_settings.dart
// 📌 WHAT: Daily reminder choices and the play log, saved on the phone with shared_preferences

import 'package:shared_preferences/shared_preferences.dart';

import 'play_log.dart';
import 'reminder_logic.dart';

/// What the player chose for the daily reminder. Off until the player says yes.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = ReminderConfig.defaultHour,
    this.minute = ReminderConfig.defaultMinute,
    this.declinedCount = 0,
    this.declinedOn,
  });

  final bool enabled;
  final int hour;
  final int minute;

  /// How many times the player answered "Not now" to the friendly question.
  final int declinedCount;

  /// "yyyy-MM-dd" of the last "Not now", or null.
  final String? declinedOn;

  /// The friendly question is asked at most this many times in total.
  static const int maxAsks = 2;

  /// After a "Not now" the question waits at least this many days.
  static const int askAgainAfterDays = 7;

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    int? declinedCount,
    String? declinedOn,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      declinedCount: declinedCount ?? this.declinedCount,
      declinedOn: declinedOn ?? this.declinedOn,
    );
  }

  /// Whether the app may show the friendly "daily reminder?" question now.
  bool canAskAgain(DateTime now) {
    if (enabled) return false;
    if (declinedCount == 0) return true;
    if (declinedCount >= maxAsks) return false;

    final last = declinedOn == null ? null : PlayLog.parseKey(declinedOn!);
    if (last == null) return true;

    final days = DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(last.year, last.month, last.day))
        .inDays;
    return days >= askAgainAfterDays;
  }
}

/// Reads and writes the reminder settings and the play log.
class ReminderStore {
  const ReminderStore();

  static const String _enabledKey = 'reminder_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';
  static const String _declinedCountKey = 'reminder_declined_count';
  static const String _declinedOnKey = 'reminder_declined_on';
  static const String _playDaysKey = 'play_days';

  static int _safeMinute(int minute) {
    if (minute < 0) return 0;
    if (minute > 59) return 59;
    return minute;
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      hour: ReminderLogic.clampHour(
        prefs.getInt(_hourKey) ?? ReminderConfig.defaultHour,
      ),
      minute: _safeMinute(
        prefs.getInt(_minuteKey) ?? ReminderConfig.defaultMinute,
      ),
      declinedCount: prefs.getInt(_declinedCountKey) ?? 0,
      declinedOn: prefs.getString(_declinedOnKey),
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, ReminderLogic.clampHour(settings.hour));
    await prefs.setInt(_minuteKey, _safeMinute(settings.minute));
    await prefs.setInt(_declinedCountKey, settings.declinedCount);
    final declinedOn = settings.declinedOn;
    if (declinedOn == null) {
      await prefs.remove(_declinedOnKey);
    } else {
      await prefs.setString(_declinedOnKey, declinedOn);
    }
  }

  Future<PlayLog> loadPlayLog() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_playDaysKey) ?? const <String>[];
    return PlayLog(stored.toSet());
  }

  Future<void> savePlayLog(PlayLog log) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_playDaysKey, log.toList());
  }
}