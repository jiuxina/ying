import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ying/providers/events_provider.dart';
import 'package:ying/providers/settings_provider.dart';
import 'package:ying/screens/add_edit_event_screen.dart';
import '../helpers/mocks.dart';

void main() {
  late MockDatabaseService mockDb;
  late EventsProvider eventsProvider;
  late SettingsProvider settingsProvider;

  setUp(() async {
    setupChannelMocks();
    mockDb = MockDatabaseService();
    eventsProvider = EventsProvider(dbService: mockDb);
    settingsProvider = SettingsProvider();
    await settingsProvider.init();
    await eventsProvider.init();
  });

  testWidgets('AddEvent - Happy Path: Enter title and save', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: eventsProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const MaterialApp(home: AddEditEventScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Find Title and Enter text
    final titleField = find.byKey(const Key('event_title_input'));
    expect(titleField, findsOneWidget);
    await tester.enterText(titleField, 'Automated Test Event');
    await tester.pumpAndSettle();

    // Scroll to bottom
    final scrollable = find.byType(SingleChildScrollView);
    await tester.drag(scrollable, const Offset(0, -1000));
    await tester.pumpAndSettle();

    // Find Save Button
    final saveButton = find.byKey(const Key('save_event_button'));
    expect(saveButton, findsOneWidget);

    // Tap
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify DB
    final events = await mockDb.getActiveEvents();
    expect(events.length, 1);
    expect(events.first.title, 'Automated Test Event');
  });

  testWidgets('AddEvent - Validation: Empty title shows error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<EventsProvider>.value(value: eventsProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
        ],
        child: const MaterialApp(home: AddEditEventScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Find Save Button and Tap
    final saveButton = find.byKey(const Key('save_event_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Error Message
    final titleField = find.byKey(const Key('event_title_input'));
    await tester.ensureVisible(titleField);
    await tester.pumpAndSettle();
    expect(find.text('请输入事件名称'), findsOneWidget);

    // Verify DB is empty
    final events = await mockDb.getActiveEvents();
    expect(events.length, 0);
  });
}
