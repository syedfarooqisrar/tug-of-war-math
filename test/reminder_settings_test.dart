// 📁 FILE: test/reminder_settings_test.dart
// 📌 WHAT: Unit tests for the reminder settings and saving

import 'package:flutter_test/flutter_test.dart';
import 'package:mathpull/core/reminder/play_log.dart';
import 'package:mathpull/core/reminder/reminder_logic.dart';
import 'package:mathpull/core/reminder/reminder_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderSettings', () {
    test('is on by default at 5:00 PM', () {
      const settings = ReminderSettings();

      expect(settings.enabled, isTrue);
      expect(settings.hour, ReminderConfig.defaultHour);
      expect(settings.minute, ReminderConfig.defaultMinute);
      expect(settings.permissionAsked, isFalse);
    });

    test('copyWith changes only what is given', () {
      final changed = const ReminderSettings().copyWith(hour: 18);

      expect(changed.hour, 18);
      expect(changed.enabled, isTrue);
      expect(changed.minute, ReminderConfig.defaultMinute);
      expect(changed.permissionAsked, isFalse);
    });
  });

  group('ReminderStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('loads the defaults when nothing was saved', () async {
      final settings = await const ReminderStore().loadSettings();

      expect(settings.enabled, isTrue);
      expect(settings.hour, ReminderConfig.defaultHour);
      expect(settings.minute, ReminderConfig.defaultMinute);
      expect(settings.permissionAsked, isFalse);
    });

    test('saves and loads the settings', () async {
      const store = ReminderStore();
      await store.saveSettings(const ReminderSettings(
        enabled: false,
        hour: 18,
        minute: 30,
        permissionAsked: true,
      ));

      final loaded = await store.loadSettings();
      expect(loaded.enabled, isFalse);
      expect(loaded.hour, 18);
      expect(loaded.minute, 30);
      expect(loaded.permissionAsked, isTrue);
    });

    test('an hour outside the allowed range is clamped on load', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reminder_hour': 23,
        'reminder_minute': 99,
      });

      final loaded = await const ReminderStore().loadSettings();
      expect(loaded.hour, ReminderConfig.latestHour);
      expect(loaded.minute, 59);
    });

    test('saves and loads the play log', () async {
      const store = ReminderStore();
      final log = const PlayLog().withPlayed(DateTime(2026, 10, 25));
      await store.savePlayLog(log);

      final loaded = await store.loadPlayLog();
      expect(loaded.playedOn(DateTime(2026, 10, 25)), isTrue);
      expect(loaded.days.length, 1);
    });

    test('an empty store gives an empty play log', () async {
      final loaded = await const ReminderStore().loadPlayLog();
      expect(loaded.days, isEmpty);
    });
  });
}