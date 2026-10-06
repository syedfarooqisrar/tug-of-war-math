import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Draws just the field content (dashed guide, rope, knot, pulling figures)
/// on a transparent background — the white card + shadow comes from the
/// Flutter Container wrapping the GameWidget in game_screen.dart.
class RopeComponent extends PositionComponent {
  double pull = 0.0;
  double _time = 0.0;

  final Paint _dashPaint = Paint()
    ..color = const Color(0xFFCBD5E1)
    ..strokeWidth = 2;
  final Paint _ropePaint = Paint()
    ..color = const Color(0xFFC69A5A)
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  final Paint _knotPaint = Paint()..color = const Color(0xFF7A5B32);

  static const _team1Body = Color(0xFF2461E8);
  static const _team1Band = Color(0xFF173E9C);
  static const _team2Body = Color(0xFFE8432B);
  static const _team2Band = Color(0xFFA72C19);
  static const _skin = Color(0xFFF2C29A);

  void setPull(double value) => pull = value.clamp(-1.0, 1.0);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final centerY = h * 0.52;
    final groundY = centerY + 34;

    // Dashed center guide line
    double y = 8;
    while (y < h - 8) {
      canvas.drawLine(Offset(w / 2, y), Offset(w / 2, y + 6), _dashPaint);
      y += 13;
    }

    final knotX = (w / 2) - (pull * (w / 2 - 46));
    final bob = math.sin(_time * 6) * 2.4;

    canvas.drawLine(Offset(16, centerY), Offset(w - 16, centerY), _ropePaint);

    _drawPerson(canvas, Offset(knotX - 36, groundY + bob),
        leanDeg: -18, bodyColor: _team1Body, bandColor: _team1Band, dir: -1);
    _drawPerson(canvas, Offset(knotX - 58, groundY - bob),
        leanDeg: -14, bodyColor: _team1Body, bandColor: _team1Band, dir: -1, scale: 0.88);

    _drawPerson(canvas, Offset(knotX + 36, groundY - bob),
        leanDeg: 18, bodyColor: _team2Body, bandColor: _team2Band, dir: 1);
    _drawPerson(canvas, Offset(knotX + 58, groundY + bob),
        leanDeg: 14, bodyColor: _team2Body, bandColor: _team2Band, dir: 1, scale: 0.88);

    canvas.drawCircle(Offset(knotX, centerY), 6.5, _knotPaint);
  }

  void _drawPerson(
    Canvas canvas,
    Offset feet, {
    required double leanDeg,
    required Color bodyColor,
    required Color bandColor,
    required int dir,
    double scale = 1.0,
  }) {
    canvas.save();
    canvas.translate(feet.dx, feet.dy);
    canvas.scale(scale);
    canvas.rotate(leanDeg * math.pi / 180);

    final limbPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final shoePaint = Paint()..color = Colors.white;

    canvas.drawLine(Offset.zero, Offset(-dir * 11, -24), limbPaint);
    canvas.drawCircle(Offset(-dir * 11, -24), 3, shoePaint);
    canvas.drawLine(Offset(dir * 4, 0), Offset(dir * 2, -22), limbPaint);

    final torsoRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-7, -50, 14, 28),
      const Radius.circular(6),
    );
    canvas.drawRRect(torsoRect, Paint()..color = bodyColor);

    canvas.drawLine(const Offset(0, -44), Offset(dir * 22, -37), limbPaint);

    canvas.drawCircle(const Offset(0, -57), 8, Paint()..color = _skin);
    canvas.drawRect(const Rect.fromLTWH(-8, -61, 16, 4.5), Paint()..color = bandColor);

    canvas.restore();
  }
}