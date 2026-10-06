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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Solid color header bar — gives strong contrast instead of flat pastel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: color,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(flagEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(teamLabel, style: AppText.heading(size: 15, color: Colors.white)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text('$score', style: AppText.number(size: 16, color: color)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: lightColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(questionText, style: AppText.heading(size: 22)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: color.withOpacity(0.4), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentInput.isEmpty ? '—' : currentInput,
                      style: AppText.number(
                        size: 20,
                        color: currentInput.isEmpty ? Colors.grey.shade400 : AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
  }
}