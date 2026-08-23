import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/app_version.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/models/event_sort_mode.dart';
import 'package:ying/models/widget_font.dart';
import 'package:ying/models/widget_element_style.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/state/font_library_controller.dart';
import 'package:ying/ui/app_theme.dart';
import 'package:ying/ui/event_card.dart';
import 'package:ying/ui/event_detail_page.dart';
import 'package:ying/ui/event_filter_bar.dart';
import 'package:ying/ui/event_form_sheet.dart';
import 'package:ying/ui/glass_ui.dart';
import 'package:ying/ui/font_library_page.dart';
import 'package:ying/ui/home_page.dart';
import 'package:ying/ui/settings_page.dart';
import 'package:ying/ui/widget_element_presets.dart';
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

      // 搜索：图标按钮展开后出现输入框。
      await tester.tap(find.byTooltip('搜索事件'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byTooltip('收起搜索'), findsOneWidget);

      // 分类：进入筛选面板选择“学习”后进入筛选状态，出现清除入口。
      await tester.tap(find.byTooltip('筛选'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('学习'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('应用筛选'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('筛选中'), findsOneWidget);
      expect(find.text('清除筛选'), findsOneWidget);

      // 排序：底部面板选择“目标日期”后按钮提示更新。
      await tester.tap(find.byTooltip('按距离'));
      await tester.pumpAndSettle();
      expect(find.text('排序方式'), findsOneWidget);
      await tester.tap(find.text('目标日期'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('按日期'), findsOneWidget);

      // 清除筛选后恢复初始状态。
      await tester.tap(find.text('清除筛选'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('筛选'), findsOneWidget);
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

    Widget buildSettingsPage(
      AppController controller, {
      SettingsCategory category = SettingsCategory.appearance,
      List<WidgetFontAsset> installedFonts = const [],
    }) {
      final fontLibrary = FontLibraryController()
        ..installed = installedFonts
        ..loading = false;
      return ProviderScope(
        overrides: [
          appControllerProvider.overrideWith((ref) => controller),
          fontLibraryProvider.overrideWith((ref) => fontLibrary),
        ],
        child: glassApp(SettingsCategoryPage(category: category)),
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

    testWidgets('外观设置开关整行可切换并持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.appearance),
      );
      await flushPlatform(tester);

      // 点击标题文字所在行即可切换（整行可点）。
      await tester.tap(find.text('减少动画'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.reduceMotion, isTrue);
      expect(saved.last.reduceMotion, isTrue);

      await tester.tap(find.text('减少透明度'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.reduceTransparency, isTrue);
      expect(find.byType(GlassSwitch), findsNWidgets(2));
    });

    testWidgets('小部件内容开关渲染并持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('事件图标'), 400);
      await tester.ensureVisible(find.text('事件图标'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GlassSwitch), findsAtLeastNWidgets(5));
      expect(find.text('事件图标'), findsOneWidget);
      expect(find.text('进度百分比'), findsOneWidget);

      await tester.tap(find.text('事件图标'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.state.settings.widgetShowIcon, isTrue);
      expect(saved.last.widgetShowIcon, isTrue);
    });

    testWidgets('小部件元素自定义分区与整体垂直对齐持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('内容垂直对齐'), 400);
      await tester.ensureVisible(find.text('内容垂直对齐'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('整体布局'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '底部'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        controller.state.settings.widgetVerticalAlign,
        WidgetVerticalAlign.bottom,
      );
      expect(saved.last.widgetVerticalAlign, WidgetVerticalAlign.bottom);
    });

    testWidgets('小部件元素样式面板持久化字号颜色对齐', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('标题样式'), 400);
      await tester.ensureVisible(find.text('标题样式'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('文字样式'), findsOneWidget);
      await tester.tap(find.text('标题样式'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final sheetMaterial = tester.widget<Material>(
        find
            .ancestor(of: find.text('显隐'), matching: find.byType(Material))
            .first,
      );
      expect(sheetMaterial.color, isNotNull);
      expect(sheetMaterial.color, isNot(Colors.transparent));

      await tester.drag(
        find.byKey(const ValueKey('slider-字号')),
        const Offset(70, 0),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(ChoiceChip, '自定义'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('自定义颜色').first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.drag(
        find.byKey(const ValueKey('slider-粗细')),
        const Offset(60, 0),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '中'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.widgetWithText(ChoiceChip, '中'));
      await tester.pump(const Duration(milliseconds: 300));

      final style = controller.state.settings.widgetElementStyles['title'];
      expect(style?.sizeScale, greaterThan(1.0));
      expect(style?.weight, greaterThan(0));
      expect(style?.colorMode, WidgetColorMode.custom);
      expect(style?.align, WidgetAlign.center);
      expect(style?.color, widgetElementColorPalette.first.toARGB32());
      expect(
        saved.last.widgetElementStyles['title']?.size,
        isNot(WidgetElementSize.normal),
      );
      expect(
        saved.last.widgetElementStyles['title']?.sizeScale,
        greaterThan(1.0),
      );
      expect(saved.last.widgetElementStyles['title']?.weight, greaterThan(0));
    });

    testWidgets('全局字号滑块防抖合并保存', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('全局字号'), 400);
      await tester.ensureVisible(find.text('全局字号'));
      await tester.pump(const Duration(milliseconds: 400));

      final slider = find.byKey(const ValueKey('slider-全局字号'));
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await gesture.moveBy(const Offset(90, 0));
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.state.settings.widgetFontScale, 1.0);
      expect(saved, isEmpty);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(controller.state.settings.widgetFontScale, isNot(1.0));
      expect(saved, isNotEmpty);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
      expect(saved, hasLength(1));
    });

    testWidgets('全局字号与内容边距滑块上限降低且步进更精细', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('全局字号'), 400);
      await tester.ensureVisible(find.text('全局字号'));
      await tester.pump(const Duration(milliseconds: 400));
      final fontSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('slider-全局字号')),
      );
      expect(fontSlider.max, 1.75);
      expect(fontSlider.divisions, 50);

      await tester.scrollUntilVisible(find.text('内容边距'), 400);
      await tester.ensureVisible(find.text('内容边距'));
      await tester.pump(const Duration(milliseconds: 400));
      final marginSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('slider-内容边距')),
      );
      expect(marginSlider.max, 32);
      expect(marginSlider.divisions, 56);
    });

    testWidgets('元素样式字号与粗细滑块上限降低且步进更精细', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('标题样式'), 400);
      await tester.ensureVisible(find.text('标题样式'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('标题样式'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final sizeSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('slider-字号')),
      );
      expect(sizeSlider.max, 1.75);
      expect(sizeSlider.divisions, 50);
      final weightSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('slider-粗细')),
      );
      expect(weightSlider.max, 800);
      expect(weightSlider.divisions, 16);
    });

    testWidgets('小部件元素样式弹层在短屏不溢出且可滚动到底部', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('标题样式'), 400);
      await tester.ensureVisible(find.text('标题样式'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('标题样式'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '中'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.widgetWithText(ChoiceChip, '中'), findsOneWidget);
      await tester.ensureVisible(find.text('重置此元素'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('重置此元素'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('非文字元素不显示粗细且字号改称大小', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('节日徽章样式'), 400);
      await tester.ensureVisible(find.text('节日徽章样式'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('节日徽章样式'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('大小'), findsOneWidget);
      expect(find.text('字号'), findsNothing);
      expect(find.text('粗细'), findsNothing);

      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('标题样式'), 400);
      await tester.ensureVisible(find.text('标题样式'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('标题样式'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('字号'), findsOneWidget);
      expect(find.text('粗细'), findsOneWidget);
      expect(find.text('大小'), findsNothing);
    });

    testWidgets('小部件按钮显隐面板保存三态', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('上一个事件'), 400);
      await tester.ensureVisible(find.text('上一个事件'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('按钮显隐'), findsOneWidget);
      await tester.tap(find.text('上一个事件'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final sheetMaterial = tester.widget<Material>(
        find
            .ancestor(of: find.text('显隐'), matching: find.byType(Material))
            .first,
      );
      expect(sheetMaterial.color, isNotNull);
      expect(sheetMaterial.color, isNot(Colors.transparent));

      await tester.tap(find.widgetWithText(ChoiceChip, '隐藏'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        controller.state.settings.widgetElementStyles['prevButton']?.visible,
        WidgetElementVisible.hide,
      );
      expect(
        saved.last.widgetElementStyles['prevButton']?.visible,
        WidgetElementVisible.hide,
      );
    });

    testWidgets('元素显隐与字号均可自由修改', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith((ref) => controller),
          ],
          child: glassApp(
            const SettingsCategoryPage(category: SettingsCategory.widget),
          ),
        ),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.text('标题样式'), 400);
      await tester.ensureVisible(find.text('标题样式'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('标题样式'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.widgetWithText(ChoiceChip, '显示'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        controller.state.settings.widgetElementStyles['title']?.visible,
        WidgetElementVisible.show,
      );

      await tester.drag(
        find.byKey(const ValueKey('slider-字号')),
        const Offset(70, 0),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        controller.state.settings.widgetElementStyles['title']?.size,
        isNot(WidgetElementSize.normal),
      );
      expect(
        saved.last.widgetElementStyles['title']?.sizeScale,
        greaterThan(1.0),
      );
    });

    testWidgets('切换小部件样式预设并持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('小部件样式：贴纸'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.widgetStyle, WidgetStyle.sticker);
      expect(saved.last.widgetStyle, WidgetStyle.sticker);

      await tester.tap(find.bySemanticsLabel('小部件样式：霓虹'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.widgetStyle, WidgetStyle.neon);
      handle.dispose();
    });

    testWidgets('主题选择带选中语义', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.appearance),
      );
      await flushPlatform(tester);

      await tester.tap(find.text('深色'));
      await tester.pumpAndSettle();
      expect(controller.state.settings.themeMode, ThemeMode.dark);

      // 选中态语义可被读屏器识别。
      final themeNode = tester.getSemantics(find.bySemanticsLabel('主题：深色'));
      expect(themeNode.flagsCollection.isSelected, isTrue);
      handle.dispose();
    });

    testWidgets('色卡选择持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.bySemanticsLabel('主色调：粉色'), 300);
      await tester.ensureVisible(find.bySemanticsLabel('主色调：粉色'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.bySemanticsLabel('主色调：粉色'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        controller.state.settings.widgetColor,
        GlassPalette.pink.toARGB32(),
      );
      expect(saved.last.widgetColor, GlassPalette.pink.toARGB32());
    });

    testWidgets('单位文案与数字字体预设持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
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

    testWidgets('数字与文字字体可分开选择并持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final asset = WidgetFontAsset(
        id: 'test-font',
        name: '测试字体',
        kind: WidgetFontKind.both,
        source: WidgetFontSource.catalog,
        filePath: '/tmp/test.ttf',
        bytes: 1,
        sha256: '0' * 64,
      );
      await tester.pumpWidget(
        buildSettingsPage(
          controller,
          category: SettingsCategory.widget,
          installedFonts: [asset],
        ),
      );
      await flushPlatform(tester);

      await tester.scrollUntilVisible(find.bySemanticsLabel('文字字体：测试字体'), 300);
      await tester.ensureVisible(find.bySemanticsLabel('文字字体：测试字体'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.bySemanticsLabel('文字字体：测试字体'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        controller.state.settings.widgetTextFontFamily,
        'catalog:test-font',
      );
      expect(controller.state.settings.widgetTextFontPath, '/tmp/test.ttf');
      expect(saved.last.widgetTextFontFamily, 'catalog:test-font');

      await tester.scrollUntilVisible(find.bySemanticsLabel('数字字体：测试字体'), 300);
      await tester.ensureVisible(find.bySemanticsLabel('数字字体：测试字体'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.bySemanticsLabel('数字字体：测试字体'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.state.settings.widgetFontFamily, 'catalog:test-font');
      expect(controller.state.settings.widgetDigitFontPath, '/tmp/test.ttf');
      expect(saved.last.widgetFontFamily, 'catalog:test-font');
    });

    testWidgets('字体库在线候选渲染且本地导入入口可用', (tester) async {
      phoneViewport(tester);
      final controller = buildController(<AppSettings>[]);
      final entry = WidgetFontCatalogEntry(
        id: 'orbitron',
        name: 'Orbitron',
        kind: WidgetFontKind.digit,
        file: 'orbitron.ttf',
        bytes: 128,
        sha256: '0' * 64,
      );
      final fontLibrary = FontLibraryController()..loading = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith((ref) => controller),
            fontLibraryProvider.overrideWith((ref) => fontLibrary),
          ],
          child: glassApp(
            FontLibraryPage(
              catalogFetcher: () async => WidgetFontCatalog(
                version: 1,
                baseUrl: 'https://example.com',
                fonts: [entry],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 在线候选与底部字体许可列表都会出现 Orbitron。
      expect(find.text('Orbitron'), findsNWidgets(2));
      expect(find.text('下载并应用'), findsOneWidget);
      expect(find.text('选择 TTF / OTF 文件导入'), findsOneWidget);
    });

    testWidgets('字体库已安装字体可一键应用', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      final asset = WidgetFontAsset(
        id: 'orbitron',
        name: 'Orbitron',
        kind: WidgetFontKind.digit,
        source: WidgetFontSource.catalog,
        filePath: '/tmp/orbitron.ttf',
        bytes: 1,
        sha256: '0' * 64,
      );
      final entry = WidgetFontCatalogEntry(
        id: 'orbitron',
        name: 'Orbitron',
        kind: WidgetFontKind.digit,
        file: 'orbitron.ttf',
        bytes: 1,
        sha256: '0' * 64,
      );
      final fontLibrary = FontLibraryController()
        ..installed = [asset]
        ..loading = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith((ref) => controller),
            fontLibraryProvider.overrideWith((ref) => fontLibrary),
          ],
          child: glassApp(
            FontLibraryPage(
              catalogFetcher: () async => WidgetFontCatalog(
                version: 1,
                baseUrl: 'https://example.com',
                fonts: [entry],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('font-apply-orbitron')));
      await tester.pumpAndSettle();
      expect(controller.state.settings.widgetFontFamily, 'catalog:orbitron');
      expect(saved.last.widgetFontFamily, 'catalog:orbitron');
      expect(saved.last.widgetDigitFontPath, '/tmp/orbitron.ttf');
    });

    testWidgets('字体库内置许可证文本可查看', (tester) async {
      phoneViewport(tester);
      final controller = buildController(<AppSettings>[]);
      final fontLibrary = FontLibraryController()..loading = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith((ref) => controller),
            fontLibraryProvider.overrideWith((ref) => fontLibrary),
          ],
          child: glassApp(
            FontLibraryPage(
              catalogFetcher: () async => const WidgetFontCatalog(
                version: 1,
                baseUrl: 'https://example.com',
                fonts: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('DSEG7 Classic'), 300);
      await tester.tap(find.text('DSEG7 Classic'));
      await tester.pumpAndSettle();
      expect(find.textContaining('SIL OPEN FONT LICENSE'), findsOneWidget);
    });

    testWidgets('事件列表模式开关持久化', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.widget),
      );
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
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.notifications),
      );
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

    testWidgets('数据管理分区渲染', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.data),
      );
      await flushPlatform(tester);

      expect(find.text('数据管理'), findsWidgets);
      expect(find.text('导出数据'), findsOneWidget);
      expect(find.text('导入数据'), findsOneWidget);
      expect(find.text('清除所有事件'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('更新与关于分区渲染', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.updateAbout),
      );
      await flushPlatform(tester);

      expect(find.text('萤 $appVersion'), findsOneWidget);
      expect(find.text('github.com/jiuxina/ying'), findsOneWidget);
      expect(find.text('赞助支持'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('导出数据复制事件到剪贴板', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      await controller.saveEvent(makeEvent(title: '剪贴板事件'));
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.data),
      );
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
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.data),
      );
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
      await tester.pumpWidget(
        buildSettingsPage(controller, category: SettingsCategory.data),
      );
      await flushPlatform(tester);

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

    testWidgets('右上角设置按钮进入二级页，分类进入三级页', (tester) async {
      phoneViewport(tester);
      final saved = <AppSettings>[];
      final controller = buildController(saved);
      SharedPreferences.setMockInitialValues({});
      await controller.load(runAutoCheck: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) => controller)],
          child: MaterialApp(theme: AppTheme.light(), home: const HomePage()),
        ),
      );
      await tester.pump();

      expect(find.text('日子'), findsOneWidget);
      expect(find.text('日历'), findsOneWidget);
      expect(find.text('萤'), findsNothing);
      expect(find.byType(CircleAvatar), findsOneWidget);
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<AssetImage>());
      expect(avatar.backgroundColor, Colors.transparent);
      final avatarTop = tester.getTopLeft(find.byType(CircleAvatar)).dy;
      final settingsTop = tester.getTopLeft(find.byTooltip('设置')).dy;
      final settingsBottom = tester.getBottomLeft(find.byTooltip('设置')).dy;
      expect(avatarTop, greaterThan(settingsTop));
      expect(
        tester.getTopLeft(find.text('还没有日子')).dy,
        greaterThan(settingsBottom),
      );
      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('外观与显示'), findsOneWidget);

      for (final category in SettingsCategory.values) {
        await tester.tap(find.text(category.label));
        await tester.pump(const Duration(milliseconds: 350));
        await flushPlatform(tester);
        expect(find.text(category.label), findsWidgets);
        await tester.tap(find.byKey(const ValueKey('settings-category-back')));
        await tester.pumpAndSettle();
        expect(find.text('设置'), findsOneWidget);
      }
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

    testWidgets('空状态预览补齐天数占位', (tester) async {
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: SingleChildScrollView(
              child: WidgetPreviewSection(
                events: const [],
                settings: const AppSettings(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('添加一个倒数日'), findsNWidgets(2));
      expect(find.text('--'), findsNWidgets(2));
      expect(find.text('天'), findsNWidgets(2));
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.text('萤'), findsOneWidget);
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
      expect(find.text('学习'), findsNWidgets(2));
      handle.dispose();
    });

    testWidgets('临近高亮在预览中替换文案', (tester) async {
      final base = DateTime.now();
      final today = DateTime(base.year, base.month, base.day);
      final urgentEvent = CountdownEvent(
        id: 'urgent-preview',
        title: '考试',
        targetDate: today.add(const Duration(days: 2, hours: 9)),
        category: '学习',
        createdAt: today.subtract(const Duration(days: 2)),
      );
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: WidgetPreviewSection(
              events: [urgentEvent],
              settings: const AppSettings(widgetUrgentHighlight: true),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('只剩2天'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('趣味主题预览同步渲染且不抛异常', (tester) async {
      final base = DateTime.now();
      final today = DateTime(base.year, base.month, base.day);
      final todayEvent = CountdownEvent(
        id: 'fun-preview',
        title: '毕业',
        targetDate: today,
        category: '重要',
        createdAt: today.subtract(const Duration(days: 2)),
      );
      for (final style in [
        WidgetStyle.envelope,
        WidgetStyle.capsule,
        WidgetStyle.crt,
        WidgetStyle.neonSign,
        WidgetStyle.pixelHealth,
        WidgetStyle.mirror,
      ]) {
        await tester.pumpWidget(
          glassApp(
            Scaffold(
              body: WidgetPreviewSection(
                events: [todayEvent],
                settings: AppSettings(widgetStyle: style),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: WidgetPreviewSection(
              events: [todayEvent],
              settings: const AppSettings(widgetStyle: WidgetStyle.capsule),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('恭喜！'), findsWidgets);
      expect(find.text('就是今天'), findsWidgets);

      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: WidgetPreviewSection(
              events: [todayEvent],
              settings: const AppSettings(widgetStyle: WidgetStyle.envelope),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('神秘信封'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('逐元素样式同步渲染到预览', (tester) async {
      final base = DateTime.now();
      final today = DateTime(base.year, base.month, base.day);
      final event = CountdownEvent(
        id: 'styled-preview',
        title: '考试',
        targetDate: today.add(const Duration(days: 5)),
        category: '学习',
        note: '加油',
        createdAt: today.subtract(const Duration(days: 2)),
      );
      await tester.pumpWidget(
        glassApp(
          Scaffold(
            body: WidgetPreviewSection(
              events: [event],
              settings: const AppSettings(
                widgetElementStyles: {
                  'title': WidgetElementStyle(
                    size: WidgetElementSize.xlarge,
                    sizeScale: 1.5,
                    colorMode: WidgetColorMode.custom,
                    color: 0xFFE91E63,
                    align: WidgetAlign.end,
                  ),
                  'category': WidgetElementStyle(
                    visible: WidgetElementVisible.hide,
                  ),
                  'days': WidgetElementStyle(
                    visible: WidgetElementVisible.hide,
                  ),
                },
                widgetVerticalAlign: WidgetVerticalAlign.bottom,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final titleTexts = tester.widgetList<Text>(find.text('考试')).toList();
      expect(titleTexts.first.style?.color, const Color(0xFFE91E63));
      expect(titleTexts.first.style?.fontSize, 15 * 1.5);
      expect(titleTexts.last.style?.fontSize, 18 * 1.5);
      expect(titleTexts.first.textAlign, TextAlign.end);
      expect(find.text('学习'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('极端字号与逐元素样式组合预览不溢出', (tester) async {
      final base = DateTime.now();
      final today = DateTime(base.year, base.month, base.day);
      final event = CountdownEvent(
        id: 'extreme-preview',
        title: '考试',
        targetDate: today.add(const Duration(days: 5)),
        category: '学习',
        note: '加油',
        createdAt: today.subtract(const Duration(days: 2)),
      );
      const elementIds = [
        'category',
        'holidayBadge',
        'title',
        'days',
        'unit',
        'note',
        'precise',
        'dateInfo',
        'progress',
        'icon',
        'listHeader',
        'rowTitle',
        'rowSubtitle',
        'rowDays',
        'rowUnit',
        'empty',
      ];
      final styles = <String, WidgetElementStyle>{
        for (final id in elementIds)
          id: WidgetElementStyle(
            sizeScale: 1.6,
            weight: widgetNonTextElementIds.contains(id) ? 0 : 900,
            colorMode: WidgetColorMode.custom,
            color: 0xFFFFD60A,
            align: WidgetAlign.center,
          ),
      };
      for (final listMode in [false, true]) {
        await tester.pumpWidget(
          glassApp(
            Scaffold(
              body: SingleChildScrollView(
                child: WidgetPreviewSection(
                  events: [event],
                  settings: AppSettings(
                    widgetListMode: listMode,
                    widgetFontScale: 1.5,
                    widgetContentMargin: 4,
                    widgetShowIcon: true,
                    widgetShowProgress: true,
                    widgetShowPreciseTime: true,
                    widgetShowLunarWeek: true,
                    widgetUrgentHighlight: true,
                    widgetShowNote: true,
                    widgetShowCategory: true,
                    widgetElementStyles: styles,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
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
