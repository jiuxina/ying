import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_navigator.dart';
import 'services/notification_service.dart';
import 'services/widget_launch_actions.dart';
import 'services/widget_service.dart';
import 'state/app_controller.dart';
import 'state/unlock_controller.dart';
import 'ui/app_theme.dart';
import 'ui/event_detail_page.dart';
import 'ui/glass_ui.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  runApp(const ProviderScope(child: DaymarkApp()));
  unawaited(_initializePlatformServices());
}

Future<void> _initializePlatformServices() async {
  // 通知与小部件插件初始化失败或挂起时不允许阻塞首帧：各给 3 秒上限，
  // 超时后继续，后续调度/同步会再次尝试初始化。
  try {
    await NotificationService.instance
        .initialize()
        .timeout(const Duration(seconds: 3), onTimeout: () {});
  } catch (_) {}
  try {
    await WidgetService.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
  } catch (_) {}
  _listenForWidgetLaunches();
}

void _listenForWidgetLaunches() {
  HomeWidget.widgetClicked.listen((uri) {
    if (uri != null && uri.scheme == 'ying') {
      unawaited(handleWidgetLaunchUri(uri));
    }
  });
  unawaited(
    HomeWidget.initiallyLaunchedFromHomeWidget().then(handleWidgetLaunchUri),
  );
}

class DaymarkApp extends ConsumerStatefulWidget {
  const DaymarkApp({super.key});

  @override
  ConsumerState<DaymarkApp> createState() => _DaymarkAppState();
}

class _DaymarkAppState extends ConsumerState<DaymarkApp>
    with WidgetsBindingObserver {
  StreamSubscription<NotificationResponse>? _notificationSubscription;
  String? _openEventId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(unlockControllerProvider.notifier).load());
    });
    _notificationSubscription = NotificationService.instance.responses.listen(
      _handleNotificationResponse,
    );
    final initial = NotificationService.instance.takeInitialResponse();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleNotificationResponse(initial),
      );
    }
    unawaited(
      NotificationService.instance.initialized.then((_) {
        final lateInitial = NotificationService.instance.takeInitialResponse();
        if (lateInitial == null || !mounted) return;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleNotificationResponse(lateInitial),
        );
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref
            .read(appControllerProvider.notifier)
            .reloadAfterNotificationAction(),
      );
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == notificationActionComplete ||
        response.actionId == notificationActionSnooze) {
      unawaited(_handleForegroundAction(response));
      return;
    }
    final eventId = eventIdFromNotificationResponse(response);
    if (eventId == null || _openEventId == eventId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null || !mounted) return;
      _openEventId = eventId;
      navigator
          .push<void>(
            GlassPageRoute(
              builder: (context) => EventDetailPage(eventId: eventId),
            ),
          )
          .whenComplete(() => _openEventId = null);
    });
  }

  Future<void> _handleForegroundAction(NotificationResponse response) async {
    final eventId = eventIdFromNotificationResponse(response);
    if (eventId == null) return;
    final controller = ref.read(appControllerProvider.notifier);
    final event = ref
        .read(appControllerProvider)
        .events
        .where((value) => value.id == eventId)
        .firstOrNull;
    if (event == null) {
      await controller.reloadAfterNotificationAction();
      return;
    }
    if (response.actionId == notificationActionComplete && !event.isCompleted) {
      await controller.toggleCompletedWithUndo(event);
    } else if (response.actionId == notificationActionSnooze) {
      await NotificationService.instance.scheduleSnooze(event);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appControllerProvider).settings;
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: '萤',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) => AccessibleAppearance(
        reduceTransparency: settings.reduceTransparency,
        reduceMotion: settings.reduceMotion,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}
