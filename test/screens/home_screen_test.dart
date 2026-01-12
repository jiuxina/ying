import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/providers/events_provider.dart';
import 'package:ying/providers/settings_provider.dart';
import 'package:ying/screens/home_screen.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/widgets/common/expandable_fab.dart';
import '../helpers/mocks.dart';

void main() {
  late MockDatabaseService mockDb;
  late EventsProvider eventsProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    
    setupChannelMocks();

    mockDb = MockDatabaseService();
    eventsProvider = EventsProvider(dbService: mockDb);
    settingsProvider = SettingsProvider();
    await settingsProvider.init();
    // EventsProvider init is called in HomeScreen RefreshIndicator or manually
    // For test stability we can init it manually or let the widget doing it if it does in initState/didChangeDependencies
    // HomeScreen calls provider.init() in RefreshIndicator, but also normally triggered?
    // EventsProvider doesn't auto-init in constructor.
    // However HomeScreen builds _buildBody.
    // If we want events to be loaded, we should call init.
  });

  testWidgets('HomeScreen renders empty state when no events', (WidgetTester tester) async {
    // Ensure provider is initialized with empty list
    await eventsProvider.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: eventsProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    
    // Allow FutureBuilder/Init to complete
    await tester.pumpAndSettle();

    expect(find.text('还没有事件'), findsOneWidget);
    expect(find.text('点击右下角按钮添加第一个倒数日'), findsOneWidget);
  });

  testWidgets('HomeScreen renders event list when events exist', (WidgetTester tester) async {
    // Add dummy event
    final event = CountdownEvent(
      id: '1',
      title: 'Test Event',
      targetDate: DateTime.now().add(const Duration(days: 10)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await mockDb.insertEvent(event);
    await eventsProvider.init(); // Reload from mockDb

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: eventsProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Event'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // Days
  });

  testWidgets('HomeScreen has FAB with actions', (WidgetTester tester) async {
    await eventsProvider.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: eventsProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify FAB exists
    // Verify FAB exists (ExpandableFab)
    expect(find.byType(ExpandableFab), findsOneWidget);
    
    // Verify Main Icon (initially maybe generic or based on state)
    // ExpandableFab uses icons.
    expect(find.byIcon(Icons.add), findsWidgets); 
  });
}
