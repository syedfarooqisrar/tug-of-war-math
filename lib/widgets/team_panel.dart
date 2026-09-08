import 'package:flutter/material.dart';
import 'numpad.dart';

class TeamPanel extends StatelessWidget {
  final String teamLabel;
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
        color: lightColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 3),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(teamLabel,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                child: Text('$score',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(questionText,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(currentInput, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
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
    );
  }
}
