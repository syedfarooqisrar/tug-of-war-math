// 📁 FILE: lib/widgets/quit_confirm_overlay.dart
// 📌 WHAT: Sticker "Quit this game?" card with tactile buttons
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';

/// "Quit this game?" card shown on top of the (paused) round.
class QuitConfirmOverlay extends StatelessWidget {
  final VoidCallback onStay;
  final VoidCallback onQuit;

  const QuitConfirmOverlay({
    super.key,
    required this.onStay,
    required this.onQuit,
  });

  static const Color _quitFace = Color(0xFFFDECEC);
  static const Color _quitEdge = Color(0xFFE5A5A0);

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
          width: 290,
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
                  color: AppColors.team2Light,
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  size: 38,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
                height: 60,
                child: ChunkyButton(
                  semanticLabel: AppStrings.keepPlaying,
                  color: AppColors.gold,
                  edgeColor: AppColors.goldDark,
                  radius: AppRadius.md,
                  depth: 5,
                  onTap: onStay,
                  child: Text(
                    AppStrings.keepPlaying,
                    style: AppText.heading(
                      size: AppText.sizeTitle,
                      color: AppColors.onGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ChunkyButton(
                  semanticLabel: AppStrings.quit,
                  color: _quitFace,
                  edgeColor: _quitEdge,
                  borderColor: AppColors.danger.withValues(alpha: 0.4),
                  radius: AppRadius.md,
                  onTap: onQuit,
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