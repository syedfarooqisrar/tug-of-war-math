import 'package:flutter/material.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const TugOfWarApp());
}

class TugOfWarApp extends StatelessWidget {
  const TugOfWarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tug of War: Mathematics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2461E8)),
      home: const StartScreen(),
    );
  }
}
