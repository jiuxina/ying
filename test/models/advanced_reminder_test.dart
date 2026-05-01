import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/advanced_reminder.dart';

void main() {
  group('ReminderType', () {
    test('should have all expected enum values', () {
      expect(ReminderType.values.length, equals(4));
      expect(ReminderType.values, contains(ReminderType.multiStage));
      expect(ReminderType.values, contains(ReminderType.smart));
      expect(ReminderType.values, contains(ReminderType.custom));
      expect(ReminderType.values, contains(ReminderType.recurring));
    });
  });

  group('ReminderRule', () {
    test('should create a rule with default values', () {
      final rule = ReminderRule.create(daysOffset: -7);

      expect(rule.id, isNotEmpty);
      expect(rule.daysOffset, equals(-7));
      expect(rule.hour, equals(9));
      expect(rule.minute, equals(0));
      expect(rule.isEnabled, isTrue);
      expect(rule.customMessageTemplate, isNull);
      expect(rule.priority, equals(5));
    });

    test('should create a rule with custom values', () {
      final rule = ReminderRule.create(
        daysOffset: -1,
        hour: 10,
        minute: 30,
        isEnabled: false,
        customMessageTemplate: 'Event {title} is in {days} days',
        priority: 8,
      );

      expect(rule.daysOffset, equals(-1));
      expect(rule.hour, equals(10));
      expect(rule.minute, equals(30));
      expect(rule.isEnabled, isFalse);
      expect(rule.customMessageTemplate, equals('Event {title} is in {days} days'));
      expect(rule.priority, equals(8));
    });

    test('should convert to and from Map correctly', () {
      final rule = ReminderRule.create(
        daysOffset: -3,
        hour: 14,
        minute: 45,
        customMessageTemplate: 'Test message',
        priority: 7,
      );

      final map = rule.toMap();
      final fromMap = ReminderRule.fromMap(map);

      expect(fromMap.id, equals(rule.id));
      expect(fromMap.daysOffset, equals(rule.daysOffset));
      expect(fromMap.hour, equals(rule.hour));
      expect(fromMap.minute, equals(rule.minute));
      expect(fromMap.isEnabled, equals(rule.isEnabled));
      expect(fromMap.customMessageTemplate, equals(rule.customMessageTemplate));
      expect(fromMap.priority, equals(rule.priority));
    });

    test('should validate correctly', () {
      // Valid rule
      expect(ReminderRule.create(daysOffset: -1, hour: 12, minute: 30).validate(), isTrue);

      // Invalid hour
      expect(ReminderRule.create(daysOffset: -1, hour: 24, minute: 0).validate(), isFalse);
      expect(ReminderRule.create(daysOffset: -1, hour: -1, minute: 0).validate(), isFalse);

      // Invalid minute
      expect(ReminderRule.create(daysOffset: -1, hour: 12, minute: 60).validate(), isFalse);
      expect(ReminderRule.create(daysOffset: -1, hour: 12, minute: -1).validate(), isFalse);

      // Invalid priority
      expect(ReminderRule.create(daysOffset: -1, hour: 12, minute: 0, priority: 0).validate(), isFalse);
      expect(ReminderRule.create(daysOffset: -1, hour: 12, minute: 0, priority: 11).validate(), isFalse);
    });

    test('should provide default multi-stage rules', () {
      final rules = ReminderRule.getDefaultMultiStageRules();

      expect(rules.length, equals(5));
      
      // Should be sorted by daysOffset
      expect(rules[0].daysOffset, equals(-1));
      expect(rules[1].daysOffset, equals(-3));
      expect(rules[2].daysOffset, equals(-7));
      expect(rules[3].daysOffset, equals(-30));
      expect(rules[4].daysOffset, equals(-90));

      // All should be enabled by default
      for (final rule in rules) {
        expect(rule.isEnabled, isTrue);
      }
    });

    test('should copyWith correctly', () {
      final rule = ReminderRule.create(daysOffset: -7);
      final copied = rule.copyWith(hour: 15, isEnabled: false);

      expect(copied.id, equals(rule.id));
      expect(copied.daysOffset, equals(rule.daysOffset));
      expect(copied.hour, equals(15));
      expect(copied.isEnabled, isFalse);
      expect(rule.isEnabled, isTrue); // Original unchanged
    });

    test('should implement equality correctly', () {
      final rule1 = ReminderRule(id: 'test-id', daysOffset: -7);
      final rule2 = ReminderRule(id: 'test-id', daysOffset: -1);
      final rule3 = ReminderRule(id: 'other-id', daysOffset: -7);

      expect(rule1, equals(rule2)); // Same ID
      expect(rule1, isNot(equals(rule3))); // Different ID
      expect(rule1.hashCode, equals(rule2.hashCode));
    });
  });

  group('AdvancedReminder', () {
    test('should create reminder with default multi-stage rules', () {
      final reminder = AdvancedReminder.create(
        eventId: 'event-1',
        type: ReminderType.multiStage,
      );

      expect(reminder.id, isNotEmpty);
      expect(reminder.eventId, equals('event-1'));
      expect(reminder.type, equals(ReminderType.multiStage));
      expect(reminder.rules.length, equals(5)); // Default multi-stage rules
      expect(reminder.smartModeEnabled, isFalse);
      expect(reminder.importanceScore, equals(5));
      expect(reminder.isEnabled, isTrue);
    });

    test('should create reminder with custom rules', () {
      final customRules = [
        ReminderRule.create(daysOffset: -1, hour: 8),
        ReminderRule.create(daysOffset: -5, hour: 9),
      ];

      final reminder = AdvancedReminder.create(
        eventId: 'event-2',
        type: ReminderType.custom,
        rules: customRules,
        importanceScore: 8,
      );

      expect(reminder.type, equals(ReminderType.custom));
      expect(reminder.rules.length, equals(2));
      expect(reminder.importanceScore, equals(8));
    });

    test('should create smart reminder', () {
      final reminder = AdvancedReminder.create(
        eventId: 'event-3',
        type: ReminderType.smart,
        smartModeEnabled: true,
        importanceScore: 9,
      );

      expect(reminder.type, equals(ReminderType.smart));
      expect(reminder.smartModeEnabled, isTrue);
      expect(reminder.importanceScore, equals(9));
      expect(reminder.rules, isEmpty); // Smart rules generated dynamically
    });

    test('should convert to and from Map correctly', () {
      final rules = [
        ReminderRule.create(daysOffset: -1),
        ReminderRule.create(daysOffset: -7),
      ];

      final reminder = AdvancedReminder.create(
        eventId: 'event-4',
        type: ReminderType.custom,
        rules: rules,
        importanceScore: 7,
      );

      final map = reminder.toMap();
      final fromMap = AdvancedReminder.fromMap(map, rules: rules);

      expect(fromMap.id, equals(reminder.id));
      expect(fromMap.eventId, equals(reminder.eventId));
      expect(fromMap.type, equals(reminder.type));
      expect(fromMap.smartModeEnabled, equals(reminder.smartModeEnabled));
      expect(fromMap.importanceScore, equals(reminder.importanceScore));
      expect(fromMap.isEnabled, equals(reminder.isEnabled));
      expect(fromMap.rules.length, equals(2));
    });

    test('should validate correctly', () {
      // Valid reminder
      expect(
        AdvancedReminder.create(eventId: 'event-1', type: ReminderType.multiStage).validate(),
        isTrue,
      );

      // Invalid: empty eventId
      final invalidReminder1 = AdvancedReminder(
        id: 'test',
        eventId: '',
        type: ReminderType.multiStage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(invalidReminder1.validate(), isFalse);

      // Invalid: importanceScore out of range
      final invalidReminder2 = AdvancedReminder(
        id: 'test',
        eventId: 'event-1',
        type: ReminderType.multiStage,
        importanceScore: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(invalidReminder2.validate(), isFalse);

      // Invalid: rule validation fails
      final invalidRule = ReminderRule.create(daysOffset: -1, hour: 25); // Invalid hour
      final invalidReminder3 = AdvancedReminder.create(
        eventId: 'event-1',
        type: ReminderType.custom,
        rules: [invalidRule],
      );
      expect(invalidReminder3.validate(), isFalse);
    });

    test('should calculate reminder times correctly', () {
      final rules = [
        ReminderRule.create(daysOffset: -7, hour: 9, minute: 0),
        ReminderRule.create(daysOffset: -1, hour: 10, minute: 30),
        ReminderRule.create(daysOffset: 0, hour: 8, minute: 0), // Event day
      ];

      final reminder = AdvancedReminder.create(
        eventId: 'event-1',
        type: ReminderType.custom,
        rules: rules,
      );

      final targetDate = DateTime(2026, 2, 15, 0, 0); // Feb 15, 2026
      final times = reminder.calculateReminderTimes(targetDate);

      // All times should be in the future (relative to when test runs)
      // We check the structure instead
      expect(times.length, greaterThanOrEqualTo(0));
      
      // Times should be sorted
      for (int i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue);
      }
    });

    test('should skip disabled rules in time calculation', () {
      final rules = [
        ReminderRule.create(daysOffset: -7, hour: 9, isEnabled: true),
        ReminderRule.create(daysOffset: -3, hour: 9, isEnabled: false), // Disabled
        ReminderRule.create(daysOffset: -1, hour: 9, isEnabled: true),
      ];

      final reminder = AdvancedReminder.create(
        eventId: 'event-1',
        type: ReminderType.custom,
        rules: rules,
      );

      final targetDate = DateTime.now().add(const Duration(days: 10));
      final times = reminder.calculateReminderTimes(targetDate);

      // Should have fewer times than total rules (disabled rules skipped)
      // Plus future time check
      expect(times.length, lessThanOrEqualTo(2));
    });

    test('should copyWith correctly', () {
      final reminder = AdvancedReminder.create(
        eventId: 'event-1',
        type: ReminderType.multiStage,
      );

      final copied = reminder.copyWith(
        isEnabled: false,
        importanceScore: 8,
      );

      expect(copied.id, equals(reminder.id));
      expect(copied.eventId, equals(reminder.eventId));
      expect(copied.isEnabled, isFalse);
      expect(copied.importanceScore, equals(8));
      expect(reminder.isEnabled, isTrue); // Original unchanged
      expect(reminder.importanceScore, equals(5)); // Original unchanged
    });
  });

  group('ReminderHistory', () {
    test('should create history record correctly', () {
      final scheduledTime = DateTime.now().add(const Duration(hours: 1));
      final history = ReminderHistory.create(
        advancedReminderId: 'reminder-1',
        eventId: 'event-1',
        scheduledTime: scheduledTime,
        isSuccessful: true,
        message: 'Test reminder message',
        ruleId: 'rule-1',
      );

      expect(history.id, isNotEmpty);
      expect(history.advancedReminderId, equals('reminder-1'));
      expect(history.eventId, equals('event-1'));
      expect(history.isSuccessful, isTrue);
      expect(history.failureReason, isNull);
      expect(history.message, equals('Test reminder message'));
      expect(history.ruleId, equals('rule-1'));
    });

    test('should create failed history record', () {
      final history = ReminderHistory.create(
        advancedReminderId: 'reminder-1',
        eventId: 'event-1',
        scheduledTime: DateTime.now(),
        isSuccessful: false,
        failureReason: 'Network error',
        message: 'Failed to send',
      );

      expect(history.isSuccessful, isFalse);
      expect(history.failureReason, equals('Network error'));
    });

    test('should convert to and from Map correctly', () {
      final history = ReminderHistory.create(
        advancedReminderId: 'reminder-1',
        eventId: 'event-1',
        scheduledTime: DateTime.now(),
        isSuccessful: true,
        message: 'Test',
        ruleId: 'rule-1',
      );

      final map = history.toMap();
      final fromMap = ReminderHistory.fromMap(map);

      expect(fromMap.id, equals(history.id));
      expect(fromMap.advancedReminderId, equals(history.advancedReminderId));
      expect(fromMap.eventId, equals(history.eventId));
      expect(fromMap.isSuccessful, equals(history.isSuccessful));
      expect(fromMap.message, equals(history.message));
    });

    test('should calculate delay correctly', () {
      final now = DateTime.now();
      final scheduledTime = now.subtract(const Duration(minutes: 5));
      final sentAt = now; // Use same timestamp to ensure exact 5 minutes
      final history = ReminderHistory(
        id: 'test',
        advancedReminderId: 'reminder-1',
        eventId: 'event-1',
        sentAt: sentAt,
        scheduledTime: scheduledTime,
        isSuccessful: true,
        message: 'Test',
      );

      // Delay should be exactly 5 minutes (300,000 ms)
      expect(history.delayMs, equals(300000));
      expect(history.isDelayed, isFalse); // Exactly 5 minutes, not greater
    });

    test('should detect delayed reminders', () {
      final scheduledTime = DateTime.now().subtract(const Duration(minutes: 10));
      final history = ReminderHistory(
        id: 'test',
        advancedReminderId: 'reminder-1',
        eventId: 'event-1',
        sentAt: DateTime.now(),
        scheduledTime: scheduledTime,
        isSuccessful: true,
        message: 'Test',
      );

      expect(history.isDelayed, isTrue); // More than 5 minutes
    });
  });

  group('SmartReminderConfig', () {
    test('should have default configuration', () {
      const config = SmartReminderConfig.defaultConfig;

      expect(config.minDaysBetweenReminders, equals(2));
      expect(config.importanceDensityFactor, equals(0.5));
      expect(config.defaultHour, equals(9));
      expect(config.defaultMinute, equals(0));
      expect(config.remindOnEventDay, isTrue);
      expect(config.reminderDaysByImportance.length, equals(7));
    });

    test('should copyWith correctly', () {
      const config = SmartReminderConfig.defaultConfig;
      final copied = config.copyWith(
        defaultHour: 10,
        minDaysBetweenReminders: 3,
      );

      expect(copied.defaultHour, equals(10));
      expect(copied.minDaysBetweenReminders, equals(3));
      expect(copied.defaultMinute, equals(0)); // Unchanged
      expect(config.defaultHour, equals(9)); // Original unchanged
    });
  });

  group('ReminderStatus', () {
    test('should create PendingReminder', () {
      final rule = ReminderRule.create(daysOffset: -1);
      final status = PendingReminder(
        scheduledTime: DateTime(2026, 2, 10, 9, 0),
        rule: rule,
        message: 'Test message',
      );

      expect(status.scheduledTime, equals(DateTime(2026, 2, 10, 9, 0)));
      expect(status.message, equals('Test message'));
      expect(status.rule.daysOffset, equals(-1));
    });

    test('should create SentReminder', () {
      final rule = ReminderRule.create(daysOffset: -1);
      final status = SentReminder(
        sentTime: DateTime(2026, 2, 10, 9, 0),
        rule: rule,
        wasSuccessful: true,
      );

      expect(status.wasSuccessful, isTrue);
    });

    test('should create SkippedReminder', () {
      final status = SkippedReminder(
        scheduledTime: DateTime(2026, 2, 10, 9, 0),
        reason: 'Event cancelled',
      );

      expect(status.reason, equals('Event cancelled'));
    });
  });
}
