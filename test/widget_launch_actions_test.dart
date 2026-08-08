import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ying/app_navigator.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/services/widget_launch_actions.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/event_detail_page.dart';
import 'package:ying/ui/event_form_sheet.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(
            (ref) => AppController(
              StorageService(),
              loadEvents: () async => [
                CountdownEvent(
                  id: 'open-me',
                  title: '考试',
                  targetDate: DateTime(2026, 9, 1),
                  category: '学习',
                  createdAt: DateTime(2026, 8, 1),
                ),
              ],
              loadSettings: () async => const AppSettings(),
              autoLoad: false,
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('ying://add opens new event sheet', (tester) async {
    await pumpApp(tester);

    await handleWidgetLaunchUri(Uri.parse('ying://add'));
    await tester.pumpAndSettle();

    expect(find.byType(EventFormSheet), findsOneWidget);
    expect(find.text('新建日子'), findsOneWidget);
  });

  testWidgets('duplicate widget launch URI opens one sheet', (tester) async {
    await pumpApp(tester);

    final uri = Uri.parse('ying://add?dup=1');
    await handleWidgetLaunchUri(uri);
    await handleWidgetLaunchUri(uri);
    await tester.pumpAndSettle();

    expect(find.byType(EventFormSheet), findsOneWidget);
  });

  testWidgets('foreign scheme is ignored', (tester) async {
    await pumpApp(tester);

    await handleWidgetLaunchUri(Uri.parse('https://example.com'));
    await tester.pumpAndSettle();

    expect(find.byType(EventFormSheet), findsNothing);
    expect(find.byType(EventDetailPage), findsNothing);
  });

  testWidgets('ying://open pushes event detail page', (tester) async {
    await pumpApp(tester);

    await handleWidgetLaunchUri(Uri.parse('ying://open?id=open-me'));
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailPage), findsOneWidget);
  });
}
