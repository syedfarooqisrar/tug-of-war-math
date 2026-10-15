// 📁 FILE: lib/widgets/confetti_burst.dart   (NEW FILE)
// 📌 WHAT: Falling confetti drawn with a CustomPainter (no package). Plays once, ignores touches.
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One piece of confetti. All numbers are chosen once, so the animation
/// is cheap: the painter only does a little maths per piece per frame.
class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.aspect,
    required this.spin,
    required this.flip,
    required this.sway,
    required this.swayFrequency,
    required this.phase,
    required this.color,
    required this.isCircle,
  });

  final double x; // start position, 0..1 of the width
  final double delay; // when it starts falling, 0..1 of the animation
  final double speed; // how far it falls (1.0 = the full height)
  final double size; // in logical pixels
  final double aspect; // height / width of a paper piece
  final double spin; // turns while falling (can be negative)
  final double flip; // speed of the "paper turning over" effect
  final double sway; // side-to-side movement, 0..1 of the width
  final double swayFrequency;
  final double phase;
  final Color color;
  final bool isCircle;
}

/// Confetti that rains from the top of its area once and then fades out.
/// Put it on top of something (for example in a [Stack]); it never blocks
/// taps. It draws nothing if the device asks for reduced motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.colors,
    this.count = 90,
    this.duration = const Duration(milliseconds: 3600),
  });

  /// Colors to pick from for the pieces.
  final List<Color> colors;

  /// Number of pieces.
  final int count;

  /// How long the whole shower lasts.
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    _pieces = _makePieces();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  List<_Piece> _makePieces() {
    final random = math.Random();
    final colors = widget.colors.isEmpty ? const [Colors.amber] : widget.colors;

    return List.generate(widget.count, (_) {
      return _Piece(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        speed: 0.75 + random.nextDouble() * 0.25,
        size: 6 + random.nextDouble() * 6,
        aspect: 0.5 + random.nextDouble() * 0.5,
        spin: (1 + random.nextDouble() * 3) * (random.nextBool() ? 1 : -1),
        flip: 4 + random.nextDouble() * 8,
        sway: 0.01 + random.nextDouble() * 0.03,
        swayFrequency: 1 + random.nextDouble() * 2,
        phase: random.nextDouble() * math.pi * 2,
        color: colors[random.nextInt(colors.length)],
        isCircle: random.nextInt(4) == 0,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect "remove animations" in the phone's accessibility settings.
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConfettiPainter(_pieces, _controller),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.animation) : super(repaint: animation);

  final List<_Piece> pieces;
  final Animation<double> animation;

  /// The last part of a piece's fall, where it fades out.
  static const double _fadeStart = 0.8;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;

    for (final piece in pieces) {
      // 0..1 progress of this piece, taking its delay into account.
      final local = ((t - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;

      final fade = local > _fadeStart ? (1 - local) / (1 - _fadeStart) : 1.0;
      final sway =
          math.sin(local * math.pi * 2 * piece.swayFrequency + piece.phase) *
              piece.sway;

      final dx = (piece.x + sway) * size.width;
      final dy = -20 + (size.height + 40) * local * piece.speed;

      // Paper turning over: its height shrinks and grows.
      final flipScale = math.cos(local * piece.flip).abs().clamp(0.15, 1.0);

      _paint.color = piece.color.withValues(alpha: fade);

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(piece.spin * local * math.pi * 2);
      canvas.scale(1, flipScale);

      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size / 2, _paint);
      } else {
        final width = piece.size;
        final height = piece.size * piece.aspect;
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          _paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces;
}