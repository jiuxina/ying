import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/models/app_settings.dart';
import 'package:ying/models/countdown_event.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/state/app_controller.dart';
import 'package:ying/ui/glass_ui.dart';
import 'package:ying/ui/home_page.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh_CN'));

  Widget glassApp(Widget home, {bool reduceMotion = false}) {
    return MaterialApp(
      builder: (context, child) => AccessibleAppearance(
        reduceTransparency: true,
        reduceMotion: reduceMotion,
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    );
  }

  testWidgets('GlassPressable 按压缩放并在松开后恢复', (tester) async {
    await tester.pumpWidget(
      glassApp(
        Scaffold(
          body: Center(
            child: GlassPressable(
              child: InkWell(
                onTap: () {},
                child: const SizedBox(width: 80, height: 80),
              ),
            ),
          ),
        ),
      ),
    );
    final scale = find.byType(AnimatedScale);
    expect(tester.widget<AnimatedScale>(scale).scale, 1);

    final gesture = await tester.startGesture(const Offset(400, 300));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(scale).scale, 0.97);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
  });

  testWidgets('CrossfadeIndexedStack 切换保留页面状态并收起隐藏页', (tester) async {
    await tester.pumpWidget(
      glassApp(const Scaffold(body: _CrossfadeHarness())),
    );
    expect(find.text('页面甲 0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tap-a')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('switch-b')));
    await tester.pump();

    // 过渡中途：新旧两页同时在场。
    expect(find.text('页面甲 1'), findsOneWidget);
    expect(find.text('页面乙 0'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('页面甲 1'), findsNothing);
    expect(find.text('页面乙 0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('switch-a')));
    await tester.pumpAndSettle();
    expect(find.text('页面甲 1'), findsOneWidget);
  });

  testWidgets('CrossfadeIndexedStack 减少动画时瞬切', (tester) async {
    await tester.pumpWidget(
      glassApp(const Scaffold(body: _CrossfadeHarness()), reduceMotion: true),
    );
    await tester.tap(find.byKey(const ValueKey('switch-b')));
    await tester.pump();
    expect(find.text('页面甲 0'), findsNothing);
    expect(find.text('页面乙 0'), findsOneWidget);
  });

  testWidgets('GlassAnimatedPresence 进场淡入、退场移除', (tester) async {
    await tester.pumpWidget(glassApp(const Scaffold(body: _PresenceHarness())));
    expect(find.text('提示内容'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('toggle-presence')));
    await tester.pump(const Duration(milliseconds: 110));
    expect(find.text('提示内容'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('提示内容'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle-presence')));
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pumpAndSettle();
    expect(find.text('提示内容'), findsNothing);
  });

  testWidgets('GlassReveal 有限时长内完成入场', (tester) async {
    await tester.pumpWidget(
      glassApp(
        const Scaffold(
          body: GlassReveal(
            delay: Duration(milliseconds: 40),
            child: Text('入场内容'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('入场内容'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('入场内容'), findsOneWidget);
  });

  testWidgets('showGlassBottomSheet 打开并关闭', (tester) async {
    await tester.pumpWidget(
      glassApp(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('open-sheet'),
                onPressed: () => showGlassBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (sheetContext) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('玻璃弹层'),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-sheet')));
    await tester.pumpAndSettle();
    expect(find.text('玻璃弹层'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('玻璃弹层'), findsNothing);
  });

  testWidgets('删除事件后撤销横幅出现，过期后消失', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final base = DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final event = CountdownEvent(
      id: 'evt-undo',
      title: '毕业',
      targetDate: today.add(const Duration(days: 29)),
      category: '生活',
      createdAt: today.subtract(const Duration(days: 2)),
    );
    final controller = AppController(
      StorageService(),
      autoLoad: false,
      loadEvents: () async => [event],
      saveEvents: (_) async {},
      loadSettings: () async => const AppSettings(),
      saveSettings: (_) async {},
      scheduleNotification: (_) async {},
      cancelNotification: (_) async {},
      syncWidget: (_, _) async {},
    );
    await controller.load(runAutoCheck: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appControllerProvider.overrideWith((ref) => controller)],
        child: glassApp(const HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('毕业'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('已删除'), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.textContaining('已删除'), findsNothing);
  });
}

class _CrossfadeHarness extends StatefulWidget {
  const _CrossfadeHarness();

  @override
  State<_CrossfadeHarness> createState() => _CrossfadeHarnessState();
}

class _CrossfadeHarnessState extends State<_CrossfadeHarness> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            TextButton(
              key: const ValueKey('switch-a'),
              onPressed: () => setState(() => index = 0),
              child: const Text('切到甲'),
            ),
            TextButton(
              key: const ValueKey('switch-b'),
              onPressed: () => setState(() => index = 1),
              child: const Text('切到乙'),
            ),
          ],
        ),
        Expanded(
          child: CrossfadeIndexedStack(
            index: index,
            children: const [
              _CountPage(label: '页面甲'),
              _CountPage(label: '页面乙'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountPage extends StatefulWidget {
  const _CountPage({required this.label});

  final String label;

  @override
  State<_CountPage> createState() => _CountPageState();
}

class _CountPageState extends State<_CountPage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${widget.label} $count'),
          FilledButton(
            key: const ValueKey('tap-a'),
            onPressed: () => setState(() => count++),
            child: const Text('加一'),
          ),
        ],
      ),
    );
  }
}

class _PresenceHarness extends StatefulWidget {
  const _PresenceHarness();

  @override
  State<_PresenceHarness> createState() => _PresenceHarnessState();
}

class _PresenceHarnessState extends State<_PresenceHarness> {
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          key: const ValueKey('toggle-presence'),
          onPressed: () => setState(() => visible = !visible),
          child: const Text('切换'),
        ),
        GlassAnimatedPresence(
          visible: visible,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('提示内容'),
          ),
        ),
      ],
    );
  }
}
