import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_sort_mode.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/event_card.dart';
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

    testWidgets('更多操作菜单提供置顶入口', (tester) async {
      var pins = 0;
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: ListView(
              children: [
                EventCard(
                  event: makeEvent(),
                  onOpen: () {},
                  onEdit: () {},
                  onToggle: () {},
                  onDelete: () {},
                  onTogglePinned: () => pins++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('更多操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('置顶').last);
      await tester.pumpAndSettle();
      expect(pins, 1);
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
  });

  group('设置页', () {
    AppController buildController(
      List<AppSettings> saved, {
      AppSettings initial = const AppSettings(),
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
      // 手机竖屏视口下四个开关同屏可见：透明度、动画、分类标签、事件备注。
      expect(find.byType(GlassSwitch), findsNWidgets(4));
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
