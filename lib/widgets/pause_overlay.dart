// 📁 FILE: lib/widgets/pause_overlay.dart
// 📌 WHAT: Sticker pause card with Music and Sound switches and tactile buttons
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'audio_toggles.dart';
import 'chunky_button.dart';

/// Dark layer with a small sticker card shown while the round is paused.
class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  static const Color _buttonEdge = Color(0xFFB7C7E2);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduceMotion ? 1.0 : 0.9, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 280,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: [
              const BoxShadow(color: AppColors.border, offset: Offset(0, 5)),
              ...AppShadows.card,
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.team1Light,
                  border: Border.all(
                    color: AppColors.team1.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 40,
                  color: AppColors.team1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.paused,
                style: AppText.heading(size: AppText.sizeDisplay),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AudioToggles(labeled: true),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ChunkyButton(
                  semanticLabel: AppStrings.resume,
                  color: AppColors.gold,
                  edgeColor: AppColors.goldDark,
                  radius: AppRadius.md,
                  depth: 5,
                  onTap: onResume,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 28,
                        color: AppColors.onGold,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        AppStrings.resume,
                        style: AppText.heading(
                          size: AppText.sizeTitle,
                          color: AppColors.onGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ChunkyButton(
                  semanticLabel: AppStrings.quitGame,
                  color: AppColors.surface,
                  edgeColor: _buttonEdge,
                  borderColor: AppColors.border,
                  radius: AppRadius.md,
                  onTap: onQuit,
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