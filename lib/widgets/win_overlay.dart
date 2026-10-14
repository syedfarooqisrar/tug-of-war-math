// 📁 FILE: lib/widgets/win_overlay.dart
// 📌 WHAT: Clean result card (flat trophy, flat score pills) with confetti for human wins
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'confetti_burst.dart';

/// Result screen shown on top of the game when the round ends.
/// [winner]: 0 = tie, 1 = team 1, 2 = team 2.
class WinOverlay extends StatelessWidget {
  final int winner;
  final int score1;
  final int score2;

  /// True on tall screens, where two players sit opposite each other.
  final bool faceToFace;

  /// True when Team 2 is the computer (single-player).
  final bool hasBot;
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
    this.hasBot = false,
  });

  // Single-player texts.
  static const String _botLabel = 'Bot';
  static const String _botWinsTitle = 'Bot Wins!';
  static const String _botWinsSubtitle = 'So close! Try again.';

  bool get _botWon => hasBot && winner == 2;

  /// Confetti is for a human win only: not for a tie, not when the bot wins.
  bool get _showConfetti => winner != 0 && !_botWon;

  @override
  Widget build(BuildContext context) {
    final winnerColor = winner == 1 ? AppColors.team1 : AppColors.team2;

    return Container(
      color: Colors.black.withValues(alpha: 0.50),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: faceToFace ? _faceToFaceLayout() : _card(withButtons: true),
            ),
          ),
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiBurst(
                colors: [
                  winnerColor,
                  winnerColor,
                  AppColors.gold,
                  AppColors.gold,
                  AppColors.success,
                  AppColors.fire,
                  const Color(0xFFEC407A),
                ],
              ),
            ),
        ],
      ),
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

  String _title(bool isTie) {
    if (isTie) return AppStrings.tieTitle;
    if (_botWon) return _botWinsTitle;
    return AppStrings.teamWins(winner);
  }

  String _subtitle(bool isTie) {
    if (isTie) return AppStrings.tieSubtitle;
    if (_botWon) return _botWinsSubtitle;
    return AppStrings.winSubtitle;
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _trophy(isTie),
            const SizedBox(height: AppSpacing.md),
            Text(
              _title(isTie),
              textAlign: TextAlign.center,
              style: AppText.heading(
                size: AppText.sizeDisplay,
                color: isTie ? AppColors.ink : winnerColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _subtitle(isTie),
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scorePill(AppStrings.team1, score1, AppColors.team1),
                const SizedBox(width: AppSpacing.md),
                _scorePill(
                  hasBot ? _botLabel : AppStrings.team2,
                  score2,
                  AppColors.team2,
                ),
              ],
            ),
            if (withButtons) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.onGold,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(
                    AppStrings.playAgain,
                    style: AppText.heading(
                      size: AppText.sizeTitle,
                      color: AppColors.onGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
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

  /// A flat icon on a soft round background: gold trophy, a handshake for
  /// a tie, a robot when the bot wins. It grows in once.
  Widget _trophy(bool isTie) {
    final Color baseColor;
    final IconData icon;
    if (isTie) {
      baseColor = AppColors.inkMuted;
      icon = Icons.handshake_rounded;
    } else if (_botWon) {
      baseColor = AppColors.team2;
      icon = Icons.smart_toy_rounded;
    } else {
      baseColor = AppColors.gold;
      icon = Icons.emoji_events_rounded;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: baseColor.withValues(alpha: 0.16),
        ),
        child: Icon(icon, size: 54, color: baseColor),
      ),
    );
  }

  Widget _scorePill(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$label: $score',
        style: AppText.body(
          size: AppText.sizeSmall,
          weight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}