import 'package:flame/game.dart';
import 'rope_component.dart';

/// The Flame game that renders just the center tug-of-war track.
/// Everything else (score, numpad, timer) is plain Flutter UI around it.
class TugOfWarGame extends FlameGame {
  late final RopeComponent rope;

  @override
  Future<void> onLoad() async {
    rope = RopeComponent()
      ..size = size
      ..position = Vector2.zero();
    add(rope);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    if (isLoaded) {
      rope.size = canvasSize;
    }
  }

  /// pull: -1.0 (Team 2 winning) .. 1.0 (Team 1 winning)
  void updatePull(double pull) {
    rope.setPull(pull);
  }
}
