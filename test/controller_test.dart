// 📁 FILE: test/controller_test.dart   (NEW FILE)
// 📌 WHAT: Unit tests for the game rules: countdown, answers, streak, double pull, match point, instant win, Speed Race, timer, pause
import 'package:flutter_test/flutter_test.dart';
import 'package:mathpull/core/constants/app_constants.dart';
import 'package:mathpull/game/game_controller.dart';
import 'package:mathpull/models/game_settings.dart';

/// Easy maths, 6 pulls to win (so a match point is quick to reach).
GameSettings _settings({GameMode mode = GameMode.classic}) => GameSettings(
      mode: mode,
      difficulty: Difficulty.easy,
      winPulls: 6,
      roundSeconds: 45,
    );

/// A controller that is already in the "playing" phase.
GameController _playing({GameMode mode = GameMode.classic}) {
  final controller = GameController(settings: _settings(mode: mode));
  addTearDown(controller.dispose);
  controller.debugStartPlaying();
  return controller;
}

/// Types the right (or a wrong) answer for [team] and presses ✓.
AnswerResult _answer(GameController c, int team, {bool right = true}) {
  final question = c.questionFor(team);
  final value = right ? question.answer : question.answer + 1;
  for (final digit in '$value'.split('')) {
    c.pressDigit(team, digit);
  }
  return c.submit(team);
}

