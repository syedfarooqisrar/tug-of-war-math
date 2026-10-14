// 📁 FILE: lib/widgets/pause_overlay.dart
// 📌 WHAT: Clean pause card (icon instead of emoji, flat buttons)
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Dark layer with a small card shown while the round is paused.
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduceMotion ? 1.0 : 0.92, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 280,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_rounded,
                size: 48,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.paused,
                style: AppText.heading(size: AppText.sizeDisplay),
              ),
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
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: Text(
                    AppStrings.resume,
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
                  onPressed: onQuit,
                  child: Text(
                    AppStrings.quitGame,
                    style: AppText.body(size: 15),
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