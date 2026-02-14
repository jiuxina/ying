import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _initializing = false;  // 防止并发初始化
  
  // 通知点击回调 - 将由外部设置
  Function(String eventId)? onNotificationTap;
  
  // 通知配置常量
  // 振动模式（毫秒）：[延迟, 振动, 暂停, 振动]
  // 第一个值(0)是Android要求的初始延迟，后续为振动-暂停-振动的模式
  static const _vibrationPatternMs = [0, 500, 200, 500];
  static const _ledColor = Color(0xFF2196F3);  // LED颜色：蓝色
  static const _ledOnMs = 1000;  // LED亮起时长（毫秒）
  static const _ledOffMs = 500;  // LED熄灭时长（毫秒）
  static const _initTimeoutSeconds = 30;  // 初始化超时时间（秒）
  
  // 时间常量
  static const _midnightHour = 0;
  static const _midnightMinute = 0;
  static const _midnightSecond = 0;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing) {
      // 等待其他初始化完成（带超时）
      final startTime = DateTime.now();
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 100));
        // 超时检查，防止无限等待
        if (DateTime.now().difference(startTime).inSeconds > _initTimeoutSeconds) {
          debugPrint('⚠️ 等待通知服务初始化超时');
          throw TimeoutException('通知服务初始化超时', const Duration(seconds: _initTimeoutSeconds));
        }
      }
      return;
    }
    
    _initializing = true;
    
    try {
      // 初始化时区数据
      tz.initializeTimeZones();
      
      // 优先使用 Asia/Shanghai 时区（中国用户主要时区）
      // 也支持其他时区，按优先级尝试
      try {
        final location = tz.getLocation('Asia/Shanghai');
        tz.setLocalLocation(location);
        debugPrint('✓ 通知服务使用时区: Asia/Shanghai (UTC+8)');
      } catch (e) {
        try {
          // 备选：亚洲/重庆（已弃用但仍可用作别名，与上海相同时区）
          // 注意：Asia/Chongqing 在 IANA 时区数据库中已被弃用（2014年起）
          // 但作为 Asia/Shanghai 的别名仍然可用
          final location = tz.getLocation('Asia/Chongqing');
          tz.setLocalLocation(location);
          debugPrint('✓ 通知服务使用时区: Asia/Chongqing (UTC+8)');
        } catch (e2) {
          // 最后备选：UTC（确保初始化总能成功）
          debugPrint('⚠️ 无法设置中国时区，使用 UTC: $e');
          tz.setLocalLocation(tz.UTC);
        }
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
      debugPrint('✓ 通知服务初始化成功');
    } catch (e) {
      debugPrint('❌ 通知服务初始化失败: $e');
      rethrow;
    } finally {
      _initializing = false;
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
    bool granted = false;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Android 13+ 需要请求通知权限
        granted = await androidImplementation.requestNotificationsPermission() ?? false;
        
        if (!granted) {
          debugPrint('❌ 通知权限被拒绝');
          return false;
        }
        
        // Android 12+ (API 31+) 需要检查精确闹钟权限
        try {
          final canScheduleExact = await androidImplementation.canScheduleExactNotifications();
          if (canScheduleExact != null && !canScheduleExact) {
            debugPrint('⚠️ 警告：精确闹钟权限未授予。通知可能不准时。');
            debugPrint('提示：请在系统设置中为本应用启用"精确闹钟"权限以确保通知准时送达。');
            debugPrint('路径：设置 -> 应用 -> 特殊访问权限 -> 闹钟和提醒 -> 允许');
            
            // 尝试请求精确闹钟权限（Android 12+）
            try {
              await androidImplementation.requestExactAlarmsPermission();
              // 再次检查
              final recheckExact = await androidImplementation.canScheduleExactNotifications();
              if (recheckExact == true) {
                debugPrint('✓ 精确闹钟权限已授予');
              }
            } catch (e) {
              debugPrint('无法自动请求精确闹钟权限: $e');
            }
            
            // 即使没有精确闹钟权限，仍返回true让应用继续运行
            // 用户可以稍后在设置中手动授权
            return true;
          } else if (canScheduleExact == true) {
            debugPrint('✓ 精确闹钟权限已授予');
          }
        } catch (e) {
          debugPrint('检查精确闹钟权限时出错: $e');
        }
        
        return granted;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iosImplementation != null) {
        granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
        
        if (granted) {
          debugPrint('✓ iOS通知权限已授予');
        } else {
          debugPrint('❌ iOS通知权限被拒绝');
        }
        
        return granted;
      }
    }
    
    // 其他平台默认返回true
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
      final reminderDateTime = reminder.reminderDateTime;
      
      // 创建时区感知的提醒时间
      final tzNotificationDateTime = tz.TZDateTime(
        tz.local,
        reminderDateTime.year,
        reminderDateTime.month,
        reminderDateTime.day,
        reminderDateTime.hour,
        reminderDateTime.minute,
        reminderDateTime.second,
      );

      // 如果通知时间已过，则不调度
      final now = tz.TZDateTime.now(tz.local);
      if (tzNotificationDateTime.isBefore(now)) {
        debugPrint('⏭ 提醒时间已过，跳过: ${event.title} - ${tzNotificationDateTime.toIso8601String()}');
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
        vibrationPattern: Int64List.fromList(_vibrationPatternMs),
        enableLights: true,
        ledColor: _ledColor,
        ledOnMs: _ledOnMs,
        ledOffMs: _ledOffMs,
        playSound: true,
        // 使用系统默认通知声音（不指定sound参数）
        // 如需自定义声音：创建 android/app/src/main/res/raw/ 目录
        // 并添加音频文件，然后使用 RawResourceAndroidNotificationSound('文件名')
        channelShowBadge: true,
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
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
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
  /// 根据事件和提醒信息生成友好的提醒文本，包含剩余时间
  String _getReminderMessage(CountdownEvent event, Reminder reminder) {
    // 如果有自定义消息，优先使用
    if (reminder.customMessage != null && reminder.customMessage!.isNotEmpty) {
      return reminder.customMessage!;
    }
    
    // 计算从提醒时间到目标日期的剩余时间
    final targetDate = event.targetDate;
    final reminderDateTime = reminder.reminderDateTime;
    
    // 计算剩余天数
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final reminderDay = DateTime(reminderDateTime.year, reminderDateTime.month, reminderDateTime.day);
    final daysRemaining = targetDay.difference(reminderDay).inDays;
    
    // 计算剩余时分秒
    final timeRemaining = targetDate.difference(reminderDateTime);
    final hours = timeRemaining.inHours % 24;
    final minutes = timeRemaining.inMinutes % 60;
    
    // 生成消息
    if (daysRemaining == 0) {
      if (hours == 0 && minutes == 0) {
        return '今天就是 ${event.title} 的日子！🎉';
      } else {
        return '今天就是 ${event.title}！还有 ${hours}小时${minutes}分钟 ⏰';
      }
    } else if (daysRemaining == 1) {
      return '明天就是 ${event.title} 了！还有1天 ⏰';
    } else if (daysRemaining == 2) {
      return '后天就是 ${event.title} 了！还有2天 📅';
    } else if (daysRemaining <= 7) {
      return '${event.title} 还有 $daysRemaining 天 📆';
    } else if (daysRemaining <= 30) {
      return '${event.title} 还有 $daysRemaining 天 🗓️';
    } else {
      return '${event.title} 还有 $daysRemaining 天';
    }
  }

  /// 生成通知 ID
  /// 
  /// 使用确定性算法生成唯一的通知 ID，避免哈希碰撞。
  /// 基于事件 ID 和提醒 ID 的组合，确保同一提醒总是生成相同的 ID。
  /// 
  /// 注意：使用管道符(|)而非下划线(_)作为分隔符，因为 UUID 中可能包含下划线，
  /// 而管道符更不可能出现在 ID 中，从而减少碰撞风险。
  int _generateNotificationId(String eventId, String reminderId) {
    // 使用 Dart 内置 hashCode，确保结果在有效范围内
    // 保持在 31 位有符号整数范围内
    final hash = '$eventId|$reminderId'.hashCode & 0x7FFFFFFF;
    
    // 将所有 ID 映射到 [0, 2000000000) 范围，避免与测试通知 ID 冲突
    // 测试通知使用范围 [2000000000, 2010000000)
    return hash % 2000000000;
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
  
  // 测试通知 ID 范围常量
  // 提供 1000 万个唯一测试 ID，足够避免在合理使用场景下的冲突
  static const int _testNotificationIdBase = 2000000000;
  static const int _testNotificationIdRange = 10000000; // 10 million unique IDs
  
  /// 发送测试通知
  /// 
  /// 立即显示一个测试通知，用于验证通知功能是否正常工作
  Future<void> sendTestNotification({
    required String eventTitle,
    String? message,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      // 使用时间戳生成唯一的测试通知 ID，避免多次测试时相互覆盖
      // 测试通知 ID 范围: [2000000000, 2010000000)
      final testNotificationId = _testNotificationIdBase + 
          (DateTime.now().millisecondsSinceEpoch % _testNotificationIdRange);
      
      final androidDetails = AndroidNotificationDetails(
        'event_reminders',
        '事件提醒',
        channelDescription: '倒数日事件的提醒通知',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(_vibrationPatternMs),
        enableLights: true,
        ledColor: _ledColor,
        ledOnMs: _ledOnMs,
        ledOffMs: _ledOffMs,
        playSound: true,
        // 使用系统默认通知声音（不指定sound参数）
        // 如需自定义声音：创建 android/app/src/main/res/raw/ 目录
        // 并添加音频文件，然后使用 RawResourceAndroidNotificationSound('文件名')
        channelShowBadge: true,
        styleInformation: BigTextStyleInformation(
          message ?? '这是一条测试通知 🔔',
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

      await _notifications.show(
        testNotificationId,
        eventTitle,
        message ?? '这是一条测试通知 🔔',
        notificationDetails,
        payload: 'test_notification',
      );
      
      debugPrint('✓ 测试通知已发送 (ID: $testNotificationId)');
    } catch (e) {
      debugPrint('❌ 发送测试通知失败: $e');
      rethrow;
    }
  }
}
