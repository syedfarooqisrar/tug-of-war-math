import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../game/game_controller.dart' show AnswerResult;
import '../theme/app_theme.dart';
import 'numpad.dart';

class TeamPanel extends StatefulWidget {
  final String teamLabel;
  final String flagEmoji;
  final Color color;
  final Color lightColor;
  final int score;
  final String questionText;
  final String currentInput;
  final ValueChanged<String> onDigit;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  /// Result of this team's most recent answer, and a counter that goes up
  /// on every answer. When the counter changes, the feedback plays.
  final AnswerResult lastResult;
  final int feedbackId;

  /// Hide the question card. Speed Race shows one shared question in the
  /// middle instead.
  final bool showQuestion;

  /// Correct answers in a row (fills the dots, then shows the flame badge).
  final int streak;

  /// Points the last answer earned (2 means a bonus pull).
  final int lastPoints;

  const TeamPanel({
    super.key,
    required this.teamLabel,
    required this.flagEmoji,
    required this.color,
    required this.lightColor,
    required this.score,
    required this.questionText,
    required this.currentInput,
    required this.onDigit,
    required this.onClear,
    required this.onSubmit,
    this.lastResult = AnswerResult.ignored,
    this.feedbackId = 0,
    this.showQuestion = true,
    this.streak = 0,
    this.lastPoints = 1,
  });

  @override
  State<TeamPanel> createState() => _TeamPanelState();
}

class _TeamPanelState extends State<TeamPanel> with TickerProviderStateMixin {
  static const Color _flashGreen = Color(0xFF2ECC71);
  static const Color _flashRed = Color(0xFFD32F2F);
  static const Color _flashFire = Color(0xFFFFA000);
  static const Color _plusOneGreen = Color(0xFF1B8F4A);
  static const Color _fireOrange = Color(0xFFFF6D00);

  late final AnimationController _anim;
  late final AnimationController _flame;
  AnswerResult? _playing;
  int _playingPoints = 1;

  bool get _onFire => widget.streak >= GameConfig.streakForBonus;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flame = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (_onFire) _flame.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TeamPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.feedbackId != oldWidget.feedbackId &&
        widget.lastResult != AnswerResult.ignored) {
      _playing = widget.lastResult;
      _playingPoints = widget.lastPoints;
      _anim.forward(from: 0);
    }

    // The flame badge pulses only while the team is on fire.
    if (_onFire && !_flame.isAnimating) {
      _flame.repeat(reverse: true);
    } else if (!_onFire && _flame.isAnimating) {
      _flame.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _flame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      child: _panel(),
      builder: (context, panel) {
        final t = _anim.value;
        final playing = _playing;

        // Wrong answer: shake sideways, getting weaker over time.
        final shake = playing == AnswerResult.wrong
            ? math.sin(t * math.pi * 6) * 9 * (1 - t)
            : 0.0;

        final flashColor = playing == AnswerResult.correct
            ? (_playingPoints > 1 ? _flashFire : _flashGreen)
            : _flashRed;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              panel!,
              if (playing != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: flashColor.withValues(alpha: 0.38 * (1 - t)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              if (playing == AnswerResult.correct)
                Positioned(
                  top: 64 - 34 * t,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 1 - t,
                      child: Center(child: _pointsPopup()),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// "+1" for a normal answer, a flame and "+2" for a bonus answer.
  Widget _pointsPopup() {
    if (_playingPoints > 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 34,
            color: _fireOrange,
          ),
          Text(
            '+$_playingPoints',
            style: AppText.heading(size: 38, color: _fireOrange),
          ),
        ],
      );
    }
    return Text('+1', style: AppText.heading(size: 34, color: _plusOneGreen));
  }

  Widget _panel() {
    final color = widget.color;
    final darkColor = Color.lerp(color, Colors.black, 0.22)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On a short panel (phone held upright) shrink the top parts so
        // the whole numpad stays visible.
        final tight = constraints.maxHeight < 380;
        // If the panel is also wide, put the question and the answer box
        // side by side to give the numpad more height.
        final compact =
            widget.showQuestion && tight && constraints.maxWidth >= 240;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(darkColor, tight),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(tight ? 8 : 10),
                  child: Column(
                    children: [
                      if (!widget.showQuestion)
                        _answerBox(tight)
                      else if (compact)
                        SizedBox(
                          height: 44,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 3, child: _questionCard(true)),
                              const SizedBox(width: 8),
                              Expanded(flex: 2, child: _answerBox(true)),
                            ],
                          ),
                        )
                      else ...[
                        _questionCard(tight),
                        SizedBox(height: tight ? 6 : 8),
                        _answerBox(tight),
                      ],
                      SizedBox(height: tight ? 6 : 10),
                      Expanded(
                        child: Numpad(
                          accentColor: color,
                          onDigit: widget.onDigit,
                          onClear: widget.onClear,
                          onSubmit: widget.onSubmit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(Color darkColor, bool tight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: tight ? 6 : 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [widget.color, darkColor],
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.flagEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              widget.teamLabel,
              style: AppText.heading(size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            _scoreBadge(),
            const SizedBox(width: 10),
            _streakMeter(),
          ],
        ),
      ),
    );
  }

  /// White badge. The number pops in whenever the score changes.
  Widget _scoreBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        ),
        child: Text(
          '${widget.score}',
          key: ValueKey(widget.score),
          textAlign: TextAlign.center,
          style: AppText.number(size: 17, color: widget.color),
        ),
      ),
    );
  }

  /// Three dots that fill as the streak grows. At the bonus streak they
  /// turn into a pulsing flame badge.
  Widget _streakMeter() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: _onFire ? _fireBadge() : _streakDots(),
    );
  }

  Widget _streakDots() {
    return Row(
      key: const ValueKey('dots'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < GameConfig.streakForBonus; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < widget.streak
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }

  Widget _fireBadge() {
    return ScaleTransition(
      key: const ValueKey('fire'),
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _flame, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _fireOrange.withValues(alpha: 0.6),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: _fireOrange,
            ),
            Text(
              '×${GameConfig.bonusPoints}',
              style: AppText.number(size: 14, color: _fireOrange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(bool tight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: tight ? 6 : 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [widget.lightColor, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.questionText,
          style: AppText.number(size: tight ? 22 : 28),
        ),
      ),
    );
  }

  /// Shows what the team has typed. It lights up in the team color
  /// as soon as there is at least one digit.
  Widget _answerBox(bool tight) {
    final hasInput = widget.currentInput.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: tight ? 36 : 46,
      decoration: BoxDecoration(
        color: hasInput ? widget.lightColor : Colors.white,
        border: Border.all(
          color: hasInput ? widget.color : widget.color.withValues(alpha: 0.35),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        hasInput ? widget.currentInput : '—',
        style: AppText.number(
          size: tight ? 20 : 24,
          color: hasInput ? AppColors.ink : Colors.grey.shade400,
        ).copyWith(letterSpacing: hasInput ? 3 : 0),
      ),
    );
  }
}