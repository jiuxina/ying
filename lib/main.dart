import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:home_widget/home_widget.dart';

import 'providers/events_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/event_detail_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'widgets/particle_background.dart';

import 'utils/route_observer.dart'; // import for globalRouteObserver

import 'pages/widget_config_page.dart';

// 全局导航器键，用于在没有 BuildContext 的情况下导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 应用入口
///
/// 初始化必要的服务和状态管理，然后启动应用。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date localization
  await initializeDateFormatting('zh_CN', null);

  // Initialize home widget
  await HomeWidget.setAppGroupId(AppConstants.appGroupId);

  // Initialize settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // Initialize events
  final eventsProvider = EventsProvider();
  await eventsProvider.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Request notification permissions
  final permissionGranted = await notificationService.requestPermissions();
  if (!permissionGranted) {
    debugPrint('⚠️ 通知权限未授予，通知功能可能无法正常工作');
    debugPrint('提示：请在系统设置中为本应用启用通知权限');
  } else {
    debugPrint('✓ 通知权限已授予');
  }
  
  // 设置通知点击回调 - 导航到事件详情页
  notificationService.onNotificationTap = (String eventId) {
    try {
      // 查找事件
      final event = eventsProvider.events.firstWhere(
        (e) => e.id == eventId,
      );
      
      if (navigatorKey.currentContext != null) {
        // 导航到事件详情页
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      }
    } on StateError {
      // 事件未找到（可能已被删除）
      debugPrint('通知点击: 事件 $eventId 未找到');
    } catch (e) {
      // 其他意外错误
      debugPrint('通知点击处理失败: $e');
    }
  };
  
  // 重新调度所有活动事件的提醒（应用启动时恢复）
  await notificationService.rescheduleAllReminders(eventsProvider.events);
  
  // 打印通知诊断信息（帮助用户排查问题）
  await notificationService.printNotificationDiagnostics();

  // 设置系统 UI 样式 - 沉浸式状态栏
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: eventsProvider),
      ],
      child: const YingApp(),
    ),
  );
}

/// 萤 - 倒数日应用
///
/// 使用 MaterialApp 作为根组件，配置主题、路由和全局装饰。
class YingApp extends StatelessWidget {
  const YingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,  // 设置全局导航器键
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(
        settings.themeColor,
        fontFamily: settings.fontFamily,
        fontSizePx: settings.fontSizePx,
      ),
      darkTheme: AppTheme.darkTheme(
        settings.themeColor,
        fontFamily: settings.fontFamily,
        fontSizePx: settings.fontSizePx,
      ),
      themeMode: settings.themeMode,
      navigatorObservers: [globalRouteObserver],
      home: const HomeScreen(),
      routes: {
        '/widget_config': (context) => const WidgetConfigPage(),
      },
      builder: (context, child) {
        return ParticleBackground(
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
