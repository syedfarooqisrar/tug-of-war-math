import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../core/constants/app_constants.dart';
import '../core/layout/adaptive_layout.dart';
import '../core/services/sound_service.dart';
import '../game/game_controller.dart';
import '../game/tug_of_war_game.dart';
import '../models/game_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/pause_overlay.dart';
import '../widgets/question_banner.dart';
import '../widgets/team_panel.dart';
import '../widgets/win_overlay.dart';

class GameScreen extends StatefulWidget {
  final GameSettings settings;

  const GameScreen({super.key, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  late final TugOfWarGame game;

  // What we already played a sound for, so each event sounds only once.
  int _lastCountdown = -99;
  int _lastFeedback1 = 0;
  int _lastFeedback2 = 0;
  bool _finishHandled = false;

  @override
  void initState() {
    super.initState();
    controller = GameController(settings: widget.settings);
    game = TugOfWarGame();
    controller.addListener(_onControllerChanged);
    controller.start();

    // Load the sounds, then play the sound for the number on screen
    // (the "3" of the countdown).
    SoundService.instance.init().then((_) {
      if (mounted) _syncSounds();
    });
  }

  /// Runs every time the controller changes (score, timer, winner).
  void _onControllerChanged() {
    if (game.isLoaded) game.updatePull(controller.pull);
    _syncSounds();
  }

  /// Plays a sound for anything new that happened in the game.
  void _syncSounds() {
    final sound = SoundService.instance;

    // 1. Countdown: tick for 3, 2, 1 and a special sound for GO!
    if (controller.isCountingDown &&
        controller.countdownValue != _lastCountdown) {
      _lastCountdown = controller.countdownValue;
      sound.play(_lastCountdown > 0 ? Sfx.tick : Sfx.go);
    }

    // 2. Answers: right or wrong sound. If this answer ended the round,
    //    skip it and let the win sound play alone.
    final justFinished = controller.isFinished && !_finishHandled;
    for (final team in const [1, 2]) {
      final id = controller.feedbackIdFor(team);
      final last = team == 1 ? _lastFeedback1 : _lastFeedback2;
      if (id != last) {
        if (team == 1) {
          _lastFeedback1 = id;
        } else {
          _lastFeedback2 = id;
        }
        if (!justFinished) {
          final correct =
              controller.lastResultFor(team) == AnswerResult.correct;
          sound.play(correct ? Sfx.correct : Sfx.wrong);
        }
      }
    }

    // 3. End of the round.
    if (justFinished) {
      _finishHandled = true;
      sound.play(Sfx.win);
    }
  }

  /// Leaves the game and goes back to the start screen.
  void _quitGame() => Navigator.of(context).pop();

  /// Starts a fresh round with the same settings.
  void _playAgain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(settings: widget.settings),
      ),
    );
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  // ---------- Small building blocks ----------

