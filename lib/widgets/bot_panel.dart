// 📁 FILE: lib/widgets/bot_panel.dart
// 📌 WHAT: Playful read-only panel for the computer opponent (same look as the team panel)
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../game/game_controller.dart' show AnswerResult;
import '../theme/app_theme.dart';

class BotPanel extends StatefulWidget {
  final String label;
  final Color color;
  final Color lightColor;
  final int score;
  final String questionText;
  final String currentInput;

  /// Hide the question card. Speed Race shows one shared question in the
  /// middle instead.
  final bool showQuestion;

  /// Correct answers in a row.
  final int streak;

  /// Result of the bot's most recent answer, and a counter that goes up on
  /// every answer. When the counter changes, the feedback plays.
  final AnswerResult lastResult;
  final int feedbackId;

  /// Points the last answer earned (2 means a bonus pull).
  final int lastPoints;

  const BotPanel({
    super.key,
    required this.label,
    required this.color,
    required this.lightColor,
    required this.score,
    required this.questionText,
    required this.currentInput,
    this.showQuestion = true,
    this.streak = 0,
    this.lastResult = AnswerResult.ignored,
    this.feedbackId = 0,
    this.lastPoints = 1,
  });

  @override
  State<BotPanel> createState() => _BotPanelState();
}

class _BotPanelState extends State<BotPanel>
    with SingleTickerProviderStateMixin {
  /// Darker orange for text on the white flame badge (readable).
  static const Color _fireText = Color(0xFFC2410C);

  /// How strong the right/wrong color flash starts (fades to 0).
  static const double _flashStrength = 0.22;

  /// Below this height the panel switches to a slim one-row layout
  /// (the bot sits at the top of a tall screen).
  static const double _compactBelowHeight = 190;

  late final AnimationController _anim;
  AnswerResult? _playing;
  int _playingPoints = 1;

  bool get _onFire => widget.streak >= GameConfig.streakForBonus;

  /// Darker shade of the team color (header edge, score pill edge).
  Color get _edge => AppColors.edge(widget.color, 0.30);

  /// Soft light shade of the team color (the solid edge under the panel).
  Color get _soft => Color.lerp(widget.color, Colors.white, 0.55)!;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void didUpdateWidget(covariant BotPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedbackId != oldWidget.feedbackId &&
        widget.lastResult != AnswerResult.ignored) {
      _playing = widget.lastResult;
      _playingPoints = widget.lastPoints;
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${widget.label}, score ${widget.score}',
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _panel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < _compactBelowHeight;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(color: _soft, offset: const Offset(0, 4)),
              ...AppShadows.card,
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _header(compact),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(compact ? 8 : 12),
                  child: compact
                      ? _compactBody()
                      : _fullBody(constraints.maxWidth - 24),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Slim layout: question and typed answer side by side.
  Widget _compactBody() {
    return Center(
      child: SizedBox(
        height: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showQuestion) ...[
              Expanded(flex: 3, child: _questionCard(true)),
              const SizedBox(width: 8),
            ],
            Expanded(flex: 2, child: _answerBox(true)),
          ],
        ),
      ),
    );
  }

  /// Roomy layout (landscape side panel): big robot icon, question, answer.
  Widget _fullBody(double width) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: math.max(width, 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.lightColor,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 52,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.showQuestion) ...[
                _questionCard(false),
                const SizedBox(height: 10),
              ],
              _answerBox(false),
            ],
          ),
        ),
      ),
    );
  }

  /// Solid team-color header with a darker edge, a robot icon, the name,
  /// the raised score pill and the streak meter.
  Widget _header(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(widget.color, Colors.white, 0.14)!, widget.color],
        ),
        border: Border(bottom: BorderSide(color: _edge, width: 3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: AppText.heading(size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            _scoreBadge(),
            const SizedBox(width: 10),
            _onFire ? _fireBadge() : _streakDots(),
          ],
        ),
      ),
    );
  }

  Widget _scoreBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _edge, offset: const Offset(0, 2))],
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

  Widget _streakDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < GameConfig.streakForBonus; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < widget.streak
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
      ],
    );
  }

  Widget _fireBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.fire.withValues(alpha: 0.55),
            blurRadius: 10,
          ),
        ],
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
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.30),
          width: 2,
        ),
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

  /// Shows what the bot has typed so far.
  Widget _answerBox(bool tight) {
    final hasInput = widget.currentInput.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      height: tight ? 44 : 46,
      decoration: BoxDecoration(
        color: hasInput ? widget.lightColor : AppColors.background,
        border: Border.all(
          color: hasInput ? widget.color : widget.color.withValues(alpha: 0.35),
          width: 2.5,
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