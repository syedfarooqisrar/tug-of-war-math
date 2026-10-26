// 📁 FILE: lib/core/reminder/reminder_manager.dart
// 📌 WHAT: Keeps the reminder settings, the play log and the scheduled reminders in sync

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
  bool _allowed = false;
  Future<void>? _starting;

  ReminderSettings get settings => _settings;
  PlayLog get playLog => _playLog;
  bool get isLoaded => _isLoaded;
  bool get isSupported => _scheduler.isSupported;

  /// Whether Android currently lets the app show notifications.
  bool get isAllowed => _allowed;

  bool get playedToday => _playLog.playedOn(_clock());
  List<WeekDot> get weekDots => _playLog.weekDots(_clock());
  int get daysPlayedThisWeek => _playLog.daysPlayedThisWeek(_clock());

  /// What the bell shows: on when the reminder is on and either allowed, or
  /// Android was not asked yet (the question comes after the first game).
  bool get looksOn =>
      isSupported &&
      _settings.enabled &&
      (_allowed || !_settings.permissionAsked);

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
      _allowed = await _scheduler.isAllowed();
      if (!_settings.enabled || !_allowed) {
        await _scheduler.cancelAll();
        notifyListeners();
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
      notifyListeners();
    } catch (error) {
      _log('could not plan reminders: $error');
    }
  }

  /// True when notifications are allowed, asking Android if they are not.
  Future<bool> _ensureAllowed() async {
    try {
      _allowed = await _scheduler.isAllowed();
      if (!_allowed) _allowed = await _scheduler.requestPermission();
    } catch (error) {
      _log('permission problem: $error');
      _allowed = false;
    }
    return _allowed;
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

  /// Asks Android, once, whether the app may show notifications. It is called
  /// when the start screen shows for the first time. Does nothing if the
  /// reminder was turned off or if Android was already asked.
  Future<void> requestPermissionIfNeeded() async {
    await start();
    final shouldAsk = _isLoaded &&
        isSupported &&
        _scheduler.isReady &&
        _settings.enabled &&
        !_settings.permissionAsked;
    if (!shouldAsk) return;

    final allowed = await _ensureAllowed();
    _settings = _settings.copyWith(permissionAsked: true, enabled: allowed);
    await _store.saveSettings(_settings);
    notifyListeners();
    await _refresh();
  }

  /// Turns the reminder on. Asks Android for permission when needed.
  /// Returns false (and stays off) when the player did not allow it.
  Future<bool> enable({int? hour, int? minute}) async {
    await start();
    if (!isSupported || !_scheduler.isReady) return false;

    final allowed = await _ensureAllowed();
    _settings = _settings.copyWith(
      enabled: allowed,
      permissionAsked: true,
      hour: ReminderLogic.clampHour(hour ?? _settings.hour),
      minute: minute ?? _settings.minute,
    );
    await _store.saveSettings(_settings);
    notifyListeners();
    await _refresh();
    return allowed;
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

  /// Shows a notification right now. Returns false when it could not be shown.
  Future<bool> sendTest() async {
    await start();
    if (!isSupported || !_scheduler.isReady) return false;
    if (!await _ensureAllowed()) return false;
    try {
      await _scheduler.showTest(ReminderMessages.pool.first);
    } catch (error) {
      _log('could not show the test notification: $error');
      return false;
    }
    // Notifications are allowed now, so make sure the reminders are planned.
    await _refresh();
    return true;
  }
}