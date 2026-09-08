import 'dart:math';

/// A single multiplication question, e.g. "7 x 6 = ?"
class Question {
  final int a;
  final int b;

  Question(this.a, this.b);

  int get answer => a * b;

  String get text => '$a × $b = ?';

  /// Generates a random question. [maxTable] controls the difficulty
  /// (e.g. 10 means the first number is between 1 and 10).
  factory Question.random({int maxTable = 10, int maxMultiplier = 10}) {
    final rand = Random();
    final a = 1 + rand.nextInt(maxTable);
    final b = 1 + rand.nextInt(maxMultiplier);
    return Question(a, b);
  }
}
