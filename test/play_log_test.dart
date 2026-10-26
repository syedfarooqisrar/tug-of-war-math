// 📁 FILE: test/play_log_test.dart
// 📌 WHAT: Unit tests for the play log and the Daily Pull week row

import 'package:flutter_test/flutter_test.dart';
import 'package:mathpull/core/reminder/play_log.dart';

void main() {
  group('PlayLog keys', () {
    test('keyFor pads month and day with zeros', () {
      expect(PlayLog.keyFor(DateTime(2026, 3, 5)), '2026-03-05');
      expect(PlayLog.keyFor(DateTime(2026, 12, 25)), '2026-12-25');
    });

    test('parseKey reads a valid key and rejects a broken one', () {
      expect(PlayLog.parseKey('2026-03-05'), DateTime(2026, 3, 5));
      expect(PlayLog.parseKey('hello'), isNull);
      expect(PlayLog.parseKey('2026-xx-05'), isNull);
      expect(PlayLog.parseKey('2026-03'), isNull);
    });
  });

  group('PlayLog.withPlayed', () {
    test('an empty log has no played days', () {
      expect(const PlayLog().playedOn(DateTime(2026, 10, 25)), isFalse);
    });

    test('remembers the day and does not duplicate it', () {
      final log = const PlayLog()
          .withPlayed(DateTime(2026, 10, 25, 9))
          .withPlayed(DateTime(2026, 10, 25, 21));

      expect(log.playedOn(DateTime(2026, 10, 25, 12)), isTrue);
      expect(log.days.length, 1);
    });

    test('forgets days older than 60 days and keeps recent ones', () {
      final log = const PlayLog(<String>{'2026-01-01', '2026-10-20'})
          .withPlayed(DateTime(2026, 10, 25));

      expect(log.playedOn(DateTime(2026, 1, 1)), isFalse);
      expect(log.playedOn(DateTime(2026, 10, 20)), isTrue);
      expect(log.playedOn(DateTime(2026, 10, 25)), isTrue);
    });

    test('drops invalid stored keys', () {
      final log = const PlayLog(<String>{'junk', '2026-10-20'})
          .withPlayed(DateTime(2026, 10, 25));

      expect(log.days.contains('junk'), isFalse);
      expect(log.days.length, 2);
    });

    test('toList is sorted', () {
      const log = PlayLog(<String>{'2026-10-25', '2026-10-20', '2026-10-22'});
      expect(log.toList(), ['2026-10-20', '2026-10-22', '2026-10-25']);
    });
  });

  group('PlayLog.weekDots', () {
    // 25 October 2026 is a Sunday.
    test('on a Sunday the week runs Monday 19th to Sunday 25th', () {
      final dots = const PlayLog().weekDots(DateTime(2026, 10, 25, 15));

      expect(dots.length, 7);
      expect(dots.first.date, DateTime(2026, 10, 19));
      expect(dots.last.date, DateTime(2026, 10, 25));
      expect(dots.last.isToday, isTrue);
      expect(dots.any((dot) => dot.isFuture), isFalse);
    });

    test('on a Monday the week starts today and the rest is in the future', () {
      final dots = const PlayLog().weekDots(DateTime(2026, 10, 26, 8));

      expect(dots.first.date, DateTime(2026, 10, 26));
      expect(dots.first.isToday, isTrue);
      expect(dots.where((dot) => dot.isFuture).length, 6);
      expect(dots.last.date, DateTime(2026, 11, 1));
    });

    test('marks the played days of this week only', () {
      const log = PlayLog(<String>{
        '2026-10-19', // Monday
        '2026-10-21', // Wednesday
        '2026-10-18', // last week's Sunday
      });
      final dots = log.weekDots(DateTime(2026, 10, 23));

      expect(dots.map((dot) => dot.played).toList(),
          [true, false, true, false, false, false, false]);
      expect(log.daysPlayedThisWeek(DateTime(2026, 10, 23)), 2);
    });

    test('a new week starts empty', () {
      const log = PlayLog(<String>{'2026-10-19', '2026-10-21'});
      expect(log.daysPlayedThisWeek(DateTime(2026, 10, 26)), 0);
    });
  });
}