// 📁 FILE: lib/core/services/audio_settings.dart   (NEW FILE)
// 📌 WHAT: Remembers the music and sound choices between app launches
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'music_service.dart';
import 'sound_service.dart';

/// Loads and saves the music and sound-effects switches. Whenever either
/// switch changes, the choice is stored on the phone.
class AudioSettings {
  AudioSettings._();

  static final AudioSettings instance = AudioSettings._();

  static const String _musicKey = 'music_on';
  static const String _soundKey = 'sound_on';

  bool _loaded = false;

  /// True when both music and sound effects are off.
  bool get allOff =>
      !MusicService.instance.enabled.value && SoundService.instance.muted.value;

  /// Reads the saved choices. Safe to call many times.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      MusicService.instance.enabled.value = prefs.getBool(_musicKey) ?? true;
      SoundService.instance.setMuted(!(prefs.getBool(_soundKey) ?? true));
    } catch (error) {
      _log('could not read the saved audio choices: $error');
    }

    // Listen only after loading, so loading itself does not trigger a save.
    MusicService.instance.enabled.addListener(_save);
    SoundService.instance.muted.addListener(_save);
  }

  /// Turns everything off, or (if everything is already off) back on.
  void toggleAll() {
    final turnOn = allOff;
    MusicService.instance.enabled.value = turnOn;
    SoundService.instance.setMuted(!turnOn);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicKey, MusicService.instance.enabled.value);
      await prefs.setBool(_soundKey, !SoundService.instance.muted.value);
    } catch (error) {
      _log('could not save the audio choices: $error');
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('AudioSettings: $message');
  }
}