import 'package:flutter_test/flutter_test.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_group.dart';
import 'package:ying/services/database_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;
  final uuid = const Uuid();

  setUp(() async {
    db = DatabaseService();
    // 数据库会在第一次访问时自动创建
  });

  tearDown(() async {
    await db.close();
  });

  group('DatabaseService - Event CRUD', () {
    test('should insert and retrieve an event', () async {
      final event = CountdownEvent(
        id: uuid.v4(),
        title: 'Test Event',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertEvent(event);

      final events = await db.getAllEvents();
      expect(events.length, 1);
      expect(events.first.id, event.id);
      expect(events.first.title, event.title);
    });

    test('should update an existing event', () async {
      final event = CountdownEvent(
        id: uuid.v4(),
        title: 'Original Title',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertEvent(event);

      final updatedEvent = event.copyWith(
        title: 'Updated Title',
        updatedAt: DateTime.now(),
      );
      await db.updateEvent(updatedEvent);

      final events = await db.getAllEvents();
      expect(events.length, 1);
      expect(events.first.title, 'Updated Title');
    });

    test('should delete an event', () async {
      final event = CountdownEvent(
        id: uuid.v4(),
        title: 'To Be Deleted',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertEvent(event);
      expect((await db.getAllEvents()).length, 1);

      await db.deleteEvent(event.id);
      expect((await db.getAllEvents()).length, 0);
    });

    test('should filter events by archived status', () async {
      final activeEvent = CountdownEvent(
        id: uuid.v4(),
        title: 'Active Event',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: false,
      );

      final archivedEvent = CountdownEvent(
        id: uuid.v4(),
        title: 'Archived Event',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isArchived: true,
      );

      await db.insertEvent(activeEvent);
      await db.insertEvent(archivedEvent);

      final activeEvents = await db.getActiveEvents();
      final archivedEvents = await db.getArchivedEvents();

      expect(activeEvents.length, 1);
      expect(archivedEvents.length, 1);
      expect(activeEvents.first.id, activeEvent.id);
      expect(archivedEvents.first.id, archivedEvent.id);
    });

    test('should filter events by category', () async {
      final birthdayEvent = CountdownEvent(
        id: uuid.v4(),
        title: 'Birthday',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final workEvent = CountdownEvent(
        id: uuid.v4(),
        title: 'Work Deadline',
        targetDate: DateTime.now().add(const Duration(days: 14)),
        categoryId: 'work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertEvent(birthdayEvent);
      await db.insertEvent(workEvent);

      final birthdayEvents = await db.getEventsByCategory('birthday');
      expect(birthdayEvents.length, 1);
      expect(birthdayEvents.first.categoryId, 'birthday');
    });

    test('should search events by title and note', () async {
      final event1 = CountdownEvent(
        id: uuid.v4(),
        title: 'Important Meeting',
        note: 'Discuss project timeline',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'work',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final event2 = CountdownEvent(
        id: uuid.v4(),
        title: 'Birthday Party',
        note: 'Celebrate with friends',
        targetDate: DateTime.now().add(const Duration(days: 14)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertEvent(event1);
      await db.insertEvent(event2);

      final results = await db.searchEvents('Meeting');
      expect(results.length, 1);
      expect(results.first.title, 'Important Meeting');

      final noteResults = await db.searchEvents('project');
      expect(noteResults.length, 1);
      expect(noteResults.first.id, event1.id);
    });
  });

  group('DatabaseService - Group CRUD', () {
    test('should insert and retrieve groups', () async {
      final group = EventGroup(
        id: uuid.v4(),
        name: 'Personal',
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertGroup(group);

      final groups = await db.getAllGroups();
      expect(groups.length, greaterThanOrEqualTo(1));
      expect(groups.any((g) => g.id == group.id), true);
    });

    test('should update a group', () async {
      final group = EventGroup(
        id: uuid.v4(),
        name: 'Original Name',
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertGroup(group);

      final updatedGroup = group.copyWith(
        name: 'Updated Name',
        updatedAt: DateTime.now(),
      );
      await db.updateGroup(updatedGroup);

      final groups = await db.getAllGroups();
      final retrieved = groups.firstWhere((g) => g.id == group.id);
      expect(retrieved.name, 'Updated Name');
    });

    test('should delete a group', () async {
      final group = EventGroup(
        id: uuid.v4(),
        name: 'To Delete',
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertGroup(group);
      expect((await db.getAllGroups()).any((g) => g.id == group.id), true);

      await db.deleteGroup(group.id);
      expect((await db.getAllGroups()).any((g) => g.id == group.id), false);
    });
  });

  group('DatabaseService - Category CRUD', () {
    test('should retrieve default categories', () async {
      final categories = await db.getAllCategories();
      // 默认分类由 _seedDefaultCategories 创建
      expect(categories.length, greaterThanOrEqualTo(7));
    });

    test('should insert a custom category', () async {
      final customCategory = {
        'id': 'custom_test_${uuid.v4()}',
        'name': 'Custom Category',
        'icon': '⭐',
        'color': 0xFF123456,
        'isDefault': 0,
      };

      await db.insertCategory(customCategory);

      final categories = await db.getAllCategories();
      expect(categories.any((c) => c['id'] == customCategory['id']), true);
    });

    test('should delete only non-default categories', () async {
      final customId = 'custom_test_${uuid.v4()}';
      final customCategory = {
        'id': customId,
        'name': 'Custom Category',
        'icon': '⭐',
        'color': 0xFF123456,
        'isDefault': 0,
      };

      await db.insertCategory(customCategory);
      expect((await db.getAllCategories()).any((c) => c['id'] == customId), true);

      await db.deleteCategory(customId);
      expect((await db.getAllCategories()).any((c) => c['id'] == customId), false);
    });
  });

  group('DatabaseService - Reminder CRUD', () {
    test('should insert and retrieve reminders', () async {
      final event = CountdownEvent(
        id: uuid.v4(),
        title: 'Event with Reminder',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertEvent(event);

      final reminder = {
        'id': uuid.v4(),
        'eventId': event.id,
        'reminderDateTime': DateTime.now().add(const Duration(days: 5)).millisecondsSinceEpoch,
        'customMessage': '5 days left!',
      };

      await db.insertReminder(reminder);

      final reminders = await db.getReminders(event.id);
      expect(reminders.length, 1);
      expect(reminders.first['customMessage'], '5 days left!');
    });

    test('should delete all reminders for an event', () async {
      final event = CountdownEvent(
        id: uuid.v4(),
        title: 'Event with Multiple Reminders',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertEvent(event);

      await db.insertReminder({
        'id': uuid.v4(),
        'eventId': event.id,
        'reminderDateTime': DateTime.now().millisecondsSinceEpoch,
      });
      await db.insertReminder({
        'id': uuid.v4(),
        'eventId': event.id,
        'reminderDateTime': DateTime.now().millisecondsSinceEpoch,
      });

      expect((await db.getReminders(event.id)).length, 2);

      await db.deleteEventReminders(event.id);
      expect((await db.getReminders(event.id)).length, 0);
    });
  });

  group('DatabaseService - Backup & Restore', () {
    test('should export all data', () async {
      final event = CountdownEvent(
        id: uuid.v4(),
        title: 'Test Event',
        targetDate: DateTime.now().add(const Duration(days: 7)),
        categoryId: 'birthday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertEvent(event);

      final exported = await db.exportAllData();

      expect(exported.containsKey('events'), true);
      expect(exported.containsKey('categories'), true);
      expect(exported.containsKey('groups'), true);
      expect(exported.containsKey('reminders'), true);
      expect((exported['events'] as List).length, greaterThanOrEqualTo(1));
    });

    test('should import data and replace existing', () async {
      final eventId = uuid.v4();
      final data = {
        'version': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'events': [
          {
            'id': eventId,
            'title': 'Imported Event',
            'targetDate': DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
            'category': 'birthday',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          }
        ],
        'categories': [],
        'groups': [],
        'reminders': [],
      };

      await db.importAllData(data);

      final events = await db.getAllEvents();
      expect(events.any((e) => e.id == eventId), true);
    });
  });
}
