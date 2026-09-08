import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Draws the tug-of-war track, the two goal markers, and the moving
/// rope knot. [pull] ranges from -1.0 (fully Team 2's side) to
/// 1.0 (fully Team 1's side).
class RopeComponent extends PositionComponent {
  double pull = 0.0;

  final Paint _trackPaint = Paint()..color = const Color(0xFFE7CF98);
  final Paint _ropePaint = Paint()
    ..color = const Color(0xFFC69A5A)
    ..strokeWidth = 8;
  final Paint _knotPaint = Paint()..color = const Color(0xFF7A5B32);
  final Paint _knotCenterPaint = Paint()..color = Colors.white.withOpacity(0.9);
  final Paint _goalLeftPaint = Paint()..color = const Color(0xFF2461E8);
  final Paint _goalRightPaint = Paint()..color = const Color(0xFFE8432B);

  /// Call this whenever the score difference changes.
  void setPull(double value) {
    pull = value.clamp(-1.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Track background.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(14)),
      _trackPaint,
    );

    // Goal markers on each edge.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, 8, h - 8), const Radius.circular(4)),
      _goalLeftPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w - 12, 4, 8, h - 8), const Radius.circular(4)),
      _goalRightPaint,
    );

    // Rope line.
    final ropeY = h / 2;
    canvas.drawLine(Offset(14, ropeY), Offset(w - 14, ropeY), _ropePaint);

    // Knot position: pull = 1 -> near left goal, pull = -1 -> near right goal.
    final knotX = (w / 2) - (pull * (w / 2 - 26));
    canvas.drawCircle(Offset(knotX, ropeY), 14, _knotPaint);
    canvas.drawCircle(Offset(knotX, ropeY), 9, _knotCenterPaint);
  }
}