void main() {
  group('Countdown', () {
    test('a new round starts in the countdown and ignores the keypad', () {
      final c = GameController(settings: _settings());
      addTearDown(c.dispose);

      expect(c.isCountingDown, isTrue);
      expect(c.countdownValue, GameConfig.countdownSeconds);

      c.pressDigit(1, '5');
      expect(c.inputFor(1), '');
      expect(c.submit(1), AnswerResult.ignored);
    });

    test('pause does nothing during the countdown', () {
      final c = GameController(settings: _settings());
      addTearDown(c.dispose);

      c.pause();
      expect(c.isCountingDown, isTrue);
    });
  });

  group('Typing', () {
    test('digits build up the answer and clear removes them', () {
      final c = _playing();

      c.pressDigit(1, '4');
      c.pressDigit(1, '2');
      expect(c.inputFor(1), '42');

      c.clearInput(1);
      expect(c.inputFor(1), '');
    });

    test('the answer cannot be longer than the allowed digits', () {
      final c = _playing();

      for (var i = 0; i < GameConfig.maxAnswerDigits + 2; i++) {
        c.pressDigit(1, '1');
      }
      expect(c.inputFor(1).length, GameConfig.maxAnswerDigits);
    });

    test('each team has its own input', () {
      final c = _playing();

      c.pressDigit(1, '7');
      expect(c.inputFor(1), '7');
      expect(c.inputFor(2), '');
    });

    test('submitting nothing is ignored and makes no feedback', () {
      final c = _playing();

      expect(c.submit(1), AnswerResult.ignored);
      expect(c.feedbackIdFor(1), 0);
    });
  });

  group('Answers', () {
    test('a right answer scores one point and starts a streak', () {
      final c = _playing();

      expect(_answer(c, 1), AnswerResult.correct);
      expect(c.scoreFor(1), 1);
      expect(c.streakFor(1), 1);
      expect(c.lastPointsFor(1), 1);
      expect(c.lastResultFor(1), AnswerResult.correct);
      expect(c.feedbackIdFor(1), 1);
      expect(c.inputFor(1), '');
    });

    test('a wrong answer scores nothing and resets the streak', () {
      final c = _playing();

      _answer(c, 1);
      _answer(c, 1);
      expect(c.streakFor(1), 2);

      expect(_answer(c, 1, right: false), AnswerResult.wrong);
      expect(c.scoreFor(1), 2);
      expect(c.streakFor(1), 0);
      expect(c.lastPointsFor(1), 0);
      expect(c.lastResultFor(1), AnswerResult.wrong);
      expect(c.inputFor(1), '');
    });

    test('the rope moves toward the team that is ahead', () {
      final c = _playing();

      expect(c.pull, 0);
      _answer(c, 1);
      _answer(c, 1);
      _answer(c, 1);
      expect(c.pull, closeTo(0.5, 0.0001)); // 3 of 6 pulls

      final c2 = _playing();
      _answer(c2, 2);
      expect(c2.pull, lessThan(0));
    });
  });

  group('Streak bonus', () {
    test('three right answers in a row make the next one pull double', () {
      final c = _playing();

      for (var i = 0; i < GameConfig.streakForBonus; i++) {
        _answer(c, 1);
      }
      expect(c.isOnFire(1), isTrue);
      expect(c.scoreFor(1), GameConfig.streakForBonus);

      _answer(c, 1);
      expect(c.lastPointsFor(1), GameConfig.bonusPoints);
      expect(c.scoreFor(1), GameConfig.streakForBonus + GameConfig.bonusPoints);
    });

    test('cashing in the bonus resets the streak', () {
      final c = _playing();

      for (var i = 0; i < GameConfig.streakForBonus + 1; i++) {
        _answer(c, 1);
      }
      expect(c.streakFor(1), 0);
      expect(c.isOnFire(1), isFalse);
    });

    test('a wrong answer takes the fire away before it is cashed in', () {
      final c = _playing();

      for (var i = 0; i < GameConfig.streakForBonus; i++) {
        _answer(c, 1);
      }
      _answer(c, 1, right: false);
      expect(c.isOnFire(1), isFalse);

      _answer(c, 1);
      expect(c.lastPointsFor(1), 1);
    });

    test('teams keep separate streaks in Classic mode', () {
      final c = _playing();

      _answer(c, 1);
      _answer(c, 1);
      _answer(c, 2);
      expect(c.streakFor(1), 2);
      expect(c.streakFor(2), 1);
    });
  });

  group('Match point and instant win', () {
    // With 6 pulls: three answers (+3), the bonus answer (+2) makes 5, which
    // is one pull from winning.
    void reachMatchPoint(GameController c, int team) {
      for (var i = 0; i < GameConfig.streakForBonus + 1; i++) {
        _answer(c, team);
      }
    }

    test('one pull from winning shows match point for that team', () {
      final c = _playing();

      expect(c.matchPointTeam, 0);
      reachMatchPoint(c, 1);
      expect(c.scoreFor(1), 5);
      expect(c.matchPointTeam, 1);
      expect(c.isFinished, isFalse);
    });

    test('match point works for team 2 too', () {
      final c = _playing();

      reachMatchPoint(c, 2);
      expect(c.matchPointTeam, 2);
    });

    test('reaching the pulls lead ends the round at once', () {
      final c = _playing();

      reachMatchPoint(c, 1);
      _answer(c, 1);

      expect(c.isFinished, isTrue);
      expect(c.winner, 1);
      expect(c.matchPointTeam, 0);
    });

    test('team 2 can win instantly as well', () {
      final c = _playing();

      reachMatchPoint(c, 2);
      _answer(c, 2);

      expect(c.isFinished, isTrue);
      expect(c.winner, 2);
    });

    test('a lead that is shared out by the other team is not a win', () {
      final c = _playing();

      reachMatchPoint(c, 1); // 5-0
      _answer(c, 2); // 5-1, the lead is 4
      expect(c.isFinished, isFalse);
      expect(c.matchPointTeam, 0);
    });

    test('nothing can be typed after the round is over', () {
      final c = _playing();

      reachMatchPoint(c, 1);
      _answer(c, 1);
      expect(c.isFinished, isTrue);

      c.pressDigit(2, '1');
      expect(c.inputFor(2), '');
      expect(c.submit(2), AnswerResult.ignored);
    });
  });

  group('Speed Race', () {
    test('both teams share one question; Classic gives each its own', () {
      final race = _playing(mode: GameMode.speedRace);
      expect(identical(race.questionFor(1), race.questionFor(2)), isTrue);
      expect(identical(race.questionFor(1), race.sharedQuestion), isTrue);

      final classic = _playing();
      expect(identical(classic.questionFor(1), classic.questionFor(2)), isFalse);
    });

    test('a right answer clears both inputs', () {
      final c = _playing(mode: GameMode.speedRace);

      c.pressDigit(2, '1'); // team 2 started typing
      expect(_answer(c, 1), AnswerResult.correct);

      expect(c.inputFor(1), '');
      expect(c.inputFor(2), '');
      expect(c.scoreFor(1), 1);
      expect(c.scoreFor(2), 0);
    });

    test('winning the question breaks the other team\'s streak', () {
      final c = _playing(mode: GameMode.speedRace);

      _answer(c, 2);
      _answer(c, 2);
      expect(c.streakFor(2), 2);

      _answer(c, 1);
      expect(c.streakFor(2), 0);
      expect(c.streakFor(1), 1);
    });

    test('a wrong answer clears only that team\'s input', () {
      final c = _playing(mode: GameMode.speedRace);

      c.pressDigit(2, '1');
      expect(_answer(c, 1, right: false), AnswerResult.wrong);

      expect(c.inputFor(1), '');
      expect(c.inputFor(2), '1');
    });

    test('in Classic mode a right answer leaves the other input alone', () {
      final c = _playing();

      c.pressDigit(2, '1');
      _answer(c, 1);
      expect(c.inputFor(2), '1');
    });
  });

  group('Pause', () {
    test('pause and resume only work in the right phase', () {
      final c = _playing();

      c.resume();
      expect(c.isPlaying, isTrue); // nothing to resume

      c.pause();
      expect(c.isPaused, isTrue);

      c.resume();
      expect(c.isPlaying, isTrue);
    });

    test('the keypad is locked while paused', () {
      final c = _playing();

      c.pause();
      c.pressDigit(1, '5');
      expect(c.inputFor(1), '');
      expect(c.submit(1), AnswerResult.ignored);
    });

    test('match point still shows while paused', () {
      final c = _playing();

      for (var i = 0; i < GameConfig.streakForBonus + 1; i++) {
        _answer(c, 1);
      }
      c.pause();
      expect(c.matchPointTeam, 1);
    });
  });

  group('Timer', () {
    /// Runs [body] with a started controller. The controller is always
    /// disposed before the test ends, so no timer stays pending (the test
    /// framework fails a test that leaves a timer running).
    Future<void> withController(
      Future<void> Function(GameController c) body,
    ) async {
      final c = GameController(settings: _settings());
      c.start();
      try {
        await body(c);
      } finally {
        c.dispose();
      }
    }

    testWidgets('the countdown ends and the round starts', (tester) async {
      await withController((c) async {
        await tester.pump(const Duration(seconds: 1));
        expect(c.countdownValue, GameConfig.countdownSeconds - 1);
        expect(c.isCountingDown, isTrue);

        // 3, 2, 1, GO! and then the round begins.
        await tester.pump(const Duration(seconds: 3));
        expect(c.isPlaying, isTrue);
        expect(c.timeLeft, 45);
      });
    });

    testWidgets('time runs out with equal scores: a tie', (tester) async {
      await withController((c) async {
        await tester.pump(const Duration(seconds: 4)); // countdown
        await tester.pump(const Duration(seconds: 45)); // the round

        expect(c.isFinished, isTrue);
        expect(c.timeLeft, 0);
        expect(c.winner, 0);
      });
    });

    testWidgets('time runs out: the team with more points wins',
        (tester) async {
      await withController((c) async {
        await tester.pump(const Duration(seconds: 4));
        _answer(c, 2);
        await tester.pump(const Duration(seconds: 45));

        expect(c.isFinished, isTrue);
        expect(c.winner, 2);
      });
    });

    testWidgets('pause freezes the clock', (tester) async {
      await withController((c) async {
        await tester.pump(const Duration(seconds: 4));
        await tester.pump(const Duration(seconds: 5));
        expect(c.timeLeft, 40);

        c.pause();
        await tester.pump(const Duration(seconds: 10));
        expect(c.timeLeft, 40);

        c.resume();
        await tester.pump(const Duration(seconds: 1));
        expect(c.timeLeft, 39);
      });
    });

    testWidgets('the timer is urgent in the last seconds', (tester) async {
      await withController((c) async {
        await tester.pump(const Duration(seconds: 4));
        expect(c.isUrgent, isFalse);

        await tester.pump(
          const Duration(seconds: 45 - GameConfig.urgentSecondsThreshold),
        );
        expect(c.isUrgent, isTrue);
      });
    });
  });
}