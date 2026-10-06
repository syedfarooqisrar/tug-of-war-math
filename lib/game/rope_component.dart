import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

Paint _fill(Color color) => Paint()..color = color;

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

class _Palette {
  static const team1 = Color(0xFF2461E8);
  static const team1Dark = Color(0xFF173E9C);
  static const team2 = Color(0xFFE8432B);
  static const team2Dark = Color(0xFFA72C19);
  static const skins = [Color(0xFFF2C29A), Color(0xFFD9A074), Color(0xFFB87A52)];
  static const hairs = [Color(0xFF2B1B12), Color(0xFF5A3A22), Color(0xFF151515)];
  static const rope = Color(0xFFC69A5A);
  static const ropeDark = Color(0xFF7A5B32);
  static const ropeLight = Color(0xFFE8CF9D);
  static const ink = Color(0xFF1E293B);
}

/// Where everything sits for the current card size and rope position.
class _Layout {
  _Layout(Vector2 size, double pull) {
    w = size.x;
    h = size.y;
    horizon = h * 0.38;
    groundY = h * 0.76;
    height = math.min(h * 0.40, w * 0.27).clamp(36.0, 170.0).toDouble();
    k = height / 110;
    margin = w * 0.13;
    knotX = w / 2 - pull * (w / 2 - margin);
    ropeY = groundY - 58 * k;
  }

  late final double w, h, horizon, groundY, height, k, margin, knotX, ropeY;
}

class _Puller {
  _Puller({
    required this.x,
    required this.facing,
    required this.team,
    required this.index,
  });

  final double x;
  final int facing; // +1 faces right (team 1), -1 faces left (team 2)
  final int team;
  final int index;
}

class _Dust {
  _Dust({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.maxLife,
  }) : life = maxLife;

  double x;
  double y;
  final double vx;
  final double vy;
  double radius;
  final double maxLife;
  double life;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    radius += dt * 9;
    life -= dt;
  }
}

// ---------------------------------------------------------------------------
// The arena
// ---------------------------------------------------------------------------

/// Draws the whole tug-of-war arena. [setPull] ranges from -1.0 (Team 2
/// winning) to 1.0 (Team 1 winning).
class RopeComponent extends PositionComponent {
  double _targetPull = 0;
  double _shownPull = 0;
  double _time = 0;
  final math.Random _rng = math.Random(11);
  final List<_Dust> _dust = [];

  void setPull(double value) => _targetPull = value.clamp(-1.0, 1.0).toDouble();

