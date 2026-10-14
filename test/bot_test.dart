// 📁 FILE: test/bot_test.dart   (NEW FILE)
// 📌 WHAT: Unit tests for the bot: think time, wrong answers, typing, pause, Speed Race reset
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathpull/game/game_controller.dart';
import 'package:mathpull/models/game_settings.dart';

/// A "random" source that always returns the same numbers, so the bot
/// behaves the same way on every run.
///
/// [double] close to 0 makes the bot answer correctly (0.0 < accuracy);
/// close to 1 makes it answer wrongly.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => true;
}

/// Hard bot, easy maths, one human against the computer.
GameSettings _botSettings({GameMode mode = GameMode.classic}) => GameSettings(
      mode: mode,
      difficulty: Difficulty.easy,
      playerMode: PlayerMode.vsBot,
      botLevel: BotLevel.hard,
    );

GameController _playingController(
  GameSettings settings, {
  double random = 0.0,
}) {
  final controller = GameController(
    settings: settings,
    random: _FixedRandom(random),
  );
  addTearDown(controller.dispose);
  controller.debugStartPlaying();
  return controller;
}

/// Runs the bot's clock in 100 ms steps until [done] is true
/// (or gives up after [maxMs]).
void _advanceUntil(
  GameController controller,
  bool Function() done, {
  int maxMs = 20000,
}) {
  var elapsed = 0;
  while (!done() && elapsed < maxMs) {
    controller.debugAdvanceBot(100);
    elapsed += 100;
  }
}

