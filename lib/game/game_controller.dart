// 📁 FILE: lib/game/game_controller.dart
// 📌 WHAT: Game rules + a computer opponent (bot) that plays Team 2
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/game_settings.dart';
import '../models/question.dart';

/// What happened when a team pressed the ✓ button.
enum AnswerResult { ignored, correct, wrong }

/// Which part of the round we are in.
enum GamePhase { countdown, playing, paused, finished }

/// Holds every rule of one round: countdown, questions, typed answers,
/// scores, streaks, the timer, the bot and the winner. The screen only
/// reads from it and calls its methods.
class GameController extends ChangeNotifier {
  GameController({required this.settings, Random? random})
      : _random = random ?? Random() {
    _timeLeft = settings.roundSeconds;
    _countdown = GameConfig.countdownSeconds;
    _shared = _newQuestion();
    _question1 = _newQuestion();
    _question2 = _newQuestion(avoid: _question1);
    _botWaitMs = _rollBotThink();
  }

  final GameSettings settings;

  /// Source of randomness for the bot. Tests pass a seeded [Random].
  final Random _random;

  // How often the bot's clock moves, and how long it takes to press a
  // digit and then the ✓ button (so the player can see it "typing").
  static const int _botTickMs = 100;
  static const int _botDigitMs = 220;
  static const int _botSubmitMs = 280;

  // Classic mode: one question per team.
  late Question _question1;
  late Question _question2;

  // Speed Race mode: one question shared by both teams.
  late Question _shared;

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

  // Streaks: correct answers in a row. At [GameConfig.streakForBonus] the
  // team is "on fire" and its next correct answer pulls double.
  int _streak1 = 0;
  int _streak2 = 0;

  // Points earned by the team's last answer (0 for a wrong answer).
  int _lastPoints1 = 0;
  int _lastPoints2 = 0;

  // ---------- Bot state ----------

  Timer? _botTimer;

  /// Milliseconds of "round time" until the bot does its next action.
  int _botWaitMs = 0;

  /// The answer the bot is typing right now (null while it is thinking).
  String? _botPlan;

  /// How many digits of [_botPlan] are already typed.
  int _botDigit = 0;

  /// The question the bot started answering. If it changes (a human won
  /// the shared question in Speed Race) the bot drops its plan.
  Question? _botQuestion;

  // ---------- Read-only state for the screen ----------

  bool get isSpeedRace => settings.mode == GameMode.speedRace;
  int get winPulls => settings.winPulls;

  /// True when Team 2 is played by the computer.
  bool get hasBot => settings.hasBot;

  /// True while the bot has digits typed and is about to press ✓.
  bool get isBotTyping => hasBot && _input2.isNotEmpty;

  /// The question a team has to answer. In Speed Race both teams
  /// get the same one.
  Question questionFor(int team) =>
      isSpeedRace ? _shared : (team == 1 ? _question1 : _question2);

  /// The shared question shown in the middle (Speed Race).
  Question get sharedQuestion => _shared;

  String inputFor(int team) => team == 1 ? _input1 : _input2;
  int scoreFor(int team) => team == 1 ? _score1 : _score2;

  /// The result of the team's most recent answer.
  AnswerResult lastResultFor(int team) =>
      team == 1 ? _lastResult1 : _lastResult2;

  /// Goes up by one on every answer, right or wrong.
  int feedbackIdFor(int team) => team == 1 ? _feedbackId1 : _feedbackId2;

  /// Correct answers in a row.
  int streakFor(int team) => team == 1 ? _streak1 : _streak2;

  /// True when the team's next correct answer pulls double.
  bool isOnFire(int team) => streakFor(team) >= GameConfig.streakForBonus;

  /// Points the team's last answer earned (0 for a wrong answer).
  int lastPointsFor(int team) => team == 1 ? _lastPoints1 : _lastPoints2;

  /// 1 or 2 when that team is one pull away from winning, otherwise 0.
  int get matchPointTeam {
    if (!isPlaying && !isPaused) return 0;
    final diff = _score1 - _score2;
    if (diff >= winPulls - 1) return 1;
    if (-diff >= winPulls - 1) return 2;
    return 0;
  }

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

