import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/app_theme.dart';
import 'package:ying/ui/calendar_page.dart';
import 'package:ying/ui/event_card.dart';
import 'package:ying/ui/event_filter_bar.dart';
import 'package:ying/ui/glass_ui.dart';
import 'package:ying/ui/home_page.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  void phoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  AppController buildController() {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    return AppController(
      StorageService(),
      autoLoad: false,
      loadEvents: () async => [
        CountdownEvent(
          id: 'evt-a',
          title: '考试',
          targetDate: now.add(const Duration(days: 3)),
          category: '学习',
          createdAt: now,
        ),
        CountdownEvent(
          id: 'evt-b',
          title: '旅行',
          targetDate: now.add(const Duration(days: 9)),
          category: '生活',
          createdAt: now,
        ),
      ],
      saveEvents: (_) async {},
      loadSettings: () async => const AppSettings(),
      saveSettings: (_) async {},
      scheduleNotification: (_) async {},
      cancelNotification: (_) async {},
      syncWidget: (_, _) async {},
      timerFactory: (_, _) => _IdleTimer(),
    );
  }

  Widget buildHome(AppController controller) {
    return ProviderScope(
      overrides: [appControllerProvider.overrideWith((ref) => controller)],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => AccessibleAppearance(
          reduceTransparency: true,
          reduceMotion: true,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const HomePage(),
      ),
    );
  }

  testWidgets('顶栏只在日子 Tab 显示', (tester) async {
    phoneViewport(tester);
    final controller = buildController();
    await controller.load(runAutoCheck: false);
    await tester.pumpWidget(buildHome(controller));
    await tester.pumpAndSettle();

    expect(find.byTooltip('设置'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    expect(find.byTooltip('设置'), findsNothing);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.text('日历'), findsWidgets);

    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pumpAndSettle();
    expect(find.byTooltip('设置'), findsOneWidget);
  });

  testWidgets('筛选栏横滑切换 Tab，事件卡片横滑不切换', (tester) async {
    phoneViewport(tester);
    final controller = buildController();
    await controller.load(runAutoCheck: false);
    await tester.pumpWidget(buildHome(controller));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(EventFilterBar),
      const Offset(-300, 0),
      1000,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('设置'), findsNothing);

    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byType(EventCard).first,
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('设置'), findsOneWidget);
  });

  testWidgets('下拉刷新时事件卡片下滑而筛选栏固定', (tester) async {
    phoneViewport(tester);
    final controller = buildController();
    await controller.load(runAutoCheck: false);
    await tester.pumpWidget(buildHome(controller));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byType(EventFilterBar),
        matching: find.byType(RefreshIndicator),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(
        of: find.byType(EventCard).first,
        matching: find.byType(RefreshIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('日历月视图网格横滑翻月，标题区横滑切 Tab', (tester) async {
    phoneViewport(tester);
    final controller = buildController();
    await controller.load(runAutoCheck: false);
    await tester.pumpWidget(buildHome(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1);
    expect(find.textContaining('${now.year}年'), findsWidgets);

    await tester.fling(
      find.byKey(const ValueKey('calendar-month-grid')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('设置'), findsNothing);
    expect(find.textContaining('${next.year}年${next.month}月'), findsOneWidget);

    await tester.flingFrom(
      const Offset(210, 24),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('设置'), findsOneWidget);
  });

  testWidgets('日历年视图网格横滑翻年', (tester) async {
    phoneViewport(tester);
    final controller = buildController();
    await controller.load(runAutoCheck: false);
    await tester.pumpWidget(buildHome(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('年'));
    await tester.pumpAndSettle();
    final year = DateTime.now().year;
    expect(find.text('$year 年'), findsOneWidget);

    await tester.fling(
      find.byKey(ValueKey('calendar-year-grid-$year')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('${year + 1} 年'), findsOneWidget);
  });
}

class _IdleTimer implements Timer {
  bool _active = true;

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}
