// 📁 FILE: lib/core/services/music_service.dart   (NEW FILE)
// 📌 WHAT: Background music: menu and game loops, fade out, ducking, tension speed-up, pause in background
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'sound_service.dart';

/// The two music loops.
enum MusicTrack { menu, game }

/// Plays the background music. One shared instance is used by the whole
/// app. It respects the mute button of [SoundService] and pauses itself
/// when the app goes to the background.
class MusicService with WidgetsBindingObserver {
  MusicService._();

  static final MusicService instance = MusicService._();

  static const Map<MusicTrack, String> _files = {
    MusicTrack.menu: 'audio/music/menu_loop.ogg',
    MusicTrack.game: 'audio/music/game_loop.ogg',
  };

  /// Normal music volume (0.0 to 1.0). Sound effects play at full volume,
  /// so the music stays a little under them.
  static const double _baseVolume = 0.55;

  /// The music is this much quieter while ducked (pause menu).
  static const double _duckFactor = 0.3;

  /// Playback speed when the round is tense.
  static const double _tensionRate = 1.06;

  static const Duration _fadeDuration = Duration(milliseconds: 500);
  static const int _fadeSteps = 10;

  /// Music on/off, separate from the sound effects. Wired to a button
  /// in a later step.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  final AudioPlayer _player = AudioPlayer();

  /// Music mixes with other audio instead of grabbing audio focus.
  static final AudioContext _audioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  bool _ready = false;

  /// The track that should be playing right now (null = none).
  MusicTrack? _track;
  bool _ducked = false;
  bool _tense = false;
  bool _inBackground = false;
  double _currentVolume = _baseVolume;

  /// Goes up whenever something new starts, so an old fade stops itself.
  int _generation = 0;

  bool get _shouldPlay =>
      _track != null &&
      enabled.value &&
      !SoundService.instance.muted.value &&
      !_inBackground;

  double get _targetVolume => _baseVolume * (_ducked ? _duckFactor : 1.0);

  Future<void> _ensureReady() async {
    if (_ready) return;
    _ready = true;
    WidgetsBinding.instance.addObserver(this);
    SoundService.instance.muted.addListener(() => _sync());
    enabled.addListener(() => _sync());
    try {
      await AudioCache.instance.loadAll(_files.values.toList());
      await _player.setAudioContext(_audioContext);
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (error) {
      _log('could not prepare music: $error');
    }
  }

  /// Starts [track] from the beginning. Does nothing if it already plays.
  Future<void> play(MusicTrack track) async {
    await _ensureReady();
    _generation++;

    if (_track == track && _player.state == PlayerState.playing) {
      await _setVolume(_targetVolume);
      return;
    }

    _track = track;
    _ducked = false;
    _tense = false;
    try {
      await _player.stop();
      await _player.setPlaybackRate(1.0);
      await _setVolume(_targetVolume);
      if (_shouldPlay) await _player.play(AssetSource(_files[track]!));
    } catch (error) {
      _log('could not play $track: $error');
    }
  }

  /// Fades the music out and stops it.
  Future<void> fadeOut() async {
    await _ensureReady();
    final generation = ++_generation;
    _track = null;
    if (_player.state != PlayerState.playing) return;

    final start = _currentVolume;
    final stepTime = _fadeDuration ~/ _fadeSteps;
    for (var i = 1; i <= _fadeSteps; i++) {
      if (generation != _generation) return; // something new started
      await _setVolume(start * (1 - i / _fadeSteps));
      await Future<void>.delayed(stepTime);
    }
    if (generation == _generation) {
      try {
        await _player.stop();
      } catch (error) {
        _log('could not stop music: $error');
      }
    }
  }

  /// Makes the music quieter (true) or normal again (false).
  Future<void> duck(bool on) async {
    if (_ducked == on) return;
    _ducked = on;
    if (_player.state == PlayerState.playing) {
      await _setVolume(_targetVolume);
    }
  }

  /// Plays a little faster when the round is tense (true) or normal (false).
  Future<void> setTension(bool on) async {
    if (_tense == on) return;
    _tense = on;
    try {
      await _player.setPlaybackRate(on ? _tensionRate : 1.0);
    } catch (error) {
      _log('could not change the music speed: $error');
    }
  }

  /// Starts, pauses or resumes the music to match the current settings.
  Future<void> _sync() async {
    try {
      if (_shouldPlay) {
        final state = _player.state;
        if (state == PlayerState.paused) {
          await _player.resume();
        } else if (state != PlayerState.playing) {
          await _player.play(AssetSource(_files[_track]!));
        }
        await _setVolume(_targetVolume);
      } else if (_player.state == PlayerState.playing) {
        await _player.pause();
      }
    } catch (error) {
      _log('could not update the music: $error');
    }
  }

  Future<void> _setVolume(double volume) async {
    _currentVolume = volume;
    try {
      await _player.setVolume(volume);
    } catch (error) {
      _log('could not set the music volume: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inBackground = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    _sync();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('MusicService: $message');
  }
}