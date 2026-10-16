// 📁 FILE: lib/core/services/sound_service.dart
// 📌 WHAT: Sound effects with the new original audio set: tap, streak-pitched chimes, bonus, win, lose, tie
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Every sound effect in the game.
enum Sfx { tap, tick, go, correct, bonus, wrong, win, lose, tie }

/// Plays sound effects and matching vibration. One shared instance is
/// used by the whole app, so the mute choice is kept between games.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  /// True when sound and vibration are turned off. The mute button
  /// listens to this.
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  static const String _folder = 'audio/sfx/';

  /// The right-answer chime comes in three pitches. The pitch climbs with
  /// the answer streak (1st, 2nd and 3rd correct in a row).
  static const List<String> _correctFiles = [
    '${_folder}correct_1.wav',
    '${_folder}correct_2.wav',
    '${_folder}correct_3.wav',
  ];

  static const Map<Sfx, String> _files = {
    Sfx.tap: '${_folder}tap.wav',
    Sfx.tick: '${_folder}tick.wav',
    Sfx.go: '${_folder}go.wav',
    Sfx.bonus: '${_folder}bonus.wav',
    Sfx.wrong: '${_folder}wrong.wav',
    Sfx.win: '${_folder}win.wav',
    Sfx.lose: '${_folder}lose.wav',
    Sfx.tie: '${_folder}tie.wav',
  };

  /// Per-sound volume (0.0 to 1.0). The key tap stays quiet so fast typing
  /// is not tiring.
  static const Map<Sfx, double> _volumes = {
    Sfx.tap: 0.7,
    Sfx.tick: 0.8,
  };

  /// One player for every file, keyed by the file path.
  final Map<String, AudioPlayer> _players = {};
  bool _started = false;

  /// Sound effects mix with other audio (for example music playing on the
  /// phone) instead of grabbing audio focus.
  static final AudioContext _audioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  List<String> get _allFiles => [..._files.values, ..._correctFiles];

  /// Loads all sounds once. Safe to call many times.
  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      await AudioCache.instance.loadAll(_allFiles);
      for (final path in _allFiles) {
        final player = AudioPlayer();
        await player.setAudioContext(_audioContext);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        _players[path] = player;
      }
    } catch (error) {
      _log('could not load sounds: $error');
    }
  }

  String _pathFor(Sfx sfx, int level) {
    if (sfx == Sfx.correct) {
      return _correctFiles[level.clamp(0, _correctFiles.length - 1).toInt()];
    }
    return _files[sfx]!;
  }

  /// Plays one sound and its vibration. Does nothing when muted.
  ///
  /// [level] only matters for [Sfx.correct]: 0, 1 or 2, a higher chime for
  /// a longer streak.
  Future<void> play(Sfx sfx, {int level = 0}) async {
    if (muted.value) return;
    _vibrate(sfx);

    final path = _pathFor(sfx, level);
    final player = _players[path];
    if (player == null) return; // not loaded (yet): stay silent
    try {
      await player.stop();
      await player.setVolume(_volumes[sfx] ?? 1.0);
      await player.play(AssetSource(path));
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
      case Sfx.tap:
      case Sfx.tick:
        HapticFeedback.selectionClick();
      case Sfx.correct:
      case Sfx.lose:
      case Sfx.tie:
        HapticFeedback.lightImpact();
      case Sfx.go:
      case Sfx.wrong:
        HapticFeedback.mediumImpact();
      case Sfx.bonus:
      case Sfx.win:
        HapticFeedback.heavyImpact();
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('SoundService: $message');
  }
}
