import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Result screen shown on top of the game when the round ends.
/// [winner]: 0 = tie, 1 = team 1, 2 = team 2.
class WinOverlay extends StatelessWidget {
  final int winner;
  final int score1;
  final int score2;

  /// True on tall screens, where two players sit opposite each other.
  final bool faceToFace;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  const WinOverlay({
    super.key,
    required this.winner,
    required this.score1,
    required this.score2,
    required this.faceToFace,
    required this.onPlayAgain,
    required this.onMenu,
  });

  /// Dark brown text on the gold button (much easier to read than gold on gold).
  static const Color _onGold = Color(0xFF4A3200);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.60),
      alignment: Alignment.center,
      child: faceToFace ? _faceToFaceLayout() : _card(withButtons: true),
    );
  }

  /// The top player gets an upside-down copy of the result (no buttons),
  /// the bottom player gets the card with the buttons.
  Widget _faceToFaceLayout() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RotatedBox(
                quarterTurns: 2,
                child: _card(withButtons: false),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _card(withButtons: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({required bool withButtons}) {
    final isTie = winner == 0;
    final winnerColor = winner == 1 ? AppColors.team1 : AppColors.team2;

    return SizedBox(
      width: 300,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _trophy(isTie),
            const SizedBox(height: 6),
            Text(
              isTie ? AppStrings.tieTitle : AppStrings.teamWins(winner),
              textAlign: TextAlign.center,
              style: AppText.heading(
                size: 28,
                color: isTie ? AppColors.ink : winnerColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isTie ? AppStrings.tieSubtitle : AppStrings.winSubtitle,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scorePill(AppStrings.team1, score1, AppColors.team1),
                const SizedBox(width: 12),
                _scorePill(AppStrings.team2, score2, AppColors.team2),
              ],
            ),
            if (withButtons) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: _onGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(
                    AppStrings.playAgain,
                    style: AppText.heading(size: 18, color: _onGold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade400, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onMenu,
                  child: Text(
                    AppStrings.backToMenu,
                    style: AppText.body(size: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A gold trophy icon with a soft glow that pops in. A handshake for a tie.
  Widget _trophy(bool isTie) {
    final baseColor = isTie ? Colors.blueGrey.shade600 : AppColors.gold;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [baseColor.withValues(alpha: 0.35), Colors.transparent],
          ),
        ),
        child: Icon(
          isTie ? Icons.handshake_rounded : Icons.emoji_events_rounded,
          size: 62,
          color: baseColor,
        ),
      ),
    );
  }

  Widget _scorePill(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $score',
        style: AppText.body(
          size: 14,
          weight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}