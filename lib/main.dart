// 📁 FILE: lib/main.dart
// 📌 WHAT: App entry point; starts the daily reminder manager after the first frame

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/reminder/reminder_manager.dart';
import 'screens/start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TugOfWarApp());

  // Not awaited: a reminder problem must never slow down or stop the app.
  unawaited(ReminderManager.instance.start());

  // TEMPORARY (debug builds only, removed in step 4): shows a test notification
  // so the permission question and the notification look can be checked.
  if (kDebugMode) {
    unawaited(
      ReminderManager.instance.start().then((_) {
        return ReminderManager.instance.sendTest();
      }),
    );
  }
}

class TugOfWarApp extends StatelessWidget {
  const TugOfWarApp({super.key});

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
