import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:home_widget/home_widget.dart';

import 'providers/events_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/particle_background.dart';

import 'utils/route_observer.dart'; // import for globalRouteObserver

import 'pages/widget_config_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date localization
  await initializeDateFormatting('zh_CN', null);
  
  // Initialize home widget
  await HomeWidget.setAppGroupId('com.jiuxina.ying');
  
  // Initialize settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();
  
  // Initialize events
  final eventsProvider = EventsProvider();
  await eventsProvider.init();

  // 设置系统 UI 样式
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // 检查是否是 Widget 配置启动
  // 注意：HomeWidget.getWidgetId() 在某些版本可能需要特定的 Intent 处理
  // 这里我们简单起见，在 HomeScreen 做个检查，或者如果能确定是配置启动（比如通过 MethodChannel），更好
  // 暂时在 main 不做跳转，交给 HomeScreen 或者专门的 Launcher
  // 但为了支持路由，我们先注册
  
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

/// 倒数日应用
class YingApp extends StatelessWidget {
  const YingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: '萤',
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
