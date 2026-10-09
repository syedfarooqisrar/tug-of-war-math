import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../constants/app_constants.dart';

/// How the two teams are arranged on screen.
enum BoardMode {
  /// Wide screen: team panel | arena | team panel, side by side.
  sideBySide,

  /// Tall screen (phone or tablet held upright): one team's panel at the
  /// top (upside down), the arena in the middle, the other team's panel
  /// at the bottom. Two players sit opposite each other.
  faceToFace,
}

class AdaptiveLayout {
  AdaptiveLayout._();

  static BoardMode modeFor(Size size) =>
      size.height > size.width ? BoardMode.faceToFace : BoardMode.sideBySide;

  /// The size the UI is designed for in each mode.
  static Size referenceSize(BoardMode mode) => mode == BoardMode.faceToFace
      ? const Size(
          LayoutConstants.portraitRefWidth,
          LayoutConstants.portraitRefHeight,
        )
      : const Size(
          LayoutConstants.landscapeRefWidth,
          LayoutConstants.landscapeRefHeight,
        );

  /// How much the UI is enlarged (above 1) or shrunk (below 1).
  /// [reference] overrides the design size (the start screen uses its own).
  static double scaleFor(Size size, {Size? reference}) {
    final ref = reference ?? referenceSize(modeFor(size));
    final fit = math.min(size.width / ref.width, size.height / ref.height);
    return fit
        .clamp(LayoutConstants.minUiScale, LayoutConstants.maxUiScale)
        .toDouble();
  }
}

/// Draws its child at a "virtual" size and scales it to fill the screen,
/// so everything (text, buttons, arena) grows and shrinks together.
class ScaledView extends StatelessWidget {
  final Widget Function(BuildContext context, Size size, BoardMode mode)
      builder;

  /// Optional design size. Leave it out for the game board.
  final Size? reference;

  const ScaledView({super.key, this.reference, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.biggest;
        if (!available.isFinite || available.isEmpty) {
          return const SizedBox.shrink();
        }

        final mode = AdaptiveLayout.modeFor(available);
        final scale = AdaptiveLayout.scaleFor(available, reference: reference);
        final virtual = Size(available.width / scale, available.height / scale);

        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: virtual.width,
            height: virtual.height,
            child: builder(context, virtual, mode),
          ),
        );
      },
    );
  }
}