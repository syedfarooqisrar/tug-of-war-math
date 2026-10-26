// 📁 FILE: lib/core/reminder/reminder_scheduler.dart
// 📌 WHAT: The part that talks to Android: asks for permission and schedules local notifications

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_logic.dart';

/// One reminder that should be shown at [moment] (device local time).
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.moment,
    required this.message,
  });

  final int id;
  final DateTime moment;
  final ReminderMessage message;
}

/// What the reminder manager needs from the phone. A fake version is used in tests.
abstract class ReminderScheduler {
  /// False on platforms where reminders are not offered (for example the web).
  bool get isSupported;

  /// True once [init] finished successfully.
  bool get isReady;

  Future<void> init();

  /// Whether the player allowed notifications for this app.
  Future<bool> isAllowed();

  /// Shows the Android permission question. Returns true when allowed.
  Future<bool> requestPermission();

  /// Cancels the old reminders and schedules exactly the given ones.
  Future<void> replaceAll(List<PlannedReminder> plan);

  Future<void> cancelAll();

  /// Shows a notification right now (the "Send a test" button).
  Future<void> showTest(ReminderMessage message);
}

/// Real implementation with flutter_local_notifications. Everything stays on the
/// phone: no internet and no server are involved.
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler();

  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'Daily reminder';
  static const String _channelDescription =
      'A friendly daily reminder to play a quick round of MathPull.';
  static const String _smallIcon = 'ic_stat_mathpull';
  static const Color _accent = Color(0xFF2563EB);

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: _smallIcon,
      color: _accent,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get isReady => _ready;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init() async {
    if (!isSupported || _ready) return;

    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_smallIcon),
      ),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> isAllowed() async {
    if (!_ready) return false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  Future<void> _cancelOwnReminders() async {
    for (var i = 0; i < ReminderConfig.windowDays; i++) {
      await _plugin.cancel(id: ReminderConfig.firstNotificationId + i);
    }
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> plan) async {
    if (!_ready) return;
    await _cancelOwnReminders();

    for (final item in plan) {
      final moment = item.moment;
      final when = tz.TZDateTime(
        tz.local,
        moment.year,
        moment.month,
        moment.day,
        moment.hour,
        moment.minute,
      );
      await _plugin.zonedSchedule(
        id: item.id,
        title: item.message.title,
        body: item.message.body,
        scheduledDate: when,
        notificationDetails: _details,
        // Inexact on purpose: it needs no exact-alarm permission, and a
        // reminder a few minutes late is fine.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _cancelOwnReminders();
  }

  @override
  Future<void> showTest(ReminderMessage message) async {
    if (!_ready) return;
    await _plugin.show(
      id: ReminderConfig.testNotificationId,
      title: message.title,
      body: message.body,
      notificationDetails: _details,
    );
  }
}