void main() {
  group('BotLevel', () {
    test('think time stays between 70% and 130% of the average', () {
      final fastest = BotLevel.hard.thinkTime(Difficulty.easy, 0.0);
      final slowest = BotLevel.hard.thinkTime(Difficulty.easy, 1.0);

      expect(fastest.inMilliseconds, closeTo(1960, 1)); // 2.8 s * 0.7
      expect(slowest.inMilliseconds, closeTo(3640, 1)); // 2.8 s * 1.3
    });

    test('values outside 0..1 are clamped', () {
      final below = BotLevel.medium.thinkTime(Difficulty.easy, -5);
      final above = BotLevel.medium.thinkTime(Difficulty.easy, 5);

      expect(below, BotLevel.medium.thinkTime(Difficulty.easy, 0));
      expect(above, BotLevel.medium.thinkTime(Difficulty.easy, 1));
    });

    test('a harder level is faster and more accurate', () {
      final easy = BotLevel.easy.thinkTime(Difficulty.medium, 0.5);
      final hard = BotLevel.hard.thinkTime(Difficulty.medium, 0.5);

      expect(hard, lessThan(easy));
      expect(BotLevel.hard.accuracy, greaterThan(BotLevel.easy.accuracy));
    });

    test('harder maths makes the bot slower', () {
      final easyMaths = BotLevel.medium.thinkTime(Difficulty.easy, 0.5);
      final hardMaths = BotLevel.medium.thinkTime(Difficulty.hard, 0.5);

      expect(hardMaths, greaterThan(easyMaths));
    });
  });

  group('wrongAnswerFor', () {
    test('is never the right answer and never negative', () {
      for (var seed = 0; seed < 200; seed++) {
        final random = Random(seed);
        for (var answer = 0; answer <= 30; answer++) {
          final wrong = GameController.wrongAnswerFor(answer, random);
          expect(wrong, isNot(answer), reason: 'seed $seed answer $answer');
          expect(wrong, greaterThanOrEqualTo(0));
        }
      }
    });

    test('stays close to the right answer', () {
      final random = Random(1);
      for (var i = 0; i < 100; i++) {
        final wrong = GameController.wrongAnswerFor(20, random);
        expect((wrong - 20).abs(), inInclusiveRange(1, 3));
      }
    });
  });

  group('Bot in a round', () {
    test('2 players: no bot, Team 2 keypad works', () {
      final controller = GameController(
        settings: const GameSettings(),
        random: _FixedRandom(0.0),
      );
      addTearDown(controller.dispose);
      controller.debugStartPlaying();

      expect(controller.hasBot, isFalse);

      controller.debugAdvanceBot(60000);
      expect(controller.scoreFor(2), 0);

      controller.pressDigit(2, '7');
      expect(controller.inputFor(2), '7');
    });

    test('with a bot, touches on the Team 2 keypad are ignored', () {
      final controller = _playingController(_botSettings());

      controller.pressDigit(2, '5');
      expect(controller.inputFor(2), '');

      expect(controller.submit(2), AnswerResult.ignored);
      expect(controller.feedbackIdFor(2), 0);
    });

    test('the bot does nothing during the countdown', () {
      final controller = GameController(
        settings: _botSettings(),
        random: _FixedRandom(0.0),
      );
      addTearDown(controller.dispose);

      controller.debugAdvanceBot(30000);

      expect(controller.isCountingDown, isTrue);
      expect(controller.inputFor(2), '');
      expect(controller.scoreFor(2), 0);
    });

    test('a bot that answers right scores a point', () {
      final controller = _playingController(_botSettings());

      _advanceUntil(controller, () => controller.feedbackIdFor(2) > 0);

      expect(controller.lastResultFor(2), AnswerResult.correct);
      expect(controller.scoreFor(2), 1);
      expect(controller.streakFor(2), 1);
      expect(controller.inputFor(2), '');
    });

    test('a bot that answers wrong scores nothing and loses its streak', () {
      final controller = _playingController(_botSettings(), random: 0.99);

      _advanceUntil(controller, () => controller.feedbackIdFor(2) > 0);

      expect(controller.lastResultFor(2), AnswerResult.wrong);
      expect(controller.scoreFor(2), 0);
      expect(controller.streakFor(2), 0);
      expect(controller.lastPointsFor(2), 0);
    });

    test('the bot types digit by digit before it submits', () {
      final controller = _playingController(_botSettings());

      var sawTyping = false;
      _advanceUntil(controller, () {
        if (controller.isBotTyping) sawTyping = true;
        return controller.feedbackIdFor(2) > 0;
      });

      expect(sawTyping, isTrue);
    });

    test('a paused round freezes the bot', () {
      final controller = _playingController(_botSettings());

      controller.pause();
      controller.debugAdvanceBot(60000);

      expect(controller.isPaused, isTrue);
      expect(controller.inputFor(2), '');
      expect(controller.scoreFor(2), 0);

      controller.resume();
      _advanceUntil(controller, () => controller.feedbackIdFor(2) > 0);
      expect(controller.scoreFor(2), 1);
    });

    test('a finished round stops the bot', () {
      final controller = _playingController(_botSettings());

      _advanceUntil(controller, () => controller.feedbackIdFor(2) > 0);
      final before = controller.scoreFor(2);

      controller.pause();
      controller.debugAdvanceBot(60000);

      expect(controller.scoreFor(2), before);
    });

    test('Speed Race: the bot drops its answer when the human scores first',
        () {
      final controller = _playingController(
        _botSettings(mode: GameMode.speedRace),
      );

      // Wait until the bot has started typing for the shared question.
      _advanceUntil(controller, () => controller.isBotTyping);
      expect(controller.isBotTyping, isTrue);

      // The human answers the same question correctly, first.
      final answer = controller.sharedQuestion.answer.toString();
      for (final digit in answer.split('')) {
        controller.pressDigit(1, digit);
      }
      expect(controller.submit(1), AnswerResult.correct);

      // The new question clears the bot's half-typed answer at once.
      expect(controller.inputFor(2), '');
      expect(controller.scoreFor(1), 1);

      // The bot gives up the old answer instead of submitting it.
      controller.debugAdvanceBot(300);
      expect(controller.scoreFor(2), 0);
      expect(controller.feedbackIdFor(2), 0);
      expect(controller.inputFor(2), '');
    });
  });
}