// 📁 FILE: lib/main.dart
// 📌 WHAT: App entry point; starts the daily reminder manager and refreshes it when the app returns

import 'dart:async';

import 'package:flutter/material.dart';

import 'core/reminder/reminder_manager.dart';
import 'screens/start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TugOfWarApp());

  // Not awaited: a reminder problem must never slow down or stop the app.
  unawaited(ReminderManager.instance.start());
}

class TugOfWarApp extends StatefulWidget {
  const TugOfWarApp({super.key});

  @override
  State<TugOfWarApp> createState() => _TugOfWarAppState();
}

class _TugOfWarAppState extends State<TugOfWarApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app: plan the next 7 days of reminders again.
    if (state == AppLifecycleState.resumed) {
      unawaited(ReminderManager.instance.refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathPull',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2461E8)),
      home: const StartScreen(),
    );
  }
}
