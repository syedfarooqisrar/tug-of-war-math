import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All colors used across the app, in one place. Change a value here
/// and it updates everywhere.
class AppColors {
  static const skyTop = Color(0xFF8ECBFF);
  static const skyBottom = Color(0xFFDFF1FF);
  static const grass1 = Color(0xFF6FBE44);
  static const grass2 = Color(0xFF5AA838);

  static const rope = Color(0xFFC69A5A);
  static const ropeDark = Color(0xFF7A5B32);

  static const team1 = Color(0xFF2461E8);
  static const team1Light = Color(0xFFE3ECFF);
  static const team1Dark = Color(0xFF173E9C);

  static const team2 = Color(0xFFE8432B);
  static const team2Light = Color(0xFFFFE6E0);
  static const team2Dark = Color(0xFFA72C19);

  static const gold = Color(0xFFF4B400);
  static const goldDark = Color(0xFFB98600);
  static const ink = Color(0xFF1E293B);
  static const paper = Color(0xFFFFFAF0);
}

/// Reusable text styles. "Fredoka" (rounded/playful) for headings and
/// numbers, "Nunito" (friendly but readable) for body text.
class AppText {
  static TextStyle heading({double size = 24, Color color = AppColors.ink}) =>
      GoogleFonts.fredoka(fontSize: size, fontWeight: FontWeight.w700, color: color);

     /// Digits use Nunito ExtraBold because its 4 is closed and very clear.
   static TextStyle number({double size = 22, Color color = AppColors.ink}) =>
       GoogleFonts.nunito(fontSize: size, fontWeight: FontWeight.w800, color: color);

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);
}

/// A scenic outdoor background (sky, sun, clouds, hills, mowed grass)
/// used behind both screens, matching the arena in the game.
class FieldBackground extends StatelessWidget {
  final Widget child;
  const FieldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _FieldPainter(),
      child: child,
    );
  }
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.52;

    _sky(canvas, w, h, horizon);
    _clouds(canvas, w, h, horizon);
    _hills(canvas, w, h, horizon);
    _grass(canvas, w, h, horizon);

    // Soft vignette so the edges feel deeper
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          math.max(w, h) * 0.8,
          const [Color(0x00000000), Color(0x22000000)],
          const [0.55, 1.0],
        ),
    );
  }

  void _sky(Canvas canvas, double w, double h, double horizon) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon + 2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, horizon),
          const [Color(0xFF4AA8F0), Color(0xFFA5DCFF), Color(0xFFE6F6FF)],
          const [0.0, 0.65, 1.0],
        ),
    );

    // Sun with a soft glow
    final sunCenter = Offset(w * 0.85, horizon * 0.35);
    final sunRadius = math.min(w, h) * 0.06;
    canvas.drawCircle(
      sunCenter,
      sunRadius * 3.6,
      Paint()
        ..shader = ui.Gradient.radial(
          sunCenter,
          sunRadius * 3.6,
          const [Color(0xCCFFF3B0), Color(0x33FFE680), Color(0x00FFE680)],
          const [0.0, 0.4, 1.0],
        ),
    );
    canvas.drawCircle(sunCenter, sunRadius, Paint()..color = const Color(0xFFFFF6C8));
  }

  void _clouds(Canvas canvas, double w, double h, double horizon) {
    // x fraction, y fraction (of the sky height), size
    const clouds = [
      [0.12, 0.30, 1.0],
      [0.45, 0.16, 0.8],
      [0.70, 0.46, 0.9],
      [0.92, 0.22, 1.1],
    ];
    final paint = Paint()..color = const Color(0xE6FFFFFF);
    for (final cloud in clouds) {
      final s = h * 0.04 * cloud[2];
      final x = w * cloud[0];
      final y = horizon * cloud[1];
      canvas.drawCircle(Offset(x, y), s, paint);
      canvas.drawCircle(Offset(x - s * 0.95, y + s * 0.28), s * 0.7, paint);
      canvas.drawCircle(Offset(x + s * 1.0, y + s * 0.25), s * 0.78, paint);
      canvas.drawCircle(Offset(x + s * 0.2, y - s * 0.35), s * 0.72, paint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - s * 1.5, y + s * 0.2, x + s * 1.65, y + s * 0.95),
          Radius.circular(s * 0.4),
        ),
        paint,
      );
    }
  }

  void _hill(
    Canvas canvas,
    double w,
    double horizon,
    Color color,
    double amp,
    double freq,
    double phase,
    double base,
  ) {
    final path = Path()..moveTo(0, horizon + 2);
    for (double x = 0; x <= w + 6; x += 6) {
      final y = base - amp * (math.sin(x / w * math.pi * 2 * freq + phase) * 0.5 + 0.5);
      path.lineTo(x, y);
    }
    path.lineTo(w, horizon + 2);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _hills(Canvas canvas, double w, double h, double horizon) {
    _hill(canvas, w, horizon, const Color(0xFF9AD6A8), h * 0.09, 1.1, 0.6, horizon - h * 0.01);
    _hill(canvas, w, horizon, const Color(0xFF7CC47E), h * 0.06, 1.6, 2.0, horizon);
  }

  void _grass(Canvas canvas, double w, double h, double horizon) {
    canvas.drawRect(
      Rect.fromLTRB(0, horizon, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizon),
          Offset(0, h),
          const [Color(0xFF8CD65C), Color(0xFF63B03B), Color(0xFF3F8A2A)],
          const [0.0, 0.5, 1.0],
        ),
    );

    // Mowing stripes that get thicker toward the viewer (perspective)
    const bands = 10;
    for (var i = 0; i < bands; i += 2) {
      final y0 = horizon + (h - horizon) * math.pow(i / bands, 1.5).toDouble();
      final y1 = horizon + (h - horizon) * math.pow((i + 1) / bands, 1.5).toDouble();
      canvas.drawRect(
        Rect.fromLTRB(0, y0, w, y1),
        Paint()..color = const Color(0x14000000),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}