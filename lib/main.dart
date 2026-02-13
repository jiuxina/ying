import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:home_widget/home_widget.dart';

import 'providers/events_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'widgets/particle_background.dart';

import 'utils/route_observer.dart'; // import for globalRouteObserver

import 'pages/widget_config_page.dart';

/// 应用入口
///
/// 初始化必要的服务和状态管理，然后启动应用。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date localization
  await initializeDateFormatting('zh_CN', null);

  // Initialize home widget
  await HomeWidget.setAppGroupId(AppConstants.appGroupId);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // Initialize events
  final eventsProvider = EventsProvider();
  await eventsProvider.init();

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
