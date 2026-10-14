// 📁 FILE: lib/widgets/question_banner.dart
// 📌 WHAT: Flat shared-question card for Speed Race (no gold glow)
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Card with the shared question (Speed Race mode). It fades and grows a
/// little each time the question changes.
class QuestionBanner extends StatelessWidget {
  final String text;
  final double fontSize;

  const QuestionBanner({super.key, required this.text, this.fontSize = 32});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Question: $text',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: AppShadows.card,
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: FittedBox(
            key: ValueKey(text),
            fit: BoxFit.scaleDown,
            child: Text(text, style: AppText.number(size: fontSize)),
          ),
        ),
      ),
    );
  }
}