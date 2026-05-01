import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/countdown_event.dart';
import '../models/widget_config.dart';

/// ============================================================================
/// 小部件服务 - 管理桌面小部件的数据更新（Glance版本）
/// 支持多实例独立配置，每个 Widget 可以显示不同的事件
/// ============================================================================

class WidgetService {
  static const String _packageName = 'com.jiuxina.ying';

  /// 存储 widgetId -> eventId 映射的 key
  static const String _mappingKey = 'widget_event_mapping';

  /// Provider名称映射
  static const Map<WidgetType, String> _providerNames = {
    WidgetType.standard: 'CountdownWidgetReceiver',
    WidgetType.large: 'CountdownLargeWidgetReceiver',
    WidgetType.mini: 'CountdownMiniWidgetReceiver',
  };

  /// 更新所有小部件数据
  static Future<void> updateAllWidgets(List<CountdownEvent> events) async {
    // 筛选未归档且非私密的事件并排序
    final activeEvents = _sortEvents(events);

    // 保存事件数据到SharedPreferences（供所有小部件读取）
    await _saveEventData(activeEvents);

    // 刷新所有已配置的 Widget（per-instance）
    await refreshAllConfiguredWidgets(events);

    // 触发更新
    await _triggerWidgetUpdate(WidgetType.standard);
    await _triggerWidgetUpdate(WidgetType.large);
    await _triggerWidgetUpdate(WidgetType.mini);
  }

  /// 刷新所有已配置的 Widget（根据 widgetId -> eventId 映射）
  static Future<void> refreshAllConfiguredWidgets(List<CountdownEvent> events) async {
    final mapping = await _getWidgetMapping();
    if (mapping.isEmpty) return;

    final eventMap = {for (var e in events) e.id: e};

    for (final entry in mapping.entries) {
      final widgetId = entry.key;
      final eventId = entry.value;
      final event = eventMap[eventId];

      if (event != null) {
        // 更新该 Widget 的数据
        await _saveWidgetEventData(int.parse(widgetId), event);
      }
    }
  }

  /// 获取 widgetId -> eventId 映射
  static Future<Map<String, String>> _getWidgetMapping() async {
    try {
      final data = await HomeWidget.getWidgetData<String>(_mappingKey);
      if (data == null || data.isEmpty) return {};
      return Map<String, String>.from(jsonDecode(data));
    } catch (e) {
      return {};
    }
  }

  /// 保存 widgetId -> eventId 映射
  static Future<void> _saveWidgetMapping(Map<String, String> mapping) async {
    await HomeWidget.saveWidgetData<String>(_mappingKey, jsonEncode(mapping));
  }

  /// 删除指定 Widget 的映射
  static Future<void> removeWidgetMapping(int widgetId) async {
    final mapping = await _getWidgetMapping();
    mapping.remove(widgetId.toString());
    await _saveWidgetMapping(mapping);
  }

  /// 更新指定类型的小部件
  static Future<void> updateWidgetByType(
    WidgetType type,
    List<CountdownEvent> events,
  ) async {
    final activeEvents = _sortEvents(events);
    await _saveEventData(activeEvents);
    await _triggerWidgetUpdate(type);
  }

  /// 更新小部件配置（样式设置）
  static Future<void> updateWidgetConfig(WidgetConfig config) async {
    // Glance 组件可能需要不同的配置逻辑，这里暂时保留旧逻辑
    // 或者根据 Glance 的需求保存配置
    final prefix = config.type.configPrefix;
    await HomeWidget.saveWidgetData<int>('${prefix}_bg_color', config.backgroundColor);
    await HomeWidget.saveWidgetData<String>('${prefix}_bg_image', config.backgroundImage ?? '');
    await HomeWidget.saveWidgetData<bool>('${prefix}_show_date', config.showDate);
    await HomeWidget.saveWidgetData<bool>('${prefix}_show_title', config.showTitle);
    await HomeWidget.saveWidgetData<bool>('${prefix}_show_days', config.showDays);
    await HomeWidget.saveWidgetData<bool>('${prefix}_show_icon', config.showIcon);
    await HomeWidget.saveWidgetData<String>('${prefix}_font_size', config.fontSize.name);
    await HomeWidget.saveWidgetData<double>('${prefix}_corner_radius', config.cornerRadius);
    await HomeWidget.saveWidgetData<int>('${prefix}_text_color', config.textColor);
    
    if (config.gradientEndColor != null) {
      await HomeWidget.saveWidgetData<int>('${prefix}_gradient_end', config.gradientEndColor!);
    }
    
    await _triggerWidgetUpdate(config.type);
  }

