import 'package:flutter_test/flutter_test.dart';
import 'package:tug_of_war_math/models/game_settings.dart';
import 'package:tug_of_war_math/models/question.dart';

void main() {
  final pattern = RegExp(r'^(\d+) ([+−×÷]) (\d+) = \?$');

  /// Solves the question text again, independently of the generator.
  int solve(String text) {
    final match = pattern.firstMatch(text);
    expect(match, isNotNull, reason: 'Unexpected question format: $text');
    final a = int.parse(match!.group(1)!);
    final b = int.parse(match.group(3)!);
    switch (match.group(2)) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        expect(a % b, 0, reason: '$text does not divide exactly');
        return a ~/ b;
    }
    throw StateError('Unknown operator in $text');
  }

  for (final operation in MathOperation.values) {
    for (final difficulty in Difficulty.values) {
      test('${operation.label} / ${difficulty.label}: answers are right', () {
        for (var i = 0; i < 500; i++) {
          final question = Question.generate(operation, difficulty);
          expect(question.answer, solve(question.text), reason: question.text);
          expect(question.answer, greaterThan(0), reason: question.text);
          expect(question.answer, lessThan(1000), reason: question.text);
        }
      });
    }
  }
}