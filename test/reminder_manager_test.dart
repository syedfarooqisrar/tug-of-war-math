// 📁 FILE: test/reminder_manager_test.dart
// 📌 WHAT: Unit tests for the reminder manager, using a fake scheduler (no phone needed)

import 'package:flutter_test/flutter_test.dart';
import 'package:mathpull/core/reminder/reminder_logic.dart';
import 'package:mathpull/core/reminder/reminder_manager.dart';
import 'package:mathpull/core/reminder/reminder_scheduler.dart';
import 'package:mathpull/core/reminder/reminder_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeScheduler implements ReminderScheduler {
  FakeScheduler({this.supported = true});

  final bool supported;
  bool ready = true;
  bool allowed = false;
  bool grantOnRequest = true;
  int initCalls = 0;
  int requestCalls = 0;
  int cancelCalls = 0;
  List<PlannedReminder> plan = <PlannedReminder>[];
  final List<ReminderMessage> shown = <ReminderMessage>[];

  @override
  bool get isSupported => supported;

  @override
  bool get isReady => ready;

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  Future<bool> isAllowed() async => allowed;

  @override
  Future<bool> requestPermission() async {
    requestCalls++;
    allowed = grantOnRequest;
    return allowed;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> newPlan) async {
    plan = newPlan;
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
    plan = <PlannedReminder>[];
  }

  @override
  Future<void> showTest(ReminderMessage message) async {
    shown.add(message);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late FakeScheduler scheduler;
  late ReminderManager manager;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    now = DateTime(2026, 10, 25, 9, 30);
    scheduler = FakeScheduler();
    manager = ReminderManager(scheduler: scheduler, clock: () => now);
  });

  test('the reminder is on by default but nothing is planned before Android allows it',
      () async {
    await manager.start();

    expect(manager.isLoaded, isTrue);
    expect(manager.settings.enabled, isTrue);
    expect(manager.settings.permissionAsked, isFalse);
    expect(manager.looksOn, isTrue);
    expect(scheduler.initCalls, 1);
    expect(scheduler.plan, isEmpty);
  });

  test('when Android already allows notifications a week is planned at once',
      () async {
    scheduler.allowed = true;

    await manager.start();

    expect(scheduler.plan.length, ReminderConfig.windowDays);
    expect(scheduler.plan.first.moment, DateTime(2026, 10, 25, 17));
  });

  test('enable asks for permission and plans a whole week', () async {
    final ok = await manager.enable();

    expect(ok, isTrue);
    expect(scheduler.requestCalls, 1);
    expect(manager.settings.enabled, isTrue);
    expect(manager.settings.permissionAsked, isTrue);
    expect(scheduler.plan.length, ReminderConfig.windowDays);
    expect(scheduler.plan.first.id, ReminderConfig.firstNotificationId);
    expect(scheduler.plan.last.id,
        ReminderConfig.firstNotificationId + ReminderConfig.windowDays - 1);
    expect(scheduler.plan.first.moment, DateTime(2026, 10, 25, 17));
    final titles = scheduler.plan.map((item) => item.message.title).toSet();
    expect(titles.length, ReminderConfig.windowDays);
  });

  test('enable turns the reminder off when the player does not allow it',
      () async {
    scheduler.grantOnRequest = false;

    final ok = await manager.enable();

    expect(ok, isFalse);
    expect(manager.settings.enabled, isFalse);
    expect(manager.looksOn, isFalse);
    expect(scheduler.plan, isEmpty);
    expect((await const ReminderStore().loadSettings()).enabled, isFalse);
  });

  test('enable does not ask again when notifications are already allowed',
      () async {
    scheduler.allowed = true;

    final ok = await manager.enable();

    expect(ok, isTrue);
    expect(scheduler.requestCalls, 0);
  });

  test('a finished game moves the first reminder to tomorrow', () async {
    await manager.enable();
    expect(scheduler.plan.first.moment, DateTime(2026, 10, 25, 17));

    await manager.onGameFinished();

    expect(manager.playedToday, isTrue);
    expect(scheduler.plan.length, ReminderConfig.windowDays);
    expect(scheduler.plan.first.moment, DateTime(2026, 10, 26, 17));
    expect((await const ReminderStore().loadPlayLog()).playedOn(now), isTrue);
  });

  test('setTime replans and keeps the hour in the allowed range', () async {
    await manager.enable();

    await manager.setTime(18, 30);
    expect(manager.settings.hour, 18);
    expect(manager.settings.minute, 30);
    expect(scheduler.plan.first.moment, DateTime(2026, 10, 25, 18, 30));

    await manager.setTime(23, 0);
    expect(manager.settings.hour, ReminderConfig.latestHour);
  });

  test('disable cancels everything and remembers the choice', () async {
    await manager.enable();

    await manager.disable();

    expect(manager.settings.enabled, isFalse);
    expect(manager.looksOn, isFalse);
    expect(scheduler.plan, isEmpty);
    expect((await const ReminderStore().loadSettings()).enabled, isFalse);
  });

  test('Android is asked at the first launch and today is planned', () async {
    await manager.start();
    expect(scheduler.requestCalls, 0);

    await manager.requestPermissionIfNeeded();

    expect(scheduler.requestCalls, 1);
    expect(manager.settings.permissionAsked, isTrue);
    expect(manager.settings.enabled, isTrue);
    expect(scheduler.plan.length, ReminderConfig.windowDays);
    expect(scheduler.plan.first.moment, DateTime(2026, 10, 25, 17));
  });

  test('Android is asked only once', () async {
    await manager.onGameFinished();

    await manager.requestPermissionIfNeeded();
    await manager.requestPermissionIfNeeded();

    expect(scheduler.requestCalls, 1);
  });

  test('a refused permission turns the reminder off', () async {
    scheduler.grantOnRequest = false;
    await manager.onGameFinished();

    await manager.requestPermissionIfNeeded();

    expect(scheduler.requestCalls, 1);
    expect(manager.settings.enabled, isFalse);
    expect(manager.looksOn, isFalse);
    expect(scheduler.plan, isEmpty);
    expect((await const ReminderStore().loadSettings()).enabled, isFalse);
  });

  test('Android is not asked when the reminder was turned off', () async {
    await manager.disable();
    await manager.onGameFinished();

    await manager.requestPermissionIfNeeded();

    expect(scheduler.requestCalls, 0);
  });

  test('an unsupported platform does nothing', () async {
    final unsupported = FakeScheduler(supported: false);
    final other = ReminderManager(scheduler: unsupported, clock: () => now);

    await other.start();
    expect(unsupported.initCalls, 0);
    expect(await other.enable(), isFalse);
    await other.onGameFinished();
    await other.requestPermissionIfNeeded();

    expect(unsupported.requestCalls, 0);
    expect(other.looksOn, isFalse);
  });

  test('enable fails when notifications could not be started', () async {
    scheduler.ready = false;

    expect(await manager.enable(), isFalse);
    expect(scheduler.requestCalls, 0);
  });

  test('the choices survive an app restart', () async {
    await manager.enable(hour: 18, minute: 15);

    final second = FakeScheduler()..allowed = true;
    final restarted = ReminderManager(scheduler: second, clock: () => now);
    await restarted.start();

    expect(restarted.settings.enabled, isTrue);
    expect(restarted.settings.hour, 18);
    expect(second.plan.first.moment, DateTime(2026, 10, 25, 18, 15));
  });

  test('sendTest shows a notification when allowed', () async {
    final ok = await manager.sendTest();

    expect(ok, isTrue);
    expect(scheduler.shown.length, 1);
  });

  test('sendTest fails when the player does not allow notifications',
      () async {
    scheduler.grantOnRequest = false;

    final ok = await manager.sendTest();

    expect(ok, isFalse);
    expect(scheduler.shown, isEmpty);
  });

  test('a revoked permission cancels the reminders but keeps the choice',
      () async {
    await manager.enable();
    scheduler.allowed = false;

    await manager.refresh();

    expect(scheduler.plan, isEmpty);
    expect(manager.settings.enabled, isTrue);
    expect(manager.looksOn, isFalse);
  });
}