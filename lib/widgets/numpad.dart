import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['clr', '0', 'go'],
    ];

    return Column(
      children: rows.map((row) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.5),
            child: Row(
              children: row.map((key) {
                Widget button;
                if (key == 'clr') {
                  button = _NumButton(label: '✕', color: Colors.grey.shade400, onTap: onClear);
                } else if (key == 'go') {
                  button = _NumButton(label: '✓', color: accentColor, onTap: onSubmit);
                } else {
                  button = _NumButton(
                    label: key,
                    color: Colors.white,
                    textColor: AppColors.ink,
                    onTap: () => onDigit(key),
                  );
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.5),
                    child: button,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NumButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _NumButton({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  State<_NumButton> createState() => _NumButtonState();
}

class _NumButtonState extends State<_NumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: AppText.number(size: 22, color: widget.textColor)),
        ),
      ),
    );
  }
}