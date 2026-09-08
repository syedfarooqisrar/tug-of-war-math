import 'package:flutter/material.dart';
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
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? const Color(0xFF2461E8) : Colors.white,
            foregroundColor: selected ? Colors.white : Colors.black87,
            side: BorderSide(color: selected ? const Color(0xFF2461E8) : Colors.grey.shade300),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF1FF),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🏆 Tug of War: Mathematics',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B3D91)),
                ),
                const SizedBox(height: 20),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Times tables', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Row(children: [
                  _segButton('1–5', maxTable == 5, () => setState(() => maxTable = 5)),
                  _segButton('1–10', maxTable == 10, () => setState(() => maxTable = 10)),
                  _segButton('1–12', maxTable == 12, () => setState(() => maxTable = 12)),
                ]),
                const SizedBox(height: 16),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Round length', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Row(children: [
                  _segButton('45s', roundSeconds == 45, () => setState(() => roundSeconds = 45)),
                  _segButton('60s', roundSeconds == 60, () => setState(() => roundSeconds = 60)),
                  _segButton('90s', roundSeconds == 90, () => setState(() => roundSeconds = 90)),
                ]),
                const SizedBox(height: 16),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Pulls to win instantly', style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Row(children: [
                  _segButton('6', winPulls == 6, () => setState(() => winPulls = 6)),
                  _segButton('8', winPulls == 8, () => setState(() => winPulls = 8)),
                  _segButton('12', winPulls == 12, () => setState(() => winPulls = 12)),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4B400),
                      foregroundColor: const Color(0xFF5A3E00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                    child: const Text('▶ Start Game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