    _botTimer?.cancel();
    if (hasBot) {
      _botTimer = Timer.periodic(
        const Duration(milliseconds: _botTickMs),
        (_) => _advanceBot(_botTickMs),
      );
    }
  }

  /// Freezes the round. Only works while the round is being played.
  /// The bot freezes too, because its clock only runs while playing.
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
    if (!isPlaying || _isBotTeam(team)) return;
    _appendDigit(team, digit);
    notifyListeners();
  }

  void clearInput(int team) {
    if (!isPlaying || _isBotTeam(team)) return;
    _setInput(team, '');
    notifyListeners();
  }

  /// Checks the typed answer. Returns what happened so the screen can
  /// react (animation, sound, and so on).
  AnswerResult submit(int team) {
    if (_isBotTeam(team)) return AnswerResult.ignored;
    return _submit(team);
  }

  // ---------- Internal helpers ----------

  /// True for Team 2 when the computer plays it. Touches on that team's
  /// keypad are ignored; only the bot itself can type for it.
  bool _isBotTeam(int team) => hasBot && team == 2;

  void _appendDigit(int team, String digit) {
    final current = inputFor(team);
    if (current.length >= GameConfig.maxAnswerDigits) return;
    _setInput(team, current + digit);
  }

  AnswerResult _submit(int team) {
    if (!isPlaying) return AnswerResult.ignored;
    final typed = inputFor(team);
    if (typed.isEmpty) return AnswerResult.ignored;

    final isCorrect = int.tryParse(typed) == questionFor(team).answer;
    final result = isCorrect ? AnswerResult.correct : AnswerResult.wrong;
    _setInput(team, '');
    _setFeedback(team, result);

    if (isCorrect) {
      // A team that is "on fire" cashes in the bonus with this answer.
      final onFire = isOnFire(team);
      final points = onFire ? GameConfig.bonusPoints : 1;
      _addScore(team, points);
      _setStreak(team, onFire ? 0 : streakFor(team) + 1);
      _setLastPoints(team, points);

      if (isSpeedRace) {
        // Winning the question breaks the other team's run. New shared
        // question, and both teams start typing again from scratch.
        _setStreak(_otherTeam(team), 0);
        _shared = _newQuestion(avoid: _shared);
        _input1 = '';
        _input2 = '';
      } else if (team == 1) {
        _question1 = _newQuestion(avoid: _question1);
      } else {
        _question2 = _newQuestion(avoid: _question2);
      }

      _checkInstantWin();
    } else {
      _setStreak(team, 0);
      _setLastPoints(team, 0);
    }

    notifyListeners();
    return result;
  }

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
    _botTimer?.cancel();
  }

  int _otherTeam(int team) => team == 1 ? 2 : 1;

  void _addScore(int team, int points) {
    if (team == 1) {
      _score1 += points;
    } else {
      _score2 += points;
    }
  }

  void _setStreak(int team, int value) {
    if (team == 1) {
      _streak1 = value;
    } else {
      _streak2 = value;
    }
  }

  void _setLastPoints(int team, int value) {
    if (team == 1) {
      _lastPoints1 = value;
    } else {
      _lastPoints2 = value;
    }
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

  /// A new question that is not the same as [avoid].
  Question _newQuestion({Question? avoid}) {
    var question = Question.generate(settings.operation, settings.difficulty);
    for (var i = 0;
        i < 5 && avoid != null && question.text == avoid.text;
        i++) {
      question = Question.generate(settings.operation, settings.difficulty);
    }
    return question;
  }

  // ---------- Bot ----------

  /// How long the bot thinks before its next answer, in milliseconds.
  int _rollBotThink() {
    final time = settings.botLevel.thinkTime(
      settings.difficulty,
      _random.nextDouble(),
    );
    return max(1, time.inMilliseconds);
  }

  /// A wrong answer that looks believable: close to the right one,
  /// never equal to it and never negative.
  @visibleForTesting
  static int wrongAnswerFor(int answer, Random random) {
    var delta = random.nextInt(3) + 1; // 1, 2 or 3
    if (random.nextBool()) delta = -delta;
    var wrong = answer + delta;
    if (wrong < 0) wrong = answer + delta.abs();
    return wrong;
  }

  /// Decides what the bot will type for [question] (right or wrong,
  /// depending on its level).
  String _planBotAnswer(Question question) {
    final correct = question.answer;
    final isRight = _random.nextDouble() < settings.botLevel.accuracy;
    final text = '${isRight ? correct : wrongAnswerFor(correct, _random)}';
    return text.length > GameConfig.maxAnswerDigits ? '$correct' : text;
  }

  void _resetBotPlan() {
    _botPlan = null;
    _botDigit = 0;
    _botQuestion = null;
  }

  /// Moves the bot's clock forward. It only runs while the round is
  /// being played, so pause and countdown freeze the bot.
  void _advanceBot(int milliseconds) {
    if (!hasBot) return;
    var remaining = milliseconds;
    while (remaining > 0 && isPlaying) {
      final step = min(remaining, _botWaitMs);
      _botWaitMs -= step;
      remaining -= step;
      if (_botWaitMs <= 0) _botAct();
    }
  }

  /// One bot action: start a plan, press the next digit, or press ✓.
  void _botAct() {
    final question = questionFor(2);

    // The question changed under the bot (Speed Race: Team 1 scored).
    // Forget the half-typed answer and think about the new question.
    if (_botPlan != null && !identical(_botQuestion, question)) {
      _resetBotPlan();
      _setInput(2, '');
      _botWaitMs = _rollBotThink();
      notifyListeners();
      return;
    }

    if (_botPlan == null) {
      _botPlan = _planBotAnswer(question);
      _botQuestion = question;
      _botDigit = 0;
    }

    final plan = _botPlan!;
    if (_botDigit < plan.length) {
      _appendDigit(2, plan[_botDigit]);
      _botDigit++;
      _botWaitMs = _botDigit < plan.length ? _botDigitMs : _botSubmitMs;
      notifyListeners();
      return;
    }

    // All digits are typed: press ✓ and start thinking about the next one.
    _resetBotPlan();
    _botWaitMs = _rollBotThink();
    _submit(2);
  }

  // ---------- Hooks for unit tests only ----------

  /// Skips the countdown so tests can start playing at once.
  @visibleForTesting
  void debugStartPlaying() {
    _phase = GamePhase.playing;
    notifyListeners();
  }

  /// Moves the bot's clock forward without waiting in real time.
  @visibleForTesting
  void debugAdvanceBot(int milliseconds) => _advanceBot(milliseconds);

  @override
  void dispose() {
    _timer?.cancel();
    _botTimer?.cancel();
    super.dispose();
  }
}