  @override
  void update(double dt) {
    super.update(dt);
    if (size.x <= 0 || size.y <= 0) return;
    _time += dt;

    final before = _shownPull;
    _shownPull += (_targetPull - _shownPull) * math.min(1.0, dt * 5);
    final speed = dt > 0 ? (_shownPull - before) / dt : 0.0;

    final lay = _Layout(size, _shownPull);
    if (speed.abs() > 0.08) _spawnDust(lay, speed);
    for (final d in _dust) {
      d.update(dt);
    }
    _dust.removeWhere((d) => d.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final lay = _Layout(size, _shownPull);

    _paintSky(canvas, lay);
    _paintHills(canvas, lay);
    _paintGround(canvas, lay);
    _paintCrowd(canvas, lay);
    _paintFieldLines(canvas, lay);

    final pullers = [..._pullersFor(1, lay), ..._pullersFor(2, lay)];
    for (final p in pullers) {
      _paintBody(canvas, p, lay);
    }
    _paintDust(canvas);
    _paintRope(canvas, lay);
    _paintKnot(canvas, lay);
    for (final p in pullers) {
      _paintArms(canvas, p, lay);
    }
    _paintVignette(canvas, lay);
  }

  // ---------- Puller data ----------

  List<_Puller> _pullersFor(int team, _Layout lay) {
    final count = lay.w >= 360 ? 3 : 2;
    final facing = team == 1 ? 1 : -1;
    return List.generate(count, (i) {
      final offset = (34 + 44 * i) * lay.k;
      final x = team == 1 ? lay.knotX - offset : lay.knotX + offset;
      return _Puller(x: x, facing: facing, team: team, index: i);
    });
  }

  Color _jersey(_Puller p) => p.team == 1 ? _Palette.team1 : _Palette.team2;
  Color _pants(_Puller p) => p.team == 1 ? _Palette.team1Dark : _Palette.team2Dark;
  Color _skin(_Puller p) => _Palette.skins[(p.index + p.team) % _Palette.skins.length];
  Color _hair(_Puller p) => _Palette.hairs[(p.index * 2 + p.team) % _Palette.hairs.length];
  double _phase(_Puller p) => p.index * 1.3 + p.team * 0.7;
  double _sway(_Puller p) => math.sin(_time * 5 + _phase(p));
  double _bob(_Puller p) => math.sin(_time * 10 + _phase(p)) * 0.8;

  /// How far the body leans back. The leading team leans back harder.
  double _lean(_Puller p) {
    final advantage = p.team == 1 ? _shownPull : -_shownPull;
    return 0.30 + 0.10 * advantage + _sway(p) * 0.025;
  }

  double _ropeY(double x, _Layout lay) {
    final t = (x / lay.w).clamp(0.0, 1.0);
    final sag = lay.height * 0.05 * math.sin(math.pi * t);
    final vibration = math.sin(x * 0.06 / lay.k + _time * 9) * 0.5 * lay.k;
    return lay.ropeY + sag + vibration;
  }

  // ---------- Dust ----------

  void _spawnDust(_Layout lay, double speed) {
    // Team 2 is dragged when the rope moves left (speed > 0), team 1 otherwise.
    final dragged = speed > 0 ? 2 : 1;
    final pullers = _pullersFor(dragged, lay);
    final p = pullers[_rng.nextInt(pullers.length)];
    final direction = speed > 0 ? 1.0 : -1.0;
    for (var i = 0; i < 2; i++) {
      _dust.add(_Dust(
        x: p.x + (_rng.nextDouble() - 0.5) * 20 * lay.k,
        y: lay.groundY + _rng.nextDouble() * 3 * lay.k,
        vx: direction * (10 + _rng.nextDouble() * 18) * lay.k,
        vy: -(6 + _rng.nextDouble() * 10) * lay.k,
        radius: 2.5 * lay.k,
        maxLife: 0.5 + _rng.nextDouble() * 0.4,
      ));
    }
  }

  void _paintDust(Canvas c) {
    for (final d in _dust) {
      final a = (d.life / d.maxLife).clamp(0.0, 1.0).toDouble();
      c.drawCircle(
        Offset(d.x, d.y),
        d.radius,
        _fill(const Color(0xFFE2D3AE).withValues(alpha: 0.55 * a)),
      );
    }
  }

  // ---------- Scenery ----------

  void _paintSky(Canvas c, _Layout lay) {
    c.drawRect(
      Rect.fromLTWH(0, 0, lay.w, lay.horizon + 2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, lay.horizon),
          const [Color(0xFF4AA8F0), Color(0xFFA5DCFF), Color(0xFFE6F6FF)],
          const [0.0, 0.65, 1.0],
        ),
    );

    // Sun with a soft glow
    final sunC = Offset(lay.w * 0.80, lay.horizon * 0.42);
    final sunR = math.min(lay.w, lay.h) * 0.055;
    c.drawCircle(
      sunC,
      sunR * 3.4,
      Paint()
        ..shader = ui.Gradient.radial(
          sunC,
          sunR * 3.4,
          const [Color(0xCCFFF3B0), Color(0x33FFE680), Color(0x00FFE680)],
          const [0.0, 0.4, 1.0],
        ),
    );
    c.drawCircle(sunC, sunR, _fill(const Color(0xFFFFF6C8)));

    // Slow drifting clouds: x fraction, y fraction, size, speed
    const clouds = [
      [0.10, 0.10, 1.0, 5.0],
      [0.52, 0.22, 0.75, 3.5],
      [0.88, 0.07, 1.2, 4.2],
    ];
    final paint = _fill(const Color(0xE6FFFFFF));
    for (final cl in clouds) {
      final s = lay.h * 0.055 * cl[2];
      final span = lay.w + s * 8;
      final x = ((cl[0] * lay.w + _time * cl[3] * lay.k * 3) % span) - s * 4;
      final y = lay.horizon * cl[1] * 2.0;
      c.drawCircle(Offset(x, y), s, paint);
      c.drawCircle(Offset(x - s * 0.95, y + s * 0.28), s * 0.7, paint);
      c.drawCircle(Offset(x + s * 1.0, y + s * 0.25), s * 0.78, paint);
      c.drawCircle(Offset(x + s * 0.2, y - s * 0.35), s * 0.72, paint);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - s * 1.5, y + s * 0.2, x + s * 1.65, y + s * 0.95),
          Radius.circular(s * 0.4),
        ),
        paint,
      );
    }
  }

  double _hillY(
    double x,
    _Layout lay, {
    required double amp,
    required double freq,
    required double phase,
    required double base,
  }) {
    return base - amp * (math.sin(x / lay.w * math.pi * 2 * freq + phase) * 0.5 + 0.5);
  }

  void _paintHills(Canvas c, _Layout lay) {
    void hill(Color color, double amp, double freq, double phase, double base) {
      final path = Path()..moveTo(0, lay.horizon + 2);
      for (double x = 0; x <= lay.w + 6; x += 6) {
        path.lineTo(
          x,
          _hillY(x, lay, amp: amp, freq: freq, phase: phase, base: base),
        );
      }
      path.lineTo(lay.w, lay.horizon + 2);
      path.close();
      c.drawPath(path, _fill(color));
    }

    // Far hills with small trees
    final farAmp = lay.h * 0.075;
    final farBase = lay.horizon - lay.h * 0.012;
    hill(const Color(0xFF9AD6A8), farAmp, 1.2, 0.6, farBase);

    final ts = lay.h * 0.035;
    for (final fraction in const [0.08, 0.27, 0.52, 0.74, 0.93]) {
      final x = lay.w * fraction;
      final y = _hillY(x, lay, amp: farAmp, freq: 1.2, phase: 0.6, base: farBase);
      c.drawRect(
        Rect.fromLTRB(x - ts * 0.12, y - ts * 0.6, x + ts * 0.12, y + ts * 0.1),
        _fill(const Color(0xFF7A5B32)),
      );
      c.drawCircle(Offset(x, y - ts * 1.0), ts * 0.7, _fill(const Color(0xFF3F9A55)));
      c.drawCircle(
        Offset(x - ts * 0.2, y - ts * 1.15),
        ts * 0.4,
        _fill(const Color(0xFF58B36C)),
      );
    }

    // Near hills
    hill(
      const Color(0xFF6DBE6B),
      lay.h * 0.05,
      1.7,
      2.0,
      lay.horizon + lay.h * 0.004,
    );
  }

  void _paintGround(Canvas c, _Layout lay) {
    c.drawRect(
      Rect.fromLTRB(0, lay.horizon, lay.w, lay.h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, lay.horizon),
          Offset(0, lay.h),
          const [Color(0xFF8CD65C), Color(0xFF63B03B), Color(0xFF3F8A2A)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // Mowing stripes that get thicker toward the viewer (perspective)
    const bands = 8;
    for (var i = 0; i < bands; i += 2) {
      final y0 = lay.horizon +
          (lay.h - lay.horizon) * math.pow(i / bands, 1.5).toDouble();
      final y1 = lay.horizon +
          (lay.h - lay.horizon) * math.pow((i + 1) / bands, 1.5).toDouble();
      c.drawRect(Rect.fromLTRB(0, y0, lay.w, y1), _fill(const Color(0x14000000)));
    }
  }

  void _paintCrowd(Canvas c, _Layout lay) {
    final s = (lay.h * 0.034).clamp(3.5, 9.0).toDouble();
    final baseY = lay.horizon + lay.h * 0.05;
    final spacing = s * 2.0;
    final count = (lay.w / spacing).ceil() + 1;
    final excite = 0.35 + 0.65 * _shownPull.abs();
    const shirts = [
      Color(0xFF2461E8),
      Color(0xFFE8432B),
      Color(0xFFF4B400),
      Color(0xFFFFFFFF),
      Color(0xFF3DDC84),
    ];

    for (var i = 0; i < count; i++) {
      final x = i * spacing + s;
      final jump = math.max(0.0, math.sin(_time * 7 + i * 1.7)) * s * 0.55 * excite;
      final skin = _Palette.skins[(i * 7 + i ~/ 2) % _Palette.skins.length];
      final shirt = shirts[(i * 7) % shirts.length];
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, baseY - s * 0.9 - jump),
            width: s * 1.5,
            height: s * 1.9,
          ),
          Radius.circular(s * 0.5),
        ),
        _fill(shirt),
      );
      c.drawCircle(Offset(x, baseY - s * 2.15 - jump), s * 0.62, _fill(skin));
    }

    // Fence in front of the crowd
    c.drawRect(
      Rect.fromLTRB(0, baseY - s * 0.55, lay.w, baseY - s * 0.2),
      _fill(const Color(0xFFF1F5F9)),
    );
    c.drawRect(
      Rect.fromLTRB(0, baseY - s * 0.2, lay.w, baseY + s * 0.7),
      _fill(const Color(0x26FFFFFF)),
    );
    for (double x = 0; x < lay.w; x += s * 6) {
      c.drawRect(
        Rect.fromLTRB(x, baseY - s * 0.55, x + s * 0.3, baseY + s * 0.9),
        _fill(const Color(0xFFCBD5E1)),
      );
    }
  }

  void _paintFieldLines(Canvas c, _Layout lay) {
    final top = lay.horizon + lay.h * 0.07;
    final k = lay.k;
    c.drawRect(
      Rect.fromLTRB(lay.w / 2 - 1.2 * k, top, lay.w / 2 + 1.2 * k, lay.h),
      _fill(const Color(0xAAFFFFFF)),
    );
    c.drawRect(
      Rect.fromLTRB(lay.margin - 1.6 * k, top, lay.margin + 1.6 * k, lay.h),
      _fill(_Palette.team1.withValues(alpha: 0.85)),
    );
    c.drawRect(
      Rect.fromLTRB(lay.w - lay.margin - 1.6 * k, top, lay.w - lay.margin + 1.6 * k, lay.h),
      _fill(_Palette.team2.withValues(alpha: 0.85)),
    );
  }

  void _paintVignette(Canvas c, _Layout lay) {
    c.drawRect(
      Rect.fromLTWH(0, 0, lay.w, lay.h),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(lay.w / 2, lay.h / 2),
          math.max(lay.w, lay.h) * 0.75,
          const [Color(0x00000000), Color(0x22000000)],
          const [0.6, 1.0],
        ),
    );
  }

  // ---------- Rope ----------

  void _paintRope(Canvas c, _Layout lay) {
    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final x = lay.w * i / steps;
      final y = _ropeY(x, lay);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final k = lay.k;
    c.drawPath(path.shift(Offset(0, 2.2 * k)), _stroke(const Color(0x40000000), 8.5 * k));
    c.drawPath(path, _stroke(_Palette.ropeDark, 7.4 * k));
    c.drawPath(path, _stroke(_Palette.rope, 5.6 * k));
    c.drawPath(path.shift(Offset(0, -1.4 * k)), _stroke(_Palette.ropeLight, 1.6 * k));

    // Twisted-strand marks
    final twist = _stroke(_Palette.ropeDark, 1.2 * k);
    for (double x = 0; x < lay.w; x += 6.5 * k) {
      c.drawLine(
        Offset(x, _ropeY(x, lay) - 2.4 * k),
        Offset(x + 3.2 * k, _ropeY(x + 3.2 * k, lay) + 2.4 * k),
        twist,
      );
    }
  }

  void _paintKnot(Canvas c, _Layout lay) {
    final k = lay.k;
    final x = lay.knotX;
    final y = _ropeY(x, lay);
    final wave = math.sin(_time * 7) * 2.0 * k;

    final ribbon = Path()
      ..moveTo(x - 2.6 * k, y + 2 * k)
      ..lineTo(x + 2.6 * k, y + 2 * k)
      ..lineTo(x + 3.4 * k + wave, y + 22 * k)
      ..lineTo(x + 0.2 * k + wave, y + 18 * k)
      ..lineTo(x - 3.0 * k + wave, y + 23 * k)
      ..close();
    c.drawPath(ribbon, _fill(const Color(0xFFD7263D)));
    c.drawCircle(Offset(x, y), 5.4 * k, _fill(_Palette.ropeDark));
    c.drawCircle(Offset(x - 1.2 * k, y - 1.2 * k), 3.2 * k, _fill(_Palette.rope));
  }

  // ---------- Characters ----------

  /// Legs, torso and head. Drawn facing right; mirrored for team 2.
  void _paintBody(Canvas c, _Puller p, _Layout lay) {
    final jersey = _jersey(p);
    final pants = _pants(p);
    final skin = _skin(p);
    final sway = _sway(p);
    final bob = _bob(p);
    final lean = _lean(p);

    c.save();
    c.translate(p.x, lay.groundY);
    c.scale(p.facing * lay.k, lay.k);

    // Ground shadow
    c.drawOval(
      Rect.fromCenter(center: const Offset(-4, 1), width: 64, height: 11),
      _fill(const Color(0x33000000)),
    );

    final hipY = -46.0 + bob;

    // Legs stay planted on the ground
    final backFootX = -30 + sway * 2.5;
    final frontFootX = 13 - sway * 1.5;
    final backLeg = Path()
      ..moveTo(-3, hipY)
      ..lineTo(-15, -25 + bob * 0.5)
      ..lineTo(backFootX, -3);
    final frontLeg = Path()
      ..moveTo(3, hipY)
      ..lineTo(18, -27 + bob * 0.5)
      ..lineTo(frontFootX, -3);
    c.drawPath(backLeg, _stroke(Color.lerp(pants, Colors.black, 0.25)!, 12));
    c.drawPath(frontLeg, _stroke(pants, 12));

    // Shoes
    final shoe = _fill(Colors.white);
    final sole = _fill(_Palette.ink);
    for (final fx in [backFootX, frontFootX]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(fx - 7, -4, fx + 9, 3),
          const Radius.circular(3.5),
        ),
        shoe,
      );
      c.drawRect(Rect.fromLTRB(fx - 7, 1.2, fx + 9, 3), sole);
    }

    // Upper body leans back around the hip
    c.translate(0, hipY);
    c.rotate(-lean);

    // Shorts, jersey, light edge, chest stripe
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-9, -6, 10, 8),
        const Radius.circular(5),
      ),
      _fill(pants),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-9.5, -40, 10.5, 0),
        const Radius.circular(9),
      ),
      _fill(jersey),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(3, -38, 9.5, -2),
        const Radius.circular(4),
      ),
      _fill(Colors.white.withValues(alpha: 0.18)),
    );
    c.drawRect(
      const Rect.fromLTRB(-9.5, -26, 10.5, -21),
      _fill(Colors.white.withValues(alpha: 0.9)),
    );

    // Head
    const head = Offset(6, -53);
    c.drawRect(const Rect.fromLTRB(1, -44, 8, -38), _fill(skin));
    c.drawCircle(head, 10, _fill(skin));
    c.drawCircle(
      head + const Offset(-2.5, 1.5),
      2.6,
      _fill(Color.lerp(skin, Colors.black, 0.12)!),
    );
    c.drawArc(
      Rect.fromCircle(center: head, radius: 10.6),
      -0.2 * math.pi,
      -1.1 * math.pi,
      true,
      _fill(_hair(p)),
    );
    // Headband
    c.drawRect(
      Rect.fromLTRB(head.dx - 10.2, head.dy - 6.2, head.dx + 10.2, head.dy - 2.8),
      _fill(jersey),
    );
    c.drawRect(
      Rect.fromLTRB(head.dx - 10.2, head.dy - 4.0, head.dx + 10.2, head.dy - 2.8),
      _fill(pants),
    );
    // Face: eye, determined eyebrow, mouth, nose
    c.drawCircle(head + const Offset(4.8, 2.0), 1.4, _fill(_Palette.ink));
    c.drawLine(
      head + const Offset(2.6, -0.6),
      head + const Offset(7.2, 0.4),
      _stroke(_Palette.ink, 1.3),
    );
    c.drawLine(
      head + const Offset(3.4, 6.2),
      head + const Offset(7.0, 5.6),
      _stroke(_Palette.ink, 1.2),
    );
    c.drawCircle(head + const Offset(9.8, 2.8), 1.8, _fill(skin));

    c.restore();
  }

  /// Arms are drawn after the rope so the hands sit on top of it.
  void _paintArms(Canvas c, _Puller p, _Layout lay) {
    final lean = _lean(p);
    final hipY = -46.0 + _bob(p);

    Offset toWorld(double lx, double ly) {
      final xr = lx * math.cos(lean) + ly * math.sin(lean);
      final yr = -lx * math.sin(lean) + ly * math.cos(lean);
      return Offset(
        p.x + p.facing * lay.k * xr,
        lay.groundY + lay.k * (hipY + yr),
      );
    }

    final nearGripX = p.x + p.facing * 16 * lay.k;
    final farGripX = nearGripX + p.facing * 5 * lay.k;
    final nearGrip = Offset(nearGripX, _ropeY(nearGripX, lay));
    final farGrip = Offset(farGripX, _ropeY(farGripX, lay) + 0.8 * lay.k);

    final jersey = _jersey(p);
    final skin = _skin(p);

    // Far arm first (a little darker), then the near arm
    _drawArm(
      c,
      toWorld(2, -35),
      farGrip,
      Color.lerp(jersey, Colors.black, 0.2)!,
      Color.lerp(skin, Colors.black, 0.15)!,
      lay.k,
    );
    _drawArm(c, toWorld(6, -34), nearGrip, jersey, skin, lay.k);
  }

  void _drawArm(
    Canvas c,
    Offset shoulder,
    Offset grip,
    Color sleeve,
    Color skin,
    double k,
  ) {
    final d = grip - shoulder;
    final len = d.distance;
    if (len < 0.01) return;

    final mid = (shoulder + grip) / 2;
    final normal = Offset(-d.dy, d.dx) / len;
    final down = normal.dy >= 0 ? normal : -normal;
    final elbow = mid + down * (len * 0.16);

    c.drawLine(shoulder, elbow, _stroke(sleeve, 8 * k));
    c.drawLine(elbow, grip, _stroke(skin, 5.6 * k));
    c.drawCircle(grip, 3.6 * k, _fill(skin));
  }
}