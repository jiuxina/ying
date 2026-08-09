import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/countdown_event.dart';
import '../models/event_reminder.dart';
import 'storage_service.dart';
import 'widget_service.dart';
import '../utils/event_repeat_utils.dart';

const notificationActionComplete = 'ying_complete';
const notificationActionSnooze = 'ying_snooze_1h';
const notificationCategoryReminder = 'ying_reminder_actions_v1';

class ReminderOccurrence {
  const ReminderOccurrence({
    required this.event,
    required this.reminder,
    required this.scheduledAt,
  });

  final CountdownEvent event;
  final EventReminder reminder;
  final DateTime scheduledAt;
}

class NotificationDiagnostics {
  const NotificationDiagnostics({
    required this.notificationsEnabled,
    required this.pendingCount,
    this.nextReminder,
    this.error,
  });

  final bool? notificationsEnabled;
  final int pendingCount;
  final ReminderOccurrence? nextReminder;
  final String? error;
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  final _responses = StreamController<NotificationResponse>.broadcast();
  final _initializationCompleter = Completer<void>();
  bool _initialized = false;
  NotificationResponse? _initialResponse;

  Stream<NotificationResponse> get responses => _responses.stream;

  /// 初始化完成信号；界面可据此在后台初始化完成后处理冷启动通知。
  Future<void> get initialized => _initializationCompleter.future;

