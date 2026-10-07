import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// Every sound effect in the game.
enum Sfx { correct, wrong, tick, go, win }

/// Plays sound effects and matching vibration. One shared instance is
/// used by the whole app, so the mute choice is kept between games.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  /// True when sound and vibration are turned off. The mute button
  /// listens to this.
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  static const Map<Sfx, String> _files = {
    Sfx.correct: SoundAssets.correct,
    Sfx.wrong: SoundAssets.wrong,
    Sfx.tick: SoundAssets.tick,
    Sfx.go: SoundAssets.go,
    Sfx.win: SoundAssets.win,
  };

  final Map<Sfx, AudioPlayer> _players = {};
  bool _started = false;

  /// Loads all sounds once. Safe to call many times.
  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      await AudioCache.instance.loadAll(_files.values.toList());
      for (final entry in _files.entries) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        _players[entry.key] = player;
      }
    } catch (error) {
      _log('could not load sounds: $error');
    }
  }

  /// Plays one sound and its vibration. Does nothing when muted.
  Future<void> play(Sfx sfx) async {
    if (muted.value) return;
    _vibrate(sfx);

    final player = _players[sfx];
    if (player == null) return; // not loaded (yet): stay silent
    try {
      await player.stop();
      await player.play(AssetSource(_files[sfx]!));
    } catch (error) {
      _log('could not play $sfx: $error');
    }
  }

  /// Turns sound and vibration on or off.
  void toggleMute() {
    muted.value = !muted.value;
    if (muted.value) {
      for (final player in _players.values) {
        player.stop();
      }
    }
  }

  void _vibrate(Sfx sfx) {
    switch (sfx) {
      case Sfx.correct:
        HapticFeedback.lightImpact();
      case Sfx.wrong:
        HapticFeedback.heavyImpact();
      case Sfx.tick:
        HapticFeedback.selectionClick();
      case Sfx.go:
        HapticFeedback.mediumImpact();
      case Sfx.win:
        HapticFeedback.heavyImpact();
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('SoundService: $message');
  }
}