import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../core/constants/app_constants.dart';
import '../game/game_controller.dart';
import '../game/tug_of_war_game.dart';
import '../theme/app_theme.dart';
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
  }

  /// Runs every time the controller changes (score, timer, winner).
  void _onControllerChanged() {
    if (game.isLoaded) game.updatePull(controller.pull);

    if (controller.isFinished && !_dialogShown && mounted) {
      _dialogShown = true;
      _showWinDialog();
    }
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
        Text('$score', style: AppText.heading(size: 18, color: color)),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏱', style: TextStyle(fontSize: 12)),
              Text(
                '${controller.timeLeft}',
                style: AppText.heading(
                  size: 15,
                  color: controller.isUrgent ? AppColors.team2 : AppColors.ink,
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          body: FieldBackground(
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
          ),
        );
      },
    );
  }
}