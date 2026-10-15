// 📁 FILE: lib/widgets/countdown_overlay.dart
// 📌 WHAT: Orientation-neutral countdown: three start lights, then green with a shockwave on GO
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Layer shown before a round starts. [value] is 3, 2, 1, and then 0
/// which means "GO!".
///
/// It uses three lights instead of big numbers, so two players sitting
/// opposite each other both read it the same way (nothing is upside down).
/// [showLabel] adds the words "Get ready!" and "GO!" under the lights; turn
/// it off when one of the players would see the words upside down.
class CountdownOverlay extends StatelessWidget {
  final int value;
  final bool showLabel;

  const CountdownOverlay({
    super.key,
    required this.value,
    this.showLabel = true,
  });

  static const int _lightCount = 3;
  static const double _lightSize = 52;
  static const double _lightGap = 14;

  static const Color _lightOff = Color(0x1FFFFFFF);
  static const Color _lightRed = Color(0xFFEF4444);
  static const Color _lightGreen = Color(0xFF22C55E);

  static const Duration _popDuration = Duration(milliseconds: 320);
  static const Duration _waveDuration = Duration(milliseconds: 700);

  bool get _isGo => value <= 0;

  /// How many lights are on: 3 -> 1, 2 -> 2, 1 -> 3, GO -> all 3.
  int get _litCount => _isGo ? _lightCount : (_lightCount + 1 - value).clamp(0, _lightCount);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      liveRegion: true,
      label: _isGo ? 'Go' : '$value',
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _lightsWithWave(reduceMotion),
            if (showLabel) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                _isGo ? AppStrings.go : AppStrings.getReady,
                style: AppText.heading(
                  size: _isGo ? AppText.sizeHero : AppText.sizeTitle,
                  color: _isGo ? _lightGreen : Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The pill with the lights. On GO a green ring grows out of it.
  Widget _lightsWithWave(bool reduceMotion) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_isGo && !reduceMotion) _shockwave(),
        // A new key every second restarts the small pop.
        TweenAnimationBuilder<double>(
          key: ValueKey(value),
          tween: Tween(begin: reduceMotion ? 1.0 : 0.88, end: 1.0),
          duration: _popDuration,
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: _pill(),
        ),
      ],
    );
  }

  Widget _pill() {
    final color = _isGo ? _lightGreen : _lightRed;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl - 2,
        vertical: AppSpacing.lg + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _lightCount; i++) ...[
            if (i > 0) const SizedBox(width: _lightGap),
            _light(on: i < _litCount, color: color),
          ],
        ],
      ),
    );
  }

  Widget _light({required bool on, required Color color}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: _lightSize,
      height: _lightSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? color : _lightOff,
        boxShadow: on
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 16,
                ),
              ]
            : const [],
      ),
    );
  }

  /// A green ring that grows and fades out, once, when the round starts.
  Widget _shockwave() {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: _waveDuration,
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.6 + t * 3.8,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _lightGreen, width: 3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}