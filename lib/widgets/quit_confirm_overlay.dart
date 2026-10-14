// 📁 FILE: lib/widgets/quit_confirm_overlay.dart
// 📌 WHAT: Clean "Quit this game?" card
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
          width: 290,
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
                Icons.exit_to_app_rounded,
                size: 44,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.quitTitle,
                textAlign: TextAlign.center,
                style: AppText.heading(size: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.quitMessage,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.onGold,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onStay,
                  child: Text(
                    AppStrings.keepPlaying,
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
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.danger, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: onQuit,
                  child: Text(
                    AppStrings.quit,
                    style: AppText.body(size: 15, color: AppColors.danger),
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