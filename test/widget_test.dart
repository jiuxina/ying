import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_reminder.dart';
import 'package:ying/models/event_repeat.dart';
import 'package:ying/models/event_sort_mode.dart';
import 'package:ying/services/notification_service.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/utils/event_date_utils.dart';
import 'package:ying/utils/event_query.dart';
import 'package:ying/utils/event_repeat_utils.dart';

void main() {
  group('AppSettings', () {
    test('keeps accessibility preferences backward compatible', () {
      final legacy = AppSettings.fromMap(const {});
      expect(legacy.reduceTransparency, isFalse);
      expect(legacy.reduceMotion, isFalse);

      final settings = legacy.copyWith(
        reduceTransparency: true,
        reduceMotion: true,
      );
      final restored = AppSettings.fromMap(settings.toMap());
      expect(restored.reduceTransparency, isTrue);
      expect(restored.reduceMotion, isTrue);
    });

    test('defaults auto update check on and round-trips the toggle', () {
      final legacy = AppSettings.fromMap(const {});
      expect(legacy.autoCheckUpdate, isTrue);

      final disabled = legacy.copyWith(autoCheckUpdate: false);
      final restored = AppSettings.fromMap(disabled.toMap());
      expect(restored.autoCheckUpdate, isFalse);
    });
  });

  group('CountdownEvent', () {
    test('calculates future countdown days', () {
      // 使用相对日期，避免 isCountingUp 内部取真实 DateTime.now() 时过期失效。
      final base = DateTime.now();
      final today = DateTime(base.year, base.month, base.day);
      final now = today.add(const Duration(hours: 20));
      final event = CountdownEvent(
        id: 'future',
        title: '考试',
        targetDate: today.add(const Duration(days: 5, hours: 9)),
        category: '学习',
        createdAt: now,
      );

      expect(event.dayDelta(now), 5);
      expect(event.isCountingUp, isFalse);
    });

    test('serializes and restores event list', () {
      final events = [
        CountdownEvent(
          id: 'past',
          title: '纪念日',
          targetDate: DateTime(2025, 7, 28),
          category: '纪念日',
          note: '第一年',
          direction: CountDirection.countup,
          reminders: const [
            EventReminder(id: 'day-before', minutesBefore: 1440),
            EventReminder(id: 'hour-before', minutesBefore: 60),
          ],
          createdAt: DateTime(2025, 7, 1),
        ),
      ];

      final restored = CountdownEvent.decodeList(
        CountdownEvent.encodeList(events),
      );
      expect(restored.single.title, '纪念日');
      expect(restored.single.note, '第一年');
      expect(restored.single.direction, CountDirection.countup);
      expect(restored.single.reminders.map((value) => value.minutesBefore), [
        1440,
        60,
      ]);
    });

    test('keeps legacy events timed and supports all-day reminder anchor', () {
      final legacy = CountdownEvent.fromJson({
        'id': 'legacy',
        'title': 'Exam-30D',
        'targetDate': '2026-08-28T16:30:00.000',
        'category': '学习',
        'createdAt': '2026-07-29T09:00:00.000',
      });
      expect(legacy.isAllDay, isFalse);
      expect(legacy.targetDate.hour, 16);
      expect(legacy.reminders, isEmpty);

      final allDay = legacy.copyWith(
        targetDate: DateTime(2026, 8, 28),
        isAllDay: true,
      );
      expect(allDay.reminderAnchor, DateTime(2026, 8, 28, 9));
      expect(
        (jsonDecode(jsonEncode(allDay.toJson()))
            as Map<String, dynamic>)['isAllDay'],
        isTrue,
      );
    });

    test('migrates legacy reminderMinutes into one reminder', () {
      final migrated = CountdownEvent.fromJson({
        'id': 'legacy-reminder',
        'title': 'Notify-Test',
        'targetDate': '2026-08-28T16:30:00.000',
        'category': '学习',
        'reminderMinutes': 1440,
        'createdAt': '2026-07-29T09:00:00.000',
      });
      expect(migrated.reminders, hasLength(1));
      expect(migrated.reminders.single.id, 'legacy-1440');
      expect(migrated.reminders.single.minutesBefore, 1440);
      expect(migrated.toJson().containsKey('reminderMinutes'), isFalse);
    });

    test('normalizes reminders by deduplicating, sorting and limiting', () {
      final normalized = EventReminder.normalize([
        for (final minutes in [30, 1440, 30, 60, 4320, 10080, 0])
          EventReminder(id: 'r-$minutes', minutesBefore: minutes),
      ]);
      expect(normalized, hasLength(5));
      expect(normalized.map((value) => value.minutesBefore), [
        10080,
        4320,
        1440,
        60,
        30,
      ]);
    });

    test('keeps old data unpinned and non-repeating', () {
      final legacy = CountdownEvent.fromJson({
        'id': 'legacy-v2',
        'title': 'Exam-30D',
        'targetDate': '2026-08-28T00:00:00.000',
        'category': '学习',
        'createdAt': '2026-07-29T09:00:00.000',
      });
      expect(legacy.isPinned, isFalse);
      expect(legacy.repeatType, EventRepeatType.none);
    });

    test('serializes yearly repeat and preserves original leap day', () {
      final event = CountdownEvent(
        id: 'leap',
        title: 'Leap-Test',
        targetDate: DateTime(2028, 2, 29),
        category: '其他',
        repeatType: EventRepeatType.yearly,
        repeatMonth: 2,
        repeatDay: 29,
        createdAt: DateTime(2026, 7, 29),
      );
      final restored = CountdownEvent.fromJson(event.toJson());
      expect(restored.repeatType, EventRepeatType.yearly);
      expect(restored.repeatMonth, 2);
      expect(restored.repeatDay, 29);
    });

    test('yearly repeat skips non-leap years and keeps timed hour', () {
      final event = CountdownEvent(
        id: 'leap-timed',
        title: 'Leap-Test',
        targetDate: DateTime(2028, 2, 29, 16, 30),
        category: '其他',
        repeatType: EventRepeatType.yearly,
        repeatMonth: 2,
        repeatDay: 29,
        createdAt: DateTime(2026, 7, 29),
      );
      expect(
        nextYearlyOccurrence(event, after: event.targetDate),
        DateTime(2032, 2, 29, 16, 30),
      );
      expect(isLeapYear(2100), isFalse);
      expect(isLeapYear(2000), isTrue);
    });

    test('filters and sorts pinned events deterministically', () {
      CountdownEvent item(
        String id, {
        String note = '',
        String category = '学习',
        bool pinned = false,
        bool completed = false,
        int days = 1,
      }) => CountdownEvent(
        id: id,
        title: id,
        targetDate: DateTime(2026, 7, 29).add(Duration(days: days)),
        category: category,
        note: note,
        isPinned: pinned,
        isCompleted: completed,
        createdAt: DateTime(2026, 7, 1).add(Duration(days: days)),
      );
      final events = [
        item('Far', note: 'Notify-Test', days: 20),
        item('Pinned', pinned: true, days: 30),
        item('Done', completed: true, days: 0),
      ];
      expect(queryEvents(events).map((value) => value.id), [
        'Pinned',
        'Far',
        'Done',
      ]);
      expect(queryEvents(events, searchText: 'notify').single.id, 'Far');
      expect(
        queryEvents(
          events,
          incompleteOnly: true,
          sortMode: EventSortMode.createdAt,
        ).map((value) => value.id),
        ['Pinned', 'Far'],
      );
    });

    test('generates stable distinct notification identifiers', () {
      final first = NotificationService.stableNotificationId('event', 'a');
      expect(first, NotificationService.stableNotificationId('event', 'a'));
      expect(
        first,
        isNot(NotificationService.stableNotificationId('event', 'b')),
      );
    });
  });

  group('event date shortcuts', () {
    test('calculates common shortcuts from local date', () {
      final now = DateTime(2026, 7, 29, 23, 30);
      expect(
        applyEventDateShortcut(EventDateShortcut.today, now: now),
        DateTime(2026, 7, 29),
      );
      expect(
        applyEventDateShortcut(EventDateShortcut.tomorrow, now: now),
        DateTime(2026, 7, 30),
      );
      expect(
        applyEventDateShortcut(EventDateShortcut.nextWeek, now: now),
        DateTime(2026, 8, 5),
      );
      expect(
        applyEventDateShortcut(EventDateShortcut.yearEnd, now: now),
        DateTime(2026, 12, 31),
      );
    });

    test('clamps next month to the destination month last day', () {
      expect(addCalendarMonth(DateTime(2025, 1, 31)), DateTime(2025, 2, 28));
      expect(addCalendarMonth(DateTime(2024, 1, 31)), DateTime(2024, 2, 29));
      expect(addCalendarMonth(DateTime(2026, 12, 31)), DateTime(2027, 1, 31));
    });
  });

  group('calendar day delta is DST safe', () {
    setUpAll(tz_data.initializeTimeZones);

    test('spring-forward day still counts one calendar day', () {
      final ny = tz.getLocation('America/New_York');
      final before = tz.TZDateTime(ny, 2026, 3, 7, 12);
      final after = tz.TZDateTime(ny, 2026, 3, 8, 12);
      expect(after.difference(before).inDays, 0, reason: '23h 本地差值是问题根源');
      expect(calendarDayDelta(before, after), 1);
    });

    test('fall-back day still counts one calendar day', () {
      final ny = tz.getLocation('America/New_York');
      final before = tz.TZDateTime(ny, 2026, 11, 1, 12);
      final after = tz.TZDateTime(ny, 2026, 11, 2, 12);
      expect(calendarDayDelta(before, after), 1);
    });

    test('CountdownEvent.dayDelta uses calendar days for DST zones', () {
      final ny = tz.getLocation('America/New_York');
      final event = CountdownEvent(
        id: 'dst-event',
        title: 'DST 事件',
        targetDate: tz.TZDateTime(ny, 2026, 3, 8, 9),
        category: '其他',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(event.dayDelta(tz.TZDateTime(ny, 2026, 3, 7, 12)), 1);
    });
  });

  group('storage robustness', () {
    test('invalid JSON falls back to an empty list', () async {
      SharedPreferences.setMockInitialValues({
        'countdown_events_v1': '{broken',
      });
      expect(await StorageService().loadEvents(), isEmpty);
    });

    test('non-array payload falls back to an empty list', () async {
      SharedPreferences.setMockInitialValues({
        'countdown_events_v1': '{"title":"oops"}',
      });
      expect(await StorageService().loadEvents(), isEmpty);
    });

    test('wrong field types fall back to an empty list', () async {
      SharedPreferences.setMockInitialValues({
        'countdown_events_v1': '[{"id": 1, "title": "bad"}]',
      });
      expect(await StorageService().loadEvents(), isEmpty);
    });
  });
}
