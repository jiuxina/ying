import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_reminder.dart';
import 'package:ying/models/event_repeat.dart';
import 'package:ying/services/storage_service.dart';
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
