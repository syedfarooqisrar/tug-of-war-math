import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// "Quit this game?" card shown on top of the (paused) round.
class QuitConfirmOverlay extends StatelessWidget {
  final VoidCallback onStay;
  final VoidCallback onQuit;

  const QuitConfirmOverlay({
    super.key,
    required this.onStay,
    required this.onQuit,
  });

  /// Dark brown text on the gold button (easy to read).
  static const Color _onGold = Color(0xFF4A3200);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.60),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          final opacity = ((scale - 0.85) / 0.15).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Container(
          width: 290,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
              const Icon(
                Icons.exit_to_app_rounded,
                size: 44,
                color: AppColors.team2,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.quitTitle,
                textAlign: TextAlign.center,
                style: AppText.heading(size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.quitMessage,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: _onGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onStay,
                  child: Text(
                    AppStrings.keepPlaying,
                    style: AppText.heading(size: 18, color: _onGold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.team2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.red.shade200, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onQuit,
                  child: Text(
                    AppStrings.quit,
                    style: AppText.body(size: 15, color: AppColors.team2),
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