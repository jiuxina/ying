import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/countdown_event.dart';
import 'widget_service.dart';

/// ============================================================================
/// Widget 更新调度器 - 确保跨天时 Widget 显示正确的天数
/// ============================================================================
class WidgetUpdateScheduler {
  static WidgetUpdateScheduler? _instance;
  static WidgetUpdateScheduler get instance => _instance ??= WidgetUpdateScheduler._();
  WidgetUpdateScheduler._();

  Timer? _midnightTimer;
  List<CountdownEvent> _events = [];
  
  /// 启动午夜更新调度
  void startScheduling(List<CountdownEvent> events) {
    _events = events;
    _scheduleNextMidnight();
  }

  /// 更新事件列表
  void updateEvents(List<CountdownEvent> events) {
    _events = events;
  }

  /// 停止调度
  void stopScheduling() {
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }

  /// 调度到下一个午夜
  void _scheduleNextMidnight() {
    _midnightTimer?.cancel();
    
    final now = DateTime.now();
    // 计算到下一个午夜的时间
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);
    
    debugPrint('Widget 更新调度: 将在 ${duration.inMinutes} 分钟后更新');
    
    _midnightTimer = Timer(duration, () async {
      debugPrint('Widget 午夜更新触发: ${DateTime.now()}');
      
      // 更新所有 Widget
      if (_events.isNotEmpty) {
        await WidgetService.refreshAllConfiguredWidgets(_events);
        await WidgetService.updateAllWidgets(_events);
      }
      
      // 重新调度下一次更新
      _scheduleNextMidnight();
    });
  }

  /// 立即刷新所有 Widget
  Future<void> refreshNow() async {
    if (_events.isNotEmpty) {
      await WidgetService.refreshAllConfiguredWidgets(_events);
      await WidgetService.updateAllWidgets(_events);
    }
  }
}
