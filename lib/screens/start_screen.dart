import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int maxTable = GameConfig.defaultMaxTable;
  int roundSeconds = GameConfig.defaultRoundSeconds;
  int winPulls = GameConfig.defaultWinPulls;

  /// One selectable button inside a row of options.
  Widget _segButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12),
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
            child: Text(
              label,
              style: AppText.body(
                size: 14,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A full row of options built from a list of numbers.
  Widget _optionRow({
    required List<int> options,
    required int selected,
    required String Function(int) label,
    required ValueChanged<int> onPick,
  }) {
    return Row(
      children: options
          .map((value) => _segButton(
                label(value),
                selected == value,
                () => onPick(value),
              ))
          .toList(),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: AppText.body(size: 14)),
        ),
      );

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          maxTable: maxTable,
          roundSeconds: roundSeconds,
          winPulls: winPulls,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FieldBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: LayoutConstants.startCardWidth,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
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
                  const Text('🏆', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.appTitle,
                    textAlign: TextAlign.center,
                    style: AppText.heading(size: 24, color: AppColors.team1Dark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.tagline,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _fieldLabel(AppStrings.timesTables),
                  _optionRow(
                    options: GameConfig.tableOptions,
                    selected: maxTable,
                    label: (v) => '1–$v',
                    onPick: (v) => setState(() => maxTable = v),
                  ),
                  const SizedBox(height: 18),
                  _fieldLabel(AppStrings.roundLength),
                  _optionRow(
                    options: GameConfig.roundSecondOptions,
                    selected: roundSeconds,
                    label: (v) => '${v}s',
                    onPick: (v) => setState(() => roundSeconds = v),
                  ),
                  const SizedBox(height: 18),
                  _fieldLabel(AppStrings.pullsToWin),
                  _optionRow(
                    options: GameConfig.winPullOptions,
                    selected: winPulls,
                    label: (v) => '$v',
                    onPick: (v) => setState(() => winPulls = v),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.goldDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _startGame,
                      child: Text(
                        '▶  ${AppStrings.startGame}',
                        style: AppText.heading(size: 18, color: AppColors.goldDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}