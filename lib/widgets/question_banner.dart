import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Big card with the shared question (Speed Race mode). It pops in each
/// time the question changes.
class QuestionBanner extends StatelessWidget {
  final String text;
  final double fontSize;

  const QuestionBanner({super.key, required this.text, this.fontSize = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: FittedBox(
          key: ValueKey(text),
          fit: BoxFit.scaleDown,
          child: Text(text, style: AppText.number(size: fontSize)),
        ),
      ),
    );
  }
}