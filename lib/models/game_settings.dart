// 📁 FILE: lib/models/game_settings.dart
// 📌 WHAT: Adds PlayerMode (2 players / vs bot) and BotLevel (speed + accuracy) to the settings
import '../core/constants/app_constants.dart';

/// Which kind of math the questions use.
enum MathOperation { addition, subtraction, multiplication, division, mixed }

/// How the two teams play.
enum GameMode {
  /// Each team gets its own question and answers at its own pace.
  classic,

  /// One shared question is shown in the middle. The first team to type
  /// the correct answer wins the point.
  speedRace,
}

/// How big the numbers in the questions are.
enum Difficulty { easy, medium, hard }

/// Who plays Team 2.
enum PlayerMode {
  /// Two humans share the screen.
  twoPlayers,

  /// One human (Team 1) plays against the computer (Team 2).
  vsBot,
}

/// How fast and how accurate the bot is. This is separate from [Difficulty],
/// so a child can play Hard maths against an Easy bot.
enum BotLevel { easy, medium, hard }

extension MathOperationInfo on MathOperation {
  /// Text on the start-screen button.
  String get symbol => switch (this) {
        MathOperation.addition => '+',
        MathOperation.subtraction => '−',
        MathOperation.multiplication => '×',
        MathOperation.division => '÷',
        MathOperation.mixed => 'Mix',
      };

  String get label => switch (this) {
        MathOperation.addition => 'Addition',
        MathOperation.subtraction => 'Subtraction',
        MathOperation.multiplication => 'Multiplication',
        MathOperation.division => 'Division',
        MathOperation.mixed => 'Mixed',
      };
}

extension GameModeInfo on GameMode {
  String get label => switch (this) {
        GameMode.classic => 'Classic',
        GameMode.speedRace => 'Speed Race',
      };

  String get description => switch (this) {
        GameMode.classic => 'Each team gets its own question.',
        GameMode.speedRace =>
          'One question for both. The fastest correct answer wins the point!',
      };
}

extension DifficultyInfo on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Easy',
        Difficulty.medium => 'Medium',
        Difficulty.hard => 'Hard',
      };

  /// Biggest number in a times table (multiplication and division).
  int get tableMax => switch (this) {
        Difficulty.easy => 5,
        Difficulty.medium => 10,
        Difficulty.hard => 12,
      };

  /// Biggest number in addition and subtraction.
  int get numberMax => switch (this) {
        Difficulty.easy => 10,
        Difficulty.medium => 20,
        Difficulty.hard => 50,
      };

  String get description => switch (this) {
        Difficulty.easy => 'Tables up to 5, numbers up to 10',
        Difficulty.medium => 'Tables up to 10, numbers up to 20',
        Difficulty.hard => 'Tables up to 12, numbers up to 50',
      };

  /// Bigger numbers take longer to think about, so the bot slows down
  /// on harder maths (a human would too).
  double get botThinkFactor => switch (this) {
        Difficulty.easy => 1.0,
        Difficulty.medium => 1.3,
        Difficulty.hard => 1.8,
      };
}

extension PlayerModeInfo on PlayerMode {
  String get label => switch (this) {
        PlayerMode.twoPlayers => '2 Players',
        PlayerMode.vsBot => 'vs Bot',
      };

  String get description => switch (this) {
        PlayerMode.twoPlayers => 'Two players on one screen.',
        PlayerMode.vsBot => 'You play against the computer.',
      };
}

extension BotLevelInfo on BotLevel {
  String get label => switch (this) {
        BotLevel.easy => 'Easy',
        BotLevel.medium => 'Medium',
        BotLevel.hard => 'Hard',
      };

  String get description => switch (this) {
        BotLevel.easy => 'Slow and makes many mistakes',
        BotLevel.medium => 'Average speed, some mistakes',
        BotLevel.hard => 'Fast and rarely wrong',
      };

  /// Average seconds the bot needs for an answer (before the maths
  /// difficulty is applied).
  double get baseThinkSeconds => switch (this) {
        BotLevel.easy => 7.0,
        BotLevel.medium => 4.5,
        BotLevel.hard => 2.8,
      };

  /// Chance (0.0 to 1.0) that the bot types the right answer.
  double get accuracy => switch (this) {
        BotLevel.easy => 0.70,
        BotLevel.medium => 0.85,
        BotLevel.hard => 0.95,
      };

  /// How long the bot "thinks" before answering one question.
  ///
  /// [t] is a random number from 0.0 to 1.0 (passed in, so tests can use
  /// fixed values). The result is between 70% and 130% of the average time.
  Duration thinkTime(Difficulty difficulty, double t) {
    final average = baseThinkSeconds * difficulty.botThinkFactor;
    final seconds = average * (0.7 + 0.6 * t.clamp(0.0, 1.0));
    return Duration(milliseconds: (seconds * 1000).round());
  }
}

/// Everything chosen on the start screen for one round.
class GameSettings {
  final MathOperation operation;
  final GameMode mode;
  final Difficulty difficulty;
  final int roundSeconds;
  final int winPulls;
  final PlayerMode playerMode;
  final BotLevel botLevel;

  const GameSettings({
    this.operation = MathOperation.multiplication,
    this.mode = GameMode.classic,
    this.difficulty = Difficulty.medium,
    this.roundSeconds = GameConfig.defaultRoundSeconds,
    this.winPulls = GameConfig.defaultWinPulls,
    this.playerMode = PlayerMode.twoPlayers,
    this.botLevel = BotLevel.medium,
  });

  /// True when Team 2 is played by the computer.
  bool get hasBot => playerMode == PlayerMode.vsBot;
}