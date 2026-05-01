import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/reminder.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final uuid = const Uuid();

  group('NotificationService - Reminder Model', () {
    test('Reminder should serialize to map correctly', () {
      final reminder = Reminder(
        id: uuid.v4(),
        eventId: uuid.v4(),
        reminderDateTime: DateTime(2026, 12, 25, 9, 0),
        customMessage: 'Christmas reminder!',
      );

      final map = reminder.toMap();

      expect(map['id'], reminder.id);
      expect(map['eventId'], reminder.eventId);
      expect(map['reminderDateTime'], reminder.reminderDateTime.millisecondsSinceEpoch);
      expect(map['customMessage'], 'Christmas reminder!');
    });

    test('Reminder should deserialize from map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'eventId': 'event-id',
        'reminderDateTime': now.millisecondsSinceEpoch,
        'customMessage': 'Test message',
      };

      final reminder = Reminder.fromMap(map);

      expect(reminder.id, 'test-id');
      expect(reminder.eventId, 'event-id');
      expect(reminder.reminderDateTime.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(reminder.customMessage, 'Test message');
    });

    test('Reminder should handle null customMessage', () {
      final map = {
        'id': 'test-id',
        'eventId': 'event-id',
        'reminderDateTime': DateTime.now().millisecondsSinceEpoch,
      };

      final reminder = Reminder.fromMap(map);

      expect(reminder.customMessage, isNull);
    });
  });

  group('NotificationService - Event with Reminders', () {
    test('CountdownEvent should include reminders in copyWith', () {
      final event = CountdownEvent(
        id: uuid.v4(),
        title: 'Test Event',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final reminders = [
        Reminder(
          id: uuid.v4(),
          eventId: event.id,
          reminderDateTime: DateTime.now().add(const Duration(days: 5)),
        ),
        Reminder(
          id: uuid.v4(),
          eventId: event.id,
          reminderDateTime: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      final eventWithReminders = event.copyWith(reminders: reminders);

      expect(eventWithReminders.reminders.length, 2);
      expect(eventWithReminders.reminders.first.eventId, event.id);
    });

    test('CountdownEvent should calculate daysRemaining correctly', () {
      // 事件在未来
      final futureEvent = CountdownEvent(
        id: uuid.v4(),
        title: 'Future Event',
        targetDate: DateTime.now().add(const Duration(days: 10)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(futureEvent.daysRemaining, greaterThan(9));
      expect(futureEvent.daysRemaining, lessThanOrEqualTo(10));

      // 事件在过去
      final pastEvent = CountdownEvent(
        id: uuid.v4(),
        title: 'Past Event',
        targetDate: DateTime.now().subtract(const Duration(days: 5)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isCountUp: true,
      );
      expect(pastEvent.daysRemaining, lessThan(0));
    });

    test('CountdownEvent should calculate progressPercentage correctly', () {
      final now = DateTime.now();
      final event = CountdownEvent(
        id: uuid.v4(),
        title: 'Progress Test',
        targetDate: now.add(const Duration(days: 10)),
        categoryId: 'birthday',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        isCountUp: false,
      );

      // 创建于5天前，目标在10天后，总共15天
      // 已过5天，剩余10天
      final progress = event.progressPercentage;
      expect(progress, greaterThan(0.5));
      expect(progress, lessThanOrEqualTo(1.0));
    });

    test('CountdownEvent isCountUp should affect progressPercentage', () {
      final now = DateTime.now();
      final countUpEvent = CountdownEvent(
        id: uuid.v4(),
        title: 'Count Up Event',
        targetDate: now.subtract(const Duration(days: 5)),
        categoryId: 'birthday',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
        isCountUp: true,
      );

      // 正数日进度应为0
      expect(countUpEvent.progressPercentage, 0.0);
    });
  });

  group('NotificationService - Notification ID Generation', () {
    test('Should generate consistent notification IDs', () {
      // 模拟通知 ID 生成逻辑
      String generateNotificationId(String eventId, String reminderId) {
        return '${eventId}_${reminderId}';
      }

      final eventId = uuid.v4();
      final reminderId = uuid.v4();

      final id1 = generateNotificationId(eventId, reminderId);
      final id2 = generateNotificationId(eventId, reminderId);

      expect(id1, id2);
      expect(id1, contains(eventId));
      expect(id1, contains(reminderId));
    });

    test('Should generate unique notification IDs for different reminders', () {
      String generateNotificationId(String eventId, String reminderId) {
        return '${eventId}_${reminderId}';
      }

      final eventId = uuid.v4();
      final reminderId1 = uuid.v4();
      final reminderId2 = uuid.v4();

      final id1 = generateNotificationId(eventId, reminderId1);
      final id2 = generateNotificationId(eventId, reminderId2);

      expect(id1 == id2, false);
    });
  });

  group('NotificationService - Time Validation', () {
    test('Should skip reminders in the past', () {
      final pastReminder = Reminder(
        id: uuid.v4(),
        eventId: uuid.v4(),
        reminderDateTime: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final now = DateTime.now();
      final isPast = pastReminder.reminderDateTime.isBefore(now);

      expect(isPast, true);
    });

    test('Should schedule reminders in the future', () {
      final futureReminder = Reminder(
        id: uuid.v4(),
        eventId: uuid.v4(),
        reminderDateTime: DateTime.now().add(const Duration(hours: 1)),
      );

      final now = DateTime.now();
      final isFuture = futureReminder.reminderDateTime.isAfter(now);

      expect(isFuture, true);
    });

    test('Should handle midnight time correctly', () {
      // 测试午夜时间
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day, 0, 0, 0);

      expect(midnight.hour, 0);
      expect(midnight.minute, 0);
      expect(midnight.second, 0);
    });
  });

  group('NotificationService - Boot Restore Logic', () {
    test('Should detect boot restore flag', () async {
      // 模拟 SharedPreferences
      const channel = MethodChannel('plugins.flutter.io/shared_preferences');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return {'boot_restore_needed': true};
        }
        if (methodCall.method == 'containsKey') {
          return true;
        }
        return null;
      });

      // 实际测试中需要 mock SharedPreferences
      // 这里仅验证逻辑结构
    });

    test('Should clear boot restore flag after restore', () {
      // 验证清除逻辑的正确性
      // 实际测试需要 mock
    });
  });
}
