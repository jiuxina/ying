import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_reminder.dart';
import 'package:ying/models/event_repeat.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/services/update_service.dart';
import 'package:ying/state/app_controller.dart';

void main() {
  CountdownEvent event(
    String id, {
    bool completed = false,
    int? reminderMinutes = 60,
    EventRepeatType repeatType = EventRepeatType.none,
  }) => CountdownEvent(
    id: id,
    title: id,
    targetDate: DateTime(2026, 9, 1, 9),
    category: '学习',
    reminders: reminderMinutes == null
        ? const []
        : [
            EventReminder(
              id: 'reminder-$reminderMinutes',
              minutesBefore: reminderMinutes,
            ),
          ],
    isCompleted: completed,
    repeatType: repeatType,
    repeatMonth: repeatType == EventRepeatType.yearly ? 9 : null,
    repeatDay: repeatType == EventRepeatType.yearly ? 1 : null,
    createdAt: DateTime(2026, 7, 29),
  );

  group('AppController undo transactions', () {
    test('delete hides immediately, stores safely, then finalizes', () async {
      final stored = <List<CountdownEvent>>[];
      final widgetStates = <List<CountdownEvent>>[];
      final cancelled = <String>[];
      final controller = AppController(
        StorageService(),
        autoLoad: false,
        saveEvents: (events) async => stored.add([...events]),
        loadEvents: () async => const [],
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (_) async {},
        cancelNotification: (id) async => cancelled.add(id),
        syncWidget: (events, _) async => widgetStates.add([...events]),
        timerFactory: (_, _) => _IdleTimer(),
      );
      final original = event('Exam-30D');
      await controller.saveEvent(original);

      await controller.deleteEventWithUndo(original);
      expect(controller.state.events, isEmpty);
      expect(controller.state.pendingUndos, hasLength(1));
      expect(stored.last.single.id, original.id);
      expect(widgetStates.last, isEmpty);
      expect(cancelled, isEmpty);

      await controller.finalizeUndo(controller.state.latestUndo!.id);
      expect(stored.last, isEmpty);
      expect(cancelled, [original.id]);
      controller.dispose();
    });

    test('undo delete restores event and reminder', () async {
      final stored = <List<CountdownEvent>>[];
      final scheduled = <String>[];
      final controller = AppController(
        StorageService(),
        autoLoad: false,
        saveEvents: (events) async => stored.add([...events]),
        loadEvents: () async => const [],
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (value) async => scheduled.add(value.id),
        cancelNotification: (_) async {},
        syncWidget: (_, _) async {},
        timerFactory: (_, _) => _IdleTimer(),
      );
      final original = event('Past-5D');
      await controller.saveEvent(original);
      scheduled.clear();
      await controller.deleteEventWithUndo(original);
      await controller.undoLatest();

      expect(controller.state.events.single.id, original.id);
      expect(controller.state.pendingUndos, isEmpty);
      expect(stored.last.single.id, original.id);
      expect(scheduled, [original.id]);
      controller.dispose();
    });

    test(
      'yearly completion advances and undo restores original date',
      () async {
        final scheduled = <CountdownEvent>[];
        final controller = AppController(
          StorageService(),
          autoLoad: false,
          saveEvents: (_) async {},
          loadEvents: () async => const [],
          loadSettings: () async => const AppSettings(),
          saveSettings: (_) async {},
          scheduleNotification: (value) async => scheduled.add(value),
          cancelNotification: (_) async {},
          syncWidget: (_, _) async {},
          timerFactory: (_, _) => _IdleTimer(),
        );
        final original = event(
          'Yearly-Test',
          repeatType: EventRepeatType.yearly,
        );
        await controller.saveEvent(original);
        scheduled.clear();
        await controller.toggleCompletedWithUndo(original);

        final advanced = controller.state.events.single;
        expect(advanced.isCompleted, isFalse);
        expect(advanced.targetDate, DateTime(2027, 9, 1, 9));
        expect(scheduled.single.targetDate, advanced.targetDate);

        await controller.undoLatest();
        expect(controller.state.events.single.targetDate, original.targetDate);
        controller.dispose();
      },
    );

    test('toggle and clear completed can be undone in LIFO order', () async {
      final controller = AppController(
        StorageService(),
        autoLoad: false,
        saveEvents: (_) async {},
        loadEvents: () async => const [],
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (_) async {},
        cancelNotification: (_) async {},
        syncWidget: (_, _) async {},
        timerFactory: (_, _) => _IdleTimer(),
      );
      final first = event('Exam-30D');
      final second = event('Past-5D', completed: true);
      await controller.saveEvent(first);
      await controller.saveEvent(second);

      await controller.toggleCompletedWithUndo(first);
      expect(
        controller.state.events.every((value) => value.isCompleted),
        isTrue,
      );
      await controller.clearCompletedWithUndo();
      expect(controller.state.events, isEmpty);
      expect(controller.state.pendingUndos, hasLength(2));

      await controller.undoLatest();
      expect(controller.state.events, hasLength(2));
      expect(
        controller.state.events.every((value) => value.isCompleted),
        isTrue,
      );
      await controller.undoLatest();
      expect(
        controller.state.events
            .firstWhere((value) => value.id == first.id)
            .isCompleted,
        isFalse,
      );
      controller.dispose();
    });

    test('clear completed uses a longer undo window', () async {
      final durations = <Duration>[];
      final controller = AppController(
        StorageService(),
        autoLoad: false,
        loadEvents: () async => const [],
        saveEvents: (_) async {},
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (_) async {},
        cancelNotification: (_) async {},
        syncWidget: (_, _) async {},
        timerFactory: (duration, _) {
          durations.add(duration);
          return _IdleTimer();
        },
      );
      await controller.saveEvent(event('Done-1', completed: true));
      await controller.clearCompletedWithUndo();
      expect(durations.single, const Duration(seconds: 10));
      controller.dispose();
    });

    test('beforeWidgetSync runs before widget sync for widget completes', () async {
      final order = <String>[];
      final controller = AppController(
        StorageService(),
        autoLoad: false,
        saveEvents: (_) async => order.add('persist'),
        loadEvents: () async => const [],
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (_) async {},
        cancelNotification: (_) async {},
        syncWidget: (_, _) async => order.add('sync'),
        timerFactory: (_, _) => _IdleTimer(),
      );
      final original = event('Widget-Complete');
      await controller.saveEvent(original);
      order.clear();

      await controller.toggleCompletedWithUndo(
        original,
        beforeWidgetSync: (_) async => order.add('undo-payload'),
      );
      expect(order, ['persist', 'undo-payload', 'sync']);
      expect(controller.state.events.single.isCompleted, isTrue);
      controller.dispose();
    });

    test('clear all events hides, stores safely, and finalizes', () async {
      final stored = <List<CountdownEvent>>[];
      final cancelled = <String>[];
      final controller = AppController(
        StorageService(),
        autoLoad: false,
        saveEvents: (events) async => stored.add([...events]),
        loadEvents: () async => const [],
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (_) async {},
        cancelNotification: (id) async => cancelled.add(id),
        syncWidget: (_, _) async {},
        timerFactory: (_, _) => _IdleTimer(),
      );
      final first = event('A-Event');
      final second = event('B-Event');
      await controller.saveEvent(first);
      await controller.saveEvent(second);
      cancelled.clear();
      await controller.clearAllEventsWithUndo();
      expect(controller.state.events, isEmpty);
      expect(controller.state.pendingUndos, hasLength(1));
      expect(stored.last, hasLength(2));
      expect(cancelled, isEmpty);

      await controller.undoLatest();
      expect(controller.state.events, hasLength(2));
      expect(controller.state.pendingUndos, isEmpty);

      await controller.clearAllEventsWithUndo();
      await controller.finalizeUndo(controller.state.latestUndo!.id);
      expect(stored.last, isEmpty);
      expect(cancelled, containsAll([first.id, second.id]));
      controller.dispose();
    });

    test('import merges events by id and schedules reminders', () async {
      final stored = <List<CountdownEvent>>[];
      final scheduled = <String>[];
      final controller = AppController(
        StorageService(),
        autoLoad: false,
        saveEvents: (events) async => stored.add([...events]),
        loadEvents: () async => const [],
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (value) async => scheduled.add(value.id),
        cancelNotification: (_) async {},
        syncWidget: (_, _) async {},
        timerFactory: (_, _) => _IdleTimer(),
      );
      await controller.saveEvent(event('Keep-Id'));
      scheduled.clear();
      final updated = event('Keep-Id', reminderMinutes: 1440);
      final fresh = event('Fresh-Id');
      await controller.importEvents([updated, fresh]);

      expect(controller.state.events, hasLength(2));
      final kept = controller.state.events.firstWhere(
        (value) => value.id == 'Keep-Id',
      );
      expect(kept.reminders.single.minutesBefore, 1440);
      expect(scheduled, containsAll(['Keep-Id', 'Fresh-Id']));
      expect(stored.last, hasLength(2));
      controller.dispose();
    });
  });

  group('AppController update checks', () {
    UpdateCheckResult newerRelease(String version) => UpdateCheckResult(
      release: ReleaseInfo(version: version, url: 'https://example.com/$version'),
      isNewer: true,
    );

    AppController buildController({
      required List<String> calls,
      UpdateCheckResult? result,
      AppSettings settings = const AppSettings(),
      Map<String, Object> prefs = const {},
      Duration updateCheckInterval = const Duration(hours: 24),
    }) {
      SharedPreferences.setMockInitialValues(prefs);
      return AppController(
        StorageService(),
        autoLoad: false,
        loadEvents: () async => const [],
        saveEvents: (_) async {},
        loadSettings: () async => settings,
        saveSettings: (_) async {},
        scheduleNotification: (_) async {},
        cancelNotification: (_) async {},
        syncWidget: (_, _) async {},
        timerFactory: (_, _) => _IdleTimer(),
        updateCheckInterval: updateCheckInterval,
        checkUpdate: (version) async {
          calls.add(version);
          return result ?? newerRelease('9.9.9');
        },
      );
    }

    test('auto check surfaces newer release, then throttles', () async {
      final calls = <String>[];
      final controller = buildController(calls: calls);

      await controller.autoCheckForUpdate();
      expect(calls, hasLength(1));
      expect(controller.state.availableRelease?.version, '9.9.9');
      expect(await StorageService().loadLastUpdateCheckAt(), isNotNull);

      // 24 小时内再次检查直接跳过。
      await controller.autoCheckForUpdate();
      expect(calls, hasLength(1));
      controller.dispose();
    });

    test('auto check respects the toggle', () async {
      final calls = <String>[];
      final controller = buildController(calls: calls);
      await controller.updateSettings(
        const AppSettings(autoCheckUpdate: false),
      );

      await controller.autoCheckForUpdate();
      expect(calls, isEmpty);
      expect(controller.state.availableRelease, isNull);
      controller.dispose();
    });

    test('auto check stays quiet for skipped versions', () async {
      final calls = <String>[];
      final controller = buildController(
        calls: calls,
        prefs: {'skipped_release_version': '9.9.9'},
      );

      await controller.autoCheckForUpdate();
      expect(calls, hasLength(1));
      expect(controller.state.availableRelease, isNull);
      controller.dispose();
    });

    test('auto check re-runs once the interval has passed', () async {
      final calls = <String>[];
      final controller = buildController(
        calls: calls,
        updateCheckInterval: Duration.zero,
      );

      await controller.autoCheckForUpdate();
      await controller.autoCheckForUpdate();
      expect(calls, hasLength(2));
      controller.dispose();
    });

    test('manual check reports up-to-date without banner', () async {
      final calls = <String>[];
      final controller = buildController(
        calls: calls,
        result: UpdateCheckResult(
          release: const ReleaseInfo(
            version: '2.0.0',
            url: 'https://example.com/2.0.0',
          ),
        ),
      );

      final result = await controller.checkForUpdateNow();
      expect(result.isNewer, isFalse);
      expect(result.errorMessage, isNull);
      expect(controller.state.availableRelease, isNull);
      controller.dispose();
    });

    test('dismiss can skip the version for future auto checks', () async {
      final calls = <String>[];
      final controller = buildController(calls: calls);
      await controller.autoCheckForUpdate();
      expect(controller.state.availableRelease, isNotNull);

      await controller.dismissUpdateRelease(skipVersion: true);
      expect(controller.state.availableRelease, isNull);
      expect(
        await StorageService().loadSkippedReleaseVersion(),
        '9.9.9',
      );
      controller.dispose();
    });

    test('turning off auto check hides the banner', () async {
      final calls = <String>[];
      final controller = buildController(calls: calls);
      await controller.autoCheckForUpdate();
      expect(controller.state.availableRelease, isNotNull);

      await controller.updateSettings(
        const AppSettings(autoCheckUpdate: false),
      );
      expect(controller.state.availableRelease, isNull);
      controller.dispose();
    });
  });
}

class _IdleTimer implements Timer {
  bool _active = true;

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

