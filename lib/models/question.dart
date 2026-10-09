import 'dart:math';
import '../core/constants/app_constants.dart';
import 'game_settings.dart';

/// One math question, for example "7 × 6 = ?" with the answer 42.
class Question {
  final String text;
  final int answer;

  const Question._(this.text, this.answer);

  static final Random _rng = Random();

  static const List<MathOperation> _basicOperations = [
    MathOperation.addition,
    MathOperation.subtraction,
    MathOperation.multiplication,
    MathOperation.division,
  ];

  /// A question of the chosen operation and difficulty.
  /// [MathOperation.mixed] picks a random operation for every question.
  factory Question.generate(MathOperation operation, Difficulty difficulty) {
    final concrete = operation == MathOperation.mixed
        ? _basicOperations[_rng.nextInt(_basicOperations.length)]
        : operation;

    return switch (concrete) {
      MathOperation.addition => _addition(difficulty.numberMax),
      MathOperation.subtraction => _subtraction(difficulty.numberMax),
      MathOperation.division =>
        _division(difficulty.tableMax, GameConfig.maxMultiplier),
      _ => _multiplication(difficulty.tableMax, GameConfig.maxMultiplier),
    };
  }

  /// Older call used by the current game code: a multiplication question.
  /// It goes away when the game engine is updated in the next step.
  factory Question.random({int maxTable = 10, int maxMultiplier = 10}) =>
      _multiplication(maxTable, maxMultiplier);

  static int _between(int min, int max) => min + _rng.nextInt(max - min + 1);

  static Question _addition(int max) {
    final a = _between(1, max);
    final b = _between(1, max);
    return Question._('$a + $b = ?', a + b);
  }

  /// The answer is never zero or negative (the keypad has no minus key).
  static Question _subtraction(int max) {
    final a = _between(2, max);
    final b = _between(1, a - 1);
    return Question._('$a − $b = ?', a - b);
  }

  static Question _multiplication(int tableMax, int maxMultiplier) {
    final a = _between(1, tableMax);
    final b = _between(1, maxMultiplier);
    return Question._('$a × $b = ?', a * b);
  }

  /// Always divides exactly: the dividend is built from divisor × answer.
  static Question _division(int tableMax, int maxMultiplier) {
    final divisor = _between(2, max(2, tableMax));
    final quotient = _between(1, maxMultiplier);
    return Question._('${divisor * quotient} ÷ $divisor = ?', quotient);
  }
}