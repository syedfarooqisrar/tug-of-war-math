// 📁 FILE: lib/widgets/chunky_button.dart   (NEW FILE)
// 📌 WHAT: Reusable tactile button: raised face with a darker bottom edge that presses down when tapped
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A raised, tactile button. The face sits above a darker "edge"; when the
/// button is pressed the face moves down into the edge.
///
/// It fills the space its parent gives it (put it in a [SizedBox] or an
/// [Expanded]). Set [onTap] to null to disable it.
class ChunkyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Color of the face.
  final Color color;

  /// Color of the bottom edge. Defaults to a darker shade of [color].
  final Color? edgeColor;

  /// Optional outline around the face (useful for white buttons).
  final Color? borderColor;

  /// Text read by screen readers.
  final String? semanticLabel;

  /// True when this button is the chosen option of a group.
  final bool selected;

  final double radius;

  /// Height of the visible edge, in logical pixels.
  final double depth;

  const ChunkyButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    this.edgeColor,
    this.borderColor,
    this.semanticLabel,
    this.selected = false,
    this.radius = AppRadius.sm,
    this.depth = 4,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const Duration _pressDuration = Duration(milliseconds: 70);

  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final pressed = _pressed && _enabled;
    final edge = widget.edgeColor ?? AppColors.edge(widget.color);
    final radius = BorderRadius.circular(widget.radius);
    final top = Color.lerp(widget.color, Colors.white, 0.14)!;

    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onTap,
      child: Opacity(
        opacity: _enabled ? 1.0 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The edge: always fills the whole button.
              DecoratedBox(
                decoration: BoxDecoration(color: edge, borderRadius: radius),
              ),
              // The face: sits on top, and drops into the edge when pressed.
              AnimatedPositioned(
                duration: reduceMotion ? Duration.zero : _pressDuration,
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: pressed ? widget.depth : 0,
                bottom: pressed ? 0 : widget.depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [top, widget.color],
                    ),
                    borderRadius: radius,
                    border: widget.borderColor == null
                        ? null
                        : Border.all(color: widget.borderColor!, width: 1.5),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}