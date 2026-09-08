import 'package:flutter/material.dart';

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
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'clr', '0', 'go'];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      children: keys.map((key) {
        if (key == 'clr') {
          return _NumButton(label: '✕', color: Colors.grey.shade400, onTap: onClear);
        }
        if (key == 'go') {
          return _NumButton(label: '✓', color: accentColor, onTap: onSubmit);
        }
        return _NumButton(
          label: key,
          color: Colors.white,
          textColor: Colors.black87,
          onTap: () => onDigit(key),
        );
      }).toList(),
    );
  }
}

class _NumButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ),
    );
  }
}
