// 📁 FILE: lib/core/reminder/reminder_settings.dart
// 📌 WHAT: Daily reminder choices and the play log, saved on the phone with shared_preferences

import 'package:shared_preferences/shared_preferences.dart';

import 'play_log.dart';
import 'reminder_logic.dart';

/// What the player chose for the daily reminder. It is on by default at
/// 5:00 PM. On Android 13+ nothing is shown until the player allows
/// notifications in the question Android asks after the first finished game.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.hour = ReminderConfig.defaultHour,
    this.minute = ReminderConfig.defaultMinute,
    this.permissionAsked = false,
  });

  final bool enabled;
  final int hour;
  final int minute;

  /// True once the app has asked Android for the notification permission.
  final bool permissionAsked;

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? permissionAsked,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      permissionAsked: permissionAsked ?? this.permissionAsked,
    );
  }
}

/// Reads and writes the reminder settings and the play log.
class ReminderStore {
  const ReminderStore();

  static const String _enabledKey = 'reminder_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';
  static const String _permissionAskedKey = 'reminder_permission_asked';
  static const String _playDaysKey = 'play_days';

  static int _safeMinute(int minute) {
    if (minute < 0) return 0;
    if (minute > 59) return 59;
    return minute;
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? true,
      hour: ReminderLogic.clampHour(
        prefs.getInt(_hourKey) ?? ReminderConfig.defaultHour,
      ),
      minute: _safeMinute(
        prefs.getInt(_minuteKey) ?? ReminderConfig.defaultMinute,
      ),
      permissionAsked: prefs.getBool(_permissionAskedKey) ?? false,
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, ReminderLogic.clampHour(settings.hour));
    await prefs.setInt(_minuteKey, _safeMinute(settings.minute));
    await prefs.setBool(_permissionAskedKey, settings.permissionAsked);
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