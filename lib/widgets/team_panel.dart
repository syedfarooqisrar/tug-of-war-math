import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'numpad.dart';

class TeamPanel extends StatelessWidget {
  final String teamLabel;
  final String flagEmoji;
  final Color color;
  final Color lightColor;
  final int score;
  final String questionText;
  final String currentInput;
  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const TeamPanel({
    super.key,
    required this.teamLabel,
    required this.flagEmoji,
    required this.color,
    required this.lightColor,
    required this.score,
    required this.questionText,
    required this.currentInput,
    required this.onDigit,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final darkColor = Color.lerp(color, Colors.black, 0.22)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On a short panel (phone on its side) shrink the top parts so
        // the whole numpad stays visible.
        final tight = constraints.maxHeight < 380;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(darkColor, tight),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(tight ? 8 : 10),
                  child: Column(
                    children: [
                      _questionCard(tight),
                      SizedBox(height: tight ? 6 : 8),
                      _answerBox(tight),
                      SizedBox(height: tight ? 6 : 10),
                      Expanded(
                        child: Numpad(
                          accentColor: color,
                          onDigit: onDigit,
                          onClear: onClear,
                          onSubmit: onSubmit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(Color darkColor, bool tight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: tight ? 6 : 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, darkColor],
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(teamLabel, style: AppText.heading(size: 16, color: Colors.white)),
            const SizedBox(width: 10),
            _scoreBadge(),
          ],
        ),
      ),
    );
  }

  /// White badge. The number pops in whenever the score changes.
  Widget _scoreBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        ),
        child: Text(
          '$score',
          key: ValueKey(score),
          textAlign: TextAlign.center,
          style: AppText.number(size: 17, color: color),
        ),
      ),
    );
  }

  Widget _questionCard(bool tight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: tight ? 6 : 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lightColor, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          questionText,
          style: AppText.number(size: tight ? 22 : 28),
        ),
      ),
    );
  }

  /// Shows what the team has typed. It lights up in the team color
  /// as soon as there is at least one digit.
  Widget _answerBox(bool tight) {
    final hasInput = currentInput.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: tight ? 36 : 46,
      decoration: BoxDecoration(
        color: hasInput ? lightColor : Colors.white,
        border: Border.all(
          color: hasInput ? color : color.withValues(alpha: 0.35),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        hasInput ? currentInput : '—',
        style: AppText.number(
          size: tight ? 20 : 24,
          color: hasInput ? AppColors.ink : Colors.grey.shade400,
        ).copyWith(letterSpacing: hasInput ? 3 : 0),
      ),
    );
  }
}