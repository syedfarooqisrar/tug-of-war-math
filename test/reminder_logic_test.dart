// 📁 FILE: test/reminder_logic_test.dart
// 📌 WHAT: Unit tests for the daily reminder rules

import 'package:flutter_test/flutter_test.dart';
import 'package:mathpull/core/reminder/reminder_logic.dart';

void main() {
  group('ReminderLogic.upcoming', () {
    test('starts today when the time is still ahead and nothing was played', () {
      final now = DateTime(2026, 10, 25, 9, 30);
      final result = ReminderLogic.upcoming(
        now: now,
        hour: 17,
        minute: 0,
        playedToday: false,
      );

      expect(result.length, ReminderConfig.windowDays);
      expect(result.first, DateTime(2026, 10, 25, 17));
      expect(result.last, DateTime(2026, 10, 31, 17));
    });

    test('starts tomorrow when today was already played', () {
      final now = DateTime(2026, 10, 25, 9, 30);
      final result = ReminderLogic.upcoming(
        now: now,
        hour: 17,
        minute: 0,
        playedToday: true,
      );

      expect(result.length, ReminderConfig.windowDays);
      expect(result.first, DateTime(2026, 10, 26, 17));
      expect(result.last, DateTime(2026, 11, 1, 17));
    });

    test('starts tomorrow when today\'s time has already passed', () {
      final now = DateTime(2026, 10, 25, 18, 0);
      final result = ReminderLogic.upcoming(
        now: now,
        hour: 17,
        minute: 0,
        playedToday: false,
      );

      expect(result.length, ReminderConfig.windowDays);
      expect(result.first, DateTime(2026, 10, 26, 17));
    });

    test('a reminder at exactly the current time counts as passed', () {
      final now = DateTime(2026, 10, 25, 17, 0);
      final result = ReminderLogic.upcoming(
        now: now,
        hour: 17,
        minute: 0,
        playedToday: false,
      );

      expect(result.first, DateTime(2026, 10, 26, 17));
    });

    test('rolls over the month and the year', () {
      final now = DateTime(2026, 12, 29, 10, 0);
      final result = ReminderLogic.upcoming(
        now: now,
        hour: 17,
        minute: 0,
        playedToday: false,
      );

      expect(result.first, DateTime(2026, 12, 29, 17));
      expect(result.last, DateTime(2027, 1, 4, 17));
    });

    test('hours outside the allowed range are clamped', () {
      final now = DateTime(2026, 10, 25, 6, 0);

      final late = ReminderLogic.upcoming(
        now: now,
        hour: 23,
        minute: 0,
        playedToday: false,
      );
      expect(late.first.hour, ReminderConfig.latestHour);

      final early = ReminderLogic.upcoming(
        now: now,
        hour: 3,
        minute: 0,
        playedToday: false,
      );
      expect(early.first.hour, ReminderConfig.earliestHour);
    });

    test('never returns a moment that is not after now', () {
      final now = DateTime(2026, 10, 25, 12, 0);
      final result = ReminderLogic.upcoming(
        now: now,
        hour: 8,
        minute: 0,
        playedToday: false,
      );

      expect(result.every((moment) => moment.isAfter(now)), isTrue);
    });

    test('clampHour keeps valid hours unchanged', () {
      expect(ReminderLogic.clampHour(17), 17);
      expect(ReminderLogic.clampHour(ReminderConfig.earliestHour), 8);
      expect(ReminderLogic.clampHour(ReminderConfig.latestHour), 20);
    });
  });

  group('ReminderMessages', () {
    test('the same date always gives the same message', () {
      final a = ReminderMessages.forDate(DateTime(2026, 10, 25, 9));
      final b = ReminderMessages.forDate(DateTime(2026, 10, 25, 21));
      expect(a.title, b.title);
    });

    test('two consecutive days never get the same message', () {
      var day = DateTime(2026, 1, 1);
      for (var i = 0; i < 800; i++) {
        final today = ReminderMessages.forDate(day);
        final tomorrow = ReminderMessages.forDate(
          DateTime(day.year, day.month, day.day + 1),
        );
        expect(today.title == tomorrow.title, isFalse);
        day = DateTime(day.year, day.month, day.day + 1);
      }
    });

    test('a whole window of days has no repeated message', () {
      expect(
        ReminderMessages.pool.length,
        greaterThanOrEqualTo(ReminderConfig.windowDays),
      );
      final titles = <String>{};
      for (var i = 0; i < ReminderConfig.windowDays; i++) {
        titles.add(ReminderMessages.forDate(DateTime(2026, 10, 25 + i)).title);
      }
      expect(titles.length, ReminderConfig.windowDays);
    });

    test('every message fits a notification', () {
      for (final message in ReminderMessages.pool) {
        expect(message.title.trim(), isNotEmpty);
        expect(message.body.trim(), isNotEmpty);
        expect(message.title.length, lessThanOrEqualTo(40));
        expect(message.body.length, lessThanOrEqualTo(80));
      }
    });
  });
}