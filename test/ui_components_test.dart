import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ying/app_version.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_sort_mode.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/event_card.dart';
import 'package:ying/ui/event_detail_page.dart';
import 'package:ying/ui/event_filter_bar.dart';
import 'package:ying/ui/event_form_sheet.dart';
import 'package:ying/ui/glass_ui.dart';
import 'package:ying/ui/settings_page.dart';
import 'package:ying/ui/widget_preview_section.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  CountdownEvent makeEvent({
    String id = 'evt-1',
    String title = '考试',
    bool completed = false,
    bool pinned = false,
  }) {
    final base = DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    return CountdownEvent(
      id: id,
      title: title,
      targetDate: today.add(const Duration(days: 30, hours: 9)),
      category: '学习',
      isCompleted: completed,
      isPinned: pinned,
      createdAt: today.subtract(const Duration(days: 2)),
    );
  }

  Widget glassApp(
    Widget home, {
    double textScale = 1,
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      builder: (context, child) => AccessibleAppearance(
        reduceTransparency: true,
        reduceMotion: reduceMotion,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
      home: home,
    );
  }

  // 默认测试视口是 800x600 横屏，底部弹层与长列表会溢出；
  // 这些用例按手机竖屏布局验证。
  void phoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('首页筛选控件', () {
    testWidgets('搜索展开、分类选择、排序面板与清除筛选', (tester) async {
      await tester.pumpWidget(glassApp(const Scaffold(body: _FilterHarness())));
      await tester.pump();

      // 搜索：展开后出现输入框。
      await tester.tap(find.text('搜索事件'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('收起搜索'), findsOneWidget);

      // 分类：选择“学习”后进入筛选状态，出现清除入口。
      await tester.tap(find.text('学习'));
      await tester.pumpAndSettle();
      expect(find.text('筛选中'), findsOneWidget);
      expect(find.text('清除筛选'), findsOneWidget);

      // 排序：底部面板选择“目标日期”后按钮文案更新。
      await tester.tap(find.text('按距离'));
      await tester.pumpAndSettle();
      expect(find.text('排序方式'), findsOneWidget);
      await tester.tap(find.text('目标日期'));
      await tester.pumpAndSettle();
      expect(find.text('按日期'), findsOneWidget);

      // 清除筛选后恢复初始状态。
      await tester.tap(find.text('清除筛选'));
      await tester.pumpAndSettle();
      expect(find.text('筛选'), findsOneWidget);
      expect(find.text('清除筛选'), findsNothing);
    });
  });

  group('事件卡片操作', () {
    testWidgets('完成与恢复按钮触发回调并更新提示', (tester) async {
      var toggles = 0;
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: ListView(
              children: [
                EventCard(
                  event: makeEvent(),
                  onOpen: () {},
                  onEdit: () {},
                  onToggle: () => toggles++,
                  onDelete: () {},
                  onTogglePinned: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('标记完成'));
      await tester.pumpAndSettle();
      expect(toggles, 1);

      // 已完成事件显示恢复入口。
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: ListView(
              children: [
                EventCard(
                  event: makeEvent(completed: true),
                  onOpen: () {},
                  onEdit: () {},
                  onToggle: () => toggles++,
                  onDelete: () {},
                  onTogglePinned: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('恢复事件'));
      await tester.pumpAndSettle();
      expect(toggles, 2);
    });

    testWidgets('右滑超过阈值完成事件，左滑露出编辑删除按钮', (tester) async {
      var toggles = 0;
      var deletes = 0;
      var edits = 0;
      Widget buildCard() => glassApp(
        Scaffold(
          body: ListView(
            children: [
              EventCard(
                event: makeEvent(),
                onOpen: () {},
                onEdit: () => edits++,
                onToggle: () => toggles++,
                onDelete: () => deletes++,
                onTogglePinned: () {},
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(buildCard());
      await tester.pump();

      // 右滑完成。
      await tester.drag(find.byType(EventCard), const Offset(220, 0));
      await tester.pumpAndSettle();
      expect(toggles, 1);

      // 左滑露出操作区，删除/编辑按钮可点。
      await tester.drag(find.byType(EventCard), const Offset(-140, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(deletes, 1);

      await tester.drag(find.byType(EventCard), const Offset(-140, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();
      expect(edits, 1);
    });

    testWidgets('长按卡片打开操作菜单，可置顶、编辑和删除', (tester) async {
      var pins = 0;
      var edits = 0;
      var deletes = 0;
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: ListView(
              children: [
                EventCard(
                  event: makeEvent(),
                  onOpen: () {},
                  onEdit: () => edits++,
                  onToggle: () {},
                  onDelete: () => deletes++,
                  onTogglePinned: () => pins++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.longPress(find.byType(EventCard));
      await tester.pumpAndSettle();
      expect(find.text('事件操作'), findsOneWidget);
      expect(find.text('置顶'), findsOneWidget);
      // 菜单行之外，左滑操作区里的同名按钮也在组件树中。
      expect(find.text('编辑'), findsNWidgets(2));
      expect(find.text('删除'), findsNWidgets(2));

      await tester.tap(find.text('置顶'));
      await tester.pumpAndSettle();
      expect(pins, 1);

      await tester.longPress(find.byType(EventCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑').last);
      await tester.pumpAndSettle();
      expect(edits, 1);

      await tester.longPress(find.byType(EventCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();
      expect(deletes, 1);
    });
  });

  group('新建/编辑表单', () {
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
        timerFactory: (_, _) => _IdleTimer(),
      );
    }

    Future<void> openSheet(WidgetTester tester, AppController controller) {
      return tester.pumpWidget(
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
                      builder: (_) => const EventFormSheet(),
                    ),
                    child: const Text('打开表单'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> revealSubmitButton(WidgetTester tester) async {
      // 先收起焦点，否则输入框的“保持焦点可见”机制会把滚动拉回去。
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      // 提交按钮是表单滚动区最后一个子项；直接把滚动位置拉到底部，
      // 比 dragUntilVisible 更可靠（按钮已构建、只是位于视口外）。
      final scrollable = find.descendant(
        of: find.byType(EventFormSheet),
        matching: find.byType(SingleChildScrollView),
      );
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: scrollable, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }

    testWidgets('空标题阻止提交并给出中文错误提示', (tester) async {
      phoneViewport(tester);
      final saved = <CountdownEvent>[];
      final controller = buildController(saved);
      await openSheet(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开表单'));
      await tester.pumpAndSettle();
      await revealSubmitButton(tester);
      await tester.tap(find.text('创建日子'));
      await tester.pumpAndSettle();

      expect(find.text('请输入事件名称'), findsOneWidget);
      expect(saved, isEmpty);
    });

    testWidgets('长标题可提交并写入控制器', (tester) async {
      phoneViewport(tester);
      final saved = <CountdownEvent>[];
      final controller = buildController(saved);
      await openSheet(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开表单'));
      await tester.pumpAndSettle();

      final longTitle = '一个特别长的中文事件名称'.padRight(60, '测');
      await tester.enterText(find.byType(TextFormField).first, longTitle);
      await revealSubmitButton(tester);
      await tester.tap(find.text('创建日子'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(saved.single.title, longTitle.trim());
      // 提交成功后表单关闭。
      expect(find.text('创建日子'), findsNothing);
    });

    testWidgets('200% 字体缩放与减少动画下仍可提交', (tester) async {
      phoneViewport(tester);
      final saved = <CountdownEvent>[];
      final controller = buildController(saved);
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
                      builder: (_) => const EventFormSheet(),
                    ),
                    child: const Text('打开表单'),
                  ),
                ),
              ),
            ),
            textScale: 2,
            reduceMotion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开表单'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextFormField).first, '无障碍提交');
      await revealSubmitButton(tester);
      await tester.tap(find.text('创建日子'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(saved.single.title, '无障碍提交');
    });

    testWidgets('选择 Emoji 图标后保存到事件', (tester) async {
      phoneViewport(tester);
      final saved = <CountdownEvent>[];
      final controller = buildController(saved);
      await openSheet(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开表单'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '旅行');
      await tester.tap(find.bySemanticsLabel('图标：✈️'));
      await revealSubmitButton(tester);
      await tester.tap(find.text('创建日子'));
      await tester.pumpAndSettle();

      expect(saved, hasLength(1));
      expect(saved.single.icon, '✈️');
    });
  });

  group('设置页', () {
    AppController buildController(
      List<AppSettings> saved, {
      AppSettings initial = const AppSettings(),
      UpdateChecker? checkUpdate,
    }) {
      return AppController(
        StorageService(),
        autoLoad: false,
        loadEvents: () async => const [],
        saveEvents: (_) async {},
        loadSettings: () async => initial,
        saveSettings: (settings) async => saved.add(settings),
        scheduleNotification: (_) async {},
        cancelNotification: (_) async {},
        syncWidget: (_, _) async {},
        timerFactory: (_, _) => _IdleTimer(),
        checkUpdate: checkUpdate,
      );
    }

    Widget buildSettingsPage(AppController controller) {
      return glassApp(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) => controller)],
          child: const Scaffold(body: SettingsPage()),
        ),
      );
    }

    // 诊断区 FutureBuilder 依赖通知插件通道，假异步下永不完成、
    // 加载指示器会让 pumpAndSettle 挂起；用真实异步冲刷挂起的 Future。
    Future<void> flushPlatform(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    testWidgets('整行可切换玻璃开关并持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      // 点击标题文字所在行即可切换（整行可点）。
      await tester.tap(find.text('减少动画'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.reduceMotion, isTrue);
      expect(saved.last.reduceMotion, isTrue);

      await tester.tap(find.text('减少透明度'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.reduceTransparency, isTrue);
      // 阶段 2 后开关数量增加，只校验可见的基础开关与新内容开关。
      expect(find.byType(GlassSwitch), findsAtLeastNWidgets(5));
      expect(find.text('事件图标'), findsOneWidget);
      expect(find.text('进度百分比'), findsOneWidget);
    });

    testWidgets('切换小部件样式预设并持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      await tester.tap(find.bySemanticsLabel('小部件样式：贴纸'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.widgetStyle, WidgetStyle.sticker);
      expect(saved.last.widgetStyle, WidgetStyle.sticker);

      await tester.tap(find.bySemanticsLabel('小部件样式：霓虹'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.widgetStyle, WidgetStyle.neon);
      handle.dispose();
    });

    testWidgets('主题选择与色卡选择带选中语义', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      await tester.tap(find.text('深色'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.themeMode, ThemeMode.dark);

      // 色卡分组在竖屏视口内同屏可见，直接点选。
      await tester.tap(find.bySemanticsLabel('主色调：粉色'));
      await tester.pumpAndSettle();
      expect(
        controller.state.settings.widgetColor,
        GlassPalette.pink.toARGB32(),
      );

      // 选中态语义可被读屏器识别。
      final themeNode = tester.getSemantics(find.bySemanticsLabel('主题：深色'));
      expect(themeNode.flagsCollection.isSelected, isTrue);
      handle.dispose();
    });

    testWidgets('单位文案与数字字体预设持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.bySemanticsLabel('单位文案：只剩'), 300);
      await tester.ensureVisible(find.bySemanticsLabel('单位文案：只剩'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.bySemanticsLabel('单位文案：只剩'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.state.settings.widgetUnitText, 'only');
      expect(saved.last.widgetUnitText, 'only');

      await tester.scrollUntilVisible(find.bySemanticsLabel('数字字体：等宽'), 300);
      await tester.ensureVisible(find.bySemanticsLabel('数字字体：等宽'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.bySemanticsLabel('数字字体：等宽'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.state.settings.widgetFontFamily, 'mono');
      expect(saved.last.widgetFontFamily, 'mono');
      handle.dispose();
    });

    testWidgets('事件列表模式开关持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('事件列表模式'), 300);
      await tester.ensureVisible(find.text('事件列表模式'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('事件列表模式'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.state.settings.widgetListMode, isTrue);
      expect(saved.last.widgetListMode, isTrue);
    });

    testWidgets('提醒诊断刷新重新加载状态', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('刷新状态'), 300);
      await tester.ensureVisible(find.text('刷新状态'));
      await flushPlatform(tester);
      // 滚动后诊断区与预览区可能同时重建，用定长 pump 避免等待
      // 测试环境永不完成的平台通道 Future。
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('提醒诊断'), findsOneWidget);
      expect(find.text('刷新状态'), findsOneWidget);

      // 刷新会以新的 Future 重建诊断区，通道错误兜底后重新渲染。
      await tester.tap(find.text('刷新状态'));
      await tester.pump();
      await flushPlatform(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('提醒诊断'), findsOneWidget);
      expect(find.text('通知权限'), findsOneWidget);
    });

    testWidgets('数据管理与关于分区渲染', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('数据管理'), 300);
      expect(find.text('导出数据'), findsOneWidget);
      expect(find.text('导入数据'), findsOneWidget);
      expect(find.text('清除所有事件'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('关于'), 300);
      expect(find.text('萤 $appVersion'), findsOneWidget);
      expect(find.text('github.com/jiuxina/ying'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('导出数据复制事件到剪贴板', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await controller.saveEvent(makeEvent(title: '剪贴板事件'));
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          if (call.method == 'Clipboard.getData') {
            return {'text': (call.arguments as Map<Object?, Object?>)['text']};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.scrollUntilVisible(find.text('导出数据'), 300);
      await tester.ensureVisible(find.text('导出数据'));
      await flushPlatform(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('导出数据'));
      await tester.pumpAndSettle();

      final copy = calls.firstWhere(
        (call) => call.method == 'Clipboard.setData',
      );
      final text = (copy.arguments as Map<Object?, Object?>)['text'] as String;
      expect(CountdownEvent.decodeList(text).single.title, '剪贴板事件');
    });

    testWidgets('导入数据从剪贴板合并事件', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final backup = CountdownEvent.encodeList([makeEvent(title: '备份事件')]);
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': backup};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.scrollUntilVisible(find.text('导入数据'), 300);
      await tester.ensureVisible(find.text('导入数据'));
      await flushPlatform(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('导入数据'));
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);

      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();

      expect(controller.state.events.single.title, '备份事件');
      expect(tester.takeException(), isNull);
    });

    testWidgets('清除所有事件需确认并执行', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await controller.saveEvent(makeEvent(title: '要被清除'));
      await tester.pumpWidget(buildSettingsPage(controller));
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('清除所有事件'), 300);
      await tester.ensureVisible(find.text('清除所有事件'));
      await flushPlatform(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('清除所有事件'));
      await tester.pumpAndSettle();
      expect(find.text('清除所有事件？'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(controller.state.events, hasLength(1));

      await tester.ensureVisible(find.text('清除所有事件'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('清除所有事件'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('清除'));
      await tester.pumpAndSettle();
      expect(controller.state.events, isEmpty);
      expect(controller.state.pendingUndos, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('事件详情页', () {
    AppController buildController() {
      return AppController(
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
    }

    testWidgets('完成、恢复与置顶按钮更新事件状态', (tester) async {
      final controller = buildController();
      final event = makeEvent(title: '详情页事件');
      await controller.saveEvent(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) => controller)],
          child: glassApp(EventDetailPage(eventId: event.id)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('标记完成'), findsOneWidget);
      expect(find.text('置顶'), findsOneWidget);

      await tester.tap(find.text('标记完成'));
      await tester.pumpAndSettle();
      expect(controller.state.events.single.isCompleted, isTrue);
      expect(find.text('恢复事件'), findsOneWidget);

      await tester.tap(find.text('置顶'));
      await tester.pumpAndSettle();
      expect(controller.state.events.single.isPinned, isTrue);
      expect(find.text('取消置顶'), findsOneWidget);
    });

    testWidgets('删除按钮移除事件并返回上一页', (tester) async {
      final controller = buildController();
      final event = makeEvent(title: '待删除事件');
      await controller.saveEvent(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) => controller)],
          child: glassApp(
            Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EventDetailPage(eventId: event.id),
                      ),
                    ),
                    child: const Text('打开详情'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开详情'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(controller.state.events, isEmpty);
      expect(find.text('打开详情'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('详情页使用不透明应用背景，避免黑底', (tester) async {
      final controller = buildController();
      final event = makeEvent(title: '背景事件');
      await controller.saveEvent(event);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) => controller)],
          child: glassApp(EventDetailPage(eventId: event.id)),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // null 表示使用主题脚手架背景（不透明），而不是透明背景。
      expect(scaffold.backgroundColor, isNull);
      expect(find.text('背景事件'), findsOneWidget);
    });
  });

  group('小组件预览与同步状态', () {
    testWidgets('展示状态行，刷新失败时给出明确反馈', (tester) async {
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: ListView(
              children: [
                WidgetPreviewSection(
                  events: [makeEvent()],
                  settings: const AppSettings(),
                ),
              ],
            ),
          ),
        ),
      );
      // status() 依赖 home_widget 平台通道，测试环境无实现会走错误兜底；
      // 通道响应只在真实异步下送达，用 runAsync 冲刷挂起的 Future。
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(find.text('桌面小部件'), findsOneWidget);
      expect(find.text('桌面实例'), findsOneWidget);
      expect(find.text('已同步事件'), findsOneWidget);
      expect(find.text('未检测到'), findsOneWidget);
      expect(find.text('尚未同步'), findsOneWidget);

      // 测试环境无桌面插件通道，一键刷新应给出失败反馈。
      await tester.tap(find.text('一键刷新'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('刷新失败'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('内容个性化设置渲染预览不抛异常', (tester) async {
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: SingleChildScrollView(
              child: WidgetPreviewSection(
                events: [makeEvent()],
                settings: const AppSettings(
                  widgetShowIcon: true,
                  widgetShowPreciseTime: true,
                  widgetShowLunarWeek: true,
                  widgetShowProgress: true,
                  widgetMysteryMode: true,
                  widgetQuoteMode: true,
                  widgetUnitText: 'only',
                  widgetFontFamily: 'mono',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('桌面小部件'), findsOneWidget);
    });

    testWidgets('列表模式显示事件列表预览', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: WidgetPreviewSection(
              events: [makeEvent()],
              settings: const AppSettings(widgetListMode: true),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('考试'), findsNWidgets(2));
      expect(find.text('学习'), findsOneWidget);
      handle.dispose();
    });
  });
}

class _FilterHarness extends StatefulWidget {
  const _FilterHarness();

  @override
  State<_FilterHarness> createState() => _FilterHarnessState();
}

class _FilterHarnessState extends State<_FilterHarness> {
  final searchController = TextEditingController();
  bool searchExpanded = false;
  bool incompleteOnly = false;
  String? selectedCategory;
  EventSortMode sortMode = EventSortMode.distance;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      incompleteOnly = false;
      selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return EventFilterBar(
      controller: searchController,
      searchExpanded: searchExpanded,
      incompleteOnly: incompleteOnly,
      selectedCategory: selectedCategory,
      categories: const ['生活', '工作', '学习'],
      sortMode: sortMode,
      onToggleSearch: () => setState(() => searchExpanded = !searchExpanded),
      onSearchChanged: (_) {},
      onIncompleteChanged: (value) => setState(() => incompleteOnly = value),
      onCategoryChanged: (value) => setState(() => selectedCategory = value),
      onSortChanged: (value) => setState(() => sortMode = value),
      onClear: clearFilters,
    );
  }
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