  NotificationResponse? takeInitialResponse() {
    final response = _initialResponse;
    _initialResponse = null;
    return response;
  }

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
      return;
    }
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      final ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            notificationCategoryReminder,
            actions: [
              DarwinNotificationAction.plain(notificationActionComplete, '完成'),
              DarwinNotificationAction.plain(notificationActionSnooze, '1 小时后提醒'),
            ],
          ),
        ],
      );
      await _plugin.initialize(
        InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _responses.add,
        onDidReceiveBackgroundNotificationResponse:
            notificationBackgroundResponse,
      );
      tz_data.initializeTimeZones();
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        _initialResponse = launchDetails?.notificationResponse;
      }
      _initialized = true;
    } finally {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  /// 已授权时直接返回 true，未授权或状态未知时才触发系统权限请求。
  Future<bool> ensureNotificationPermission() async {
    await initialize();
    try {
      final enabled = await _notificationsEnabled();
      if (enabled == true) return true;
    } catch (_) {
      // 平台实现缺失或查询失败时退回请求流程。
    }
    return requestPermission();
  }

  static const _settingsChannel = MethodChannel('ying/settings');

  /// 打开系统通知设置页，用于通知权限被拒后的引导。
  Future<void> openAppNotificationSettings() async {
    try {
      await _settingsChannel.invokeMethod<void>('openAppNotificationSettings');
    } on MissingPluginException {
      // 桌面或测试环境没有原生实现，静默忽略。
    } catch (_) {
      // 打开失败不打断当前流程。
    }
  }

  Future<void> schedule(CountdownEvent event) async {
    await initialize();
    await cancel(event.id);
    if (event.isCompleted) return;
    for (final reminder in event.reminders.where((value) => value.enabled)) {
      final occurrence = occurrenceFor(event, reminder);
      if (!occurrence.scheduledAt.isAfter(DateTime.now())) continue;
      await _scheduleOccurrence(occurrence);
    }
  }

  Future<void> scheduleSnooze(
    CountdownEvent event, {
    Duration duration = const Duration(hours: 1),
  }) async {
    await initialize();
    if (event.isCompleted) return;
    final scheduledAt = DateTime.now().add(duration);
    final reminder = EventReminder(
      id: 'snooze-${scheduledAt.millisecondsSinceEpoch}',
      minutesBefore: 0,
    );
    await _scheduleOccurrence(
      ReminderOccurrence(
        event: event,
        reminder: reminder,
        scheduledAt: scheduledAt,
      ),
      body: '“${event.title}”的稍后提醒',
    );
  }

  Future<void> cancel(String eventId) async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (_eventIdFromPayload(request.payload) == eventId) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> rescheduleAll(List<CountdownEvent> events) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
    final now = DateTime.now();
    final occurrences = <ReminderOccurrence>[
      for (final event in events.where((value) => !value.isCompleted))
        for (final reminder in event.reminders.where((value) => value.enabled))
          occurrenceFor(event, reminder),
    ]
      ..removeWhere((occurrence) => !occurrence.scheduledAt.isAfter(now))
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final limit = defaultTargetPlatform == TargetPlatform.iOS ? 60 : null;
    for (final occurrence in occurrences.take(limit ?? occurrences.length)) {
      await _scheduleOccurrence(occurrence);
    }
  }

  Future<NotificationDiagnostics> diagnostics(
    List<CountdownEvent> events,
  ) async {
    try {
      await initialize();
      final pending = await _plugin.pendingNotificationRequests();
      final enabled = await _notificationsEnabled();
      return NotificationDiagnostics(
        notificationsEnabled: enabled,
        pendingCount: pending.length,
        nextReminder: nextOccurrence(events),
      );
    } catch (error) {
      return NotificationDiagnostics(
        notificationsEnabled: null,
        pendingCount: 0,
        nextReminder: nextOccurrence(events),
        error: error.toString(),
      );
    }
  }

  Future<void> scheduleTestNotification() async {
    await initialize();
    final scheduledAt = DateTime.now().add(const Duration(seconds: 5));
    await _plugin.zonedSchedule(
      stableNotificationId('diagnostic', 'test'),
      '萤 · 测试提醒',
      '如果你看到这条通知，基础提醒调度工作正常。',
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ying_reminders',
          '倒数日提醒',
          channelDescription: '倒数日事件的提前提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '{"type":"diagnostic"}',
    );
  }

  ReminderOccurrence occurrenceFor(
    CountdownEvent event,
    EventReminder reminder,
  ) {
    return ReminderOccurrence(
      event: event,
      reminder: reminder,
      scheduledAt: event.reminderAnchor.subtract(
        Duration(minutes: reminder.minutesBefore),
      ),
    );
  }

  ReminderOccurrence? nextOccurrence(List<CountdownEvent> events) {
    final now = DateTime.now();
    final occurrences = <ReminderOccurrence>[
      for (final event in events.where((value) => !value.isCompleted))
        for (final reminder in event.reminders.where((value) => value.enabled))
          if (occurrenceFor(event, reminder).scheduledAt.isAfter(now))
            occurrenceFor(event, reminder),
    ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return occurrences.firstOrNull;
  }

  static int stableNotificationId(String eventId, String reminderId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in '$eventId|$reminderId'.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  Future<void> _scheduleOccurrence(
    ReminderOccurrence occurrence, {
    String? body,
  }) async {
    final event = occurrence.event;
    final reminder = occurrence.reminder;
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'ying_reminders',
        '倒数日提醒',
        channelDescription: '倒数日事件的提前提醒',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        actions: [
          AndroidNotificationAction(
            notificationActionComplete,
            '完成',
            semanticAction: SemanticAction.markAsRead,
          ),
          AndroidNotificationAction(notificationActionSnooze, '1 小时后提醒'),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: notificationCategoryReminder,
      ),
    );
    await _plugin.zonedSchedule(
      stableNotificationId(event.id, reminder.id),
      event.title,
      body ?? _notificationBody(event, reminder.minutesBefore),
      tz.TZDateTime.from(occurrence.scheduledAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _payload(event.id, reminder.id),
    );
  }

  Future<bool?> _notificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return permissions?.isEnabled;
    }
    return null;
  }

  String _payload(String eventId, String reminderId) => jsonEncode({
    'type': 'event',
    'eventId': eventId,
    'reminderId': reminderId,
  });

  String _notificationBody(CountdownEvent event, int minutes) {
    if (minutes == 0) return '“${event.title}”就在现在';
    if (minutes >= 1440 && minutes % 1440 == 0) {
      return '距离“${event.title}”还有 ${minutes ~/ 1440} 天';
    }
    if (minutes >= 60 && minutes % 60 == 0) {
      return '距离“${event.title}”还有 ${minutes ~/ 60} 小时';
    }
    return '距离“${event.title}”还有 $minutes 分钟';
  }
}

String? eventIdFromNotificationResponse(NotificationResponse response) =>
    _eventIdFromPayload(response.payload);

String? _eventIdFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final value = jsonDecode(payload) as Map<String, dynamic>;
    return value['eventId'] as String?;
  } on FormatException {
    return payload;
  }
}

@pragma('vm:entry-point')
Future<void> notificationBackgroundResponse(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  final eventId = eventIdFromNotificationResponse(response);
  if (eventId == null) return;
  final storage = StorageService();
  final events = await storage.loadEvents();
  final index = events.indexWhere((event) => event.id == eventId);
  if (index < 0) return;
  final event = events[index];

  if (response.actionId == notificationActionComplete) {
    final updated = completeEvent(event);
    await NotificationService.instance.cancel(eventId);
    events[index] = updated;
    await storage.saveEvents(events);
    if (updated.repeatsYearly) {
      await NotificationService.instance.schedule(updated);
    }
    final settings = await storage.loadSettings();
    await WidgetService.sync(events, settings);
    await storage.markNotificationAction();
    return;
  }
  if (response.actionId == notificationActionSnooze) {
    await NotificationService.instance.scheduleSnooze(event);
    await storage.markNotificationAction();
  }
}

