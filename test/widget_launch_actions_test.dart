import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/app_navigator.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/services/widget_launch_actions.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/event_detail_page.dart';
import 'package:ying/ui/event_form_sheet.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(
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
      syncWidget: (_, _) async {},
      autoLoad: false,
    );
    await controller.load(runAutoCheck: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
  }

  test('pruneWidgetLaunchUris keeps newest entries within capacity', () {
    final source = {
      for (var index = 0; index < 70; index++) 'uri-$index': index,
    };
    final pruned = pruneWidgetLaunchUris(source);
    expect(pruned.length, widgetLaunchDedupeCapacity);
    expect(pruned.containsKey('uri-0'), isFalse);
    expect(pruned.containsKey('uri-69'), isTrue);
  });

  testWidgets('ying://add opens new event sheet', (tester) async {
    await pumpApp(tester);

    unawaited(handleWidgetLaunchUri(Uri.parse('ying://add')));
    await tester.pumpAndSettle();

    expect(find.byType(EventFormSheet), findsOneWidget);
    expect(find.text('新建日子'), findsOneWidget);
  });

  testWidgets('legacy ying://new opens new event sheet', (tester) async {
    await pumpApp(tester);

    unawaited(handleWidgetLaunchUri(Uri.parse('ying://new')));
    await tester.pumpAndSettle();

    expect(find.byType(EventFormSheet), findsOneWidget);
  });

  testWidgets('duplicate widget launch URI opens one sheet', (tester) async {
    await pumpApp(tester);

    final uri = Uri.parse('ying://add?dup=1');
    unawaited(handleWidgetLaunchUri(uri));
    unawaited(handleWidgetLaunchUri(uri));
    await tester.pumpAndSettle();

    expect(find.byType(EventFormSheet), findsOneWidget);
  });

  testWidgets('foreign scheme is ignored', (tester) async {
    await pumpApp(tester);

    unawaited(handleWidgetLaunchUri(Uri.parse('https://example.com')));
    await tester.pumpAndSettle();

    expect(find.byType(EventFormSheet), findsNothing);
    expect(find.byType(EventDetailPage), findsNothing);
  });

  testWidgets('ying://open and legacy event host push detail page', (
    tester,
  ) async {
    await pumpApp(tester);

    unawaited(handleWidgetLaunchUri(Uri.parse('ying://open?id=open-me')));
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailPage), findsOneWidget);
  });

  testWidgets('legacy ying://event host opens event detail page', (tester) async {
    await pumpApp(tester);

    unawaited(handleWidgetLaunchUri(Uri.parse('ying://event?id=open-me')));
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailPage), findsOneWidget);
  });

  testWidgets('gives up retrying when navigator is never mounted', (
    tester,
  ) async {
    final future = handleWidgetLaunchUri(Uri.parse('ying://add'));
    await tester.pump(
      const Duration(milliseconds: widgetLaunchMaxRetries * 50 + 100),
    );
    await future;
    expect(find.byType(EventFormSheet), findsNothing);
  });
}
