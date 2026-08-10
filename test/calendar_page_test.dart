import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_repeat.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/app_theme.dart';
import 'package:ying/ui/calendar_page.dart';
import 'package:ying/ui/glass_ui.dart';
import 'package:ying/utils/calendar_occurrences.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  test('月视图包含目标日与每年重复，闰日跳过非闰年', () {
    final base = DateTime(2026, 8, 9);
    final yearly = CountdownEvent(
      id: 'yearly',
      title: '生日',
      targetDate: DateTime(2025, 8, 9, 9),
      category: '生活',
      repeatType: EventRepeatType.yearly,
      repeatMonth: 8,
      repeatDay: 9,
      createdAt: base,
    );
    final once = CountdownEvent(
      id: 'once',
      title: '考试',
      targetDate: DateTime(2026, 8, 20, 9),
      category: '学习',
      createdAt: base,
    );
    final feb29 = CountdownEvent(
      id: 'feb29',
      title: '闰日',
      targetDate: DateTime(2024, 2, 29),
      category: '生活',
      repeatType: EventRepeatType.yearly,
      repeatMonth: 2,
      repeatDay: 29,
      createdAt: base,
    );

    final august2026 = calendarOccurrencesForMonth([
      yearly,
      once,
      feb29,
    ], DateTime(2026, 8));
    expect(august2026, hasLength(2));

    expect(calendarOccurrencesForMonth([feb29], DateTime(2027, 2)), isEmpty);
    expect(
      calendarOccurrencesForMonth([feb29], DateTime(2028, 2)),
      hasLength(1),
    );
  });

  test('列表视图每个事件按当前目标日期出现一次', () {
    final base = DateTime(2026, 8, 9);
    final yearly = CountdownEvent(
      id: 'yearly',
      title: '生日',
      targetDate: DateTime(2026, 8, 9, 9),
      category: '生活',
      repeatType: EventRepeatType.yearly,
      repeatMonth: 8,
      repeatDay: 9,
      createdAt: base,
    );
    final agenda = calendarOccurrencesForAgenda([yearly]);
    expect(agenda, hasLength(1));
    expect(agenda.single.date, DateTime(2026, 8, 9));
  });

  group('日历页', () {
    void phoneViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    AppController buildController(List<CountdownEvent> events) {
      return AppController(
        StorageService(),
        autoLoad: false,
        loadEvents: () async => events,
        saveEvents: (_) async {},
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (_) async {},
        cancelNotification: (_) async {},
        syncWidget: (_, _) async {},
        timerFactory: (_, _) => _IdleTimer(),
      );
    }

    Widget buildCalendar(AppController controller) {
      return ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => AccessibleAppearance(
            reduceTransparency: true,
            reduceMotion: true,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: CalendarPage()),
        ),
      );
    }

    Future<AppController> readyController(List<CountdownEvent> events) async {
      SharedPreferences.setMockInitialValues({});
      final controller = buildController(events);
      await controller.load(runAutoCheck: false);
      return controller;
    }

    DateTime currentMonthDay(DateTime now, {int offset = 5}) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      var day = now.day + offset;
      if (day > daysInMonth) day = daysInMonth;
      if (day == now.day && day > 1) day -= 1;
      if (day == now.day && day == 1 && daysInMonth > 1) day = 2;
      return DateTime(now.year, now.month, day);
    }

    testWidgets('月视图选中目标日期并展示事件，点事件进入详情', (tester) async {
      phoneViewport(tester);
      final now = DateTime.now();
      final target = currentMonthDay(now);
      final event = CountdownEvent(
        id: 'evt-calendar',
        title: '考试',
        targetDate: DateTime(target.year, target.month, target.day, 9),
        category: '学习',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      final controller = await readyController([event]);
      await tester.pumpWidget(buildCalendar(controller));
      await tester.pump();

      await tester.tap(
        find.byKey(
          ValueKey('calendar-day-${target.year}-${target.month}-${target.day}'),
        ),
      );
      await tester.pump();
      expect(find.text('考试'), findsOneWidget);

      await tester.tap(find.text('考试'));
      await tester.pumpAndSettle();
      expect(find.text('标记完成'), findsOneWidget);
    });

    testWidgets('已完成事件在当天事件列表淡化显示', (tester) async {
      phoneViewport(tester);
      final now = DateTime.now();
      final target = currentMonthDay(now);
      final event = CountdownEvent(
        id: 'evt-done',
        title: '已完成的旅行',
        targetDate: DateTime(target.year, target.month, target.day, 9),
        category: '生活',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 5)),
      );
      final controller = await readyController([event]);
      await tester.pumpWidget(buildCalendar(controller));
      await tester.pump();

      await tester.tap(
        find.byKey(
          ValueKey('calendar-day-${target.year}-${target.month}-${target.day}'),
        ),
      );
      await tester.pump();

      final row = tester.widget<Opacity>(
        find.byKey(const ValueKey('calendar-event-evt-done')),
      );
      expect(row.opacity, 0.5);
    });

    testWidgets('月/年/列表模式切换，列表按月份分组', (tester) async {
      phoneViewport(tester);
      final now = DateTime.now();
      final first = currentMonthDay(now);
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final events = [
        CountdownEvent(
          id: 'evt-first',
          title: '本月事件',
          targetDate: DateTime(first.year, first.month, first.day, 9),
          category: '学习',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        CountdownEvent(
          id: 'evt-next',
          title: '下月事件',
          targetDate: DateTime(nextYear, nextMonth, 5, 9),
          category: '生活',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];
      final controller = await readyController(events);
      await tester.pumpWidget(buildCalendar(controller));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('calendar-mode-year')));
      await tester.pump();
      expect(find.text('${now.year} 年'), findsOneWidget);
      expect(find.text('${now.month} 月'), findsOneWidget);

      await tester.tap(find.text('${now.month} 月'));
      await tester.pump();
      expect(find.byKey(const ValueKey('calendar-mode-month')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('calendar-mode-list')));
      await tester.pump();
      expect(find.text('本月事件'), findsOneWidget);
      expect(find.text('下月事件'), findsOneWidget);
      expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
      final nextLabel = nextYear == now.year
          ? '${now.year}年$nextMonth月'
          : '$nextYear年$nextMonth月';
      expect(find.text(nextLabel), findsOneWidget);
    });

    testWidgets('今天按钮仅在选中非当日时显示，点击后回到今天', (tester) async {
      phoneViewport(tester);
      final now = DateTime.now();
      final target = currentMonthDay(now);
      final controller = await readyController([]);
      await tester.pumpWidget(buildCalendar(controller));
      await tester.pump();

      expect(find.text('今天'), findsNothing);

      await tester.tap(
        find.byKey(
          ValueKey('calendar-day-${target.year}-${target.month}-${target.day}'),
        ),
      );
      await tester.pump();

      expect(find.text('今天'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('calendar-today')));
      await tester.pump();

      expect(find.text('今天'), findsNothing);
    });

    testWidgets('今天按钮出现时副标题行高度不变', (tester) async {
      phoneViewport(tester);
      final now = DateTime.now();
      final target = currentMonthDay(now);
      final controller = await readyController([]);
      await tester.pumpWidget(buildCalendar(controller));
      await tester.pump();

      final before = tester
          .getTopLeft(find.byKey(const ValueKey('calendar-mode-month')))
          .dy;

      await tester.tap(
        find.byKey(
          ValueKey('calendar-day-${target.year}-${target.month}-${target.day}'),
        ),
      );
      await tester.pump();

      final after = tester
          .getTopLeft(find.byKey(const ValueKey('calendar-mode-month')))
          .dy;
      expect(after, before);
    });

    testWidgets('年视图仅在非当前年份显示今天按钮', (tester) async {
      phoneViewport(tester);
      final now = DateTime.now();
      final controller = await readyController([]);
      await tester.pumpWidget(buildCalendar(controller));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('calendar-mode-year')));
      await tester.pump();
      expect(find.text('今天'), findsNothing);

      await tester.tap(find.byTooltip('上一年'));
      await tester.pump();
      expect(find.text('今天'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('calendar-today')));
      await tester.pump();
      expect(find.text('${now.year} 年'), findsOneWidget);
      expect(find.text('今天'), findsNothing);
    });
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
