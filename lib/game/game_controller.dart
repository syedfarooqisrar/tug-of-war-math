import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/question.dart';

/// What happened when a team pressed the ✓ button.
enum AnswerResult { ignored, correct, wrong }

/// Which part of the round we are in.
enum GamePhase { countdown, playing, paused, finished }

/// Holds every rule of one round: countdown, questions, typed answers,
/// scores, the timer and the winner. The screen only reads from it
/// and calls its methods.
class GameController extends ChangeNotifier {
  GameController({
    required this.maxTable,
    required this.roundSeconds,
    required this.winPulls,
  }) {
    _timeLeft = roundSeconds;
    _countdown = GameConfig.countdownSeconds;
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
  late int _countdown;
  Timer? _timer;
  GamePhase _phase = GamePhase.countdown;
  int _winner = 0; // 0 = tie, 1 = team 1, 2 = team 2 (valid once finished)

  // Last answer result per team, plus a counter that goes up on every
  // answer so the screen knows when to play a feedback animation.
  AnswerResult _lastResult1 = AnswerResult.ignored;
  AnswerResult _lastResult2 = AnswerResult.ignored;
  int _feedbackId1 = 0;
  int _feedbackId2 = 0;

  // ---------- Read-only state for the screen ----------

  Question questionFor(int team) => team == 1 ? _question1 : _question2;
  String inputFor(int team) => team == 1 ? _input1 : _input2;
  int scoreFor(int team) => team == 1 ? _score1 : _score2;

  /// The result of the team's most recent answer.
  AnswerResult lastResultFor(int team) =>
      team == 1 ? _lastResult1 : _lastResult2;

  /// Goes up by one on every answer, right or wrong.
  int feedbackIdFor(int team) => team == 1 ? _feedbackId1 : _feedbackId2;

  GamePhase get phase => _phase;
  bool get isCountingDown => _phase == GamePhase.countdown;
  bool get isPlaying => _phase == GamePhase.playing;
  bool get isPaused => _phase == GamePhase.paused;
  bool get isFinished => _phase == GamePhase.finished;

  /// 3, 2, 1, then 0 which means "GO!". Only meaningful while counting down.
  int get countdownValue => _countdown;

  int get timeLeft => _timeLeft;
  bool get isUrgent => _timeLeft <= GameConfig.urgentSecondsThreshold;

  /// 0 = tie, 1 = team 1, 2 = team 2. Only valid when [isFinished] is true.
  int get winner => _winner;

  /// Rope position: -1.0 means team 2 is winning fully, 1.0 means team 1.
  double get pull => ((_score1 - _score2) / winPulls).clamp(-1.0, 1.0);

  // ---------- Actions ----------

  /// Begins the countdown. Call once when the screen opens.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Freezes the round. Only works while the round is being played.
  void pause() {
    if (!isPlaying) return;
    _phase = GamePhase.paused;
    notifyListeners();
  }

  /// Continues a paused round.
  void resume() {
    if (!isPaused) return;
    _phase = GamePhase.playing;
    notifyListeners();
  }

  void pressDigit(int team, String digit) {
    if (!isPlaying) return;
    final current = inputFor(team);
    if (current.length >= GameConfig.maxAnswerDigits) return;
    _setInput(team, current + digit);
    notifyListeners();
  }

  void clearInput(int team) {
    if (!isPlaying) return;
    _setInput(team, '');
    notifyListeners();
  }

  /// Checks the typed answer. Returns what happened so the screen can
  /// react (animation, sound, and so on).
  AnswerResult submit(int team) {
    if (!isPlaying) return AnswerResult.ignored;
    final typed = inputFor(team);
    if (typed.isEmpty) return AnswerResult.ignored;

    final isCorrect = int.tryParse(typed) == questionFor(team).answer;
    final result = isCorrect ? AnswerResult.correct : AnswerResult.wrong;
    _setInput(team, '');
    _setFeedback(team, result);

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
    return result;
  }

  // ---------- Internal helpers ----------

  void _tick() {
    switch (_phase) {
      case GamePhase.countdown:
        _countdown--; // 3 -> 2 -> 1 -> 0 ("GO!") -> -1 (round starts)
        if (_countdown < 0) _phase = GamePhase.playing;
        break;
      case GamePhase.playing:
        _timeLeft--;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _finish(_score1 == _score2 ? 0 : (_score1 > _score2 ? 1 : 2));
        }
        break;
      case GamePhase.paused:
      case GamePhase.finished:
        return;
    }
    notifyListeners();
  }

  void _checkInstantWin() {
    if (_score1 - _score2 >= winPulls) _finish(1);
    if (_score2 - _score1 >= winPulls) _finish(2);
  }

  void _finish(int winner) {
    _winner = winner;
    _phase = GamePhase.finished;
    _timer?.cancel();
  }

  void _setInput(int team, String value) {
    if (team == 1) {
      _input1 = value;
    } else {
      _input2 = value;
    }
  }

  void _setFeedback(int team, AnswerResult result) {
    if (team == 1) {
      _lastResult1 = result;
      _feedbackId1++;
    } else {
      _lastResult2 = result;
      _feedbackId2++;
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