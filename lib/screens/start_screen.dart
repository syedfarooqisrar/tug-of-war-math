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
  MathOperation operation = MathOperation.multiplication;
  GameMode mode = GameMode.classic;
  Difficulty difficulty = Difficulty.medium;
  int roundSeconds = GameConfig.defaultRoundSeconds;
  int winPulls = GameConfig.defaultWinPulls;

  /// Dark brown text on the gold button (easy to read).
  static const Color _onGold = Color(0xFF4A3200);

  /// One selectable button inside a row of options.
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double fontSize = 14,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 42,
            decoration: BoxDecoration(
              color: selected ? AppColors.team1 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.team1Dark : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.team1.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
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
    );
  }

  /// A full row of options built from a list of values.
  Widget _chipRow<T>({
    required List<T> options,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onPick,
    double Function(T)? fontSize,
  }) {
    return Row(
      children: [
        for (final option in options)
          _chip(
            label: label(option),
            selected: option == selected,
            fontSize: fontSize?.call(option) ?? 14,
            onTap: () => onPick(option),
          ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: AppText.body(size: 14)),
        ),
      );

  /// Small explanation line under a row.
  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              color: Colors.grey.shade600,
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
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 2),
          Text(
            AppStrings.appTitle,
            textAlign: TextAlign.center,
            style: AppText.heading(size: 22, color: AppColors.team1Dark),
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.tagline,
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel(AppStrings.operation),
          _chipRow<MathOperation>(
            options: MathOperation.values,
            selected: operation,
            label: (o) => o.symbol,
            fontSize: (o) => o == MathOperation.mixed ? 14 : 22,
            onPick: (o) => setState(() => operation = o),
          ),
          const SizedBox(height: 14),
          _fieldLabel(AppStrings.gameMode),
          _chipRow<GameMode>(
            options: GameMode.values,
            selected: mode,
            label: (m) => m.label,
            onPick: (m) => setState(() => mode = m),
          ),
          _hint(mode.description),
          const SizedBox(height: 14),
          _fieldLabel(AppStrings.difficulty),
          _chipRow<Difficulty>(
            options: Difficulty.values,
            selected: difficulty,
            label: (d) => d.label,
            onPick: (d) => setState(() => difficulty = d),
          ),
          _hint(difficulty.description),
          const SizedBox(height: 14),
          _fieldLabel(AppStrings.roundLength),
          _chipRow<int>(
            options: GameConfig.roundSecondOptions,
            selected: roundSeconds,
            label: (v) => '${v}s',
            onPick: (v) => setState(() => roundSeconds = v),
          ),
          const SizedBox(height: 14),
          _fieldLabel(AppStrings.pullsToWin),
          _chipRow<int>(
            options: GameConfig.winPullOptions,
            selected: winPulls,
            label: (v) => '$v',
            onPick: (v) => setState(() => winPulls = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: _onGold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: _startGame,
              child: Text(
                '▶  ${AppStrings.startGame}',
                style: AppText.heading(size: 18, color: _onGold),
              ),
            ),
          ),
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
            reference: const Size(
              LayoutConstants.startRefWidth,
              LayoutConstants.startRefHeight,
            ),
            builder: (context, size, boardMode) {
              // Normal screens: the whole card is always visible (it shrinks
              // a little if needed). Short screens (a phone on its side): the
              // card scrolls instead.
              final fits =
                  size.height >= LayoutConstants.startScrollBelowHeight;

              return Center(
                child: fits
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: LayoutConstants.startCardWidth,
                            child: _card(),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: LayoutConstants.startCardWidth,
                          ),
                          child: _card(),
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