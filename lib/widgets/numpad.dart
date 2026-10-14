// 📁 FILE: lib/widgets/numpad.dart
// 📌 WHAT: Flat, minimalist numpad with icon keys, press tint and screen-reader labels
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

  static const String _clearKey = 'clr';
  static const String _submitKey = 'go';

  static const String _clearLabel = 'Clear';
  static const String _submitLabel = 'Submit answer';

  static const double _keyGap = 4;

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
        return _NumButton(
          semanticLabel: _clearLabel,
          background: AppColors.backgroundDeep,
          pressedBackground: AppColors.border,
          borderColor: Colors.transparent,
          onTap: onClear,
          child: const Icon(
            Icons.close_rounded,
            size: 24,
            color: AppColors.inkMuted,
          ),
        );
      case _submitKey:
        return _NumButton(
          semanticLabel: _submitLabel,
          background: accentColor,
          pressedBackground: Color.lerp(accentColor, Colors.black, 0.18)!,
          borderColor: Colors.transparent,
          onTap: onSubmit,
          child: const Icon(
            Icons.check_rounded,
            size: 28,
            color: Colors.white,
          ),
        );
      default:
        return _NumButton(
          semanticLabel: key,
          background: AppColors.surface,
          pressedBackground: Color.alphaBlend(
            accentColor.withValues(alpha: 0.14),
            AppColors.surface,
          ),
          borderColor: AppColors.border,
          onTap: () => onDigit(key),
          child: Text(key, style: AppText.number(size: AppText.sizeDisplay)),
        );
    }
  }
}

class _NumButton extends StatefulWidget {
  final String semanticLabel;
  final Color background;
  final Color pressedBackground;
  final Color borderColor;
  final VoidCallback onTap;
  final Widget child;

  const _NumButton({
    required this.semanticLabel,
    required this.background,
    required this.pressedBackground,
    required this.borderColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_NumButton> createState() => _NumButtonState();
}

class _NumButtonState extends State<_NumButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            decoration: BoxDecoration(
              color: _pressed ? widget.pressedBackground : widget.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: widget.borderColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: FittedBox(fit: BoxFit.scaleDown, child: widget.child),
          ),
        ),
      ),
    );
  }
}