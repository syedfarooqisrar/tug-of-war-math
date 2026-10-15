// 📁 FILE: lib/widgets/numpad.dart
// 📌 WHAT: Tactile numpad built from ChunkyButton: white digit keys, grey clear key, team-colored submit key
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';

class Numpad extends StatelessWidget {
  final Color accentColor;
  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const Numpad({
    super.key,
    required this.accentColor,
    required this.onDigit,
    required this.onClear,
    required this.onSubmit,
  });

  static const String _clearKey = 'clr';
  static const String _submitKey = 'go';

  static const String _clearLabel = 'Clear';
  static const String _submitLabel = 'Submit answer';

  static const double _keyGap = 3;

  // Key colors: white digits, a soft grey clear key, both with a blue-grey edge.
  static const Color _keyEdge = Color(0xFFB7C7E2);
  static const Color _clearFace = Color(0xFFE6EDF8);

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [_clearKey, '0', _submitKey],
    ];

    return Column(
      children: rows.map((row) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _keyGap),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _keyGap),
                    child: _buildKey(key),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    switch (key) {
      case _clearKey:
        return ChunkyButton(
          semanticLabel: _clearLabel,
          color: _clearFace,
          edgeColor: _keyEdge,
          onTap: onClear,
          child: const Icon(
            Icons.backspace_rounded,
            size: 24,
            color: AppColors.inkMuted,
          ),
        );
      case _submitKey:
        return ChunkyButton(
          semanticLabel: _submitLabel,
          color: accentColor,
          onTap: onSubmit,
          child: const Icon(
            Icons.check_rounded,
            size: 30,
            color: Colors.white,
          ),
        );
      default:
        return ChunkyButton(
          semanticLabel: key,
          color: AppColors.surface,
          edgeColor: _keyEdge,
          borderColor: AppColors.border,
          onTap: () => onDigit(key),
          child: Text(key, style: AppText.number(size: AppText.sizeDisplay)),
        );
    }
  }
}