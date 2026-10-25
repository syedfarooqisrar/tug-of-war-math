// 📁 FILE: test/reminder_settings_test.dart
// 📌 WHAT: Unit tests for the reminder settings, when to ask, and saving

import 'package:flutter_test/flutter_test.dart';
import 'package:mathpull/core/reminder/play_log.dart';
import 'package:mathpull/core/reminder/reminder_logic.dart';
import 'package:mathpull/core/reminder/reminder_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderSettings.canAskAgain', () {
    final now = DateTime(2026, 10, 25, 12);

    test('a new player can be asked', () {
      expect(const ReminderSettings().canAskAgain(now), isTrue);
    });

    test('is off by default', () {
      expect(const ReminderSettings().enabled, isFalse);
      expect(const ReminderSettings().hour, ReminderConfig.defaultHour);
    });

    test('is never asked when the reminder is already on', () {
      expect(const ReminderSettings(enabled: true).canAskAgain(now), isFalse);
    });

    test('is not asked again the same day after "Not now"', () {
      const settings = ReminderSettings(declinedCount: 1, declinedOn: '2026-10-25');
      expect(settings.canAskAgain(now), isFalse);
    });

    test('is not asked again after 6 days but is after 7', () {
      const sixDays = ReminderSettings(declinedCount: 1, declinedOn: '2026-10-19');
      const sevenDays = ReminderSettings(declinedCount: 1, declinedOn: '2026-10-18');
      expect(sixDays.canAskAgain(now), isFalse);
      expect(sevenDays.canAskAgain(now), isTrue);
    });

    test('is never asked a third time', () {
      const settings = ReminderSettings(declinedCount: 2, declinedOn: '2026-01-01');
      expect(settings.canAskAgain(now), isFalse);
    });
  });

  group('ReminderStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('loads the defaults when nothing was saved', () async {
      final settings = await const ReminderStore().loadSettings();

      expect(settings.enabled, isFalse);
      expect(settings.hour, ReminderConfig.defaultHour);
      expect(settings.minute, ReminderConfig.defaultMinute);
      expect(settings.declinedCount, 0);
      expect(settings.declinedOn, isNull);
    });

    test('saves and loads the settings', () async {
      const store = ReminderStore();
      await store.saveSettings(const ReminderSettings(
        enabled: true,
        hour: 18,
        minute: 30,
        declinedCount: 1,
        declinedOn: '2026-10-20',
      ));

      final loaded = await store.loadSettings();
      expect(loaded.enabled, isTrue);
      expect(loaded.hour, 18);
      expect(loaded.minute, 30);
      expect(loaded.declinedCount, 1);
      expect(loaded.declinedOn, '2026-10-20');
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