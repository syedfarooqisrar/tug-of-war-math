// 📁 FILE: lib/core/reminder/reminder_manager.dart
// 📌 WHAT: Keeps the reminder settings, the play log and the scheduled reminders in sync

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'play_log.dart';
import 'reminder_logic.dart';
import 'reminder_scheduler.dart';
import 'reminder_settings.dart';

/// The one place the UI talks to for the daily reminder.
class ReminderManager extends ChangeNotifier {
  ReminderManager({
    required ReminderScheduler scheduler,
    ReminderStore store = const ReminderStore(),
    DateTime Function()? clock,
  })  : _scheduler = scheduler,
        _store = store,
        _clock = clock ?? DateTime.now;

  /// The manager used by the app.
  static final ReminderManager instance =
      ReminderManager(scheduler: LocalNotificationScheduler());

  final ReminderScheduler _scheduler;
  final ReminderStore _store;
  final DateTime Function() _clock;

  ReminderSettings _settings = const ReminderSettings();
  PlayLog _playLog = const PlayLog();
  bool _isLoaded = false;
  Future<void>? _starting;

  ReminderSettings get settings => _settings;
  PlayLog get playLog => _playLog;
  bool get isLoaded => _isLoaded;
  bool get isSupported => _scheduler.isSupported;
  bool get playedToday => _playLog.playedOn(_clock());
  List<WeekDot> get weekDots => _playLog.weekDots(_clock());
  int get daysPlayedThisWeek => _playLog.daysPlayedThisWeek(_clock());

  /// True when the friendly "daily reminder?" question may be shown now.
  /// Never before the first finished game.
  bool get shouldAskNow =>
      _isLoaded &&
      isSupported &&
      _playLog.days.isNotEmpty &&
      _settings.canAskAgain(_clock());

  void _log(String message) {
    if (kDebugMode) debugPrint('ReminderManager: $message');
  }

  /// Loads the saved choices and sets up the reminders. Safe to call many times.
  Future<void> start() => _starting ??= _load();

  Future<void> _load() async {
    try {
      _settings = await _store.loadSettings();
      _playLog = await _store.loadPlayLog();
    } catch (error) {
      _log('could not load saved data: $error');
    }
    _isLoaded = true;
    notifyListeners();

    if (!isSupported) return;
    try {
      await _scheduler.init();
    } catch (error) {
      _log('could not start notifications: $error');
      return;
    }
    await _refresh();
  }

  /// Plans the next reminders again. Call it when the app comes back to the
  /// front, so the 7-day window keeps moving forward.
  Future<void> refresh() async {
    await start();
    await _refresh();
  }

  Future<void> _refresh() async {
    if (!isSupported || !_scheduler.isReady) return;
    try {
      if (!_settings.enabled || !await _scheduler.isAllowed()) {
        await _scheduler.cancelAll();
        return;
      }
      final now = _clock();
      final moments = ReminderLogic.upcoming(
        now: now,
        hour: _settings.hour,
        minute: _settings.minute,
        playedToday: _playLog.playedOn(now),
      );
      final plan = <PlannedReminder>[
        for (var i = 0; i < moments.length; i++)
          PlannedReminder(
            id: ReminderConfig.firstNotificationId + i,
            moment: moments[i],
            message: ReminderMessages.forDate(moments[i]),
          ),
      ];
      await _scheduler.replaceAll(plan);
    } catch (error) {
      _log('could not plan reminders: $error');
    }
  }

  Future<bool> _ensureAllowed() async {
    try {
      if (await _scheduler.isAllowed()) return true;
      return await _scheduler.requestPermission();
    } catch (error) {
      _log('permission problem: $error');
      return false;
    }
  }

  /// Call when a game finished (not when it was quit). Remembers today and
  /// moves the next reminder to tomorrow.
  Future<void> onGameFinished() async {
    await start();
    _playLog = _playLog.withPlayed(_clock());
    await _store.savePlayLog(_playLog);
    notifyListeners();
    await _refresh();
  }

  /// Turns the reminder on. Asks Android for permission when needed.
  /// Returns false (and stays off) when the player did not allow it.
  Future<bool> enable({int? hour, int? minute}) async {
    await start();
    if (!isSupported || !_scheduler.isReady) return false;
    if (!await _ensureAllowed()) return false;

    _settings = _settings.copyWith(
      enabled: true,
      hour: ReminderLogic.clampHour(hour ?? _settings.hour),
      minute: minute ?? _settings.minute,
    );
    await _store.saveSettings(_settings);
    notifyListeners();
    await _refresh();
    return true;
  }

  Future<void> disable() async {
    await start();
    _settings = _settings.copyWith(enabled: false);
    await _store.saveSettings(_settings);
    notifyListeners();
    await _refresh();
  }

  Future<void> setTime(int hour, int minute) async {
    await start();
    _settings = _settings.copyWith(
      hour: ReminderLogic.clampHour(hour),
      minute: minute,
    );
    await _store.saveSettings(_settings);
    notifyListeners();
    await _refresh();
  }

  /// The player said "Not now" to the friendly question.
  Future<void> declineAsk() async {
    await start();
    _settings = _settings.copyWith(
      declinedCount: _settings.declinedCount + 1,
      declinedOn: PlayLog.keyFor(_clock()),
    );
    await _store.saveSettings(_settings);
    notifyListeners();
  }

  /// Shows a notification right now. Returns false when it could not be shown.
  Future<bool> sendTest() async {
    await start();
    if (!isSupported || !_scheduler.isReady) return false;
    if (!await _ensureAllowed()) return false;
    try {
      await _scheduler.showTest(ReminderMessages.pool.first);
      return true;
    } catch (error) {
      _log('could not show the test notification: $error');
      return false;
    }
  }
}