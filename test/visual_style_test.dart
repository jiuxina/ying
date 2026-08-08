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
import 'package:ying/ui/home_page.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  test('theme follows the reference HTML palette', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.colorScheme.primary, const Color(0xFF0F766E));
    expect(light.scaffoldBackgroundColor, const Color(0xFFFCFBF9));
    expect(dark.colorScheme.primary, const Color(0xFFBEF264));
    expect(dark.scaffoldBackgroundColor, const Color(0xFF0F1115));
  });

  testWidgets('mobile navigation keeps days, add and settings entries', (
    tester,
  ) async {
    final controller = AppController(
      StorageService(),
      autoLoad: false,
      loadEvents: () async => const [],
      saveEvents: (_) async {},
      loadSettings: () async => const AppSettings(),
      saveSettings: (_) async {},
      scheduleNotification: (_) async {},
      cancelNotification: (_) async {},
      syncWidget: (_, _) async {},
      timerFactory: (_, _) => _IdleTimer(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(theme: AppTheme.light(), home: const HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('日子'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.byTooltip('新建倒数日'), findsOneWidget);
  });

  testWidgets('勾选完成后卡片带动画搬入已展开的已完成分组', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final base = DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final event = CountdownEvent(
      id: 'evt-1',
      title: '毕业',
      targetDate: today.add(const Duration(days: 29)),
      category: '生活',
      createdAt: today.subtract(const Duration(days: 2)),
    );
    final controller = AppController(
      StorageService(),
      loadEvents: () async => [event],
      saveEvents: (_) async {},
      loadSettings: () async => const AppSettings(),
      saveSettings: (_) async {},
      scheduleNotification: (_) async {},
      cancelNotification: (_) async {},
      syncWidget: (_, _) async {},
      timerFactory: (_, _) => _IdleTimer(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(theme: AppTheme.light(), home: const HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('毕业'), findsOneWidget);
    expect(find.text('已完成 1'), findsNothing);

    await tester.tap(find.byTooltip('标记完成'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    // 过渡进行中：旧卡片正退出、已完成分组头与新卡片正在进入。
    expect(find.text('毕业'), findsNWidgets(2));
    expect(find.text('已完成 1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('毕业'), findsOneWidget);
    expect(controller.state.events.single.isCompleted, isTrue);

    // 恢复后卡片搬回进行中分组，分组头随之移除。
    await tester.tap(find.byTooltip('恢复事件'));
    await tester.pumpAndSettle();
    expect(find.text('毕业'), findsOneWidget);
    expect(find.text('已完成 1'), findsNothing);
    expect(controller.state.events.single.isCompleted, isFalse);
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
