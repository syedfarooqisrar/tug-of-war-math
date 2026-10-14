// 📁 FILE: lib/widgets/team_panel.dart
// 📌 WHAT: Clean team panel: flat tinted header, score pill, flat question and answer boxes
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../game/game_controller.dart' show AnswerResult;
import '../theme/app_theme.dart';
import 'numpad.dart';

class TeamPanel extends StatefulWidget {
  final String teamLabel;

  /// Not used any more (the header shows a color dot instead of an emoji).
  /// Kept so existing callers still compile; it will be removed later.
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
    this.flagEmoji = '',
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
  /// Darker orange for text on the light orange badge (readable).
  static const Color _fireText = Color(0xFFC2410C);

  /// How strong the right/wrong color flash starts (fades to 0).
  static const double _flashStrength = 0.22;

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

  Color get _textColor => Color.lerp(widget.color, Colors.black, 0.25)!;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${widget.teamLabel}, score ${widget.score}',
      child: AnimatedBuilder(
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
              ? (_playingPoints > 1 ? AppColors.fire : AppColors.success)
              : AppColors.danger;

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
                          color: flashColor.withValues(
                            alpha: _flashStrength * (1 - t),
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
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
      ),
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
            color: AppColors.fire,
          ),
          Text(
            '+$_playingPoints',
            style: AppText.heading(size: 38, color: AppColors.fire),
          ),
        ],
      );
    }
    return Text(
      '+1',
      style: AppText.heading(size: 34, color: AppColors.success),
    );
  }

  Widget _panel() {
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(tight),
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
                          accentColor: widget.color,
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

  /// Flat header: light team tint, a color dot, the team name, the score
  /// pill and the streak meter.
  Widget _header(bool tight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: tight ? 6 : 10, horizontal: 8),
      color: widget.lightColor,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.teamLabel,
              style: AppText.heading(size: 16, color: _textColor),
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

  /// Solid team-color pill. The number pops in whenever the score changes.
  Widget _scoreBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(20),
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
          style: AppText.number(size: 17, color: Colors.white),
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
                  ? widget.color
                  : widget.color.withValues(alpha: 0.25),
            ),
          ),
      ],
    );
  }

  Widget _fireBadge() {
    return ScaleTransition(
      key: const ValueKey('fire'),
      scale: Tween<double>(begin: 0.94, end: 1.06).animate(
        CurvedAnimation(parent: _flame, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.fire.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fire, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: AppColors.fire,
            ),
            Text(
              '×${GameConfig.bonusPoints}',
              style: AppText.number(size: 14, color: _fireText),
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.questionText,
          style: AppText.number(size: tight ? 22 : AppText.sizeDisplay),
        ),
      ),
    );
  }

  /// Shows what the team has typed. The border is in the team color and
  /// the box gets a light tint as soon as there is at least one digit.
  Widget _answerBox(bool tight) {
    final hasInput = widget.currentInput.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: tight ? 36 : 46,
      decoration: BoxDecoration(
        color: hasInput ? widget.lightColor : AppColors.surface,
        border: Border.all(
          color: hasInput ? widget.color : AppColors.border,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Text(
        hasInput ? widget.currentInput : '—',
        style: AppText.number(
          size: tight ? 20 : 24,
          color: hasInput ? AppColors.ink : AppColors.inkFaint,
        ).copyWith(letterSpacing: hasInput ? 3 : 0),
      ),
    );
  }
}