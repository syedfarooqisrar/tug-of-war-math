import 'package:flame/game.dart';
import 'rope_component.dart';
import 'package:flutter/material.dart';

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
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    if (isLoaded) {
      rope.size = canvasSize;
    }
  }

  void updatePull(double pull) {
    rope.setPull(pull);
  }
}