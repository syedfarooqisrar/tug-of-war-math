import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Full-screen dark layer shown while the round is paused.
class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
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
          width: 280,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏸', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 6),
              Text(
                AppStrings.paused,
                style: AppText.heading(size: 26, color: AppColors.team1Dark),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.goldDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onResume,
                  child: Text(
                    '▶  ${AppStrings.resume}',
                    style: AppText.heading(size: 18, color: AppColors.goldDark),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                  onPressed: onQuit,
                  child: Text(
                    AppStrings.quitGame,
                    style: AppText.body(size: 15, color: AppColors.ink),
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