import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:home_widget/home_widget.dart';
// ignore: unused_import
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'l10n/app_localizations.dart';
import 'providers/events_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/batch_operations_provider.dart';
import 'services/notification_service.dart';
import 'services/debug_service.dart';
import 'services/widget_update_scheduler.dart';
import 'services/cloud_sync_service.dart';
import 'services/webdav_service.dart';
import 'services/font_service.dart';
import 'screens/main_screen.dart';
import 'screens/event_detail_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'widgets/particle_background.dart';
import 'widgets/global_particle_overlay.dart';
import 'widgets/debug/debug_overlay_widget.dart';

import 'utils/route_observer.dart'; // import for globalRouteObserver

import 'pages/widget_config_page.dart';
import 'widgets/startup_auth_wrapper.dart';

// 全局导航器键，用于在没有 BuildContext 的情况下导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 悬浮窗入口点
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DebugOverlayWidget(),
    ),
  );
}

/// 应用入口
///
/// 初始化必要的服务和状态管理，然后启动应用。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date localization
  await initializeDateFormatting('zh_CN', null);

  // Initialize home widget
  await HomeWidget.setAppGroupId(AppConstants.appGroupId);

  // Load custom fonts
  await FontService.loadAllCustomFonts();

  // Initialize settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // Initialize events
  final eventsProvider = EventsProvider();
  await eventsProvider.init();

  // Initialize batch operations provider
  final batchOpsProvider = BatchOperationsProvider(eventsProvider: eventsProvider);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize debug service
  final debugService = DebugService();
  if (settingsProvider.debugModeEnabled) {
    await debugService.initialize();
    debugService.info('App started', source: 'Main');
  }
  
  // Request notification permissions
  final permissionGranted = await notificationService.requestPermissions();
  if (!permissionGranted) {
    debugPrint('⚠️ 通知权限未授予，通知功能可能无法正常工作');
    debugPrint('提示：请在系统设置中为本应用启用通知权限');
  } else {
    debugPrint('✓ 通知权限已授予');
  }
  
  // 检查是否需要在开机后恢复通知
  final needsBootRestore = await notificationService.checkBootRestoreNeeded();
  if (needsBootRestore) {
    debugPrint('检测到系统重启，正在恢复通知调度...');
    debugService.info('Boot restore detected, restoring notifications', source: 'Main');
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
  
  // 清除开机恢复标记
  if (needsBootRestore) {
    await notificationService.clearBootRestoreFlag();
    debugPrint('✓ 通知调度已恢复');
    debugService.info('Notifications restored after boot', source: 'Main');
  }
  
  // 打印通知诊断信息（帮助用户排查问题）
  await notificationService.printNotificationDiagnostics();

  // 设置系统 UI 样式 - 沉浸式状态栏
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 注意：具体的颜色和亮度由 AppTheme 中的 appBarTheme.systemOverlayStyle 控制

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: eventsProvider),
        ChangeNotifierProvider.value(value: batchOpsProvider),
      ],
      child: const YingApp(),
    ),
  );
}

/// 萤 - 倒数日应用
///
/// 使用 MaterialApp 作为根组件，配置主题、路由和全局装饰。
class YingApp extends StatefulWidget {
  const YingApp({super.key});

  @override
  State<YingApp> createState() => _YingAppState();
}

class _YingAppState extends State<YingApp> with WidgetsBindingObserver {
  final DebugService _debugService = DebugService();
  CloudSyncService? _cloudSyncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 启动 Widget 午夜更新调度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWidgetScheduler();
      // 检查并执行自动同步
      _checkAutoSync();
    });
  }
  
  void _startWidgetScheduler() {
    final eventsProvider = context.read<EventsProvider>();
    WidgetUpdateScheduler.instance.startScheduling(eventsProvider.events);
  }
  
  /// 检查并执行自动同步
  Future<void> _checkAutoSync() async {
    final settings = context.read<SettingsProvider>();
    
    // 检查是否启用了自动同步且已配置 WebDAV
    if (!settings.autoSyncEnabled || !settings.isWebdavConfigured) {
      return;
    }
    
    // 检查上次同步时间，如果超过1小时则执行同步
    final lastSync = settings.lastSyncTime;
    if (lastSync != null) {
      final timeSinceLastSync = DateTime.now().difference(lastSync);
      // 如果距离上次同步不到1小时，跳过
      if (timeSinceLastSync.inHours < 1) {
        debugPrint('自动同步: 距离上次同步不到1小时，跳过');
        return;
      }
    }
    
    // 执行自动备份
    await _performAutoBackup(settings);
  }
  
  /// 执行自动备份
  Future<void> _performAutoBackup(SettingsProvider settings) async {
    try {
      debugPrint('自动同步: 开始执行自动备份...');
      
      // 初始化 WebDAV 服务
      final webdavService = WebDAVService();
      webdavService.initialize(WebDAVConfig(
        url: settings.webdavUrl,
        username: settings.webdavUsername,
        password: settings.webdavPassword,
      ));
      
      // 创建云同步服务
      _cloudSyncService = CloudSyncService(webdavService: webdavService);
      
      // 执行备份
      final result = await _cloudSyncService!.backup();
      
      if (result.success) {
        await settings.updateLastSyncTime();
        debugPrint('自动同步: 备份成功');
        _debugService.info('Auto backup completed successfully', source: 'CloudSync');
      } else {
        debugPrint('自动同步: 备份失败 - ${result.errorMessage}');
        _debugService.info('Auto backup failed: ${result.errorMessage}', source: 'CloudSync');
      }
    } catch (e) {
      debugPrint('自动同步: 备份异常 - $e');
      _debugService.error('Auto backup error: $e', source: 'CloudSync');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetUpdateScheduler.instance.stopScheduling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _debugService.updateAppState('Resumed');
        // 应用恢复时刷新 Widget
        WidgetUpdateScheduler.instance.refreshNow();
        // 检查并执行自动同步
        _checkAutoSync();
        break;
      case AppLifecycleState.inactive:
        _debugService.updateAppState('Inactive');
        break;
      case AppLifecycleState.paused:
        _debugService.updateAppState('Paused');
        break;
      case AppLifecycleState.detached:
        _debugService.updateAppState('Detached');
        break;
      case AppLifecycleState.hidden:
        _debugService.updateAppState('Hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,  // 设置全局导航器键
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // 国际化支持
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'), // 简体中文
        Locale('en'), // 英文
      ],
      locale: settings.locale,
      // localeResolutionCallback: 确保正确匹配语言
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return const Locale('zh');
        }
        // 首先尝试完全匹配
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        // 默认返回中文
        return const Locale('zh');
      },
      theme: AppTheme.lightTheme(
        settings.themeColor,
        fontFamily: settings.fontFamily,
        fontSizePx: settings.fontSizePx,
        buttonStyleMode: settings.buttonStyleMode,
        cardOpacity: settings.cardOpacity,
      ),
      darkTheme: AppTheme.darkTheme(
        settings.themeColor,
        fontFamily: settings.fontFamily,
        fontSizePx: settings.fontSizePx,
        buttonStyleMode: settings.buttonStyleMode,
        cardOpacity: settings.cardOpacity,
      ),
      themeMode: settings.themeMode,
      navigatorObservers: [globalRouteObserver],
      home: const StartupAuthWrapper(
        child: MainScreen(),
      ),
      routes: {
        '/widget_config': (context) => const WidgetConfigPage(),
      },
      builder: (context, child) {
        return GlobalParticleOverlay(
          child: ParticleBackground(
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}
