import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ying/services/storage_service.dart';
import 'package:ying/ui/onboarding_page.dart';
import 'package:ying/ui/permission_manage_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('首次引导标记持久化', () async {
    final storage = StorageService();
    expect(await storage.loadOnboardingCompleted(), isFalse);
    await storage.saveOnboardingCompleted();
    expect(await storage.loadOnboardingCompleted(), isTrue);
  });

  testWidgets('首次引导页渲染并可完成', (tester) async {
    mockPlatformChannels(tester);
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(onFinished: () => finished = true),
      ),
    );
    await flushPlatform(tester);

    expect(find.text('欢迎使用'), findsOneWidget);
    expect(find.text('完成基础配置'), findsOneWidget);
    expect(
      find.text('本地优先的倒数日与正计时，事件与提醒只保存在你的设备上。'),
      findsNothing,
    );
    expect(find.text('建议开启，让提醒更稳定'), findsNothing);
    expect(find.text('开始使用'), findsOneWidget);
    expect(find.text('跳过，稍后再设置'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-finish')));
    expect(finished, isTrue);
  });

  testWidgets('权限管理卡片渲染三类权限', (tester) async {
    mockPlatformChannels(tester);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PermissionManageSection())),
    );
    await flushPlatform(tester);

    expect(find.text('权限管理'), findsOneWidget);
    expect(find.text('通知提醒'), findsOneWidget);
    expect(find.text('开机自启动'), findsOneWidget);
    expect(find.text('忽略电池优化'), findsOneWidget);
    expect(find.text('去开启'), findsNWidgets(2));
    expect(find.text('去设置'), findsOneWidget);
  });

  testWidgets('电池优化按钮调用原生通道并给出提示', (tester) async {
    mockPlatformChannels(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PermissionManageSection())),
    );
    await flushPlatform(tester);

    await tester.tap(find.byKey(const ValueKey('permission-battery-action')));
    await flushPlatform(tester);
    await tester.pumpAndSettle();

    expect(find.text('已打开系统页面，请允许萤忽略电池优化'), findsOneWidget);
  });
}

Future<void> flushPlatform(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump();
}

void mockPlatformChannels(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (call) async {
      return switch (call.method) {
        'initialize' => true,
        'getNotificationAppLaunchDetails' => null,
        'areNotificationsEnabled' => false,
        _ => null,
      };
    },
  );
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('ying/permissions'),
    (call) async {
      return switch (call.method) {
        'isIgnoringBatteryOptimizations' => false,
        'requestIgnoreBatteryOptimizations' => const {
            'opened': true,
            'fallback': false,
          },
        'autoStartSupported' => false,
        'openAppDetailsSettings' => false,
        _ => null,
      };
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      null,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('ying/permissions'),
      null,
    );
  });
}
