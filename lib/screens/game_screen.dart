// 📁 FILE: lib/screens/game_screen.dart
// 📌 WHAT: Clean game screen: flat scoreboard and arena card, 44-unit round buttons, icons instead of emoji
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../core/constants/app_constants.dart';
import '../core/layout/adaptive_layout.dart';
import '../core/services/sound_service.dart';
import '../game/game_controller.dart';
import '../game/tug_of_war_game.dart';
import '../models/game_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/bot_panel.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/pause_overlay.dart';
import '../widgets/quit_confirm_overlay.dart';
import '../widgets/question_banner.dart';
import '../widgets/team_panel.dart';
import '../widgets/win_overlay.dart';
import '../widgets/match_point_banner.dart';

class GameScreen extends StatefulWidget {
  final GameSettings settings;

  const GameScreen({super.key, required this.settings});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// Name of the computer player (shown instead of "Team 2").
  static const String _botLabel = 'Bot';
  static const String _botMatchPoint = 'BOT · MATCH POINT';

  // Labels for the round buttons (read by screen readers and tooltips).
  static const String _pauseLabel = 'Pause';
  static const String _muteLabel = 'Mute sound';
  static const String _unmuteLabel = 'Turn sound on';

  /// Size of the round buttons (pause, mute, quit), in design units.
  static const double _buttonSize = 44;

  late final GameController controller;
  late final TugOfWarGame game;

  // What we already played a sound for, so each event sounds only once.
  int _lastCountdown = -99;
  int _lastFeedback1 = 0;
  int _lastFeedback2 = 0;
  bool _finishHandled = false;
  bool _resultScheduled = false;
  bool _showResult = false;
  bool _confirmingQuit = false;
  bool _pausedForQuit = false;

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
    final finished = controller.isFinished;

    if (game.isLoaded) {
      game.updatePull(controller.pull);
      if (finished) game.setResult(controller.winner);
    }
    _syncSounds();

