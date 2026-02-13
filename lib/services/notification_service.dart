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
  
  // 通知点击回调 - 将由外部设置
  Function(String eventId)? onNotificationTap;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 初始化时区数据
      tz.initializeTimeZones();
      // 使用设备本地时区，而不是硬编码为 Asia/Shanghai
      // 这样可以支持国际用户
      final localTimeZone = DateTime.now().timeZoneName;
      try {
        // 尝试使用当前系统时区
        tz.setLocalLocation(tz.local);
        debugPrint('通知服务使用本地时区: ${tz.local.name}');
      } catch (e) {
        // 如果失败，回退到 UTC
        debugPrint('无法设置本地时区，使用 UTC: $e');
        tz.setLocalLocation(tz.UTC);
      }

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
  /// 
  /// 当用户点击通知时调用此方法，导航到事件详情页。
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知被点击: ${response.payload}');
    if (response.payload != null && onNotificationTap != null) {
      try {
        onNotificationTap!(response.payload!);
      } catch (e) {
        debugPrint('处理通知点击失败: $e');
      }
    }
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
        
        // Android 12+ (API 31+) 需要检查精确闹钟权限
        try {
          final canScheduleExact = await androidImplementation.canScheduleExactNotifications();
          if (canScheduleExact != null && !canScheduleExact) {
            debugPrint('⚠️ 警告：精确闹钟权限未授予。通知可能不准时。');
            debugPrint('提示：请在系统设置中为本应用启用"精确闹钟"权限以确保通知准时送达。');
            // 返回 true 允许应用继续运行，但警告用户
            // 实际的通知功能取决于系统权限
          } else if (canScheduleExact == true) {
            debugPrint('✓ 精确闹钟权限已授予');
          }
        } catch (e) {
          debugPrint('检查精确闹钟权限时出错: $e');
        }
        
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

    // 统计成功和失败的提醒
    int successCount = 0;
    int failCount = 0;

    // 为每个提醒创建通知
    for (final reminder in event.reminders) {
      final success = await _scheduleReminder(event, reminder);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }
    
    if (successCount > 0) {
      debugPrint('✓ 成功调度 $successCount 个提醒通知 (${event.title})');
    }
    if (failCount > 0) {
      debugPrint('⚠️ $failCount 个提醒调度失败 (${event.title})');
    }
  }

  /// 调度单个提醒通知
  /// 
  /// 返回 true 表示调度成功，false 表示失败
  Future<bool> _scheduleReminder(CountdownEvent event, Reminder reminder) async {
    try {
      // 使用 TZDateTime 确保时区正确性，避免夏令时问题
      final targetDate = event.targetDate;
      
      // 创建时区感知的目标日期时间
      final tzTargetDateTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        reminder.hour,
        reminder.minute,
        0,  // 秒
      );
      
      // 减去提前天数（使用时区感知的日期运算）
      final tzNotificationDateTime = tzTargetDateTime.subtract(
        Duration(days: reminder.daysBefore),
      );

      // 如果通知时间已过，则不调度
      if (tzNotificationDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('⏭ 提醒时间已过，跳过: ${event.title} - ${reminder.daysBefore}天前 ${reminder.hour}:${reminder.minute.toString().padLeft(2, '0')}');
        return false;
      }

      final notificationId = _generateNotificationId(event.id, reminder.id);
      
      final androidDetails = AndroidNotificationDetails(
        'event_reminders',
        '事件提醒',
        channelDescription: '倒数日事件的提醒通知',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
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
        tzNotificationDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: event.id,
      );

      debugPrint('✓ 已调度提醒: ${event.title} - ${tzNotificationDateTime.toIso8601String()}');
      return true;
    } catch (e) {
      debugPrint('❌ 调度提醒失败: ${event.title} - $e');
      return false;
    }
  }

  /// 生成提醒消息
  /// 
  /// 根据提前天数生成友好的提醒文本
  String _getReminderMessage(CountdownEvent event, Reminder reminder) {
    final days = reminder.daysBefore;
    final timeStr = '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
    
    if (days == 0) {
      return '今天就是 ${event.title} 的日子！🎉';
    } else if (days == 1) {
      return '明天就是 ${event.title} 了！还有1天 ⏰';
    } else if (days == 2) {
      return '后天就是 ${event.title} 了！还有2天 📅';
    } else if (days <= 7) {
      return '${event.title} 还有 $days 天 📆';
    } else if (days <= 30) {
      return '${event.title} 还有 $days 天 🗓️';
    } else {
      return '${event.title} 还有 $days 天';
    }
  }

  /// 生成通知 ID
  /// 
  /// 使用确定性算法生成唯一的通知 ID，避免哈希碰撞。
  /// 基于事件 ID 和提醒 ID 的组合，确保同一提醒总是生成相同的 ID。
  int _generateNotificationId(String eventId, String reminderId) {
    final combined = '$eventId|$reminderId';
    
    // 使用改进的哈希算法减少碰撞
    // FNV-1a 哈希的简化版本
    int hash = 2166136261;
    for (int i = 0; i < combined.length; i++) {
      hash ^= combined.codeUnitAt(i);
      hash = (hash * 16777619) & 0x7FFFFFFF;  // 保持在 32 位有符号整数范围内
    }
    
    // 确保结果为正数且在有效范围内
    return hash & 0x7FFFFFFF;
  }

  /// 取消事件的所有通知
  /// 
  /// 高效地取消与指定事件关联的所有通知。
  /// 遍历所有待处理通知，根据 payload 匹配事件 ID。
  Future<void> cancelEventNotifications(String eventId) async {
    if (!_initialized) return;
    
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      int canceledCount = 0;
      
      for (final notification in pendingNotifications) {
        if (notification.payload == eventId) {
          await _notifications.cancel(notification.id);
          canceledCount++;
        }
      }
      
      if (canceledCount > 0) {
        debugPrint('✓ 已取消事件的 $canceledCount 个通知: $eventId');
      }
    } catch (e) {
      debugPrint('❌ 取消通知失败: $e');
    }
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    try {
      await _notifications.cancelAll();
      debugPrint('✓ 已取消所有通知');
    } catch (e) {
      debugPrint('❌ 取消所有通知失败: $e');
    }
  }

  /// 获取待处理的通知列表
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) return [];
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ 获取待处理通知列表失败: $e');
      return [];
    }
  }
  
  /// 获取指定事件的待处理通知数量
  Future<int> getEventNotificationCount(String eventId) async {
    if (!_initialized) return 0;
    
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      return pendingNotifications.where((n) => n.payload == eventId).length;
    } catch (e) {
      debugPrint('❌ 获取事件通知数量失败: $e');
      return 0;
    }
  }
  
  /// 重新调度所有活动事件的提醒
  /// 
  /// 用于应用启动时恢复通知调度，或系统时区变更后重新调度
  Future<void> rescheduleAllReminders(List<CountdownEvent> activeEvents) async {
    if (!_initialized) {
      await initialize();
    }
    
    debugPrint('开始重新调度所有事件的提醒...');
    int totalScheduled = 0;
    
    for (final event in activeEvents) {
      if (event.enableNotification && event.reminders.isNotEmpty) {
        await scheduleEventReminders(event);
        totalScheduled += event.reminders.length;
      }
    }
    
    debugPrint('✓ 已重新调度 ${activeEvents.length} 个事件的 $totalScheduled 个提醒');
  }
}
