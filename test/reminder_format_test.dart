// 📁 FILE: test/reminder_format_test.dart
// 📌 WHAT: Unit tests for the reminder text helpers

import 'package:flutter_test/flutter_test.dart';
import 'package:mathpull/core/reminder/reminder_format.dart';

void main() {
  test('formats afternoon hours', () {
    expect(ReminderFormat.time(16, 0), '4:00 PM');
    expect(ReminderFormat.time(17, 0), '5:00 PM');
    expect(ReminderFormat.time(19, 0), '7:00 PM');
  });

  test('formats morning hours and pads the minutes', () {
    expect(ReminderFormat.time(8, 5), '8:05 AM');
    expect(ReminderFormat.time(11, 45), '11:45 AM');
  });

  test('noon and midnight use 12', () {
    expect(ReminderFormat.time(12, 0), '12:00 PM');
    expect(ReminderFormat.time(12, 30), '12:30 PM');
    expect(ReminderFormat.time(0, 0), '12:00 AM');
  });

  test('week summary reads naturally', () {
    expect(ReminderFormat.weekSummary(0), '0 of 7 days');
    expect(ReminderFormat.weekSummary(3), '3 of 7 days');
  });

  test('there is a letter and a name for each day of the week', () {
    expect(ReminderFormat.weekdayLetters.length, 7);
    expect(ReminderFormat.weekdayNames.length, 7);
    expect(ReminderFormat.weekdayLetters.first, 'M');
    expect(ReminderFormat.weekdayNames.last, 'Sunday');
  });
}