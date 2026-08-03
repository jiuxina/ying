import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/ui/event_card.dart';
import 'package:ying/ui/glass_ui.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  testWidgets('event card remains usable with 200 percent text scale', (
    tester,
  ) async {
    final event = CountdownEvent(
      id: 'Exam-30D',
      title: 'Exam-30D with a deliberately long title',
      targetDate: DateTime(2026, 8, 28),
      category: '学习',
      note: 'Notify-Test',
      createdAt: DateTime(2026, 7, 29),
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AccessibleAppearance(
          reduceTransparency: true,
          reduceMotion: true,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventCard(
              event: event,
              onOpen: () {},
              onEdit: () {},
              onToggle: () {},
              onDelete: () {},
              onTogglePinned: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Exam-30D'), findsOneWidget);
    expect(find.byTooltip('标记完成'), findsOneWidget);
  });

  testWidgets('system animation preference overrides app motion setting', (
    tester,
  ) async {
    late BuildContext leafContext;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AccessibleAppearance(
          reduceTransparency: false,
          reduceMotion: false,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Builder(
              builder: (context) {
                leafContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
        home: const SizedBox(),
      ),
    );

    expect(reduceMotionOf(leafContext), isTrue);
    expect(
      motionDuration(leafContext, const Duration(milliseconds: 200)),
      Duration.zero,
    );
  });
}
