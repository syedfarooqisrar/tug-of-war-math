// 📁 FILE: lib/widgets/match_point_banner.dart
// 📌 WHAT: Flat, calm match-point pill with an optional custom label
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Gently pulsing label shown on the arena when a team is one pull away
/// from winning.
class MatchPointBanner extends StatefulWidget {
  final int team;

  /// Text to show. If null, "TEAM n · MATCH POINT" is used.
  final String? label;

  const MatchPointBanner({super.key, required this.team, this.label});

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
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect "remove animations" in the phone's accessibility settings.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.team == 1 ? AppColors.team1 : AppColors.team2;
    final text = widget.label ?? AppStrings.matchPoint(widget.team);

    return ScaleTransition(
      scale: Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              text,
              style: AppText.heading(size: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}