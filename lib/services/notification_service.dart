import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/countdown_event.dart';
import '../models/reminder.dart';

/// 通知服务
/// 
/// 负责管理本地通知的初始化、调度和取消。
/// 支持 Android 和 iOS 平台的通知功能。
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 初始化时区数据
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

      // Android 初始化设置
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS 初始化设置
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      debugPrint('通知服务初始化成功');
    } catch (e) {
      debugPrint('通知服务初始化失败: $e');
    }
  }

  /// 处理通知点击事件
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知被点击: ${response.payload}');
    // TODO: 根据 payload 跳转到对应事件详情页
  }

  /// 请求通知权限
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Android 13+ 需要请求通知权限
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// 为事件安排所有提醒通知
  Future<void> scheduleEventReminders(CountdownEvent event) async {
    if (!_initialized) {
      await initialize();
    }

    if (!event.enableNotification || event.reminders.isEmpty) {
      return;
    }

    // 取消该事件的所有旧通知
    await cancelEventNotifications(event.id);

    // 为每个提醒创建通知
    for (final reminder in event.reminders) {
      await _scheduleReminder(event, reminder);
    }
  }

  /// 调度单个提醒通知
  Future<void> _scheduleReminder(CountdownEvent event, Reminder reminder) async {
    try {
      final targetDate = event.targetDate;
      final notificationDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        reminder.hour,
        reminder.minute,
      ).subtract(Duration(days: reminder.daysBefore));

      // 如果通知时间已过，则不调度
      if (notificationDate.isBefore(DateTime.now())) {
        debugPrint('提醒时间已过，跳过: ${event.title} - ${reminder.daysBefore}天前');
        return;
      }

      final notificationId = _generateNotificationId(event.id, reminder.id);
      
      final androidDetails = AndroidNotificationDetails(
        'event_reminders',
        '事件提醒',
        channelDescription: '倒数日事件的提醒通知',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          _getReminderMessage(event, reminder),
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        event.title,
        _getReminderMessage(event, reminder),
        tz.TZDateTime.from(notificationDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: event.id,
      );

      debugPrint('已调度提醒: ${event.title} - ${notificationDate}');
    } catch (e) {
      debugPrint('调度提醒失败: $e');
    }
  }

  /// 生成提醒消息
  String _getReminderMessage(CountdownEvent event, Reminder reminder) {
    final days = reminder.daysBefore;
    if (days == 0) {
      return '今天就是 ${event.title} 的日子！';
    } else if (days == 1) {
      return '明天就是 ${event.title} 了！';
    } else {
      return '还有 $days 天就是 ${event.title} 了！';
    }
  }

  /// 生成通知 ID（使用事件 ID 和提醒 ID 的哈希）
  int _generateNotificationId(String eventId, String reminderId) {
    return '${eventId}_$reminderId'.hashCode.abs() % 2147483647;
  }

  /// 取消事件的所有通知
  Future<void> cancelEventNotifications(String eventId) async {
    if (!_initialized) return;
    
    try {
      // 注意：由于我们使用哈希生成 ID，无法直接获取所有相关通知
      // 建议：在数据库中存储通知 ID，或使用固定的 ID 生成规则
      // 当前实现：取消所有待处理通知（性能考虑，仅用于演示）
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      for (final notification in pendingNotifications) {
        if (notification.payload == eventId) {
          await _notifications.cancel(notification.id);
        }
      }
      debugPrint('已取消事件通知: $eventId');
    } catch (e) {
      debugPrint('取消通知失败: $e');
    }
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    await _notifications.cancelAll();
    debugPrint('已取消所有通知');
  }

  /// 获取待处理的通知列表
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) return [];
    return await _notifications.pendingNotificationRequests();
  }
}