  /// 兼容旧方法 - 更新小部件（单事件）
  static Future<void> updateWidget(CountdownEvent? event) async {
    if (event != null) {
      await updateAllWidgets([event]);
    } else {
      await updateAllWidgets([]);
    }
  }

  /// 兼容旧方法 - 用顶部事件更新
  static Future<void> updateWithTopEvent(List<CountdownEvent> events) async {
    await updateAllWidgets(events);
  }

  /// 兼容旧方法 - 更新多事件
  static Future<void> updateWidgets(List<CountdownEvent> events) async {
    await updateAllWidgets(events);
  }

  /// 保存特定 Widget ID 的配置（Glance多实例支持）
  static Future<void> saveConfiguredWidget(int widgetId, CountdownEvent event, {WidgetConfig? config}) async {
    // 1. 保存事件数据（per-widget）
    await _saveWidgetEventData(widgetId, event);

    // 2. 保存 widgetId -> eventId 映射
    final mapping = await _getWidgetMapping();
    mapping[widgetId.toString()] = event.id;
    await _saveWidgetMapping(mapping);

    // 3. 保存样式配置
    if (config != null) {
      await saveWidgetStyle(widgetId, config);
    }

    // 4. 触发所有 Widget 更新
    await _triggerAllWidgetUpdates();
  }

  /// 保存 Widget 的事件数据
  static Future<void> _saveWidgetEventData(int widgetId, CountdownEvent event) async {
    await HomeWidget.saveWidgetData<String>('title_$widgetId', event.title);
    await HomeWidget.saveWidgetData<int>('target_ts_$widgetId', event.targetDate.millisecondsSinceEpoch);
    await HomeWidget.saveWidgetData<String>('date_str_$widgetId', DateFormat('yyyy-MM-dd').format(event.targetDate));
    
    // 额外保存事件ID，方便后续查询
    await HomeWidget.saveWidgetData<String>('event_id_$widgetId', event.id);
  }

  /// 保存 Widget 样式配置
  static Future<void> saveWidgetStyle(int widgetId, WidgetConfig config) async {
    final prefix = 'style_$widgetId';
    await HomeWidget.saveWidgetData<int>('${prefix}_bg_color', config.backgroundColor);
    await HomeWidget.saveWidgetData<String>('${prefix}_style', config.style.name);
    await HomeWidget.saveWidgetData<bool>('${prefix}_show_date', config.showDate);
    await HomeWidget.saveWidgetData<bool>('${prefix}_show_title', config.showTitle);
    await HomeWidget.saveWidgetData<bool>('${prefix}_show_days', config.showDays);
    await HomeWidget.saveWidgetData<bool>('${prefix}_show_icon', config.showIcon);
    await HomeWidget.saveWidgetData<String>('${prefix}_font_size', config.fontSize.name);
    await HomeWidget.saveWidgetData<double>('${prefix}_opacity', config.opacity);
    await HomeWidget.saveWidgetData<double>('${prefix}_corner_radius', config.cornerRadius);
    await HomeWidget.saveWidgetData<int>('${prefix}_text_color', config.textColor);
    
    if (config.gradientEndColor != null) {
      await HomeWidget.saveWidgetData<int>('${prefix}_gradient_end', config.gradientEndColor!);
    }
    
    if (config.backgroundImage != null) {
      await HomeWidget.saveWidgetData<String>('${prefix}_bg_image', config.backgroundImage!);
    }
  }

  /// 获取 Widget 配置的事件ID
  static Future<String?> getWidgetEventId(int widgetId) async {
    return await HomeWidget.getWidgetData<String>('event_id_$widgetId');
  }

