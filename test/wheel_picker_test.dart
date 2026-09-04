import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/app_theme.dart';
import 'package:ying/ui/event_form_sheet.dart';
import 'package:ying/ui/glass_ui.dart';
import 'package:ying/ui/wheel_datetime_picker.dart';

const _rowExtent = 44.0;

void main() {
  DateTime? capturedDate;
  TimeOfDay? capturedTime;
  int? capturedMinutes;

  Widget glassApp(Widget home) {
    return MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => AccessibleAppearance(
        reduceTransparency: true,
        reduceMotion: false,
        child: child!,
      ),
      home: home,
    );
  }

  Widget pickerHarness(WidgetBuilder opener) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(child: Builder(builder: (context) => opener(context))),
      ),
    );
  }

  Future<void> dragWheel(
    WidgetTester tester,
    int index,
    double rows, {
    bool reverse = false,
  }) async {
    await tester.drag(
      find.byType(ListWheelScrollView).at(index),
      Offset(0, reverse ? _rowExtent * rows : -_rowExtent * rows),
    );
    await tester.pumpAndSettle();
  }

  group('轮盘日期选择器', () {
    testWidgets('拖动月份滚轮后确认返回对应日期', (tester) async {
      capturedDate = null;
      await tester.pumpWidget(
        pickerHarness(
          (context) => FilledButton(
            onPressed: () async {
              capturedDate = await showGlassWheelDatePicker(
                context: context,
                initialDate: DateTime(2026, 9, 4),
              );
            },
            child: const Text('打开日期'),
          ),
        ),
      );
      await tester.tap(find.text('打开日期'));
      await tester.pumpAndSettle();

      // 2026-09-04 是星期五。
      expect(find.text('2026年9月4日 星期五'), findsOneWidget);

      await dragWheel(tester, 1, 1.1); // 9月 → 10月
      expect(find.text('2026年10月4日 星期日'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(capturedDate, DateTime(2026, 10, 4));
    });

    testWidgets('切换到短月时日期自动收敛', (tester) async {
      capturedDate = null;
      await tester.pumpWidget(
        pickerHarness(
          (context) => FilledButton(
            onPressed: () async {
              capturedDate = await showGlassWheelDatePicker(
                context: context,
                initialDate: DateTime(2026, 1, 31),
              );
            },
            child: const Text('打开日期'),
          ),
        ),
      );
      await tester.tap(find.text('打开日期'));
      await tester.pumpAndSettle();

      await dragWheel(tester, 1, 1.1); // 1月 → 2月，31 日收敛为 28 日
      expect(find.text('2026年2月28日 星期六'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(capturedDate, DateTime(2026, 2, 28));
    });

    testWidgets('取消不返回结果', (tester) async {
      capturedDate = null;
      await tester.pumpWidget(
        pickerHarness(
          (context) => FilledButton(
            onPressed: () async {
              capturedDate = await showGlassWheelDatePicker(
                context: context,
                initialDate: DateTime(2026, 9, 4),
              );
            },
            child: const Text('打开日期'),
          ),
        ),
      );
      await tester.tap(find.text('打开日期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(capturedDate, isNull);
    });
  });

  group('轮盘时间选择器', () {
    testWidgets('日期时间一体弹层可同时调整', (tester) async {
      capturedDate = null;
      await tester.pumpWidget(
        pickerHarness(
          (context) => FilledButton(
            onPressed: () async {
              capturedDate = await showGlassWheelDateTimePicker(
                context: context,
                initialDateTime: DateTime(2026, 9, 4, 9, 30),
              );
            },
            child: const Text('打开日期时间'),
          ),
        ),
      );
      await tester.tap(find.text('打开日期时间'));
      await tester.pumpAndSettle();

      expect(find.text('2026年9月4日 星期五 09:30'), findsOneWidget);

      await dragWheel(tester, 3, 5); // 9时 → 14时
      expect(find.text('2026年9月4日 星期五 14:30'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(capturedDate, DateTime(2026, 9, 4, 14, 30));
    });

    testWidgets('纯时间弹层返回 TimeOfDay', (tester) async {
      capturedTime = null;
      await tester.pumpWidget(
        pickerHarness(
          (context) => FilledButton(
            onPressed: () async {
              capturedTime = await showGlassWheelTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 9, minute: 30),
              );
            },
            child: const Text('打开时间'),
          ),
        ),
      );
      await tester.tap(find.text('打开时间'));
      await tester.pumpAndSettle();

      expect(find.text('上午 09:30'), findsOneWidget);
      await dragWheel(tester, 1, 5); // 30分 → 35分
      expect(find.text('上午 09:35'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(capturedTime, const TimeOfDay(hour: 9, minute: 35));
    });
  });

  group('自定义提醒时长', () {
    testWidgets('数量+单位轮盘返回分钟数', (tester) async {
      capturedMinutes = null;
      await tester.pumpWidget(
        pickerHarness(
          (context) => FilledButton(
            onPressed: () async {
              capturedMinutes = await showGlassReminderOffsetPicker(
                context: context,
                initialMinutes: 60,
              );
            },
            child: const Text('打开自定义提醒'),
          ),
        ),
      );
      await tester.tap(find.text('打开自定义提醒'));
      await tester.pumpAndSettle();

      // 60 分钟归一为「1 小时」。
      expect(find.text('提醒时间：提前 1 小时'), findsOneWidget);
      await dragWheel(tester, 0, 1.1); // 1 → 2
      expect(find.text('提醒时间：提前 2 小时'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(capturedMinutes, 120);
    });

    testWidgets('切换单位时数量收敛到有效范围', (tester) async {
      capturedMinutes = null;
      await tester.pumpWidget(
        pickerHarness(
          (context) => FilledButton(
            onPressed: () async {
              capturedMinutes = await showGlassReminderOffsetPicker(
                context: context,
                initialMinutes: 90 * 1440,
              );
            },
            child: const Text('打开自定义提醒'),
          ),
        ),
      );
      await tester.tap(find.text('打开自定义提醒'));
      await tester.pumpAndSettle();

      expect(find.text('提醒时间：提前 90 天'), findsOneWidget);
      await dragWheel(tester, 1, 1.1, reverse: true); // 天 → 小时
      // 小时的数量上限是 59，90 收敛为 59。
      expect(find.text('提醒时间：提前 59 小时'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(capturedMinutes, 59 * 60);
    });
  });

  group('表单集成', () {
    AppController buildController(List<CountdownEvent> saved) {
      return AppController(
        StorageService(),
        autoLoad: false,
        loadEvents: () async => const [],
        saveEvents: (events) async => saved.addAll([...events]),
        loadSettings: () async => const AppSettings(),
        saveSettings: (_) async {},
        scheduleNotification: (_) async {},
        cancelNotification: (_) async {},
        syncWidget: (_, _) async {},
      );
    }

    Future<void> pumpForm(
      WidgetTester tester,
      AppController controller, {
      CountdownEvent? event,
    }) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) => controller)],
          child: glassApp(
            Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => EventFormSheet(event: event),
                    ),
                    child: const Text('打开表单'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开表单'));
      await tester.pumpAndSettle();
    }

    testWidgets('保存栏固定在底部，无需滚动即可保存', (tester) async {
      phoneViewport(tester);
      final saved = <CountdownEvent>[];
      await pumpForm(tester, buildController(saved));

      expect(find.text('创建日子'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '毕业典礼');
      await tester.tap(find.text('创建日子'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(saved.single.title, '毕业典礼');
      expect(find.byType(EventFormSheet), findsNothing);
    });

    testWidgets('快捷选项添加提醒，重复添加给出中文提示', (tester) async {
      phoneViewport(tester);
      final saved = <CountdownEvent>[];
      await pumpForm(tester, buildController(saved));

      await tester.tap(find.text('添加提醒时间'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GlassChoiceTile, '提前 1 天'));
      await tester.pumpAndSettle();
      expect(find.text('提前 1 天'), findsOneWidget);

      await tester.tap(find.text('添加提醒时间'));
      await tester.pumpAndSettle();
      expect(find.text('已添加'), findsOneWidget);
      await tester.tap(find.widgetWithText(GlassChoiceTile, '提前 1 天'));
      await tester.pumpAndSettle();
      expect(find.text('该提醒时间已存在'), findsOneWidget);
      expect(find.text('提前 1 天'), findsOneWidget);
    });

    testWidgets('自定义提醒时间通过轮盘写入事件', (tester) async {
      phoneViewport(tester);
      final saved = <CountdownEvent>[];
      await pumpForm(tester, buildController(saved));

      await tester.tap(find.text('添加提醒时间'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GlassChoiceTile, '自定义提醒时间'));
      await tester.pumpAndSettle();

      // 初始为「1 天」，拖动数量轮到 2 天。
      await dragWheel(tester, 0, 1.1);
      expect(find.text('提醒时间：提前 2 天'), findsOneWidget);
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(find.text('提前 2 天'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '还款日');
      await tester.tap(find.text('创建日子'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(
        saved.single.reminders.map((reminder) => reminder.minutesBefore),
        contains(2880),
      );
    });

    testWidgets('编辑全天事件时目标日期带星期显示', (tester) async {
      phoneViewport(tester);
      final saved = <CountdownEvent>[];
      final base = DateTime.now();
      final event = CountdownEvent(
        id: 'evt-edit',
        title: '生日',
        targetDate:
            DateTime(base.year, base.month, base.day).add(
              const Duration(days: 30),
            ),
        category: '生活',
        isAllDay: true,
        createdAt: base.subtract(const Duration(days: 2)),
      );
      await pumpForm(tester, buildController(saved), event: event);

      expect(find.text('编辑日子'), findsOneWidget);
      expect(find.textContaining('· 全天'), findsOneWidget);
      expect(find.textContaining('星期'), findsWidgets);
    });
  });
}

void phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