    // Let the arena celebrate for a moment before the result card appears.
    if (finished && !_resultScheduled) {
      _resultScheduled = true;
      Future.delayed(GameConfig.resultDelay, () {
        if (mounted) setState(() => _showResult = true);
      });
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

    // 2. Answers: one sound per answer (wrong, correct, or bonus). If this
    //    answer ended the round, skip it and let the win sound play alone.
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
          final bonus = controller.lastPointsFor(team) > 1;
          sound.play(correct ? (bonus ? Sfx.bonus : Sfx.correct) : Sfx.wrong);
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

  /// Asks "really quit?". The round is paused while the question is open.
  void _requestQuit() {
    if (controller.isFinished || _confirmingQuit) return;

    // Nothing to lose during the 3-2-1-GO countdown.
    if (controller.isCountingDown) {
      _quitGame();
      return;
    }

    setState(() => _confirmingQuit = true);
    if (controller.isPlaying) {
      controller.pause();
      _pausedForQuit = true;
    }
  }

  /// "Keep playing": closes the question and continues the round.
  void _stayInGame() {
    setState(() => _confirmingQuit = false);
    if (_pausedForQuit) {
      _pausedForQuit = false;
      controller.resume();
    }
  }

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
            size: AppText.sizeCaption,
            weight: FontWeight.w700,
            color: AppColors.inkMuted,
          ),
        ),
        Text('$score', style: AppText.number(size: 20, color: color)),
      ],
    );
  }

  Widget _teamPanel(int team) {
    // Team 2 is the computer in single-player: no keypad, just a display.
    if (team == 2 && controller.hasBot) {
      return BotPanel(
        label: _botLabel,
        color: AppColors.team2,
        lightColor: AppColors.team2Light,
        score: controller.scoreFor(2),
        questionText: controller.questionFor(2).text,
        currentInput: controller.inputFor(2),
        showQuestion: !controller.isSpeedRace,
        streak: controller.streakFor(2),
        lastResult: controller.lastResultFor(2),
        feedbackId: controller.feedbackIdFor(2),
        lastPoints: controller.lastPointsFor(2),
      );
    }

    final isTeam1 = team == 1;
    return TeamPanel(
      teamLabel: isTeam1 ? AppStrings.team1 : AppStrings.team2,
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
      streak: controller.streakFor(team),
      lastPoints: controller.lastPointsFor(team),
    );
  }

  /// A round icon button (pause, mute, quit). [onTap] null = disabled.
  Widget _roundButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color background = AppColors.backgroundDeep,
    Color iconColor = AppColors.ink,
  }) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: _buttonSize,
              height: _buttonSize,
              child: Icon(icon, size: 22, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }

  /// Round pause button. Faded and inactive unless the round is playing.
  Widget _pauseButton() {
    final enabled = controller.isPlaying;
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: _roundButton(
        icon: Icons.pause_rounded,
        label: _pauseLabel,
        onTap: enabled ? controller.pause : null,
      ),
    );
  }

  /// Sound on/off button. Muting also turns off vibration.
  Widget _muteButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: SoundService.instance.muted,
      builder: (context, muted, _) {
        return _roundButton(
          icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          label: muted ? _unmuteLabel : _muteLabel,
          onTap: SoundService.instance.toggleMute,
          background: muted
              ? AppColors.danger.withValues(alpha: 0.12)
              : AppColors.backgroundDeep,
          iconColor: muted ? AppColors.danger : AppColors.ink,
        );
      },
    );
  }

  /// Quit button (asks first, so a stray tap cannot end the game).
  Widget _quitButton() {
    return _roundButton(
      icon: Icons.close_rounded,
      label: AppStrings.quit,
      onTap: _requestQuit,
      background: AppColors.danger.withValues(alpha: 0.12),
      iconColor: AppColors.danger,
    );
  }

  Widget _scoreboard() {
    final team2Label = controller.hasBot ? _botLabel : AppStrings.team2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: AppShadows.card,
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
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.inkMuted,
                  ),
                  Text(
                    '${controller.timeLeft}',
                    style: AppText.number(
                      size: 16,
                      color: controller.isUrgent
                          ? AppColors.danger
                          : AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              _pauseButton(),
              const SizedBox(width: AppSpacing.sm),
              _muteButton(),
              const SizedBox(width: AppSpacing.sm),
              _quitButton(),
            ],
          ),
          _scoreboardChip(
            team2Label.toUpperCase(),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: game)),
          if (controller.matchPointTeam != 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Center(
                child: MatchPointBanner(
                  key: ValueKey(controller.matchPointTeam),
                  team: controller.matchPointTeam,
                  label: controller.hasBot && controller.matchPointTeam == 2
                      ? _botMatchPoint
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Scoreboard on top, then (Speed Race only) the shared question,
  /// then the arena.
  Widget _arenaColumn() {
    return Column(
      children: [
        _scoreboard(),
        const SizedBox(height: AppSpacing.sm),
        if (controller.isSpeedRace) ...[
          QuestionBanner(text: controller.sharedQuestion.text, fontSize: 34),
          const SizedBox(height: AppSpacing.sm),
        ],
        Expanded(child: _ropeCard()),
      ],
    );
  }

  /// Small timer chip that floats on top of the arena (tall screens).
  Widget _timerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 13,
            color: AppColors.inkMuted,
          ),
          const SizedBox(width: 4),
          Text(
            '${controller.timeLeft}',
            style: AppText.number(
              size: 14,
              color: controller.isUrgent ? AppColors.danger : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  /// Pause, mute and quit stacked vertically in a small pill (corner of
  /// tall screens).
  Widget _cornerButtons() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pauseButton(),
          const SizedBox(height: 6),
          _muteButton(),
          const SizedBox(height: 6),
          _quitButton(),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 22,
            color: AppColors.gold,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppStrings.appTitle,
            style: AppText.heading(size: AppText.sizeTitle),
          ),
        ],
      ),
    );
  }

  // ---------- The layouts ----------

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
        // Pause, mute and quit: stacked in the bottom-left corner.
        Positioned(left: 8, bottom: 12, child: _cornerButtons()),
      ],
    );
  }

  /// Tall screens, one human against the bot: nobody sits opposite, so
  /// nothing is turned upside down. The bot is a slim panel on top, the
  /// arena is in the middle and the player's calculator is at the bottom.
  Widget _botPortraitBoard() {
    final race = controller.isSpeedRace;
    const gap = 8.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: _limitedWidth(
                  LayoutConstants.portraitPanelMaxWidth,
                  _teamPanel(2),
                ),
              ),
              const SizedBox(height: gap),
              if (race) ...[
                _portraitBanner(),
                const SizedBox(height: gap),
              ],
              Expanded(
                flex: 6,
                child: _limitedWidth(
                  LayoutConstants.portraitArenaMaxWidth,
                  _faceToFaceArena(),
                ),
              ),
              const SizedBox(height: gap),
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
        Positioned(left: 8, bottom: 12, child: _cornerButtons()),
      ],
    );
  }

  Widget _board() {
    return FieldBackground(
      child: SafeArea(
        child: ScaledView(
          builder: (context, size, mode) {
            if (mode == BoardMode.faceToFace) {
              return controller.hasBot
                  ? _botPortraitBoard()
                  : _faceToFaceBoard();
            }
            return _sideBySideBoard(size);
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
        return PopScope(
          // Once the round is over, Back simply leaves. During a round it
          // asks first, so a stray tap on Back cannot throw the game away.
          canPop: controller.isFinished,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _requestQuit();
          },
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: _board()),
                if (controller.isCountingDown)
                  Positioned.fill(
                    child: ScaledView(
                      builder: (context, size, mode) => CountdownOverlay(
                        value: controller.countdownValue,
                        // In 2-player portrait one player would read the
                        // words upside down, so show only the lights there.
                        showLabel: mode != BoardMode.faceToFace ||
                            controller.hasBot,
                      ),
                    ),
                  ),
                if (controller.isPaused && !_confirmingQuit)
                  Positioned.fill(
                    child: ScaledView(
                      builder: (context, size, mode) => PauseOverlay(
                        onResume: controller.resume,
                        onQuit: _quitGame,
                      ),
                    ),
                  ),
                if (_confirmingQuit)
                  Positioned.fill(
                    child: ScaledView(
                      builder: (context, size, mode) => QuitConfirmOverlay(
                        onStay: _stayInGame,
                        onQuit: _quitGame,
                      ),
                    ),
                  ),
                if (controller.isFinished && _showResult)
                  Positioned.fill(
                    child: ScaledView(
                      builder: (context, size, mode) => WinOverlay(
                        winner: controller.winner,
                        score1: controller.scoreFor(1),
                        score2: controller.scoreFor(2),
                        // With a bot there is no player on the other side,
                        // so no upside-down copy of the result.
                        faceToFace: mode == BoardMode.faceToFace &&
                            !controller.hasBot,
                        hasBot: controller.hasBot,
                        onPlayAgain: _playAgain,
                        onMenu: _quitGame,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}