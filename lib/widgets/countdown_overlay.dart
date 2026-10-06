import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Full-screen dark layer shown before a round starts.
/// [value] is 3, 2, 1, and then 0 which shows "GO!".
class CountdownOverlay extends StatelessWidget {
  final int value;

  const CountdownOverlay({super.key, required this.value});

  static const Color _goGreen = Color(0xFF3DDC84);

  @override
  Widget build(BuildContext context) {
    final isGo = value <= 0;
    final text = isGo ? AppStrings.go : '$value';

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A new key each second restarts the pop animation.
          TweenAnimationBuilder<double>(
            key: ValueKey(text),
            tween: Tween(begin: 0.4, end: 1.0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              final opacity = ((scale - 0.4) / 0.6).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Text(
              text,
              style: AppText.heading(
                size: isGo ? 96 : 120,
                color: isGo ? _goGreen : Colors.white,
              ).copyWith(
                shadows: [
                  Shadow(
                    color: (isGo ? _goGreen : Colors.white)
                        .withValues(alpha: 0.6),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
          if (!isGo) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.getReady,
              style: AppText.body(
                size: 16,
                weight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}