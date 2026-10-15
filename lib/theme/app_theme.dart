// 📁 FILE: lib/theme/app_theme.dart
// 📌 WHAT: "Playful Clean" tokens: softly colored background with a faint math-symbol pattern, a stronger outline color and an edge-color helper for tactile buttons
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All colors used across the app, in one place. Change a value here
/// and it updates everywhere.
///
/// Design rule: a light, softly blue world; the two team colors for the
/// teams; gold for the main action and the trophy; green, red and orange
/// only for feedback.
class AppColors {
  AppColors._();

  // ---------- Neutrals ----------
  static const background = Color(0xFFEAF3FF);
  static const backgroundDeep = Color(0xFFD7E6FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFC9D8EE);
  static const ink = Color(0xFF1B2433);
  static const inkMuted = Color(0xFF5B6678);
  static const inkFaint = Color(0xFF94A3B8);

  /// Cards (start screen, result card). Plain white.
  static const paper = Color(0xFFFFFFFF);

  // ---------- Teams ----------
  static const team1 = Color(0xFF2563EB);
  static const team1Light = Color(0xFFE8F0FE);
  static const team1Dark = Color(0xFF1D4ED8);

  static const team2 = Color(0xFFDC2626);
  static const team2Light = Color(0xFFFDECEC);
  static const team2Dark = Color(0xFFB91C1C);

  // ---------- Accent ----------
  static const gold = Color(0xFFF5B301);
  static const goldDark = Color(0xFFB98600);

  /// Dark brown text on gold (readable).
  static const onGold = Color(0xFF4A3200);

  // ---------- Feedback ----------
  static const success = Color(0xFF22A559);
  static const danger = Color(0xFFD92D20);
  static const fire = Color(0xFFF97316);

  // ---------- Arena scenery ----------
  static const skyTop = Color(0xFF8ECBFF);
  static const skyBottom = Color(0xFFDFF1FF);
  static const grass1 = Color(0xFF6FBE44);
  static const grass2 = Color(0xFF5AA838);

  static const rope = Color(0xFFC69A5A);
  static const ropeDark = Color(0xFF7A5B32);

  /// A darker shade of [color], used as the bottom "edge" of a tactile
  /// button so it looks raised from the surface.
  static Color edge(Color color, [double amount = 0.28]) =>
      Color.lerp(color, Colors.black, amount)!;
}

/// Spacing scale. Use these instead of loose numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Corner radius scale.
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

/// One soft shadow for every card, so the app feels consistent.
class AppShadows {
  AppShadows._();

  static final List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF1B3A6B).withValues(alpha: 0.10),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Reusable text styles. "Fredoka" (rounded, friendly) for headings and
/// "Nunito" (clear and readable) for numbers and body text.
///
/// Only the font weights that are bundled in assets/google_fonts may be
/// used (Fredoka 600/700, Nunito 600/700/800). Another weight would make
/// the app try to download a font.
class AppText {
  AppText._();

  // The type scale: use only these sizes in new code.
  static const double sizeCaption = 12;
  static const double sizeSmall = 14;
  static const double sizeTitle = 18;
  static const double sizeDisplay = 28;
  static const double sizeHero = 44;

  static TextStyle heading({double size = 24, Color color = AppColors.ink}) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Digits use Nunito ExtraBold because its 4 is closed and very clear.
  static TextStyle number({double size = 22, Color color = AppColors.ink}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);
}

/// The background behind both screens: a soft sky-blue gradient with a
/// faint pattern of maths symbols (+ − × ÷ =) in the team colors and gold.
///
/// The pattern is drawn once on its own layer, so it costs almost nothing
/// while the game runs.
class FieldBackground extends StatelessWidget {
  final Widget child;
  const FieldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD6E9FF), Color(0xFFF3F8FF)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _MathPatternPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

enum _Symbol { plus, minus, times, divide, equals }

class _PatternItem {
  const _PatternItem(this.x, this.y, this.size, this.turns, this.symbol);

  /// Position as a fraction of the width and height.
  final double x;
  final double y;

  /// Half-width of the symbol in logical pixels (before scaling).
  final double size;

  /// Rotation in turns (0.25 = 90 degrees).
  final double turns;
  final _Symbol symbol;
}

class _MathPatternPainter extends CustomPainter {
  const _MathPatternPainter();

  static const List<_PatternItem> _items = [
    _PatternItem(0.08, 0.07, 22, 0.04, _Symbol.plus),
    _PatternItem(0.34, 0.04, 16, -0.06, _Symbol.times),
    _PatternItem(0.62, 0.09, 20, 0.08, _Symbol.equals),
    _PatternItem(0.90, 0.06, 18, -0.03, _Symbol.divide),
    _PatternItem(0.18, 0.24, 18, -0.05, _Symbol.minus),
    _PatternItem(0.78, 0.26, 24, 0.05, _Symbol.times),
    _PatternItem(0.05, 0.44, 20, 0.06, _Symbol.divide),
    _PatternItem(0.94, 0.47, 18, -0.07, _Symbol.plus),
    _PatternItem(0.12, 0.64, 22, -0.04, _Symbol.equals),
    _PatternItem(0.88, 0.68, 20, 0.04, _Symbol.minus),
    _PatternItem(0.30, 0.82, 18, 0.07, _Symbol.plus),
    _PatternItem(0.58, 0.90, 22, -0.05, _Symbol.divide),
    _PatternItem(0.82, 0.88, 18, 0.06, _Symbol.times),
    _PatternItem(0.06, 0.92, 16, -0.08, _Symbol.times),
  ];

  static const List<Color> _colors = [
    AppColors.team1,
    AppColors.team2,
    AppColors.gold,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Bigger screens get bigger symbols, in a sensible range.
    final scale = (size.shortestSide / 400).clamp(0.8, 2.2).toDouble();

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final s = item.size * scale;
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: 0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.38
        ..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.translate(size.width * item.x, size.height * item.y);
      canvas.rotate(item.turns * 2 * math.pi);
      _drawSymbol(canvas, item.symbol, s, paint);
      canvas.restore();
    }
  }

  void _drawSymbol(Canvas c, _Symbol symbol, double s, Paint paint) {
    switch (symbol) {
      case _Symbol.plus:
        c.drawLine(Offset(-s, 0), Offset(s, 0), paint);
        c.drawLine(Offset(0, -s), Offset(0, s), paint);
      case _Symbol.minus:
        c.drawLine(Offset(-s, 0), Offset(s, 0), paint);
      case _Symbol.times:
        c.drawLine(Offset(-s * 0.8, -s * 0.8), Offset(s * 0.8, s * 0.8), paint);
        c.drawLine(Offset(-s * 0.8, s * 0.8), Offset(s * 0.8, -s * 0.8), paint);
      case _Symbol.divide:
        c.drawLine(Offset(-s, 0), Offset(s, 0), paint);
        final dot = Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;
        c.drawCircle(Offset(0, -s * 0.75), paint.strokeWidth * 0.6, dot);
        c.drawCircle(Offset(0, s * 0.75), paint.strokeWidth * 0.6, dot);
      case _Symbol.equals:
        c.drawLine(Offset(-s, -s * 0.4), Offset(s, -s * 0.4), paint);
        c.drawLine(Offset(-s, s * 0.4), Offset(s, s * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}