  /// 触发所有 Widget 更新
  static Future<void> _triggerAllWidgetUpdates() async {
    await _triggerWidgetUpdate(WidgetType.mini);
    await _triggerWidgetUpdate(WidgetType.standard);
    await _triggerWidgetUpdate(WidgetType.large);
  }

  /// 提供一个静态方法 updateCountdown 供外部直接调用
  static Future<void> updateCountdown(String title, DateTime targetDate) async {
     await HomeWidget.saveWidgetData<String>('title', title);
     await HomeWidget.saveWidgetData<int>('target_ts', targetDate.millisecondsSinceEpoch);
     await HomeWidget.saveWidgetData<String>('date_str', DateFormat('yyyy-MM-dd').format(targetDate));
     
     await HomeWidget.updateWidget(
        androidName: 'CountdownWidgetReceiver',
        qualifiedAndroidName: '$_packageName.CountdownWidgetReceiver',
      );
  }

  // ==================== 私有方法 ====================

  /// 排序事件（置顶优先，然后按天数）
  /// 排除私密事件
  static List<CountdownEvent> _sortEvents(List<CountdownEvent> events) {
    // 逻辑不变，但排除私密事件
    final activeEvents = events
        .where((e) => !e.isArchived && !e.isPrivate)
        .toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return a.daysRemaining.compareTo(b.daysRemaining);
      });
    return activeEvents;
  }

  /// 保存事件数据到SharedPreferences
  static Future<void> _saveEventData(List<CountdownEvent> events) async {
    if (events.isNotEmpty) {
      final main = events.first;
      
      // 保存给 Glance 组件使用的数据
      // 按照用户需求：title, target_ts, date_str
      await HomeWidget.saveWidgetData<String>('title', main.title);
      await HomeWidget.saveWidgetData<int>('target_ts', main.targetDate.millisecondsSinceEpoch);
      await HomeWidget.saveWidgetData<String>('date_str', DateFormat('yyyy-MM-dd').format(main.targetDate)); // 简化日期格式
      
      // 同时保留旧数据以防万一（如果大组件还在用）
      final days = main.daysRemaining.abs();
      final isCountUp = main.isCountUp;
      final prefix = isCountUp ? '已经' : (main.daysRemaining >= 0 ? '还有' : '已过');
      final dateStrOld = DateFormat('yyyy年MM月dd日').format(main.targetDate);

      await HomeWidget.saveWidgetData<String>('widget_title', main.title);
      await HomeWidget.saveWidgetData<String>('widget_days', '$days');
      await HomeWidget.saveWidgetData<String>('widget_prefix', prefix);
      await HomeWidget.saveWidgetData<String>('widget_date', dateStrOld);

      // 保存列表数据（供大组件显示列表）
      if (events.length > 1) {
        final e2 = events[1];
        final d2 = e2.daysRemaining.abs();
        await HomeWidget.saveWidgetData<String>('widget_event2_title', e2.title);
        await HomeWidget.saveWidgetData<String>('widget_event2_days', '$d2');
      } else {
        await HomeWidget.saveWidgetData<String>('widget_event2_title', '');
        await HomeWidget.saveWidgetData<String>('widget_event2_days', '');
      }

      if (events.length > 2) {
        final e3 = events[2];
        final d3 = e3.daysRemaining.abs();
        await HomeWidget.saveWidgetData<String>('widget_event3_title', e3.title);
        await HomeWidget.saveWidgetData<String>('widget_event3_days', '$d3');
      } else {
        await HomeWidget.saveWidgetData<String>('widget_event3_title', '');
        await HomeWidget.saveWidgetData<String>('widget_event3_days', '');
      }
    } else {
        // 清空或默认
      await HomeWidget.saveWidgetData<String>('title', '萤');
      await HomeWidget.saveWidgetData<int>('target_ts', DateTime.now().millisecondsSinceEpoch);
      await HomeWidget.saveWidgetData<String>('date_str', '');
    }
  }

  /// 触发指定类型小部件更新
  static Future<void> _triggerWidgetUpdate(WidgetType type) async {
    final providerName = _providerNames[type];
    if (providerName != null) {
      await HomeWidget.updateWidget(
        androidName: providerName,
        qualifiedAndroidName: '$_packageName.$providerName',
      );
    }
  }
}
