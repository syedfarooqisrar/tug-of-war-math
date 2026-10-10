import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Pulsing label shown on the arena when a team is one pull away from
/// winning.
class MatchPointBanner extends StatefulWidget {
  final int team;

  const MatchPointBanner({super.key, required this.team});

  @override
  State<MatchPointBanner> createState() => _MatchPointBannerState();
}

class _MatchPointBannerState extends State<MatchPointBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.team == 1 ? AppColors.team1 : AppColors.team2;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1.06).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              AppStrings.matchPoint(widget.team),
              style: AppText.heading(size: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}