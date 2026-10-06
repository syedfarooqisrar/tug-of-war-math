import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WinDialog extends StatefulWidget {
  final int winner; // 0 = tie, 1 = team 1, 2 = team 2
  final int score1;
  final int score2;
  final VoidCallback onBackToMenu;

  const WinDialog({
    super.key,
    required this.winner,
    required this.score1,
    required this.score2,
    required this.onBackToMenu,
  });

  @override
  State<WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<WinDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.15), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTie = widget.winner == 0;
    final winnerColor = widget.winner == 1 ? AppColors.team1 : AppColors.team2;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: const Text('🏆', style: TextStyle(fontSize: 60)),
            ),
            const SizedBox(height: 6),
            Text(
              isTie ? "It's a Tie!" : 'Team ${widget.winner} Wins!',
              style: AppText.heading(size: 24, color: isTie ? AppColors.ink : winnerColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              isTie ? 'Evenly matched — run it back!' : 'Great tug-of-war battle!',
              style: AppText.body(size: 13, weight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scorePill('Team 1', widget.score1, AppColors.team1),
                const SizedBox(width: 14),
                _scorePill('Team 2', widget.score2, AppColors.team2),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.goldDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: widget.onBackToMenu,
                child: Text('Play Again', style: AppText.heading(size: 17, color: AppColors.goldDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scorePill(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Text('$label: $score', style: AppText.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
    );
  }
}