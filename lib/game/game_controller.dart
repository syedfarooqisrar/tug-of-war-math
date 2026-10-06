import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/question.dart';

/// What happened when a team pressed the ✓ button.
enum AnswerResult { ignored, correct, wrong }

/// Holds every rule of one round: questions, typed answers, scores,
/// the countdown timer and the winner. The screen only reads from it
/// and calls its methods.
class GameController extends ChangeNotifier {
  GameController({
    required this.maxTable,
    required this.roundSeconds,
    required this.winPulls,
  }) {
    _timeLeft = roundSeconds;
    _question1 = _newQuestion();
    _question2 = _newQuestion();
  }

  final int maxTable;
  final int roundSeconds;
  final int winPulls;

  late Question _question1;
  late Question _question2;
  String _input1 = '';
  String _input2 = '';
  int _score1 = 0;
  int _score2 = 0;
  late int _timeLeft;
  Timer? _timer;
  int? _winner; // null = still playing, 0 = tie, 1 = team 1, 2 = team 2

  // ---------- Read-only state for the screen ----------

  Question questionFor(int team) => team == 1 ? _question1 : _question2;
  String inputFor(int team) => team == 1 ? _input1 : _input2;
  int scoreFor(int team) => team == 1 ? _score1 : _score2;

  int get timeLeft => _timeLeft;
  bool get isUrgent => _timeLeft <= GameConfig.urgentSecondsThreshold;
  bool get isFinished => _winner != null;

  /// 0 = tie, 1 = team 1, 2 = team 2. Only valid when [isFinished] is true.
  int get winner => _winner ?? 0;

  /// Rope position: -1.0 means team 2 is winning fully, 1.0 means team 1.
  double get pull => ((_score1 - _score2) / winPulls).clamp(-1.0, 1.0);

  // ---------- Actions ----------

  /// Starts the countdown. Call once when the round begins.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pressDigit(int team, String digit) {
    if (isFinished) return;
    final current = inputFor(team);
    if (current.length >= GameConfig.maxAnswerDigits) return;
    _setInput(team, current + digit);
    notifyListeners();
  }

  void clearInput(int team) {
    if (isFinished) return;
    _setInput(team, '');
    notifyListeners();
  }

  /// Checks the typed answer. Returns what happened so the screen can
  /// react (animation, sound, and so on).
  AnswerResult submit(int team) {
    if (isFinished) return AnswerResult.ignored;
    final typed = inputFor(team);
    if (typed.isEmpty) return AnswerResult.ignored;

    final isCorrect = int.tryParse(typed) == questionFor(team).answer;
    _setInput(team, '');

    if (isCorrect) {
      if (team == 1) {
        _score1++;
        _question1 = _newQuestion();
      } else {
        _score2++;
        _question2 = _newQuestion();
      }
      _checkInstantWin();
    }

    notifyListeners();
    return isCorrect ? AnswerResult.correct : AnswerResult.wrong;
  }

  // ---------- Internal helpers ----------

  void _tick() {
    if (isFinished) return;
    _timeLeft--;
    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _finish(_score1 == _score2 ? 0 : (_score1 > _score2 ? 1 : 2));
    }
    notifyListeners();
  }

  void _checkInstantWin() {
    if (_score1 - _score2 >= winPulls) _finish(1);
    if (_score2 - _score1 >= winPulls) _finish(2);
  }

  void _finish(int winner) {
    _winner = winner;
    _timer?.cancel();
  }

  void _setInput(int team, String value) {
    if (team == 1) {
      _input1 = value;
    } else {
      _input2 = value;
    }
  }

  Question _newQuestion() => Question.random(
        maxTable: maxTable,
        maxMultiplier: GameConfig.maxMultiplier,
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}