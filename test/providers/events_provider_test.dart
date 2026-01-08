import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_group.dart';
import 'package:ying/models/reminder.dart';

import 'package:ying/providers/events_provider.dart';
import 'package:ying/services/database_service.dart';

// Manual Mock
class MockDatabaseService implements DatabaseService {
  final List<CountdownEvent> _mockEvents = [];
  final List<CountdownEvent> _mockArchived = [];
  final List<EventGroup> _mockGroups = [];

  @override
  Future<Database> get database => throw UnimplementedError();

  @override
  Future<List<CountdownEvent>> getActiveEvents() async => [..._mockEvents];

  @override
  Future<List<CountdownEvent>> getArchivedEvents() async => [..._mockArchived];

  @override
  Future<void> insertEvent(CountdownEvent event) async {
    _mockEvents.add(event);
  }

  @override
  Future<void> updateEvent(CountdownEvent event) async {
    final index = _mockEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _mockEvents[index] = event;
    } else {
      // Check archived?
      final archIndex = _mockArchived.indexWhere((e) => e.id == event.id);
      if (archIndex != -1) _mockArchived[archIndex] = event;
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    _mockEvents.removeWhere((e) => e.id == id);
    _mockArchived.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<CountdownEvent>> getAllEvents() async => [..._mockEvents, ..._mockArchived];

  @override
  Future<List<CountdownEvent>> getEventsByCategory(String categoryId) async {
    return _mockEvents.where((e) => e.categoryId == categoryId).toList();
  }

  @override
  Future<List<CountdownEvent>> searchEvents(String query) async {
     return _mockEvents.where((e) => e.title.contains(query)).toList();
  }

  @override
  Future<List<EventGroup>> getAllGroups() async => [..._mockGroups];

  @override
  Future<void> insertGroup(EventGroup group) async {
    _mockGroups.add(group);
  }

  @override
  Future<void> updateGroup(EventGroup group) async {
    final index = _mockGroups.indexWhere((g) => g.id == group.id);
    if (index != -1) _mockGroups[index] = group;
  }

  @override
  Future<void> deleteGroup(String id) async {
    _mockGroups.removeWhere((g) => g.id == id);
  }

  // Category methods
  final List<Map<String, dynamic>> _mockCategories = [];

  @override
  Future<List<Map<String, dynamic>>> getAllCategories() async => [..._mockCategories];

  @override
  Future<void> insertCategory(Map<String, dynamic> category) async {
    _mockCategories.add(category);
  }

  @override
  Future<void> updateCategory(Map<String, dynamic> category) async {
    final index = _mockCategories.indexWhere((c) => c['id'] == category['id']);
    if (index != -1) _mockCategories[index] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _mockCategories.removeWhere((c) => c['id'] == id);
  }

  // Reminder methods
  final List<Map<String, dynamic>> _mockReminders = [];

  @override
  Future<List<Map<String, dynamic>>> getReminders(String eventId) async {
    return _mockReminders.where((r) => r['eventId'] == eventId).toList();
  }

  @override
  Future<void> insertReminder(Map<String, dynamic> reminder) async {
    _mockReminders.add(reminder);
  }

  @override
  Future<void> deleteReminder(String id) async {
    _mockReminders.removeWhere((r) => r['id'] == id);
  }

  @override
  Future<void> deleteEventReminders(String eventId) async {
    _mockReminders.removeWhere((r) => r['eventId'] == eventId);
  }

  // Backup methods
  @override
  Future<Map<String, dynamic>> exportAllData() async {
    return {};
  }

  @override
  Future<void> importAllData(Map<String, dynamic> data) async {}

  @override
  Future<void> close() async {}
}

void main() {
  late EventsProvider eventsProvider;
  late MockDatabaseService mockDb;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    
    // Mocking HomeWidget channel to prevent MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), (MethodCall methodCall) async {
        return true;
      });
    
    mockDb = MockDatabaseService();
    eventsProvider = EventsProvider(dbService: mockDb);
  });

  group('EventsProvider Tests', () {
    test('Should start with empty events', () async {
      await eventsProvider.init();
      expect(eventsProvider.events, isEmpty);
    });

    test('Should add event', () async {
      await eventsProvider.init();
      final now = DateTime.now();
      await eventsProvider.addEvent(
        title: 'New Event',
        targetDate: now.add(const Duration(days: 1)),
      );

      expect(eventsProvider.events.length, 1);
      expect(eventsProvider.events.first.title, 'New Event');
    });

    test('Should toggle pin', () async {
      await eventsProvider.init();
      await eventsProvider.addEvent(
        title: 'Event 1',
        targetDate: DateTime.now().add(const Duration(days: 5)),
      );
      
      final eventId = eventsProvider.events.first.id;
      expect(eventsProvider.events.first.isPinned, false);

      await eventsProvider.togglePin(eventId);
      expect(eventsProvider.events.first.isPinned, true);
      
      // Check sorting: Pinned should remain at top
      await eventsProvider.addEvent(
        title: 'Event 2',
        targetDate: DateTime.now().add(const Duration(days: 1)), // sooner, should be first if not pinned
      );
      
      // Currently: Event 1 (pinned, 5 days), Event 2 (unpinned, 1 day)
      // Sort order: Pinned first.
      expect(eventsProvider.events.first.id, eventId);
    });

    test('Should delete event', () async {
      await eventsProvider.init();
      await eventsProvider.addEvent(
        title: 'To Delete',
        targetDate: DateTime.now(),
      );
      
      expect(eventsProvider.events.length, 1);
      final id = eventsProvider.events.first.id;
      
      await eventsProvider.deleteEvent(id);
      expect(eventsProvider.events, isEmpty);
    });

    test('Should add event with reminders', () async {
      await eventsProvider.init();
      await eventsProvider.addEvent(
        title: 'Reminder Event',
        targetDate: DateTime.now().add(const Duration(days: 1)),
        reminders: [
          Reminder.create(eventId: 'temp', daysBefore: 1, hour: 9, minute: 0),
        ],
      );

      final event = eventsProvider.events.first;
      // Database check
      final dbReminders = await mockDb.getReminders(event.id);
      expect(dbReminders.length, 1);
      
      // Local check (if reload happened or if local update logic is perfect)
      // Since addEvent adds the event object passed to it, and that object had reminders (with temp ID), 
      // the local object should have 1 reminder.
      expect(event.reminders.length, 1);
      
      // Verify reminder saved in DB has correct eventId
      expect(dbReminders.first['eventId'], event.id);
    });
  });
}
