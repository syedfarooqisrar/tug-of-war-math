import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int maxTable = 10;
  int roundSeconds = 60;
  int winPulls = 8;

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
              border: Border.all(color: selected ? AppColors.team1Dark : Colors.grey.shade300, width: 2),
              boxShadow: selected
                  ? [BoxShadow(color: AppColors.team1.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(label, style: AppText.body(size: 14, color: selected ? Colors.white : AppColors.ink)),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(alignment: Alignment.centerLeft, child: Text(text, style: AppText.body(size: 14))),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FieldBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 420,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 4),
                  Text(
                    'Tug of War: Mathematics',
                    textAlign: TextAlign.center,
                    style: AppText.heading(size: 24, color: AppColors.team1Dark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Two teams race to solve tables and pull the rope!',
                    textAlign: TextAlign.center,
                    style: AppText.body(size: 13, weight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  _fieldLabel('Times tables'),
                  Row(children: [
                    _segButton('1–5', maxTable == 5, () => setState(() => maxTable = 5)),
                    _segButton('1–10', maxTable == 10, () => setState(() => maxTable = 10)),
                    _segButton('1–12', maxTable == 12, () => setState(() => maxTable = 12)),
                  ]),
                  const SizedBox(height: 18),
                  _fieldLabel('Round length'),
                  Row(children: [
                    _segButton('45s', roundSeconds == 45, () => setState(() => roundSeconds = 45)),
                    _segButton('60s', roundSeconds == 60, () => setState(() => roundSeconds = 60)),
                    _segButton('90s', roundSeconds == 90, () => setState(() => roundSeconds = 90)),
                  ]),
                  const SizedBox(height: 18),
                  _fieldLabel('Pulls to win instantly'),
                  Row(children: [
                    _segButton('6', winPulls == 6, () => setState(() => winPulls = 6)),
                    _segButton('8', winPulls == 8, () => setState(() => winPulls = 8)),
                    _segButton('12', winPulls == 12, () => setState(() => winPulls = 12)),
                  ]),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.goldDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
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
                      },
                      child: Text('▶  Start Game', style: AppText.heading(size: 18, color: AppColors.goldDark)),
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