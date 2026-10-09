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
}

/// Everything chosen on the start screen for one round.
class GameSettings {
  final MathOperation operation;
  final GameMode mode;
  final Difficulty difficulty;
  final int roundSeconds;
  final int winPulls;

  const GameSettings({
    this.operation = MathOperation.multiplication,
    this.mode = GameMode.classic,
    this.difficulty = Difficulty.medium,
    this.roundSeconds = GameConfig.defaultRoundSeconds,
    this.winPulls = GameConfig.defaultWinPulls,
  });
}