import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/tug_of_war_game.dart';
import '../models/question.dart';
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
  late final TugOfWarGame game;
  late Question q1;
  late Question q2;
  String input1 = '';
  String input2 = '';
  int score1 = 0;
  int score2 = 0;
  late int timeLeft;
  Timer? timer;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    game = TugOfWarGame();
    q1 = Question.random(maxTable: widget.maxTable);
    q2 = Question.random(maxTable: widget.maxTable);
    timeLeft = widget.roundSeconds;
    _startTimer();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => timeLeft--);
      if (timeLeft <= 0) {
        t.cancel();
        _endGame(score1 == score2 ? 0 : (score1 > score2 ? 1 : 2));
      }
    });
  }

  void _updateRope() {
    final diff = (score1 - score2).toDouble();
    final pull = (diff / widget.winPulls).clamp(-1.0, 1.0);
    game.updatePull(pull);
  }

  void _submit(int team) {
    if (gameOver) return;
    final input = team == 1 ? input1 : input2;
    if (input.isEmpty) return;
    final question = team == 1 ? q1 : q2;
    final correct = int.tryParse(input) == question.answer;

    setState(() {
      if (correct) {
        if (team == 1) {
          score1++;
          q1 = Question.random(maxTable: widget.maxTable);
          input1 = '';
        } else {
          score2++;
          q2 = Question.random(maxTable: widget.maxTable);
          input2 = '';
        }
        _updateRope();
      } else {
        if (team == 1) {
          input1 = '';
        } else {
          input2 = '';
        }
      }
    });

    if (score1 - score2 >= widget.winPulls) _endGame(1);
    if (score2 - score1 >= widget.winPulls) _endGame(2);
  }

  void _endGame(int winner) {
    if (gameOver) return;
    gameOver = true;
    timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WinDialog(
        winner: winner,
        score1: score1,
        score2: score2,
        onBackToMenu: () => Navigator.of(context)
          ..pop()
          ..pop(),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget _scoreboardChip(String label, int score, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.body(size: 10, weight: FontWeight.w700, color: Colors.grey.shade600)),
        Text('$score', style: AppText.heading(size: 18, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final urgent = timeLeft <= 10;

    return Scaffold(
      body: FieldBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('🏆 TUG OF WAR: MATHEMATICS',
                    style: AppText.heading(size: 18, color: AppColors.team1Dark)),
              ),
              // Fixed-size centered game board — does NOT stretch to fill the screen.
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820, maxHeight: 420),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TeamPanel(
                                teamLabel: 'Team 1',
                                flagEmoji: '🔵',
                                color: AppColors.team1,
                                lightColor: AppColors.team1Light,
                                score: score1,
                                questionText: q1.text,
                                currentInput: input1,
                                onDigit: (d) =>
                                    setState(() => input1 = input1.length < 3 ? input1 + d : input1),
                                onClear: () => setState(() => input1 = ''),
                                onSubmit: () => _submit(1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 3)),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _scoreboardChip('TEAM 1', score1, AppColors.team1),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('⏱', style: TextStyle(fontSize: 12)),
                                            Text('$timeLeft',
                                                style: AppText.heading(size: 15, color: urgent ? AppColors.team2 : AppColors.ink)),
                                          ],
                                        ),
                                        _scoreboardChip('TEAM 2', score2, AppColors.team2),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 5)),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: GameWidget(game: game),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TeamPanel(
                                teamLabel: 'Team 2',
                                flagEmoji: '🔴',
                                color: AppColors.team2,
                                lightColor: AppColors.team2Light,
                                score: score2,
                                questionText: q2.text,
                                currentInput: input2,
                                onDigit: (d) =>
                                    setState(() => input2 = input2.length < 3 ? input2 + d : input2),
                                onClear: () => setState(() => input2 = ''),
                                onSubmit: () => _submit(2),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}