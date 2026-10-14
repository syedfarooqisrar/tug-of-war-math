// 📁 FILE: lib/screens/start_screen.dart
// 📌 WHAT: Clean start screen: flat card, 48dp option chips, one gold Start button
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/layout/adaptive_layout.dart';
import '../models/game_settings.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  PlayerMode playerMode = PlayerMode.twoPlayers;
  BotLevel botLevel = BotLevel.medium;
  MathOperation operation = MathOperation.multiplication;
  GameMode mode = GameMode.classic;
  Difficulty difficulty = Difficulty.medium;
  int roundSeconds = GameConfig.defaultRoundSeconds;
  int winPulls = GameConfig.defaultWinPulls;

  // Labels for the single-player options.
  static const String _playersLabel = 'Players';
  static const String _botLevelLabel = 'Bot level';

  /// Height of an option chip (at least 48 for easy tapping).
  static const double _chipHeight = 48;

  /// Space between two option groups.
  static const double _groupGap = AppSpacing.lg;

  /// One selectable button inside a row of options.
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double fontSize = 14,
    String? semanticLabel,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Semantics(
          button: true,
          selected: selected,
          label: semanticLabel ?? label,
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: _chipHeight,
              decoration: BoxDecoration(
                color: selected ? AppColors.team1 : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: selected ? AppColors.team1 : AppColors.border,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    style: AppText.number(
                      size: fontSize,
                      color: selected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A full row of options built from a list of values.
  Widget _chipRow<T>({
    required List<T> options,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onPick,
    double Function(T)? fontSize,
    String Function(T)? semanticLabel,
  }) {
    return Row(
      children: [
        for (final option in options)
          _chip(
            label: label(option),
            selected: option == selected,
            fontSize: fontSize?.call(option) ?? 14,
            semanticLabel: semanticLabel?.call(option),
            onTap: () => onPick(option),
          ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: AppText.body(
              size: AppText.sizeSmall,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      );

  /// Small explanation line under a row.
  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: AppText.body(
              size: AppText.sizeCaption,
              weight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      );

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          settings: GameSettings(
            operation: operation,
            mode: mode,
            difficulty: difficulty,
            roundSeconds: roundSeconds,
            winPulls: winPulls,
            playerMode: playerMode,
            botLevel: botLevel,
          ),
        ),
      ),
    );
  }

  // ---------- Building blocks shared by both layouts ----------

  /// The option rows. The bot level row only appears when playing
  /// against the bot.
  Widget _options() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(_playersLabel),
        _chipRow<PlayerMode>(
          options: PlayerMode.values,
          selected: playerMode,
          label: (p) => p.label,
          onPick: (p) => setState(() => playerMode = p),
        ),
        _hint(playerMode.description),
        if (playerMode == PlayerMode.vsBot) ...[
          const SizedBox(height: _groupGap),
          _fieldLabel(_botLevelLabel),
          _chipRow<BotLevel>(
            options: BotLevel.values,
            selected: botLevel,
            label: (b) => b.label,
            onPick: (b) => setState(() => botLevel = b),
          ),
          _hint(botLevel.description),
        ],
        const SizedBox(height: _groupGap),
        _fieldLabel(AppStrings.operation),
        _chipRow<MathOperation>(
          options: MathOperation.values,
          selected: operation,
          label: (o) => o.symbol,
          semanticLabel: (o) => o.label,
          fontSize: (o) => o == MathOperation.mixed ? 14 : 22,
          onPick: (o) => setState(() => operation = o),
        ),
        const SizedBox(height: _groupGap),
        _fieldLabel(AppStrings.gameMode),
        _chipRow<GameMode>(
          options: GameMode.values,
          selected: mode,
          label: (m) => m.label,
          onPick: (m) => setState(() => mode = m),
        ),
        _hint(mode.description),
        const SizedBox(height: _groupGap),
        _fieldLabel(AppStrings.difficulty),
        _chipRow<Difficulty>(
          options: Difficulty.values,
          selected: difficulty,
          label: (d) => d.label,
          onPick: (d) => setState(() => difficulty = d),
        ),
        _hint(difficulty.description),
        const SizedBox(height: _groupGap),
        _fieldLabel(AppStrings.roundLength),
        _chipRow<int>(
          options: GameConfig.roundSecondOptions,
          selected: roundSeconds,
          label: (v) => '${v}s',
          semanticLabel: (v) => '$v seconds',
          onPick: (v) => setState(() => roundSeconds = v),
        ),
        const SizedBox(height: _groupGap),
        _fieldLabel(AppStrings.pullsToWin),
        _chipRow<int>(
          options: GameConfig.winPullOptions,
          selected: winPulls,
          label: (v) => '$v',
          semanticLabel: (v) => '$v pulls',
          onPick: (v) => setState(() => winPulls = v),
        ),
      ],
    );
  }

  Widget _startButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
        onPressed: _startGame,
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: Text(
          AppStrings.startGame,
          style: AppText.heading(
            size: AppText.sizeTitle,
            color: AppColors.onGold,
          ),
        ),
      ),
    );
  }

  /// Flat gold trophy on a soft round background.
  Widget _trophyBadge(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: 0.16),
      ),
      child: Icon(
        Icons.emoji_events_rounded,
        size: size * 0.6,
        color: AppColors.gold,
      ),
    );
  }

  Widget _titleBlock({required double trophySize, required double titleSize}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _trophyBadge(trophySize),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.appTitle,
          textAlign: TextAlign.center,
          style: AppText.heading(size: titleSize),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.tagline,
          textAlign: TextAlign.center,
          style: AppText.body(
            size: AppText.sizeSmall,
            weight: FontWeight.w600,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border, width: 1.5),
      boxShadow: AppShadows.card,
    );
  }

  // ---------- The two layouts ----------

  /// Tall screens (phones, tablets held upright): one column.
  Widget _tallCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _titleBlock(trophySize: 56, titleSize: AppText.sizeDisplay),
          const SizedBox(height: AppSpacing.xl),
          _options(),
          const SizedBox(height: AppSpacing.xl),
          _startButton(),
        ],
      ),
    );
  }

  /// Wide screens (landscape): title and Start button on the left,
  /// the options on the right.
  Widget _wideCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _titleBlock(trophySize: 88, titleSize: 36),
                const SizedBox(height: 28),
                _startButton(),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(flex: 6, child: _options()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FieldBackground(
        child: SafeArea(
          child: ScaledView(
            landscapeReference: const Size(
              LayoutConstants.startWideRefWidth,
              LayoutConstants.startWideRefHeight,
            ),
            portraitReference: const Size(
              LayoutConstants.startRefWidth,
              LayoutConstants.startRefHeight,
            ),
            builder: (context, size, boardMode) {
              final wide = boardMode == BoardMode.sideBySide;
              final cardWidth = wide
                  ? LayoutConstants.startWideCardWidth
                  : LayoutConstants.startCardWidth;
              final card = wide ? _wideCard() : _tallCard();

              // Normal screens: the whole card is always visible (it shrinks
              // a little if needed). Short screens (a phone on its side):
              // the card scrolls instead.
              final fits =
                  size.height >= LayoutConstants.startScrollBelowHeight;

              return Center(
                child: fits
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(width: cardWidth, child: card),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardWidth),
                          child: card,
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}