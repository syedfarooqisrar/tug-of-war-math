import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/tug_of_war_game.dart';
import '../models/question.dart';
import '../widgets/team_panel.dart';

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
      builder: (_) => AlertDialog(
        title: Text(winner == 0 ? "It's a tie!" : 'Team $winner wins! 🏆'),
        content: Text('Team 1: $score1    Team 2: $score2'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(),
            child: const Text('Back to menu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF1FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('⏱ $timeLeft',
            style: const TextStyle(color: Color(0xFF0B3D91), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: TeamPanel(
                teamLabel: 'Team 1',
                color: const Color(0xFF2461E8),
                lightColor: const Color(0xFFE3ECFF),
                score: score1,
                questionText: q1.text,
                currentInput: input1,
                onDigit: (d) => setState(() => input1 = input1.length < 3 ? input1 + d : input1),
                onClear: () => setState(() => input1 = ''),
                onSubmit: () => _submit(1),
              ),
            ),
            SizedBox(
              width: 140,
              child: GameWidget(game: game),
            ),
            Expanded(
              flex: 4,
              child: TeamPanel(
                teamLabel: 'Team 2',
                color: const Color(0xFFE8432B),
                lightColor: const Color(0xFFFFE6E0),
                score: score2,
                questionText: q2.text,
                currentInput: input2,
                onDigit: (d) => setState(() => input2 = input2.length < 3 ? input2 + d : input2),
                onClear: () => setState(() => input2 = ''),
                onSubmit: () => _submit(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
