// 📁 FILE: lib/game/tug_of_war_game.dart
// 📌 WHAT: Same arena game; onGameResize parameter renamed to match Flame (fixes the lint)
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'rope_component.dart';

/// The Flame game that renders the tug-of-war arena. Everything else
/// (score, numpad, timer) is plain Flutter UI around it.
class TugOfWarGame extends FlameGame {
  late final RopeComponent rope;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    rope = RopeComponent()
      ..size = size
      ..position = Vector2.zero();
    add(rope);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      rope.size = size;
    }
  }

  /// pull: -1.0 (Team 2 winning) .. 1.0 (Team 1 winning)
  void updatePull(double pull) {
    rope.setPull(pull);
  }

  /// The round is over: 0 = tie, 1 = team 1 won, 2 = team 2 won.
  void setResult(int winner) {
    rope.setResult(winner);
  }
}