  Widget _scoreboardChip(String label, int score, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppText.body(
            size: 10,
            weight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        Text('$score', style: AppText.number(size: 18, color: color)),
      ],
    );
  }

  Widget _teamPanel(int team) {
    final isTeam1 = team == 1;
    return TeamPanel(
      teamLabel: isTeam1 ? AppStrings.team1 : AppStrings.team2,
      flagEmoji: isTeam1 ? '🔵' : '🔴',
      color: isTeam1 ? AppColors.team1 : AppColors.team2,
      lightColor: isTeam1 ? AppColors.team1Light : AppColors.team2Light,
      score: controller.scoreFor(team),
      questionText: controller.questionFor(team).text,
      currentInput: controller.inputFor(team),
      onDigit: (digit) => controller.pressDigit(team, digit),
      onClear: () => controller.clearInput(team),
      onSubmit: () => controller.submit(team),
      lastResult: controller.lastResultFor(team),
      feedbackId: controller.feedbackIdFor(team),
      // Speed Race shows one shared question in the middle instead.
      showQuestion: !controller.isSpeedRace,
    );
  }

  /// Round pause button. Faded and inactive unless the round is playing.
  Widget _pauseButton() {
    final enabled = controller.isPlaying;
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Material(
        color: Colors.grey.shade200,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? controller.pause : null,
          child: const SizedBox(
            width: 34,
            height: 34,
            child: Icon(Icons.pause_rounded, size: 20, color: AppColors.ink),
          ),
        ),
      ),
    );
  }

  /// Sound on/off button. Muting also turns off vibration.
  Widget _muteButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: SoundService.instance.muted,
      builder: (context, muted, _) {
        return Material(
          color: muted ? Colors.red.shade50 : Colors.grey.shade200,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: SoundService.instance.toggleMute,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: 20,
                color: muted ? AppColors.team2 : AppColors.ink,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _scoreboard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _scoreboardChip(
            AppStrings.team1.toUpperCase(),
            controller.scoreFor(1),
            AppColors.team1,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⏱', style: TextStyle(fontSize: 12)),
                  Text(
                    '${controller.timeLeft}',
                    style: AppText.number(
                      size: 15,
                      color:
                          controller.isUrgent ? AppColors.team2 : AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              _pauseButton(),
              const SizedBox(width: 8),
              _muteButton(),
            ],
          ),
          _scoreboardChip(
            AppStrings.team2.toUpperCase(),
            controller.scoreFor(2),
            AppColors.team2,
          ),
        ],
      ),
    );
  }

  Widget _ropeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GameWidget(game: game),
    );
  }

  /// Scoreboard on top, then (Speed Race only) the shared question,
  /// then the arena.
  Widget _arenaColumn() {
    return Column(
      children: [
        _scoreboard(),
        const SizedBox(height: 8),
        if (controller.isSpeedRace) ...[
          QuestionBanner(text: controller.sharedQuestion.text, fontSize: 34),
          const SizedBox(height: 8),
        ],
        Expanded(child: _ropeCard()),
      ],
    );
  }

  /// Small timer chip that floats on top of the arena (tall screens).
  Widget _timerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⏱', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            '${controller.timeLeft}',
            style: AppText.number(
              size: 13,
              color: controller.isUrgent ? AppColors.team2 : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  /// Pause and mute stacked vertically in a small pill (corner of tall screens).
  Widget _cornerButtons() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pauseButton(),
          const SizedBox(height: 6),
          _muteButton(),
        ],
      ),
    );
  }

  /// The arena with the small timer chip floating at the top (tall screens).
  Widget _faceToFaceArena() {
    return Stack(
      children: [
        Positioned.fill(child: _ropeCard()),
        Positioned(
          top: 6,
          left: 0,
          right: 0,
          child: Center(child: _timerChip()),
        ),
      ],
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        '🏆 ${AppStrings.appTitle.toUpperCase()}',
        style: AppText.heading(size: 18, color: AppColors.team1Dark),
      ),
    );
  }

  // ---------- The two layouts ----------

  /// Wide screens (landscape): panel | arena | panel.
  Widget _sideBySideBoard(Size size) {
    final showTitle = size.height >= LayoutConstants.titleMinHeight;

    return Column(
      children: [
        if (showTitle) _title(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LayoutConstants.boardMaxWidth,
                  maxHeight: LayoutConstants.boardMaxHeight,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: _teamPanel(1)),
                    const SizedBox(width: LayoutConstants.panelGap),
                    Expanded(flex: 3, child: _arenaColumn()),
                    const SizedBox(width: LayoutConstants.panelGap),
                    Expanded(flex: 2, child: _teamPanel(2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Keeps a widget centered and no wider than [maxWidth].
  Widget _limitedWidth(double maxWidth, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// The shared question as a slim strip (tall screens, Speed Race).
  Widget _portraitBanner() {
    return _limitedWidth(
      LayoutConstants.portraitArenaMaxWidth,
      SizedBox(
        height: 54,
        child: QuestionBanner(
          text: controller.sharedQuestion.text,
          fontSize: 28,
        ),
      ),
    );
  }

  /// Tall screens (phone or tablet held upright): two players sit opposite
  /// each other. Team 2 is at the top, turned upside down; Team 1 is at
  /// the bottom. In Speed Race each player also gets the shared question,
  /// facing them.
  Widget _faceToFaceBoard() {
    final race = controller.isSpeedRace;
    final gap = race ? 8.0 : 10.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              Expanded(
                flex: 10,
                child: RotatedBox(
                  quarterTurns: 2,
                  child: _limitedWidth(
                    LayoutConstants.portraitPanelMaxWidth,
                    _teamPanel(2),
                  ),
                ),
              ),
              SizedBox(height: gap),
              if (race) ...[
                RotatedBox(quarterTurns: 2, child: _portraitBanner()),
                SizedBox(height: gap),
              ],
              Expanded(
                flex: 5,
                child: _limitedWidth(
                  LayoutConstants.portraitArenaMaxWidth,
                  _faceToFaceArena(),
                ),
              ),
              SizedBox(height: gap),
              if (race) ...[
                _portraitBanner(),
                SizedBox(height: gap),
              ],
              Expanded(
                flex: 10,
                child: _limitedWidth(
                  LayoutConstants.portraitPanelMaxWidth,
                  _teamPanel(1),
                ),
              ),
            ],
          ),
        ),
        // Pause and mute: stacked in the bottom-left corner, next to Team 1.
        Positioned(left: 8, bottom: 12, child: _cornerButtons()),
      ],
    );
  }

  Widget _board() {
    return FieldBackground(
      child: SafeArea(
        child: ScaledView(
          builder: (context, size, mode) => mode == BoardMode.faceToFace
              ? _faceToFaceBoard()
              : _sideBySideBoard(size),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: _board()),
              if (controller.isCountingDown)
                Positioned.fill(
                  child: ScaledView(
                    builder: (context, size, mode) =>
                        CountdownOverlay(value: controller.countdownValue),
                  ),
                ),
              if (controller.isPaused)
                Positioned.fill(
                  child: ScaledView(
                    builder: (context, size, mode) => PauseOverlay(
                      onResume: controller.resume,
                      onQuit: _quitGame,
                    ),
                  ),
                ),
              if (controller.isFinished)
                Positioned.fill(
                  child: ScaledView(
                    builder: (context, size, mode) => WinOverlay(
                      winner: controller.winner,
                      score1: controller.scoreFor(1),
                      score2: controller.scoreFor(2),
                      faceToFace: mode == BoardMode.faceToFace,
                      onPlayAgain: _playAgain,
                      onMenu: _quitGame,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}