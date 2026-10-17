// 📁 FILE: lib/widgets/audio_toggles.dart
// 📌 WHAT: Music and Sound switches: small light-gold round icons stacked vertically (start screen) or wide labeled buttons (pause card)
import 'package:flutter/material.dart';
import '../core/services/music_service.dart';
import '../core/services/sound_service.dart';
import '../theme/app_theme.dart';
import 'chunky_button.dart';

/// The Music and Sound switches. "Sound" covers the sound effects and the
/// vibration.
class AudioToggles extends StatelessWidget {
  /// True: two wide buttons with words (pause card).
  /// False: two small round icon buttons, one above the other (start
  /// screen corner).
  final bool labeled;

  const AudioToggles({super.key, this.labeled = false});

  static const String _musicLabel = 'Music';
  static const String _soundLabel = 'Sound';

  static const double _labeledHeight = 52;
  static const Color _edge = Color(0xFFB7C7E2);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        MusicService.instance.enabled,
        SoundService.instance.muted,
      ]),
      builder: (context, _) {
        final musicOn = MusicService.instance.enabled.value;
        final soundOn = !SoundService.instance.muted.value;

        void toggleMusic() => MusicService.instance.enabled.value = !musicOn;
        void toggleSound() => SoundService.instance.toggleMute();

        if (labeled) {
          return Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: _labeledHeight,
                  child: _labeledToggle(
                    on: musicOn,
                    label: _musicLabel,
                    onIcon: Icons.music_note_rounded,
                    offIcon: Icons.music_off_rounded,
                    onTap: toggleMusic,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: _labeledHeight,
                  child: _labeledToggle(
                    on: soundOn,
                    label: _soundLabel,
                    onIcon: Icons.volume_up_rounded,
                    offIcon: Icons.volume_off_rounded,
                    onTap: toggleSound,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniToggle(
              on: musicOn,
              semanticLabel: '$_musicLabel ${musicOn ? 'on' : 'off'}',
              onIcon: Icons.music_note_rounded,
              offIcon: Icons.music_off_rounded,
              onTap: toggleMusic,
            ),
            _MiniToggle(
              on: soundOn,
              semanticLabel: '$_soundLabel ${soundOn ? 'on' : 'off'}',
              onIcon: Icons.volume_up_rounded,
              offIcon: Icons.volume_off_rounded,
              onTap: toggleSound,
            ),
          ],
        );
      },
    );
  }

  Widget _labeledToggle({
    required bool on,
    required String label,
    required IconData onIcon,
    required IconData offIcon,
    required VoidCallback onTap,
  }) {
    final iconColor = on ? Colors.white : AppColors.inkMuted;

    return ChunkyButton(
      semanticLabel: '$label ${on ? 'on' : 'off'}',
      selected: on,
      color: on ? AppColors.team1 : AppColors.surface,
      edgeColor: on ? AppColors.team1Dark : _edge,
      borderColor: on ? null : AppColors.border,
      radius: AppRadius.md,
      depth: 4,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(on ? onIcon : offIcon, size: 22, color: iconColor),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            label,
            style: AppText.body(
              size: 15,
              color: on ? Colors.white : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small round light-gold icon button. It looks small (34) but the area
/// that reacts to a tap is 44 x 44, so a finger can hit it easily.
class _MiniToggle extends StatefulWidget {
  final bool on;
  final String semanticLabel;
  final IconData onIcon;
  final IconData offIcon;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.on,
    required this.semanticLabel,
    required this.onIcon,
    required this.offIcon,
    required this.onTap,
  });

  @override
  State<_MiniToggle> createState() => _MiniToggleState();
}

class _MiniToggleState extends State<_MiniToggle> {
  static const double _tapArea = 44;
  static const double _size = 34;
  static const double _iconSize = 18;
  static const double _edgeDepth = 2;

  // Light gold when on, white when off.
  static const Color _onFace = Color(0xFFFFF3C4);
  static const Color _onBorder = Color(0xFFEBCB6B);
  static const Color _onEdge = Color(0xFFE3BE55);
  static const Color _onIcon = AppColors.goldDark;

  static const Color _offFace = AppColors.surface;
  static const Color _offBorder = AppColors.border;
  static const Color _offEdge = Color(0xFFD5DFEE);
  static const Color _offIcon = AppColors.inkFaint;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final on = widget.on;

    return Semantics(
      button: true,
      selected: on,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: SizedBox(
          width: _tapArea,
          height: _tapArea,
          child: Center(
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 70),
              width: _size,
              height: _size,
              transform: Matrix4.translationValues(
                0,
                _pressed ? _edgeDepth : 0,
                0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? _onFace : _offFace,
                border: Border.all(
                  color: on ? _onBorder : _offBorder,
                  width: 1.5,
                ),
                boxShadow: _pressed
                    ? const []
                    : [
                        BoxShadow(
                          color: on ? _onEdge : _offEdge,
                          offset: const Offset(0, _edgeDepth),
                        ),
                      ],
              ),
              child: Icon(
                on ? widget.onIcon : widget.offIcon,
                size: _iconSize,
                color: on ? _onIcon : _offIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}