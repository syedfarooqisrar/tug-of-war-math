import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../core/constants/app_constants.dart';
import '../core/services/sound_service.dart';
import '../game/game_controller.dart';
import '../game/tug_of_war_game.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/pause_overlay.dart';
import '../widgets/team_panel.dart';
import '../widgets/win_dialog.dart';

class GameScreen extends StatefulWidget {
  final int maxTable;
  final int roundSeconds;
  final int winPulls;

  const GameScreen({
    super.key,
    required this.maxTable,
    required this.roundSeconds,
    required this.winPulls,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;
  late final TugOfWarGame game;
  bool _dialogShown = false;

  // What we already played a sound for, so each event sounds only once.
  int _lastCountdown = -99;
  int _lastFeedback1 = 0;
  int _lastFeedback2 = 0;

  @override
  void initState() {
    super.initState();
    controller = GameController(
      maxTable: widget.maxTable,
      roundSeconds: widget.roundSeconds,
      winPulls: widget.winPulls,
    );
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

    if (controller.isFinished && !_dialogShown && mounted) {
      _dialogShown = true;
      _showWinDialog();
    }
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
    final justFinished = controller.isFinished && !_dialogShown;
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
    if (justFinished) sound.play(Sfx.win);
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WinDialog(
        winner: controller.winner,
        score1: controller.scoreFor(1),
        score2: controller.scoreFor(2),
        onBackToMenu: () => Navigator.of(context)
          ..pop()
          ..pop(),
      ),
    );
  }

  /// Leaves the game and goes back to the start screen.
  void _quitGame() => Navigator.of(context).pop();

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

  // ---------- The two board layouts ----------

  /// Tablet landscape, laptop, web: panel | rope | panel in one row.
  Widget _wideBoard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: LayoutConstants.boardMaxWidth,
        maxHeight: LayoutConstants.boardMaxHeight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _teamPanel(1)),
          const SizedBox(width: LayoutConstants.panelGap),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _scoreboard(),
                const SizedBox(height: 8),
                Expanded(child: _ropeCard()),
              ],
            ),
          ),
          const SizedBox(width: LayoutConstants.panelGap),
          Expanded(flex: 2, child: _teamPanel(2)),
        ],
      ),
    );
  }

  /// Phone in portrait, narrow window: scoreboard and rope on top,
  /// the two team panels side by side below.
  Widget _compactBoard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: LayoutConstants.compactBoardMaxWidth,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutConstants.compactSidePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _scoreboard(),
            const SizedBox(height: 8),
            SizedBox(
              height: LayoutConstants.compactRopeHeight,
              child: _ropeCard(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _teamPanel(1)),
                  const SizedBox(width: LayoutConstants.panelGap),
                  Expanded(child: _teamPanel(2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The whole game board with its title, responsive to screen size.
  Widget _board() {
    return FieldBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide =
                constraints.maxWidth >= LayoutConstants.wideMinWidth &&
                    constraints.maxWidth > constraints.maxHeight;
            final showTitle =
                constraints.maxHeight >= LayoutConstants.titleMinHeight;

            return Column(
              children: [
                if (showTitle)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '🏆 ${AppStrings.appTitle.toUpperCase()}',
                      style: AppText.heading(
                        size: 18,
                        color: AppColors.team1Dark,
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: isWide
                        ? Center(child: _wideBoard())
                        : Align(
                            alignment: Alignment.topCenter,
                            child: _compactBoard(),
                          ),
                  ),
                ),
              ],
            );
          },
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
                  child: CountdownOverlay(value: controller.countdownValue),
                ),
              if (controller.isPaused)
                Positioned.fill(
                  child: PauseOverlay(
                    onResume: controller.resume,
                    onQuit: _quitGame,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}