import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_group.dart';
import 'package:ying/providers/events_provider.dart';
import 'package:ying/providers/settings_provider.dart';
import 'package:ying/services/database_service.dart';
import 'package:ying/widgets/event_card.dart';

// Simple Mock DB for EventsProvider
class MockDatabaseService implements DatabaseService {
  @override
  Future<List<Map<String, dynamic>>> getAllCategories() async => [];
  
  @override
  Future<List<CountdownEvent>> getActiveEvents() async => [];
  
  @override
  Future<List<CountdownEvent>> getArchivedEvents() async => [];
  
  @override
  Future<List<EventGroup>> getAllGroups() async => [];
  
  // Implement other required overrides with dummy returns
  @override Future<Database> get database => throw UnimplementedError();
  @override Future<void> close() async {}
  @override Future<void> deleteCategory(String id) async {}
  @override Future<void> deleteEvent(String id) async {}
  @override Future<void> deleteGroup(String id) async {}
  @override Future<List<CountdownEvent>> getAllEvents() async => [];
  @override Future<List<CountdownEvent>> getEventsByCategory(String category) async => [];
  @override Future<void> insertCategory(Map<String, dynamic> category) async {}
  @override Future<void> insertEvent(CountdownEvent event) async {}
  @override Future<void> insertGroup(EventGroup group) async {}
  @override Future<List<CountdownEvent>> searchEvents(String query) async => [];
  @override Future<void> updateCategory(Map<String, dynamic> category) async {}
  @override Future<void> updateEvent(CountdownEvent event) async {}
  @override Future<void> updateGroup(EventGroup group) async {}

  // Reminders
  @override Future<List<Map<String, dynamic>>> getReminders(String eventId) async => [];
  @override Future<void> insertReminder(Map<String, dynamic> reminder) async {}
  @override Future<void> deleteReminder(String id) async {}
  @override Future<void> deleteEventReminders(String eventId) async {}

  // Backup
  @override Future<Map<String, dynamic>> exportAllData() async => {};
  @override Future<void> importAllData(Map<String, dynamic> data) async {}
}

void main() {
  late SettingsProvider settingsProvider;
  late EventsProvider eventsProvider;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mocking FlutterSecureStorage channel
    const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, (MethodCall methodCall) async {
        return null; // Return null (empty) for read/write
      });

    // Mocking HomeWidget channel just in case
    const homeWidgetChannel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(homeWidgetChannel, (MethodCall methodCall) async {
        return true; 
      });

    SharedPreferences.setMockInitialValues({});
    settingsProvider = SettingsProvider();
    await settingsProvider.init();

    eventsProvider = EventsProvider(dbService: MockDatabaseService());
    // No need to await init for basic category lookup as it has defaults if list is empty
  });

  testWidgets('EventCard should render title and days', (WidgetTester tester) async {
    final now = DateTime.now();
    final target = now.add(const Duration(days: 3));
    
    final event = CountdownEvent(
      id: '1',
      title: 'Birthday Party',
      targetDate: target,
      categoryId: 'birthday',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
              ChangeNotifierProvider<EventsProvider>.value(value: eventsProvider),
            ],
            child: EventCard(event: event),
          ),
        ),
      ),
    );

    // Verify title is shown
    expect(find.text('Birthday Party'), findsOneWidget);
    
    // Verify days are shown (3)
    expect(find.text('3'), findsOneWidget);
    
    // Verify "Days" label
    expect(find.text('天'), findsOneWidget);
  });

  testWidgets('EventCard onTap callback', (WidgetTester tester) async {
    bool tapped = false;
    final event = CountdownEvent(
      id: '1',
      title: 'Tap Me',
      targetDate: DateTime.now(),
      categoryId: 'work',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
              ChangeNotifierProvider<EventsProvider>.value(value: eventsProvider),
            ],
            child: EventCard(
              event: event,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EventCard));
    await tester.pumpAndSettle(); 
    
    expect(tapped, true);
  });
}
